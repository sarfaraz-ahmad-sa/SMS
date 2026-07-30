import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function truthy(value, fallback = false) {
  if (value == null || String(value).trim() === '') return fallback;
  return ['1', 'true', 'yes', 'y'].includes(String(value).trim().toLowerCase());
}

const projectId = required('FIREBASE_PROJECT_ID');
const requestedTenantId = process.env.TENANT_ID?.trim() || null;
const dryRun = truthy(process.env.DRY_RUN, true);

const relatedCollections = Object.freeze([
  'student_enrollments',
  'student_promotions',
  'student_transfers',
  'discipline_records',
  'student_achievements',
  'student_attendance',
  'student_leave_requests',
  'fee_invoices',
  'payments',
  'mark_entries',
  'exam_results',
  'transcripts',
  'book_loans',
  'library_reservations',
  'transport_assignments',
  'hostel_allocations',
  'certificate_requests',
  'issued_certificates',
  'student_medical_profiles',
  'clinic_visits',
  'counseling_cases',
  'learning_accommodations',
  'parent_meetings',
  'event_registrations',
  'leave_requests',
  'support_tickets',
  'complaints',
]);

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

function text(value) {
  return String(value ?? '').trim();
}

function stringList(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map(text).filter(Boolean))];
}

function relationshipPatch(student) {
  return {
    studentRecordId: student.id,
    authUid: text(student.data.authUid),
    guardianUids: stringList(student.data.guardianUids),
  };
}

function changed(data, patch) {
  return (
    text(data.studentRecordId) !== patch.studentRecordId ||
    text(data.authUid) !== patch.authUid ||
    JSON.stringify(stringList(data.guardianUids).sort()) !==
      JSON.stringify([...patch.guardianUids].sort())
  );
}

async function loadStudents(tenantRef) {
  const snapshot = await tenantRef.collection('students').get();
  const byId = new Map();
  const byAdmission = new Map();
  for (const document of snapshot.docs) {
    const record = { id: document.id, ref: document.ref, data: document.data() ?? {} };
    byId.set(document.id, record);
    const admissionNo = text(record.data.admissionNo);
    if (admissionNo) byAdmission.set(admissionNo, record);
  }
  return { byId, byAdmission };
}

function resolveStudent(data, students) {
  const candidates = [
    data.studentRecordId,
    data.studentId,
    data.admissionNo,
    data.studentAdmissionNo,
  ].map(text).filter(Boolean);
  for (const candidate of candidates) {
    const match = students.byId.get(candidate) ?? students.byAdmission.get(candidate);
    if (match) return match;
  }
  return null;
}

async function migrateTenant(tenantSnapshot) {
  if (!tenantSnapshot.exists) throw new Error(`Tenant not found: ${tenantSnapshot.id}`);
  const tenantId = tenantSnapshot.id;
  const tenantRef = tenantSnapshot.ref;
  const students = await loadStudents(tenantRef);
  const writer = dryRun ? null : db.bulkWriter();
  const counters = {
    tenantId,
    students: students.byId.size,
    guardianLinksScanned: 0,
    studentGuardianUpdates: 0,
    relatedScanned: 0,
    relatedUpdated: 0,
    unresolved: 0,
  };

  const guardianSnapshot = await tenantRef.collection('guardians').get();
  const guardianAuthById = new Map(
    guardianSnapshot.docs
      .map((document) => [document.id, text(document.data()?.authUid)])
      .filter(([, uid]) => uid),
  );
  const guardianLinks = await tenantRef.collection('student_guardians').get();
  const guardianUidsByStudent = new Map();

  for (const linkDocument of guardianLinks.docs) {
    counters.guardianLinksScanned += 1;
    const link = linkDocument.data() ?? {};
    const student = resolveStudent(link, students);
    if (!student) {
      counters.unresolved += 1;
      continue;
    }
    const guardianUid = text(link.guardianAuthUid) ||
      guardianAuthById.get(text(link.guardianId)) || '';
    const currentGuardians = stringList(student.data.guardianUids);
    const mergedGuardians = [...new Set([
      ...currentGuardians,
      ...(guardianUid ? [guardianUid] : []),
    ])];
    guardianUidsByStudent.set(student.id, mergedGuardians);

    const linkPatch = {
      ...relationshipPatch({
        ...student,
        data: { ...student.data, guardianUids: mergedGuardians },
      }),
      ...(guardianUid ? { guardianAuthUid: guardianUid } : {}),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: 'portal-link-migration',
    };
    if (!dryRun) writer.set(linkDocument.ref, linkPatch, { merge: true });
  }

  for (const [studentId, guardianUids] of guardianUidsByStudent.entries()) {
    const student = students.byId.get(studentId);
    if (!student) continue;
    if (
      JSON.stringify(stringList(student.data.guardianUids).sort()) ===
      JSON.stringify([...guardianUids].sort())
    ) continue;
    counters.studentGuardianUpdates += 1;
    student.data.guardianUids = guardianUids;
    if (!dryRun) {
      writer.set(
        student.ref,
        {
          guardianUids,
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: 'portal-link-migration',
        },
        { merge: true },
      );
    }
  }

  for (const collectionName of relatedCollections) {
    const snapshot = await tenantRef.collection(collectionName).get();
    for (const document of snapshot.docs) {
      counters.relatedScanned += 1;
      const data = document.data() ?? {};
      const student = resolveStudent(data, students);
      if (!student) {
        const hasReference = [
          data.studentRecordId,
          data.studentId,
          data.admissionNo,
          data.studentAdmissionNo,
        ].some((value) => text(value));
        if (hasReference) counters.unresolved += 1;
        continue;
      }
      const patch = relationshipPatch(student);
      if (!changed(data, patch)) continue;
      counters.relatedUpdated += 1;
      if (!dryRun) {
        writer.set(
          document.ref,
          {
            ...patch,
            updatedAt: FieldValue.serverTimestamp(),
            updatedBy: 'portal-link-migration',
          },
          { merge: true },
        );
      }
    }
  }

  if (!dryRun) {
    writer.create(tenantRef.collection('audit_logs').doc(), {
      tenantId,
      actorUid: 'portal-link-migration',
      action: 'portal.relationships.backfilled',
      module: 'user-access',
      recordCollection: 'students',
      recordId: tenantId,
      after: counters,
      reason: 'Backfilled trusted student, guardian and portal relationship fields.',
      occurredAt: FieldValue.serverTimestamp(),
    });
    await writer.close();
  }

  console.log(JSON.stringify(counters, null, 2));
  return counters;
}

const tenantSnapshots = requestedTenantId
  ? [await db.collection('tenants').doc(requestedTenantId).get()]
  : (await db.collection('tenants').get()).docs;

const results = [];
for (const tenantSnapshot of tenantSnapshots) {
  results.push(await migrateTenant(tenantSnapshot));
}

console.log(JSON.stringify({
  success: true,
  projectId,
  dryRun,
  tenants: results.length,
  totals: results.reduce(
    (total, current) => ({
      relatedScanned: total.relatedScanned + current.relatedScanned,
      relatedUpdated: total.relatedUpdated + current.relatedUpdated,
      studentGuardianUpdates:
        total.studentGuardianUpdates + current.studentGuardianUpdates,
      unresolved: total.unresolved + current.unresolved,
    }),
    { relatedScanned: 0, relatedUpdated: 0, studentGuardianUpdates: 0, unresolved: 0 },
  ),
}, null, 2));
