import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

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
try {
  authUser = await auth.getUserByEmail(userEmail);
} catch (error) {
  if (error?.code !== 'auth/user-not-found') throw error;

  const password = process.env.USER_PASSWORD;
  if (!password || password.length < 8) {
    throw new Error(
      'Firebase user does not exist. Set USER_PASSWORD (minimum 8 characters) to create it, or create the account in Firebase Authentication first.',
    );
  }

  authUser = await auth.createUser({
    email: userEmail,
    password,
    displayName,
    emailVerified: false,
    disabled: false,
  });
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
    updatedAt: now,
  },
  { merge: true },
);

batch.set(
  membershipRef,
  {
    status: 'active',
    isActive: true,
    roles,
    permissions: [],
    deniedPermissions: [],
    campusIds,
    activeCampusId: campusIds[0] ?? null,
    activeAcademicYearId: academicYearId,
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
  campusIds,
}, null, 2));
