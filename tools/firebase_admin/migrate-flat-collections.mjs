import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function flag(name, fallback = false) {
  const raw = process.env[name];
  if (raw == null) return fallback;
  return ['1', 'true', 'yes'].includes(raw.trim().toLowerCase());
}

const projectId = required('FIREBASE_PROJECT_ID');
const tenantId = required('TENANT_ID');
const actorUid = required('ACTOR_UID');
const dryRun = flag('DRY_RUN', true);
const deleteSource = flag('DELETE_SOURCE', false);

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

async function migrateCollection(sourceName, normalize) {
  const snapshot = await db.collection(sourceName).get();
  let copied = 0;

  for (const document of snapshot.docs) {
    const target = db
      .collection('tenants')
      .doc(tenantId)
      .collection(sourceName)
      .doc(document.id);
    const data = normalize(document.data());

    if (!dryRun) {
      await target.set(data, { merge: true });
      if (deleteSource) await document.ref.delete();
    }
    copied += 1;
  }

  return copied;
}

const students = await migrateCollection('students', (data) => ({
  ...data,
  tenantId,
  isArchived: data.isArchived === true,
  createdBy: data.createdBy || actorUid,
  updatedBy: actorUid,
  createdAt: data.createdAt || FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
}));

const events = await migrateCollection('events', (data) => ({
  ...data,
  tenantId,
  isArchived: data.isArchived === true,
  createdBy: data.createdBy || actorUid,
  updatedBy: actorUid,
  createdAt: data.createdAt || FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
}));

console.log(JSON.stringify({
  success: true,
  dryRun,
  deleteSource,
  tenantId,
  copied: { students, events },
}, null, 2));
