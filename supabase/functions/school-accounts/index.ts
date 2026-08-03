import { createClient } from "npm:@supabase/supabase-js@2";

const commonPermissions = ["dashboard.view", "profile.view", "notifications.view", "timetable.view", "communication.view", "events.view"];
const rolePermissions: Record<string, string[]> = {
  superAdmin: ["*"], schoolOwner: ["*"], principal: ["*"], vicePrincipal: ["*"],
  adminStaff: [...commonPermissions, "school_setup.view", "school_setup.manage", "admissions.view", "admissions.manage", "students.view", "students.create", "students.update", "students.manage", "parents.view", "parents.manage", "teachers.view", "employees.view", "attendance.view", "attendance.manage", "academics.view", "exams.view", "fees.view", "library.view", "transport.view", "hostel.view", "inventory.view", "communication.manage", "events.manage", "documents.view", "documents.manage", "welfare.view", "welfare.manage", "compliance.view", "reports.view", "helpdesk.view", "helpdesk.manage", "settings.view", "users.manage"],
  accountant: [...commonPermissions, "students.view", "parents.view", "fees.view", "fees.manage", "fees.collect", "fees.refund", "accounting.view", "accounting.manage", "payroll.manage", "inventory.view", "reports.view", "documents.view"],
  teacher: [...commonPermissions, "students.view", "attendance.view", "attendance.mark", "academics.view", "academics.manage", "exams.view", "exams.marks.enter", "activities.view", "activities.manage", "leave.view", "leave.apply", "library.view", "documents.view"],
  classTeacher: [...commonPermissions, "students.view", "students.update", "parents.view", "attendance.view", "attendance.mark", "attendance.manage", "academics.view", "academics.manage", "exams.view", "exams.marks.enter", "communication.manage", "activities.view", "activities.manage", "leave.view", "leave.apply", "library.view", "reports.view", "documents.view"],
  student: [...commonPermissions, "students.view", "academics.view", "welfare.view", "helpdesk.view", "attendance.view", "exams.view", "fees.view", "library.view", "transport.view", "hostel.view", "activities.view", "leave.view", "leave.apply", "documents.view"],
  parent: [...commonPermissions, "parents.view", "academics.view", "library.view", "hostel.view", "welfare.view", "helpdesk.view", "students.view", "attendance.view", "exams.view", "fees.view", "transport.view", "activities.view", "leave.view", "leave.apply", "documents.view"],
  librarian: [...commonPermissions, "library.view", "library.manage", "students.view", "teachers.view", "employees.view", "reports.view"],
  hrManager: [...commonPermissions, "teachers.view", "teachers.manage", "employees.view", "employees.manage", "hr.view", "hr.manage", "payroll.manage", "attendance.view", "attendance.manage", "leave.view", "leave.manage", "reports.view", "documents.view", "documents.manage", "welfare.view", "compliance.view", "compliance.manage"],
  receptionist: [...commonPermissions, "admissions.view", "admissions.manage", "students.view", "students.create", "parents.view", "transport.view", "helpdesk.view", "helpdesk.manage"],
  transportManager: [...commonPermissions, "transport.view", "transport.manage", "students.view", "parents.view", "employees.view", "reports.view"],
  hostelManager: [...commonPermissions, "hostel.view", "hostel.manage", "students.view", "parents.view", "fees.view", "inventory.view", "reports.view"],
  itAdmin: [...commonPermissions, "school_setup.view", "settings.view", "settings.manage", "users.manage", "tenant.manage", "subscription.manage", "audit.view", "integrations.view", "integrations.manage", "compliance.view", "compliance.manage", "ai.view", "ai.manage", "saas_admin.view", "saas_admin.manage", "reports.view", "helpdesk.view", "helpdesk.manage"],
};
const allRoles = new Set(Object.keys(rolePermissions));
const permissionsFor = (roles: string[]) => [...new Set(roles.flatMap((role) => rolePermissions[role] ?? []))].sort();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

class RequestError extends Error {
  constructor(message: string, readonly status = 400) { super(message); }
}

const text = (value: unknown) => typeof value === "string" ? value.trim() : "";
const strings = (value: unknown) => Array.isArray(value)
  ? [...new Set(value.map(text).filter(Boolean))]
  : [];
const strongPassword = (value: string) => value.length >= 10 &&
  /[A-Z]/.test(value) && /[a-z]/.test(value) && /[0-9]/.test(value) && /[^A-Za-z0-9]/.test(value);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization") ?? "";
    if (!url || !anonKey || !serviceKey || !authorization.startsWith("Bearer ")) {
      throw new RequestError("Authentication is required.", 401);
    }

    const callerClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: authData, error: authError } = await callerClient.auth.getUser();
    if (authError || !authData.user) throw new RequestError("Your session is invalid.", 401);

    const body = await request.json() as Record<string, unknown>;
    const action = text(body.action);
    const tenantId = text(body.tenantId);
    if (!tenantId) throw new RequestError("School is required.");

    const { data: actor, error: actorError } = await admin.from("tenant_members")
      .select("roles, permissions, denied_permissions, is_active, status")
      .eq("tenant_id", tenantId).eq("user_id", authData.user.id).maybeSingle();
    if (actorError || !actor || !actor.is_active || actor.status !== "active") {
      throw new RequestError("You do not have active access to this school.", 403);
    }

    const actorRoles = strings(actor.roles);
    const actorPermissions = strings(actor.permissions);
    const denied = strings(actor.denied_permissions);
    const canManage = !denied.includes("users.manage") &&
      (actorPermissions.includes("*") || actorPermissions.includes("users.manage") ||
        actorRoles.some((role) => ["superAdmin", "schoolOwner", "principal", "vicePrincipal"].includes(role)));
    const selfActions = new Set(["completePasswordChange", "recordLogin"]);
    if (!selfActions.has(action) && !canManage) {
      throw new RequestError("You do not have permission to manage school accounts.", 403);
    }

    if (action === "completePasswordChange" || action === "recordLogin") {
      const update = action === "completePasswordChange"
        ? { must_change_password: false, updated_at: new Date().toISOString() }
        : { last_login_at: new Date().toISOString(), updated_at: new Date().toISOString() };
      const { error } = await admin.from("tenant_members").update(update)
        .eq("tenant_id", tenantId).eq("user_id", authData.user.id);
      if (error) throw error;
      return json({ ok: true });
    }

    const targetUid = text(body.targetUid);
    if (["updateAccess", "activate", "suspend", "resetPassword"].includes(action) && !targetUid) {
      throw new RequestError("Target account is required.");
    }
    if (targetUid === authData.user.id && ["suspend", "updateAccess"].includes(action)) {
      throw new RequestError("You cannot suspend or change your own access.");
    }

    if (action === "provision") {
      const email = text(body.email).toLowerCase();
      const displayName = text(body.displayName);
      const roles = strings(body.roles);
      const campusIds = strings(body.campusIds);
      const setupMethod = text(body.setupMethod);
      const temporaryPassword = text(body.temporaryPassword);
      if (!/^\S+@\S+\.\S+$/.test(email)) throw new RequestError("A valid email is required.");
      if (displayName.length < 2 || displayName.length > 120) throw new RequestError("A valid display name is required.");
      validateRoles(roles, actorRoles);
      await validateCampuses(admin, tenantId, campusIds);
      if (setupMethod === "temporaryPassword" && !strongPassword(temporaryPassword)) {
        throw new RequestError("Temporary password does not meet the security requirements.");
      }

      const existing = await findUserByEmail(admin, email);
      let user = existing;
      let created = false;
      let passwordEmailSent = false;
      if (!user) {
        if (setupMethod === "emailLink") {
          const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
            data: { display_name: displayName },
          });
          if (error) throw error;
          user = data.user;
          passwordEmailSent = true;
        } else {
          const { data, error } = await admin.auth.admin.createUser({
            email, password: temporaryPassword, email_confirm: true,
            user_metadata: { display_name: displayName },
          });
          if (error) throw error;
          user = data.user;
        }
        created = true;
      }
      if (!user) throw new RequestError("Authentication account could not be created.", 500);

      const recordType = text(body.recordType) || null;
      const recordId = text(body.recordId) || null;
      const accountCategory = roles.some((role) => role === "student" || role === "parent") ? "portal" : "staff";
      const membership = {
        tenant_id: tenantId, user_id: user.id, email, display_name: displayName,
        roles, permissions: permissionsFor(roles), denied_permissions: [], campus_ids: campusIds,
        linked_record_type: recordType, linked_record_id: recordId,
        status: "active", is_active: true,
        must_change_password: setupMethod === "temporaryPassword" && body.forcePasswordChange !== false,
        account_category: accountCategory, suspension_reason: null,
        updated_at: new Date().toISOString(),
      };
      const { error: profileError } = await admin.from("profiles").upsert({
        user_id: user.id, display_name: displayName, active_tenant_id: tenantId,
        updated_at: new Date().toISOString(),
      }, { onConflict: "user_id" });
      if (profileError) throw profileError;
      const { error: memberError } = await admin.from("tenant_members").upsert(membership, {
        onConflict: "tenant_id,user_id",
      });
      if (memberError) {
        if (created) await admin.auth.admin.deleteUser(user.id);
        throw memberError;
      }
      await audit(admin, tenantId, authData.user.id, "provision_account", user.id, { email, roles, campusIds });
      return json({ uid: user.id, created, requiresPasswordChange: membership.must_change_password,
        passwordEmailSent, existingAuthenticationAccount: Boolean(existing) });
    }

    const { data: target, error: targetError } = await admin.from("tenant_members").select("*")
      .eq("tenant_id", tenantId).eq("user_id", targetUid).maybeSingle();
    if (targetError || !target) throw new RequestError("School account was not found.", 404);

    if (action === "updateAccess") {
      const roles = strings(body.roles);
      const campusIds = strings(body.campusIds);
      const displayName = text(body.displayName);
      validateRoles(roles, actorRoles);
      await validateCampuses(admin, tenantId, campusIds);
      const { error } = await admin.from("tenant_members").update({
        display_name: displayName, roles, permissions: permissionsFor(roles), campus_ids: campusIds,
        account_category: roles.some((role) => role === "student" || role === "parent") ? "portal" : "staff",
        updated_at: new Date().toISOString(),
      }).eq("tenant_id", tenantId).eq("user_id", targetUid);
      if (error) throw error;
      await admin.from("profiles").update({ display_name: displayName, updated_at: new Date().toISOString() }).eq("user_id", targetUid);
      await audit(admin, tenantId, authData.user.id, "update_account_access", targetUid, { roles, campusIds });
      return json({ ok: true });
    }

    if (action === "activate" || action === "suspend") {
      const active = action === "activate";
      const { error } = await admin.from("tenant_members").update({
        is_active: active, status: active ? "active" : "suspended",
        suspension_reason: active ? null : text(body.reason), updated_at: new Date().toISOString(),
      }).eq("tenant_id", tenantId).eq("user_id", targetUid);
      if (error) throw error;
      await audit(admin, tenantId, authData.user.id, action + "_account", targetUid, { reason: text(body.reason) });
      return json({ ok: true });
    }

    if (action === "resetPassword") {
      const password = text(body.temporaryPassword);
      if (!strongPassword(password)) throw new RequestError("Temporary password does not meet the security requirements.");
      const { error: authUpdateError } = await admin.auth.admin.updateUserById(targetUid, { password });
      if (authUpdateError) throw authUpdateError;
      const { error } = await admin.from("tenant_members").update({
        must_change_password: true, updated_at: new Date().toISOString(),
      }).eq("tenant_id", tenantId).eq("user_id", targetUid);
      if (error) throw error;
      await audit(admin, tenantId, authData.user.id, "reset_account_password", targetUid, {});
      return json({ ok: true });
    }

    throw new RequestError("Unsupported account action.", 400);
  } catch (error) {
    const status = error instanceof RequestError ? error.status : 500;
    const message = error instanceof Error ? error.message : "School Accounts request failed.";
    console.error("school-accounts", { status, message });
    return json({ error: message }, status);
  }
});

function validateRoles(roles: string[], actorRoles: string[]) {
  if (roles.length === 0 || roles.some((role) => !allRoles.has(role))) {
    throw new RequestError("One or more roles are invalid.");
  }
  if (roles.includes("superAdmin") && !actorRoles.includes("superAdmin")) {
    throw new RequestError("Only a Super Admin can assign the Super Admin role.", 403);
  }
}

async function validateCampuses(admin: ReturnType<typeof createClient>, tenantId: string, campusIds: string[]) {
  if (campusIds.length === 0) return;
  const { data, error } = await admin.from("campuses").select("id")
    .eq("tenant_id", tenantId).eq("is_archived", false).in("id", campusIds);
  if (error || (data?.length ?? 0) !== campusIds.length) throw new RequestError("Campus scope contains an invalid campus.");
}

async function findUserByEmail(admin: ReturnType<typeof createClient>, email: string) {
  for (let page = 1; page <= 10; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    const found = data.users.find((user) => user.email?.toLowerCase() === email);
    if (found) return found;
    if (data.users.length < 200) return null;
  }
  throw new RequestError("Authentication directory is too large for email lookup.", 503);
}

async function audit(admin: ReturnType<typeof createClient>, tenantId: string, actor: string,
  action: string, recordId: string, newData: Record<string, unknown>) {
  const { error } = await admin.from("audit_logs").insert({ tenant_id: tenantId,
    actor_user_id: actor, action, table_name: "tenant_members", record_id: recordId, new_data: newData });
  if (error) throw error;
}
