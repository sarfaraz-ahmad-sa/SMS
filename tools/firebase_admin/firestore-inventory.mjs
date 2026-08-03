import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function present(value) {
  return value != null && value.toString().trim().length > 0;
}

function isArchived(data) {
  return data.isArchived === true || data.is_archived === true;
}

function hasCampus(data) {
  return present(data.campusId) || present(data.campus_id);
}

function hasAcademicYear(data) {
  return present(data.academicYearId) || present(data.academic_year_id);
}

async function inspectCollection(reference) {
  const snapshot = await reference.get();
  let archived = 0;
  let missingCampus = 0;
  let missingAcademicYear = 0;
  let nestedCollections = 0;

  for (const document of snapshot.docs) {
    const data = document.data();
    if (isArchived(data)) archived += 1;
    if (!hasCampus(data)) missingCampus += 1;
    if (!hasAcademicYear(data)) missingAcademicYear += 1;
    nestedCollections += (await document.ref.listCollections()).length;
  }

  return {
    count: snapshot.size,
    archived,
    missingCampus,
    missingAcademicYear,
    nestedCollections,
  };
}

async function main() {
  const projectId = required('FIREBASE_PROJECT_ID');
  const tenantId = required('SOURCE_FIREBASE_TENANT_ID');

  initializeApp({ credential: applicationDefault(), projectId });
  const db = getFirestore();
  const tenantReference = db.collection('tenants').doc(tenantId);
  const tenantSnapshot = await tenantReference.get();
  if (!tenantSnapshot.exists) {
    throw new Error(`Source tenant not found: ${tenantId}`);
  }

  const references = await tenantReference.listCollections();
  const collections = {};
  let totalDocuments = 0;

  for (const reference of references.sort((a, b) => a.id.localeCompare(b.id))) {
    const stats = await inspectCollection(reference);
    collections[reference.id] = stats;
    totalDocuments += stats.count;
  }

  const rootUserCount = (await db.collection('users').count().get()).data().count;

  console.log(JSON.stringify({
    success: true,
    readOnly: true,
    projectId,
    tenantId,
    collectionCount: references.length,
    totalTenantDocuments: totalDocuments,
    rootUserCount,
    collections,
  }, null, 2));
}

main().catch((error) => {
  console.error(JSON.stringify({
    success: false,
    readOnly: true,
    error: error instanceof Error ? error.message : String(error),
  }, null, 2));
  process.exitCode = 1;
});
