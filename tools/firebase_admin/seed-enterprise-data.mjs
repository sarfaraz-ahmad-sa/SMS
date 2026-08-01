import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

const projectId = required('FIREBASE_PROJECT_ID');
const tenantId = required('TENANT_ID');
const actorId = process.env.ACTOR_UID?.trim() || 'system-seeder';
const academicYearId = process.env.ACADEMIC_YEAR_ID?.trim() || '2026-2027';

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const tenantRef = db.collection('tenants').doc(tenantId);

const records = [
  ['campuses', 'main-campus', {
    name: 'Main Campus', code: 'MAIN', address: 'Update school address',
    phone: '', email: '', principalName: '', status: 'Active',
  }],
  ['academic_years', academicYearId, {
    name: academicYearId, startDate: '2026-04-01', endDate: '2027-03-31', status: 'Active',
  }],
  ['departments', 'administration', {
    name: 'Administration', code: 'ADMIN', headName: '', description: 'School administration department.',
  }],
  ['departments', 'academics', {
    name: 'Academics', code: 'ACA', headName: '', description: 'Academic operations department.',
  }],
  ['classes', 'grade-1', {
    name: 'Grade 1', program: 'Primary', board: '', capacity: 30, monthlyFee: 0,
  }],
  ['classes', 'grade-9', {
    name: 'Grade 9', program: 'Matric', board: 'Configure Board', capacity: 40, monthlyFee: 0,
  }],
  ['sections', 'grade-1-a', {
    className: 'Grade 1', name: 'A', classTeacher: '', room: 'R-101', capacity: 30,
  }],
  ['subjects', 'english', {
    name: 'English', code: 'ENG', type: 'Theory', totalMarks: 100, passingMarks: 40,
  }],
  ['subjects', 'mathematics', {
    name: 'Mathematics', code: 'MATH', type: 'Theory', totalMarks: 100, passingMarks: 40,
  }],
  ['grading_schemes', 'default-grading', {
    name: 'Default Percentage Grading', minPercentage: 0, maxPercentage: 100,
    grade: 'Configure bands', gradePoint: 0, remarks: 'Create one record per grade band.',
  }],
  ['fee_structures', 'default-monthly-fee', {
    name: 'Default Monthly Tuition', academicYear: academicYearId,
    className: 'Configure Class', category: 'Tuition Fee', amount: 0,
    billingFrequency: 'Monthly', dueDay: 10, status: 'Draft',
  }],
  ['chart_of_accounts', 'cash-in-hand', {
    code: '1001', name: 'Cash in Hand', accountType: 'Asset', parentAccount: '',
    openingBalance: 0, status: 'Active',
  }],
  ['chart_of_accounts', 'fee-income', {
    code: '4001', name: 'Fee Income', accountType: 'Income', parentAccount: '',
    openingBalance: 0, status: 'Active',
  }],
  ['announcements', 'welcome-announcement', {
    title: 'Welcome to SEEF School ERP', audience: 'All',
    message: 'The enterprise school workspace is ready. Configure master data before onboarding users.',
    publishDate: new Date().toISOString().slice(0, 10), expiryDate: '', priority: 'Normal', status: 'Published',
  }],
  ['feature_flags', 'core-erp', {
    featureKey: 'core_erp', module: 'Platform',
    description: 'Core school ERP modules.', enabled: true, rolloutPercentage: 100, status: 'Active',
  }],
  ['retention_policies', 'student-records', {
    recordType: 'Student Academic Records', retentionYears: 10,
    retentionBasis: 'Configure according to school policy and applicable law.',
    disposalMethod: 'Manual Review', legalHoldSupported: true,
    owner: 'School Administration', status: 'Draft',
  }],
];

let batch = db.batch();
let operations = 0;
let committed = 0;

for (const [collection, id, data] of records) {
  batch.set(
    tenantRef.collection(collection).doc(id),
    {
      ...data,
      tenantId,
      campusId: 'main-campus',
      academicYearId,
      createdBy: actorId,
      createdAt: FieldValue.serverTimestamp(),
      updatedBy: actorId,
      updatedAt: FieldValue.serverTimestamp(),
      isArchived: false,
    },
    { merge: true },
  );
  operations += 1;

  if (operations === 450) {
    await batch.commit();
    committed += operations;
    batch = db.batch();
    operations = 0;
  }
}

if (operations > 0) {
  await batch.commit();
  committed += operations;
}

console.log(JSON.stringify({
  success: true,
  projectId,
  tenantId,
  academicYearId,
  recordsWritten: committed,
}, null, 2));
