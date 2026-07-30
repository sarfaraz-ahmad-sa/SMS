import process from 'node:process';
import { createRequire } from 'node:module';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const require = createRequire(import.meta.url);
const { allRoles, effectivePermissionsForRoles } =
  require('../../functions/role-permissions.js');

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function csv(name, fallback = '') {
  return (process.env[name] ?? fallback)
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

const projectId = required('FIREBASE_PROJECT_ID');
const tenantId = required('TENANT_ID');
const tenantName = required('TENANT_NAME');
const tenantCode = required('TENANT_CODE').toUpperCase();
const userEmail = required('USER_EMAIL').toLowerCase();
const displayName = process.env.USER_NAME?.trim() || 'School Owner';
const roles = csv('ROLES', 'schoolOwner');
if (roles.some((role) => !allRoles.includes(role))) {
  throw new Error(`ROLES contains an unsupported role. Allowed: ${allRoles.join(', ')}`);
}
const permissions = effectivePermissionsForRoles(roles);
const campusIds = csv('CAMPUS_IDS', 'main-campus');
const academicYearId = process.env.ACADEMIC_YEAR_ID?.trim() || '2026-2027';
const timezone = process.env.TIMEZONE?.trim() || 'Asia/Karachi';
const currency = process.env.CURRENCY?.trim() || 'PKR';

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const auth = getAuth();
const db = getFirestore();

let authUser;
let createdAuthUser = false;
try {
  authUser = await auth.getUserByEmail(userEmail);
} catch (error) {
  if (error?.code !== 'auth/user-not-found') throw error;

  const password = process.env.USER_PASSWORD;
  if (!password ||
      password.length < 10 ||
      !/[A-Z]/.test(password) ||
      !/[a-z]/.test(password) ||
      !/[0-9]/.test(password) ||
      !/[^A-Za-z0-9]/.test(password)) {
    throw new Error(
      'Firebase user does not exist. Set USER_PASSWORD to at least 10 characters with uppercase, lowercase, number and special character, or create the account in Firebase Authentication first.',
    );
  }

  authUser = await auth.createUser({
    email: userEmail,
    password,
    displayName,
    emailVerified: false,
    disabled: false,
  });
  createdAuthUser = true;
}

const now = FieldValue.serverTimestamp();
const batch = db.batch();
const tenantRef = db.collection('tenants').doc(tenantId);
const userRef = db.collection('users').doc(authUser.uid);
const membershipRef = tenantRef.collection('members').doc(authUser.uid);

batch.set(
  tenantRef,
  {
    name: tenantName,
    code: tenantCode,
    timezone,
    currency,
    isActive: true,
    activeAcademicYearId: academicYearId,
    subscription: {
      tier: 'trial',
      status: 'trialing',
      trialEndsAt: new Date(Date.now() + (30 * 24 * 60 * 60 * 1000)),
      cancelAtPeriodEnd: false,
      limits: {
        students: 30,
        staffUsers: 10,
        campuses: 1,
        storageMb: 512,
        smsPerMonth: 100,
        emailPerMonth: 500,
        aiActionsPerMonth: 25,
      },
    },
    createdAt: now,
    updatedAt: now,
  },
  { merge: true },
);

batch.set(
  userRef,
  {
    email: userEmail,
    displayName,
    tenantIds: FieldValue.arrayUnion(tenantId),
    activeTenantId: tenantId,
    isActive: true,
    mustChangePassword: createdAuthUser,
    linkedRecordType: '',
    linkedRecordId: '',
    themeMode: 'system',
    updatedAt: now,
  },
  { merge: true },
);

batch.set(
  tenantRef.collection('saas_usage').doc('current'),
  {
    students: 0,
    staffUsers: 1,
    campuses: campusIds.length,
    storageMb: 0,
    smsThisMonth: 0,
    emailThisMonth: 0,
    aiActionsThisMonth: 0,
    updatedAt: now,
    updatedBy: authUser.uid,
  },
  { merge: true },
);

batch.set(
  membershipRef,
  {
    status: 'active',
    isActive: true,
    roles,
    permissions,
    deniedPermissions: [],
    campusIds,
    activeCampusId: campusIds[0] ?? null,
    activeAcademicYearId: academicYearId,
    accountCategory: roles.length > 0 &&
      roles.every((role) => ['student', 'parent'].includes(role))
      ? 'portal'
      : 'staff',
    mustChangePassword: createdAuthUser,
    linkedRecordType: '',
    linkedRecordId: '',
    themeMode: 'system',
    updatedAt: now,
  },
  { merge: true },
);

await batch.commit();

console.log(JSON.stringify({
  success: true,
  projectId,
  tenantId,
  userUid: authUser.uid,
  userEmail,
  roles,
  permissions,
  campusIds,
}, null, 2));
