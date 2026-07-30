"use strict";

const { randomBytes } = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const {
  allRoles,
  effectivePermissionsForRoles,
} = require("./role-permissions");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const leadershipRoles = new Set([
  "superAdmin",
  "schoolOwner",
  "principal",
  "vicePrincipal",
]);
const accountAdministratorRoles = new Set(["adminStaff", "itAdmin"]);
const defaultStaffLimits = Object.freeze({
  trial: 10,
  starter: 40,
  pro: 250,
  enterprise: 0,
  custom: 0,
});

const meteredCollectionConfig = Object.freeze({
  students: Object.freeze({
    usageField: "students",
    limitKey: "students",
    permissions: Object.freeze(["students.create", "students.manage"]),
  }),
  campuses: Object.freeze({
    usageField: "campuses",
    limitKey: "campuses",
    permissions: Object.freeze(["school_setup.manage"]),
  }),
});

const defaultMeteredLimits = Object.freeze({
  trial: Object.freeze({ students: 30, campuses: 1 }),
  starter: Object.freeze({ students: 250, campuses: 1 }),
  pro: Object.freeze({ students: 2000, campuses: 10 }),
  enterprise: Object.freeze({ students: 0, campuses: 0 }),
  custom: Object.freeze({ students: 0, campuses: 0 }),
});

function cleanText(value, field, maxLength = 160) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  const result = value.trim();
  if (!result || result.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} is invalid.`);
  }
  return result;
}

function cleanList(value, field, allowedValues = null) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  const result = [...new Set(value.map((item) => cleanText(item, field, 80)))];
  if (allowedValues && result.some((item) => !allowedValues.includes(item))) {
    throw new HttpsError("invalid-argument", `${field} contains an unsupported value.`);
  }
  return result;
}

async function getCallerMembership(uid, tenantId) {
  const snapshot = await db
    .collection("tenants")
    .doc(tenantId)
    .collection("members")
    .doc(uid)
    .get();
  const membership = snapshot.data();
  if (
    !snapshot.exists ||
    membership?.isActive === false ||
    ["inactive", "suspended", "disabled"].includes(
      String(membership?.status ?? "").toLowerCase(),
    )
  ) {
    throw new HttpsError("permission-denied", "Your school membership is inactive.");
  }
  return membership;
}

function canManageUsers(membership) {
  const roles = Array.isArray(membership.roles) ? membership.roles : [];
  const permissions = Array.isArray(membership.permissions)
    ? membership.permissions
    : [];
  return (
    roles.some((role) => leadershipRoles.has(role)) ||
    roles.some((role) => ["adminStaff", "itAdmin"].includes(role)) ||
    permissions.includes("*") ||
    permissions.includes("users.manage")
  );
}

function assertRoleDelegation(callerMembership, requestedRoles) {
  const callerRoles = Array.isArray(callerMembership.roles)
    ? callerMembership.roles
    : [];
  const callerIsSuperAdmin = callerRoles.includes("superAdmin");
  const callerIsSchoolOwner = callerRoles.includes("schoolOwner");

  if (requestedRoles.includes("superAdmin") && !callerIsSuperAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Only a super administrator can assign the super-admin role.",
    );
  }

  if (
    requestedRoles.some((role) => leadershipRoles.has(role)) &&
    !callerIsSuperAdmin &&
    !callerIsSchoolOwner
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only the school owner can assign a leadership role.",
    );
  }

  if (
    requestedRoles.some((role) => accountAdministratorRoles.has(role)) &&
    !callerIsSuperAdmin &&
    !callerIsSchoolOwner
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only the school owner can assign an account-administrator role.",
    );
  }
}


function cleanCampusIds(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(
    value
      .map((item) => String(item ?? "").trim())
      .filter((item) => item.length > 0 && item.length <= 100),
  )];
}

function validateTemporaryPassword(value) {
  if (typeof value !== "string" || value.length < 10 || value.length > 128) {
    throw new HttpsError(
      "invalid-argument",
      "Temporary password must contain 10 to 128 characters.",
    );
  }
  if (
    !/[A-Z]/.test(value) ||
    !/[a-z]/.test(value) ||
    !/[0-9]/.test(value) ||
    !/[^A-Za-z0-9]/.test(value)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Temporary password requires uppercase, lowercase, number and special characters.",
    );
  }
  return value;
}

function callerIsSuperAdmin(membership) {
  const roles = Array.isArray(membership?.roles) ? membership.roles : [];
  return roles.includes("superAdmin");
}

function assertCanManageTarget(callerMembership, targetRoles) {
  const callerRoles = Array.isArray(callerMembership?.roles)
    ? callerMembership.roles
    : [];
  const callerIsSuper = callerRoles.includes("superAdmin");
  const callerIsOwner = callerRoles.includes("schoolOwner");
  const targetIsSuper = targetRoles.includes("superAdmin");
  const targetIsLeadership = targetRoles.some((role) => leadershipRoles.has(role));
  const targetIsAccountAdmin = targetRoles.some((role) =>
    accountAdministratorRoles.has(role),
  );

  if (targetIsSuper && !callerIsSuper) {
    throw new HttpsError(
      "permission-denied",
      "Only a super administrator can manage this account.",
    );
  }
  if (targetIsLeadership && !callerIsSuper && !callerIsOwner) {
    throw new HttpsError(
      "permission-denied",
      "Only the school owner can manage a leadership account.",
    );
  }
  if (targetIsAccountAdmin && !callerIsSuper && !callerIsOwner) {
    throw new HttpsError(
      "permission-denied",
      "Only the school owner can manage an account administrator.",
    );
  }
}

function accountCategoryForRoles(roles) {
  const normalized = Array.isArray(roles) ? roles : [];
  return normalized.length > 0 &&
    normalized.every((role) => ["student", "parent"].includes(role))
    ? "portal"
    : "staff";
}

async function activeStaffCount(tenantRef) {
  const snapshot = await tenantRef
    .collection("members")
    .where("isActive", "==", true)
    .get();
  return snapshot.docs.filter((document) => {
    const data = document.data() ?? {};
    const roles = Array.isArray(data.roles)
      ? data.roles
      : (data.role ? [data.role] : []);
    const category = ["staff", "portal"].includes(data.accountCategory)
      ? data.accountCategory
      : accountCategoryForRoles(roles);
    return category === "staff";
  }).length;
}

function staffLimitFor(subscription) {
  const tier = String(subscription?.tier ?? "trial").toLowerCase();
  const configuredLimit = Number(subscription?.limits?.staffUsers);
  return {
    tier,
    limit: Number.isFinite(configuredLimit) && configuredLimit >= 0
      ? configuredLimit
      : (defaultStaffLimits[tier] ?? defaultStaffLimits.trial),
  };
}

async function assertStaffCapacity(tenantRef, subscription) {
  const { tier, limit } = staffLimitFor(subscription);
  if (limit <= 0) return;
  const currentStaffUsers = await activeStaffCount(tenantRef);
  if (currentStaffUsers >= limit) {
    throw new HttpsError(
      "resource-exhausted",
      `The ${tier} plan staff-user limit (${limit}) has been reached.`,
    );
  }
}


function timestampDate(value) {
  if (value?.toDate) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function assertSubscriptionUsable(tenantData) {
  if (tenantData?.isActive === false) {
    throw new HttpsError("failed-precondition", "The selected school is inactive.");
  }
  const subscription = tenantData?.subscription ?? {};
  const status = String(subscription.status ?? "active").toLowerCase();
  if (["cancelled", "suspended", "expired"].includes(status)) {
    throw new HttpsError(
      "failed-precondition",
      "The school subscription is not active.",
    );
  }
  const periodEnd = timestampDate(
    status === "trialing"
      ? subscription.trialEndsAt ?? subscription.currentPeriodEnd
      : subscription.currentPeriodEnd,
  );
  if (periodEnd && periodEnd < new Date()) {
    const graceEnd = timestampDate(subscription.gracePeriodEndsAt);
    if (!graceEnd || graceEnd < new Date()) {
      throw new HttpsError(
        "failed-precondition",
        "The school subscription period has expired.",
      );
    }
  }
  return subscription;
}

function planLimit(subscription, key) {
  const configured = Number(subscription?.limits?.[key]);
  if (Number.isFinite(configured) && configured >= 0) return configured;
  const tier = String(subscription?.tier ?? "trial").toLowerCase();
  return Number(defaultMeteredLimits[tier]?.[key] ?? defaultMeteredLimits.trial[key]);
}

function hasAnyPermission(membership, permissions) {
  const roles = Array.isArray(membership?.roles) ? membership.roles : [];
  const current = Array.isArray(membership?.permissions)
    ? membership.permissions
    : [];
  return (
    roles.some((role) => leadershipRoles.has(role)) ||
    current.includes("*") ||
    permissions.some((permission) => current.includes(permission))
  );
}

function cleanRecordValues(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Record values are required.");
  }
  const entries = Object.entries(value);
  if (entries.length === 0 || entries.length > 100) {
    throw new HttpsError("invalid-argument", "Record values are invalid.");
  }
  const blocked = new Set([
    "tenantId", "createdAt", "createdBy", "updatedAt", "updatedBy",
    "archivedAt", "archivedBy", "isArchived",
  ]);
  if (entries.some(([key]) => blocked.has(key))) {
    throw new HttpsError(
      "invalid-argument",
      "System metadata cannot be supplied by the client.",
    );
  }
  if (Buffer.byteLength(JSON.stringify(value), "utf8") > 200000) {
    throw new HttpsError("invalid-argument", "The record is too large.");
  }
  return value;
}

async function provisionSchoolUser(request) {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in before creating an account.");
  }

  const tenantId = cleanText(request.data?.tenantId, "School", 100);
  const email = cleanText(request.data?.email, "Email", 180).toLowerCase();
  const displayName = cleanText(request.data?.displayName, "Display name", 120);
  const roles = cleanList(request.data?.roles, "Role", allRoles);
  const campusIds = cleanCampusIds(request.data?.campusIds);
  const recordType = String(request.data?.recordType ?? "").trim();
  const recordId = String(request.data?.recordId ?? "").trim();
  const setupMethod = String(
    request.data?.setupMethod ?? "temporaryPassword",
  ).trim();
  const forcePasswordChange = request.data?.forcePasswordChange !== false;

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  if (!["temporaryPassword", "emailLink"].includes(setupMethod)) {
    throw new HttpsError("invalid-argument", "Account setup method is invalid.");
  }
  const requestedPassword = setupMethod === "temporaryPassword"
    ? validateTemporaryPassword(request.data?.temporaryPassword)
    : randomBytes(32).toString("base64url");

  if (recordType && !["student", "guardian", "teacher"].includes(recordType)) {
    throw new HttpsError("invalid-argument", "Linked record type is invalid.");
  }
  if ((recordType && !recordId) || (!recordType && recordId)) {
    throw new HttpsError(
      "invalid-argument",
      "Both linked record type and record ID are required.",
    );
  }
  const hasStudentRole = roles.includes("student");
  const hasParentRole = roles.includes("parent");
  const hasTeacherRole = roles.some((role) =>
    ["teacher", "classTeacher"].includes(role),
  );
  if (hasStudentRole && recordType !== "student") {
    throw new HttpsError(
      "invalid-argument",
      "Student accounts must be linked to a student profile.",
    );
  }
  if (hasParentRole && recordType !== "guardian") {
    throw new HttpsError(
      "invalid-argument",
      "Parent accounts must be linked to a guardian profile.",
    );
  }
  if (hasTeacherRole && recordType !== "teacher") {
    throw new HttpsError(
      "invalid-argument",
      "Teacher accounts must be linked to a teacher profile.",
    );
  }
  if (recordType === "student" && !hasStudentRole) {
    throw new HttpsError(
      "invalid-argument",
      "A student profile can only be linked to a student role.",
    );
  }
  if (recordType === "guardian" && !hasParentRole) {
    throw new HttpsError(
      "invalid-argument",
      "A guardian profile can only be linked to a parent role.",
    );
  }
  if (recordType === "teacher" && !hasTeacherRole) {
    throw new HttpsError(
      "invalid-argument",
      "A teacher profile requires a teacher or class-teacher role.",
    );
  }

  const callerMembership = await getCallerMembership(request.auth.uid, tenantId);
  if (!canManageUsers(callerMembership)) {
    throw new HttpsError(
      "permission-denied",
      "You do not have permission to manage school accounts.",
    );
  }
  assertRoleDelegation(callerMembership, roles);

  let targetUser = null;
  let createdAuthUser = false;
  try {
    targetUser = await auth.getUserByEmail(email);
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
  }

  if (targetUser?.uid === request.auth.uid) {
    throw new HttpsError(
      "failed-precondition",
      "Use another administrator to change your own roles.",
    );
  }

  const tenantRef = db.collection("tenants").doc(tenantId);
  const tenantSnapshot = await tenantRef.get();
  if (!tenantSnapshot.exists || tenantSnapshot.data()?.isActive === false) {
    throw new HttpsError("failed-precondition", "The selected school is inactive.");
  }
  const subscription = assertSubscriptionUsable(tenantSnapshot.data() ?? {});

  if (targetUser) {
    const existingMembership = await tenantRef
      .collection("members")
      .doc(targetUser.uid)
      .get();
    if (existingMembership.exists) {
      throw new HttpsError(
        "already-exists",
        "This email already has an account in the selected school. Edit it from the account directory.",
      );
    }
  }
  const accountCategory = accountCategoryForRoles(roles);
  if (accountCategory === "staff") {
    await assertStaffCapacity(tenantRef, subscription);
  }

  if (recordType && recordId) {
    const collection = recordType === "student"
      ? "students"
      : recordType === "guardian"
        ? "guardians"
        : "teachers";
    const recordSnapshot = await tenantRef.collection(collection).doc(recordId).get();
    if (!recordSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        `The linked ${recordType} record was not found.`,
      );
    }
    const currentAuthUid = String(recordSnapshot.data()?.authUid ?? "").trim();
    if (currentAuthUid && currentAuthUid !== targetUser?.uid) {
      throw new HttpsError(
        "already-exists",
        `The linked ${recordType} record already has a login account.`,
      );
    }
  }

  let guardianLinks = [];
  const guardianStudentRecords = [];
  if (recordType === "guardian" && recordId) {
    const linkSnapshot = await tenantRef
      .collection("student_guardians")
      .where("guardianId", "==", recordId)
      .limit(100)
      .get();
    guardianLinks = linkSnapshot.docs;
    if (guardianLinks.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Link this guardian to at least one student before creating the parent portal account.",
      );
    }

    for (const linkDocument of guardianLinks) {
      const link = linkDocument.data() ?? {};
      const candidate = String(
        link.studentRecordId ?? link.studentId ?? "",
      ).trim();
      if (!candidate) continue;

      let studentSnapshot = await tenantRef.collection("students").doc(candidate).get();
      if (!studentSnapshot.exists) {
        const byAdmission = await tenantRef
          .collection("students")
          .where("admissionNo", "==", candidate)
          .limit(2)
          .get();
        if (byAdmission.size === 1) studentSnapshot = byAdmission.docs[0];
      }
      if (studentSnapshot.exists) {
        guardianStudentRecords.push(studentSnapshot);
      }
    }
  }

  if (!targetUser) {
    targetUser = await auth.createUser({
      email,
      displayName,
      password: requestedPassword,
      emailVerified: false,
      disabled: false,
    });
    createdAuthUser = true;
  }

  const targetUid = targetUser.uid;
  const userRef = db.collection("users").doc(targetUid);
  const memberRef = tenantRef.collection("members").doc(targetUid);
  const effectivePermissions = effectivePermissionsForRoles(roles);
  const passwordWasApplied = createdAuthUser && setupMethod === "temporaryPassword";
  const requiresPasswordChange = passwordWasApplied && forcePasswordChange;
  const now = FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.set(
    userRef,
    {
      email,
      displayName,
      tenantIds: FieldValue.arrayUnion(tenantId),
      activeTenantId: tenantId,
      isActive: true,
      ...(createdAuthUser
        ? {
          mustChangePassword: requiresPasswordChange,
          accountSetupMethod: setupMethod,
          createdAt: now,
          createdBy: request.auth.uid,
        }
        : {}),
      updatedAt: now,
    },
    { merge: true },
  );
  batch.create(memberRef, {
    tenantId,
    email,
    displayName,
    status: "active",
    isActive: true,
    roles,
    permissions: effectivePermissions,
    deniedPermissions: [],
    campusIds,
    activeCampusId: campusIds[0] ?? null,
    accountCategory,
    linkedRecordType: recordType || null,
    linkedRecordId: recordId || null,
    mustChangePassword: requiresPasswordChange,
    accountSetupMethod: setupMethod,
    invitationStatus: setupMethod === "emailLink" ? "pending" : "temporaryPassword",
    createdBy: request.auth.uid,
    createdAt: now,
    updatedBy: request.auth.uid,
    updatedAt: now,
  });
  if (accountCategory === "staff") {
    batch.set(
      tenantRef.collection("saas_usage").doc("current"),
      {
        staffUsers: FieldValue.increment(1),
        updatedAt: now,
        updatedBy: request.auth.uid,
      },
      { merge: true },
    );
  }

  if (recordType && recordId) {
    const collection = recordType === "student"
      ? "students"
      : recordType === "guardian"
        ? "guardians"
        : "teachers";
    batch.update(tenantRef.collection(collection).doc(recordId), {
      authUid: targetUid,
      email,
      updatedBy: request.auth.uid,
      updatedAt: now,
    });

    if (recordType === "guardian") {
      const studentById = new Map(
        guardianStudentRecords.map((student) => [student.id, student]),
      );
      for (const student of studentById.values()) {
        batch.update(student.ref, {
          guardianUids: FieldValue.arrayUnion(targetUid),
          updatedBy: request.auth.uid,
          updatedAt: now,
        });
      }
      for (const linkDocument of guardianLinks) {
        const link = linkDocument.data() ?? {};
        const candidate = String(
          link.studentRecordId ?? link.studentId ?? "",
        ).trim();
        const student = studentById.get(candidate) ??
          [...studentById.values()].find(
            (item) => String(item.data()?.admissionNo ?? "").trim() === candidate,
          );
        batch.update(linkDocument.ref, {
          guardianAuthUid: targetUid,
          guardianUids: FieldValue.arrayUnion(targetUid),
          ...(student
            ? {
              studentRecordId: student.id,
              authUid: String(student.data()?.authUid ?? "").trim(),
            }
            : {}),
          updatedBy: request.auth.uid,
          updatedAt: now,
        });
      }
    }
  }

  batch.create(
    tenantRef.collection("audit_logs").doc(),
    auditDocument(tenantId, request.auth.uid, "account.created", {
      module: "user-access",
      recordCollection: "members",
      recordId: targetUid,
      after: {
        email,
        displayName,
        roles,
        campusIds,
        accountCategory,
        linkedRecordType: recordType || null,
        linkedRecordId: recordId || null,
        setupMethod,
        requiresPasswordChange,
      },
    }),
  );

  try {
    await batch.commit();
    if (targetUser.displayName !== displayName) {
      await auth.updateUser(targetUid, { displayName });
    }
  } catch (error) {
    if (createdAuthUser) {
      await auth.deleteUser(targetUid).catch(() => undefined);
    }
    throw error;
  }

  return {
    uid: targetUid,
    email,
    roles,
    created: createdAuthUser,
    existingAuthenticationAccount: !createdAuthUser,
    passwordApplied: passwordWasApplied,
    requiresPasswordChange,
  };
}

function publicProvisioningError(error) {
  if (error instanceof HttpsError) return error;

  const code = String(error?.code ?? "");
  if (code === "auth/operation-not-allowed") {
    return new HttpsError(
      "failed-precondition",
      "Enable the Email/Password sign-in provider in Firebase Authentication.",
    );
  }
  if (code === "auth/insufficient-permission") {
    return new HttpsError(
      "failed-precondition",
      "The Cloud Function service account cannot manage Firebase Authentication users.",
    );
  }
  if (code === "auth/email-already-exists") {
    return new HttpsError(
      "already-exists",
      "An authentication account already uses this email address.",
    );
  }
  if (
    code === "auth/invalid-email" ||
    code === "auth/invalid-password" ||
    code === "auth/invalid-display-name"
  ) {
    return new HttpsError(
      "invalid-argument",
      error?.message ?? "The authentication account details are invalid.",
    );
  }

  return new HttpsError(
    "internal",
    "Account provisioning failed on the server. Check the provisionSchoolUser function log.",
  );
}

exports.provisionSchoolUser = onCall(
  { region: "asia-south1", timeoutSeconds: 60 },
  async (request) => {
    try {
      return await provisionSchoolUser(request);
    } catch (error) {
      console.error("provisionSchoolUser failed", {
        callerUid: request.auth?.uid ?? null,
        tenantId: request.data?.tenantId ?? null,
        email: request.data?.email ?? null,
        code: error?.code ?? null,
        message: error?.message ?? String(error),
        stack: error?.stack ?? null,
      });
      throw publicProvisioningError(error);
    }
  },
);



exports.manageSchoolUser = onCall(
  { region: "asia-south1", timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before managing an account.");
    }

    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const targetUid = cleanText(request.data?.targetUid, "Account", 180);
    const action = cleanText(request.data?.action, "Action", 40);
    const reason = String(request.data?.reason ?? "").trim().slice(0, 1000);
    const callerMembership = await getCallerMembership(request.auth.uid, tenantId);
    if (!canManageUsers(callerMembership)) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to manage school accounts.",
      );
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantSnapshot = await tenantRef.get();
    if (!tenantSnapshot.exists) {
      throw new HttpsError("not-found", "The selected school was not found.");
    }
    const subscription = assertSubscriptionUsable(tenantSnapshot.data() ?? {});
    const memberRef = tenantRef.collection("members").doc(targetUid);
    const memberSnapshot = await memberRef.get();
    if (!memberSnapshot.exists) {
      throw new HttpsError("not-found", "The school account was not found.");
    }
    const before = memberSnapshot.data() ?? {};
    const targetRoles = Array.isArray(before.roles) ? before.roles : [];
    const beforeAccountCategory = ["staff", "portal"].includes(
      before.accountCategory,
    )
      ? before.accountCategory
      : accountCategoryForRoles(targetRoles);
    assertCanManageTarget(callerMembership, targetRoles);

    if (targetUid === request.auth.uid && ["suspend", "updateAccess"].includes(action)) {
      throw new HttpsError(
        "failed-precondition",
        "Use another administrator to change your own access.",
      );
    }

    const userRef = db.collection("users").doc(targetUid);
    const now = FieldValue.serverTimestamp();
    const batch = db.batch();
    let after = {};

    if (action === "updateAccess") {
      const displayName = cleanText(
        request.data?.displayName ?? before.displayName,
        "Display name",
        120,
      );
      const roles = cleanList(request.data?.roles, "Role", allRoles);
      const campusIds = cleanCampusIds(request.data?.campusIds);
      assertRoleDelegation(callerMembership, roles);
      const accountCategory = accountCategoryForRoles(roles);
      if (
        before.isActive === true &&
        beforeAccountCategory !== "staff" &&
        accountCategory === "staff"
      ) {
        await assertStaffCapacity(tenantRef, subscription);
      }
      const linkedType = String(before.linkedRecordType ?? "").trim();
      if (linkedType === "student" && !roles.includes("student")) {
        throw new HttpsError(
          "failed-precondition",
          "Unlink the student profile before changing this account role.",
        );
      }
      if (linkedType === "guardian" && !roles.includes("parent")) {
        throw new HttpsError(
          "failed-precondition",
          "Unlink the guardian profile before changing this account role.",
        );
      }
      if (
        linkedType === "teacher" &&
        !roles.some((role) => ["teacher", "classTeacher"].includes(role))
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Unlink the teacher profile before changing this account role.",
        );
      }
      if (roles.includes("student") && linkedType !== "student") {
        throw new HttpsError(
          "failed-precondition",
          "A student role requires a linked student profile.",
        );
      }
      if (roles.includes("parent") && linkedType !== "guardian") {
        throw new HttpsError(
          "failed-precondition",
          "A parent role requires a linked guardian profile.",
        );
      }
      if (
        roles.some((role) => ["teacher", "classTeacher"].includes(role)) &&
        linkedType !== "teacher"
      ) {
        throw new HttpsError(
          "failed-precondition",
          "A teacher role requires a linked teacher profile.",
        );
      }
      const update = {
        displayName,
        roles,
        permissions: effectivePermissionsForRoles(roles),
        accountCategory,
        campusIds,
        activeCampusId: campusIds.includes(before.activeCampusId)
          ? before.activeCampusId
          : (campusIds[0] ?? null),
        updatedBy: request.auth.uid,
        updatedAt: now,
      };
      batch.update(memberRef, update);
      batch.set(userRef, { displayName, updatedAt: now }, { merge: true });
      if (before.isActive === true && beforeAccountCategory !== accountCategory) {
        batch.set(
          tenantRef.collection("saas_usage").doc("current"),
          {
            staffUsers: FieldValue.increment(
              accountCategory === "staff" ? 1 : -1,
            ),
            updatedAt: now,
            updatedBy: request.auth.uid,
          },
          { merge: true },
        );
      }
      after = update;
      await auth.updateUser(targetUid, { displayName });
    } else if (action === "suspend") {
      if (!reason) {
        throw new HttpsError(
          "invalid-argument",
          "Enter a reason before suspending an account.",
        );
      }
      const update = {
        isActive: false,
        status: "suspended",
        suspensionReason: reason,
        suspendedBy: request.auth.uid,
        suspendedAt: now,
        updatedBy: request.auth.uid,
        updatedAt: now,
      };
      batch.update(memberRef, update);
      if (before.isActive === true && beforeAccountCategory === "staff") {
        batch.set(
          tenantRef.collection("saas_usage").doc("current"),
          {
            staffUsers: FieldValue.increment(-1),
            updatedAt: now,
            updatedBy: request.auth.uid,
          },
          { merge: true },
        );
      }
      after = update;
      await auth.revokeRefreshTokens(targetUid);
    } else if (action === "activate") {
      if (before.isActive !== true && beforeAccountCategory === "staff") {
        await assertStaffCapacity(tenantRef, subscription);
      }
      const update = {
        isActive: true,
        status: "active",
        accountCategory: beforeAccountCategory,
        suspensionReason: null,
        activatedBy: request.auth.uid,
        activatedAt: now,
        updatedBy: request.auth.uid,
        updatedAt: now,
      };
      batch.update(memberRef, update);
      if (before.isActive !== true && beforeAccountCategory === "staff") {
        batch.set(
          tenantRef.collection("saas_usage").doc("current"),
          {
            staffUsers: FieldValue.increment(1),
            updatedAt: now,
            updatedBy: request.auth.uid,
          },
          { merge: true },
        );
      }
      after = update;
      await auth.revokeRefreshTokens(targetUid);
    } else if (action === "resetPassword") {
      const password = validateTemporaryPassword(request.data?.temporaryPassword);
      const userSnapshot = await userRef.get();
      const tenantIds = Array.isArray(userSnapshot.data()?.tenantIds)
        ? userSnapshot.data().tenantIds
        : [];
      if (tenantIds.length > 1 && !callerIsSuperAdmin(callerMembership)) {
        throw new HttpsError(
          "failed-precondition",
          "This email is used by multiple schools. Send a password reset email instead of setting a tenant-specific temporary password.",
        );
      }
      await auth.updateUser(targetUid, { password, disabled: false });
      await auth.revokeRefreshTokens(targetUid);
      const update = {
        mustChangePassword: true,
        accountSetupMethod: "temporaryPassword",
        invitationStatus: "temporaryPasswordReset",
        passwordResetBy: request.auth.uid,
        passwordResetAt: now,
        updatedBy: request.auth.uid,
        updatedAt: now,
      };
      batch.update(memberRef, update);
      batch.set(
        userRef,
        {
          mustChangePassword: true,
          accountSetupMethod: "temporaryPassword",
          updatedAt: now,
        },
        { merge: true },
      );
      after = update;
    } else {
      throw new HttpsError("invalid-argument", "Unsupported account action.");
    }

    batch.create(
      tenantRef.collection("audit_logs").doc(),
      auditDocument(tenantId, request.auth.uid, `account.${action}`, {
        module: "user-access",
        recordCollection: "members",
        recordId: targetUid,
        before,
        after,
        reason: reason || null,
      }),
    );
    await batch.commit();
    return { uid: targetUid, action, success: true };
  },
);

exports.completeInitialPasswordChange = onCall(
  { region: "asia-south1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before completing setup.");
    }
    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const newPassword = validateTemporaryPassword(request.data?.newPassword);
    const authTime = Number(request.auth.token?.auth_time ?? 0);
    const nowSeconds = Math.floor(Date.now() / 1000);
    if (!authTime || nowSeconds - authTime > 10 * 60) {
      throw new HttpsError(
        "failed-precondition",
        "Re-enter the temporary password and try again.",
      );
    }
    const membership = await getCallerMembership(request.auth.uid, tenantId);
    if (membership.mustChangePassword !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Initial password setup has already been completed.",
      );
    }
    const tenantRef = db.collection("tenants").doc(tenantId);
    const now = FieldValue.serverTimestamp();
    const update = {
      mustChangePassword: false,
      invitationStatus: "completed",
      passwordChangedAt: now,
      updatedAt: now,
    };
    await auth.updateUser(request.auth.uid, {
      password: newPassword,
      disabled: false,
    });
    const batch = db.batch();
    batch.update(tenantRef.collection("members").doc(request.auth.uid), update);
    batch.set(
      db.collection("users").doc(request.auth.uid),
      { mustChangePassword: false, updatedAt: now },
      { merge: true },
    );
    batch.create(
      tenantRef.collection("audit_logs").doc(),
      auditDocument(tenantId, request.auth.uid, "account.password.initialChanged", {
        module: "user-access",
        recordCollection: "members",
        recordId: request.auth.uid,
        before: { mustChangePassword: membership.mustChangePassword === true },
        after: { mustChangePassword: false },
      }),
    );
    await batch.commit();
    return { success: true };
  },
);

exports.recordSuccessfulLogin = onCall(
  { region: "asia-south1", timeoutSeconds: 20 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before recording activity.");
    }
    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const membership = await getCallerMembership(request.auth.uid, tenantId);
    const now = FieldValue.serverTimestamp();
    const batch = db.batch();
    batch.update(
      db.collection("tenants").doc(tenantId).collection("members").doc(request.auth.uid),
      {
        lastLoginAt: now,
        loginCount: FieldValue.increment(1),
        ...(membership.accountSetupMethod === "emailLink" &&
            membership.invitationStatus === "pending"
          ? { invitationStatus: "completed", setupCompletedAt: now }
          : {}),
        updatedAt: now,
      },
    );
    batch.set(
      db.collection("users").doc(request.auth.uid),
      { lastLoginAt: now, updatedAt: now },
      { merge: true },
    );
    await batch.commit();
    return { success: true };
  },
);

exports.createMeteredErpRecord = onCall(
  { region: "asia-south1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before creating a record.");
    }
    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const collection = cleanText(request.data?.collection, "Collection", 100);
    const config = meteredCollectionConfig[collection];
    if (!config) {
      throw new HttpsError(
        "invalid-argument",
        "This collection is not configured for metered creation.",
      );
    }
    const values = cleanRecordValues(request.data?.values);
    const campusId = String(request.data?.campusId ?? "").trim() || null;
    const academicYearId = String(request.data?.academicYearId ?? "").trim() || null;
    const membership = await getCallerMembership(request.auth.uid, tenantId);
    if (!hasAnyPermission(membership, config.permissions)) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to create this record.",
      );
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantSnapshot = await tenantRef.get();
    if (!tenantSnapshot.exists) {
      throw new HttpsError("not-found", "The selected school was not found.");
    }
    const subscription = assertSubscriptionUsable(tenantSnapshot.data() ?? {});
    const limit = planLimit(subscription, config.limitKey);
    const existingCount = await tenantRef
      .collection(collection)
      .where("isArchived", "==", false)
      .count()
      .get();

    const recordRef = tenantRef.collection(collection).doc();
    const usageRef = tenantRef.collection("saas_usage").doc("current");
    const auditRef = tenantRef.collection("audit_logs").doc();
    await db.runTransaction(async (transaction) => {
      const usageSnapshot = await transaction.get(usageRef);
      const usage = usageSnapshot.data() ?? {};
      const stored = Number(usage[config.usageField]);
      const current = Number.isFinite(stored)
        ? stored
        : existingCount.data().count;
      if (limit > 0 && current >= limit) {
        throw new HttpsError(
          "resource-exhausted",
          `The plan limit for ${config.usageField} (${limit}) has been reached.`,
        );
      }
      const now = FieldValue.serverTimestamp();
      const record = {
        ...values,
        tenantId,
        campusId,
        academicYearId,
        createdBy: request.auth.uid,
        createdAt: now,
        updatedBy: request.auth.uid,
        updatedAt: now,
        isArchived: false,
      };
      transaction.create(recordRef, record);
      transaction.set(
        usageRef,
        {
          [config.usageField]: current + 1,
          updatedAt: now,
          updatedBy: request.auth.uid,
        },
        { merge: true },
      );
      transaction.create(
        auditRef,
        auditDocument(tenantId, request.auth.uid, `${collection}.created`, {
          module: collection,
          recordCollection: collection,
          recordId: recordRef.id,
          after: record,
        }),
      );
    });
    return { recordId: recordRef.id };
  },
);

exports.archiveMeteredErpRecord = onCall(
  { region: "asia-south1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before archiving a record.");
    }
    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const collection = cleanText(request.data?.collection, "Collection", 100);
    const recordId = cleanText(request.data?.recordId, "Record ID", 140);
    const config = meteredCollectionConfig[collection];
    if (!config) {
      throw new HttpsError(
        "invalid-argument",
        "This collection is not configured for metered archiving.",
      );
    }
    const membership = await getCallerMembership(request.auth.uid, tenantId);
    if (!hasAnyPermission(membership, config.permissions)) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to archive this record.",
      );
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantSnapshot = await tenantRef.get();
    if (!tenantSnapshot.exists) {
      throw new HttpsError("not-found", "The selected school was not found.");
    }
    assertSubscriptionUsable(tenantSnapshot.data() ?? {});

    const recordRef = tenantRef.collection(collection).doc(recordId);
    const usageRef = tenantRef.collection("saas_usage").doc("current");
    const auditRef = tenantRef.collection("audit_logs").doc();
    await db.runTransaction(async (transaction) => {
      const [recordSnapshot, usageSnapshot] = await Promise.all([
        transaction.get(recordRef),
        transaction.get(usageRef),
      ]);
      if (!recordSnapshot.exists) {
        throw new HttpsError("not-found", "The record was not found.");
      }
      const before = recordSnapshot.data() ?? {};
      if (before.isArchived === true) return;
      const usage = usageSnapshot.data() ?? {};
      const stored = Number(usage[config.usageField]);
      const current = Number.isFinite(stored) ? stored : 1;
      const now = FieldValue.serverTimestamp();
      const update = {
        isArchived: true,
        archivedBy: request.auth.uid,
        archivedAt: now,
        updatedBy: request.auth.uid,
        updatedAt: now,
      };
      transaction.update(recordRef, update);
      transaction.set(
        usageRef,
        {
          [config.usageField]: Math.max(0, current - 1),
          updatedAt: now,
          updatedBy: request.auth.uid,
        },
        { merge: true },
      );
      transaction.create(
        auditRef,
        auditDocument(tenantId, request.auth.uid, `${collection}.archived`, {
          module: collection,
          recordCollection: collection,
          recordId,
          before,
          after: update,
        }),
      );
    });
    return { recordId, archived: true };
  },
);

const approvalManagers = new Set([
  "saas_admin.manage",
  "accounting.manage",
  "fees.manage",
  "payroll.manage",
  "exams.manage",
  "students.manage",
  "leave.manage",
]);

function membershipHasPermission(membership, permission) {
  const permissions = Array.isArray(membership?.permissions)
    ? membership.permissions
    : [];
  return permissions.includes("*") || permissions.includes(permission);
}

function canDecideApprovals(membership) {
  const roles = Array.isArray(membership?.roles) ? membership.roles : [];
  const permissions = Array.isArray(membership?.permissions)
    ? membership.permissions
    : [];
  return (
    roles.some((role) => leadershipRoles.has(role)) ||
    permissions.includes("*") ||
    permissions.some((permission) => approvalManagers.has(permission))
  );
}

function auditDocument(tenantId, actorUid, action, details = {}) {
  return {
    tenantId,
    actorUid,
    action,
    module: String(details.module ?? "saas"),
    recordCollection: String(details.recordCollection ?? ""),
    recordId: String(details.recordId ?? ""),
    before: details.before ?? {},
    after: details.after ?? {},
    reason: details.reason ?? null,
    approvalId: details.approvalId ?? null,
    occurredAt: FieldValue.serverTimestamp(),
  };
}

exports.refreshSaasUsage = onCall(
  { region: "asia-south1", timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before refreshing usage.");
    }
    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const membership = await getCallerMembership(request.auth.uid, tenantId);
    if (
      !canManageUsers(membership) &&
      !membershipHasPermission(membership, "saas_admin.view") &&
      !membershipHasPermission(membership, "subscription.manage")
    ) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to view subscription usage.",
      );
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const [students, activeMembers, campuses, existingUsage] = await Promise.all([
      tenantRef.collection("students").where("isArchived", "==", false).count().get(),
      tenantRef.collection("members").where("isActive", "==", true).get(),
      tenantRef.collection("campuses").where("isArchived", "==", false).count().get(),
      tenantRef.collection("saas_usage").doc("current").get(),
    ]);
    const staffUsers = activeMembers.docs.filter((document) => {
      const data = document.data() ?? {};
      const roles = Array.isArray(data.roles)
        ? data.roles
        : (data.role ? [data.role] : []);
      return (["staff", "portal"].includes(data.accountCategory)
        ? data.accountCategory
        : accountCategoryForRoles(roles)) === "staff";
    }).length;

    const previous = existingUsage.data() ?? {};
    const usage = {
      students: students.data().count,
      staffUsers,
      campuses: campuses.data().count,
      storageMb: Number(previous.storageMb ?? 0),
      smsThisMonth: Number(previous.smsThisMonth ?? 0),
      emailThisMonth: Number(previous.emailThisMonth ?? 0),
      aiActionsThisMonth: Number(previous.aiActionsThisMonth ?? 0),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid,
    };

    const batch = db.batch();
    batch.set(tenantRef.collection("saas_usage").doc("current"), usage, {
      merge: true,
    });
    batch.set(
      tenantRef.collection("audit_logs").doc(),
      auditDocument(tenantId, request.auth.uid, "saas.usage.refresh", {
        module: "administration-saas",
        recordCollection: "saas_usage",
        recordId: "current",
        after: usage,
      }),
    );
    await batch.commit();

    return {
      students: usage.students,
      staffUsers: usage.staffUsers,
      campuses: usage.campuses,
      storageMb: usage.storageMb,
      smsThisMonth: usage.smsThisMonth,
      emailThisMonth: usage.emailThisMonth,
      aiActionsThisMonth: usage.aiActionsThisMonth,
    };
  },
);


const approvableCollections = new Set([
  "admission_applications",
  "student_promotions",
  "attendance_corrections",
  "leave_requests",
  "student_leave_requests",
  "fee_refunds",
  "expenses",
  "journal_vouchers",
  "purchase_orders",
  "payroll_runs",
  "exam_results",
  "certificate_requests",
]);

exports.requestApproval = onCall(
  { region: "asia-south1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before requesting approval.");
    }

    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const type = cleanText(request.data?.type, "Approval type", 80);
    const title = cleanText(request.data?.title, "Title", 180);
    const recordCollection = cleanText(
      request.data?.recordCollection,
      "Record collection",
      100,
    );
    const recordId = cleanText(request.data?.recordId, "Record ID", 140);
    const totalStepsRaw = Number(request.data?.totalSteps ?? 1);
    const totalSteps = Number.isInteger(totalStepsRaw)
      ? Math.min(Math.max(totalStepsRaw, 1), 10)
      : 1;
    if (!approvableCollections.has(recordCollection)) {
      throw new HttpsError(
        "invalid-argument",
        "This record type is not configured for trusted approval.",
      );
    }

    await getCallerMembership(request.auth.uid, tenantId);
    const tenantRef = db.collection("tenants").doc(tenantId);
    const targetSnapshot = await tenantRef
      .collection(recordCollection)
      .doc(recordId)
      .get();
    if (!targetSnapshot.exists) {
      throw new HttpsError("not-found", "The record requiring approval was not found.");
    }

    const approvalRef = tenantRef.collection("approval_requests").doc();
    const approval = {
      tenantId,
      type,
      title,
      requesterUid: request.auth.uid,
      assignedToUid: null,
      status: "submitted",
      recordCollection,
      recordId,
      currentStep: 1,
      totalSteps,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    const batch = db.batch();
    batch.create(approvalRef, approval);
    batch.create(
      tenantRef.collection("audit_logs").doc(),
      auditDocument(tenantId, request.auth.uid, "approval.submitted", {
        module: type,
        recordCollection,
        recordId,
        approvalId: approvalRef.id,
        after: approval,
      }),
    );
    await batch.commit();
    return { approvalId: approvalRef.id, status: "submitted" };
  },
);

exports.decideApproval = onCall(
  { region: "asia-south1", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before deciding approval.");
    }

    const tenantId = cleanText(request.data?.tenantId, "School", 100);
    const approvalId = cleanText(request.data?.approvalId, "Approval", 140);
    const decision = cleanText(request.data?.decision, "Decision", 20).toLowerCase();
    const reason = String(request.data?.reason ?? "").trim().slice(0, 1000);
    if (!["approved", "rejected"].includes(decision)) {
      throw new HttpsError("invalid-argument", "Decision must be approved or rejected.");
    }

    const membership = await getCallerMembership(request.auth.uid, tenantId);
    if (!canDecideApprovals(membership)) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to decide this approval.",
      );
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const approvalRef = tenantRef.collection("approval_requests").doc(approvalId);
    const approvalSnapshot = await approvalRef.get();
    if (!approvalSnapshot.exists) {
      throw new HttpsError("not-found", "The approval request was not found.");
    }
    const approval = approvalSnapshot.data();
    if (!["submitted", "underReview"].includes(String(approval?.status ?? ""))) {
      throw new HttpsError(
        "failed-precondition",
        "Only submitted approvals can be decided.",
      );
    }

    const update = {
      status: decision,
      decisionReason: reason || null,
      decidedBy: request.auth.uid,
      decidedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    const batch = db.batch();
    batch.update(approvalRef, update);
    batch.create(
      tenantRef.collection("audit_logs").doc(),
      auditDocument(tenantId, request.auth.uid, `approval.${decision}`, {
        module: approval.type,
        recordCollection: approval.recordCollection,
        recordId: approval.recordId,
        approvalId,
        before: approval,
        after: update,
        reason,
      }),
    );
    await batch.commit();
    return { approvalId, status: decision };
  },
);
