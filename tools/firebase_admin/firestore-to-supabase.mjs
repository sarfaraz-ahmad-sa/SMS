import process from 'node:process';
import { pathToFileURL } from 'node:url';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const COLLECTIONS = Object.freeze([
  'campuses',
  'academic_years',
  'classes',
  'sections',
  'subjects',
  'students',
  'guardians',
  'student_guardians',
]);

const UPSERT_CONFLICTS = Object.freeze({
  campuses: 'tenant_id,id',
  academic_years: 'tenant_id,id',
  classes: 'tenant_id,id',
  sections: 'tenant_id,id',
  subjects: 'tenant_id,id',
  students: 'tenant_id,id',
  guardians: 'tenant_id,id',
  student_guardians: 'tenant_id,student_id,guardian_id',
});

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function flag(name, fallback = false) {
  const value = process.env[name];
  if (value == null) return fallback;
  return ['1', 'true', 'yes'].includes(value.trim().toLowerCase());
}

function text(...values) {
  for (const value of values) {
    const normalized = value?.toString().trim();
    if (normalized) return normalized;
  }
  return null;
}

function date(value) {
  if (value == null) return null;
  const parsed = typeof value?.toDate === 'function' ? value.toDate() : new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString().slice(0, 10);
}

function integer(value, fallback = 0) {
  const parsed = Number.parseInt(value?.toString() ?? '', 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function archived(data) {
  return data.isArchived === true || data.is_archived === true;
}

function scope(data, defaults) {
  return {
    campus_id: text(data.campusId, data.campus_id, defaults.campusId),
    academic_year_id: text(
      data.academicYearId,
      data.academic_year_id,
      defaults.academicYearId,
    ),
  };
}

function normalizeStatus(value, allowed, fallback) {
  const normalized = text(value)?.toLowerCase().replaceAll(' ', '_');
  return allowed.includes(normalized) ? normalized : fallback;
}

function slug(value) {
  return text(value)
    ?.toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'unknown';
}

function titleFromId(value) {
  return value
    .split(/[-_]+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(' ');
}

function classIdFor(data, scoped) {
  return text(data.classId, data.class_id) || (
    text(data.className)
      ? `${slug(scoped.campus_id)}-${slug(scoped.academic_year_id)}-class-${slug(data.className)}`
      : null
  );
}

function sectionIdFor(data, scoped, classId) {
  return text(data.sectionId, data.section_id) || (
    classId && text(data.sectionName)
      ? `${classId}-section-${slug(data.sectionName)}`
      : null
  );
}

export function transformRecord(collection, id, data, context) {
  const tenant_id = context.tenantId;
  const scoped = scope(data, context);
  const common = { tenant_id, id, is_archived: archived(data) };

  switch (collection) {
    case 'campuses':
      return {
        ...common,
        code: text(data.code, id)?.toUpperCase(),
        name: text(data.name, data.campusName),
        address: text(data.address),
      };
    case 'academic_years':
      return {
        ...common,
        id: text(data.academicYearId, data.academic_year_id, id),
        name: text(data.name, data.academicYear, id),
        starts_on: date(data.startsOn ?? data.startDate ?? data.starts_on),
        ends_on: date(data.endsOn ?? data.endDate ?? data.ends_on),
        status: normalizeStatus(
          data.status,
          ['draft', 'active', 'closed'],
          id === context.academicYearId ? 'active' : 'draft',
        ),
      };
    case 'classes':
      return {
        ...common,
        ...scoped,
        name: text(data.name, data.className),
        sort_order: integer(data.sortOrder ?? data.sort_order),
      };
    case 'sections':
      return {
        ...common,
        ...scoped,
        class_id: text(data.classId, data.class_id),
        name: text(data.name, data.sectionName),
        capacity: data.capacity == null ? null : integer(data.capacity),
      };
    case 'subjects':
      return {
        ...common,
        ...scoped,
        code: text(data.code, data.subjectCode, id)?.toUpperCase(),
        name: text(data.name, data.subjectName),
      };
    case 'students': {
      const classId = classIdFor(data, scoped);
      const sectionId = sectionIdFor(data, scoped, classId);
      return {
        ...common,
        ...scoped,
        class_id: classId,
        section_id: sectionId,
        admission_no: text(
          data.admissionNo,
          data.admissionNumber,
          data.admission_no,
          id,
        ),
        full_name: text(data.fullName, data.studentName, data.name),
        date_of_birth: date(data.dateOfBirth ?? data.dob ?? data.date_of_birth),
        gender: text(data.gender)?.toLowerCase(),
        auth_user_id: null,
        status: normalizeStatus(
          data.status,
          ['active', 'inactive', 'graduated', 'withdrawn'],
          'active',
        ),
      };
    }
    case 'guardians':
      return {
        ...common,
        full_name: text(data.fullName, data.guardianName, data.name),
        phone: text(data.phone, data.mobile),
        email: text(data.email)?.toLowerCase(),
        auth_user_id: null,
      };
    case 'student_guardians':
      return {
        tenant_id,
        student_id: text(data.studentId, data.student_id),
        guardian_id: text(data.guardianId, data.guardian_id),
        relationship: text(data.relationship, data.relation, 'guardian'),
        is_primary: data.isPrimary === true || data.is_primary === true,
        can_pick_up: data.canPickUp !== false && data.can_pick_up !== false,
      };
    default:
      throw new Error(`Unsupported collection: ${collection}`);
  }
}

function yearDates(yearId) {
  const match = /^(\d{4})\D+(\d{4})$/.exec(yearId);
  if (!match) return { starts_on: null, ends_on: null };
  return {
    starts_on: `${match[1]}-08-01`,
    ends_on: `${match[2]}-07-31`,
  };
}

export function synthesizeReferenceData(dataset, rawStudents, context) {
  const campusIds = new Set(dataset.campuses.map((row) => row.id));
  const yearIds = new Set(dataset.academic_years.map((row) => row.id));
  const classIds = new Set(dataset.classes.map((row) => row.id));
  const sectionIds = new Set(dataset.sections.map((row) => row.id));

  const referencedCampuses = new Set([
    context.campusId,
    ...dataset.students.map((row) => row.campus_id),
  ]);
  for (const campusId of referencedCampuses) {
    if (!campusId || campusIds.has(campusId)) continue;
    dataset.campuses.push({
      tenant_id: context.tenantId,
      id: campusId,
      code: campusId.replace(/[^a-z0-9]/gi, '').toUpperCase().slice(0, 20),
      name: titleFromId(campusId),
      address: null,
      is_archived: false,
    });
    campusIds.add(campusId);
  }

  const referencedYears = new Set([
    context.academicYearId,
    ...dataset.students.map((row) => row.academic_year_id),
  ]);
  for (const yearId of referencedYears) {
    if (!yearId || yearIds.has(yearId)) continue;
    dataset.academic_years.push({
      tenant_id: context.tenantId,
      id: yearId,
      name: yearId,
      ...yearDates(yearId),
      status: yearId === context.academicYearId ? 'active' : 'draft',
      is_archived: false,
    });
    yearIds.add(yearId);
  }

  for (const source of rawStudents) {
    const data = source.data;
    const scoped = scope(data, context);
    const classId = classIdFor(data, scoped);
    if (classId && !classIds.has(classId)) {
      dataset.classes.push({
        tenant_id: context.tenantId,
        id: classId,
        ...scoped,
        name: text(data.className, classId),
        sort_order: integer(data.className),
        is_archived: false,
      });
      classIds.add(classId);
    }

    const sectionId = sectionIdFor(data, scoped, classId);
    if (sectionId && !sectionIds.has(sectionId)) {
      dataset.sections.push({
        tenant_id: context.tenantId,
        id: sectionId,
        ...scoped,
        class_id: classId,
        name: text(data.sectionName, sectionId),
        capacity: null,
        is_archived: false,
      });
      sectionIds.add(sectionId);
    }
  }

  return dataset;
}

export function validateDataset(dataset) {
  const errors = [];
  const ids = Object.fromEntries(
    COLLECTIONS.map((name) => [
      name,
      new Set(dataset[name].map((row) => row.id).filter(Boolean)),
    ]),
  );

  function requireFields(collection, fields) {
    for (const row of dataset[collection]) {
      for (const field of fields) {
        if (row[field] == null || row[field] === '') {
          errors.push({ collection, id: row.id ?? null, code: `missing_${field}` });
        }
      }
    }
  }

  requireFields('campuses', ['id', 'code', 'name']);
  requireFields('academic_years', ['id', 'name', 'starts_on', 'ends_on']);
  requireFields('classes', ['id', 'campus_id', 'academic_year_id', 'name']);
  requireFields('sections', ['id', 'campus_id', 'academic_year_id', 'class_id', 'name']);
  requireFields('subjects', ['id', 'campus_id', 'academic_year_id', 'code', 'name']);
  requireFields('students', ['id', 'campus_id', 'academic_year_id', 'admission_no', 'full_name']);
  requireFields('guardians', ['id', 'full_name']);
  requireFields('student_guardians', ['student_id', 'guardian_id', 'relationship']);

  const scoped = ['classes', 'sections', 'subjects', 'students'];
  for (const collection of scoped) {
    for (const row of dataset[collection]) {
      if (!ids.campuses.has(row.campus_id)) {
        errors.push({ collection, id: row.id, code: 'unknown_campus_id' });
      }
      if (!ids.academic_years.has(row.academic_year_id)) {
        errors.push({ collection, id: row.id, code: 'unknown_academic_year_id' });
      }
    }
  }

  for (const row of dataset.sections) {
    if (!ids.classes.has(row.class_id)) {
      errors.push({ collection: 'sections', id: row.id, code: 'unknown_class_id' });
    }
  }
  for (const row of dataset.students) {
    if (row.class_id && !ids.classes.has(row.class_id)) {
      errors.push({ collection: 'students', id: row.id, code: 'unknown_class_id' });
    }
    if (row.section_id && !ids.sections.has(row.section_id)) {
      errors.push({ collection: 'students', id: row.id, code: 'unknown_section_id' });
    }
  }
  for (const row of dataset.student_guardians) {
    if (!ids.students.has(row.student_id)) {
      errors.push({ collection: 'student_guardians', id: null, code: 'unknown_student_id' });
    }
    if (!ids.guardians.has(row.guardian_id)) {
      errors.push({ collection: 'student_guardians', id: null, code: 'unknown_guardian_id' });
    }
  }

  for (const collection of COLLECTIONS) {
    const keys = new Set();
    for (const row of dataset[collection]) {
      const key = collection === 'student_guardians'
        ? `${row.student_id}|${row.guardian_id}`
        : row.id;
      if (key && keys.has(key)) {
        errors.push({ collection, id: row.id ?? null, code: 'duplicate_primary_key' });
      }
      if (key) keys.add(key);
    }
  }

  return errors;
}

async function readDataset(db, sourceTenantId, context) {
  const root = db.collection('tenants').doc(sourceTenantId);
  const snapshots = await Promise.all(
    COLLECTIONS.map((collection) => root.collection(collection).get()),
  );
  const dataset = Object.fromEntries(
    COLLECTIONS.map((collection, index) => [
      collection,
      snapshots[index].docs.map((document) =>
        transformRecord(collection, document.id, document.data(), context)),
    ]),
  );
  const studentIndex = COLLECTIONS.indexOf('students');
  const rawStudents = snapshots[studentIndex].docs.map((document) => ({
    id: document.id,
    data: document.data(),
  }));
  return synthesizeReferenceData(dataset, rawStudents, context);
}

async function upsertRows({ baseUrl, serviceRoleKey, collection, rows }) {
  if (rows.length === 0) return;
  const conflict = UPSERT_CONFLICTS[collection];
  const headers = {
    apikey: serviceRoleKey,
    'content-type': 'application/json',
    prefer: 'resolution=merge-duplicates,return=minimal',
  };
  // New sb_secret keys are opaque API keys, not JWTs. Legacy service_role
  // keys remain JWTs and still require the Authorization bearer header.
  if (!serviceRoleKey.startsWith('sb_secret_')) {
    headers.authorization = `Bearer ${serviceRoleKey}`;
  }
  for (let index = 0; index < rows.length; index += 200) {
    const response = await fetch(
      `${baseUrl}/rest/v1/${collection}?on_conflict=${encodeURIComponent(conflict)}`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify(rows.slice(index, index + 200)),
      },
    );
    if (!response.ok) {
      const body = await response.text();
      throw new Error(`${collection} import failed (${response.status}): ${body}`);
    }
  }
}

async function main() {
  const sourceTenantId = required('SOURCE_FIREBASE_TENANT_ID');
  const context = {
    tenantId: required('TARGET_SUPABASE_TENANT_ID'),
    campusId: required('DEFAULT_CAMPUS_ID'),
    academicYearId: required('DEFAULT_ACADEMIC_YEAR_ID'),
  };
  const projectId = required('FIREBASE_PROJECT_ID');
  const apply = flag('APPLY_SUPABASE', false);

  initializeApp({ credential: applicationDefault(), projectId });
  const dataset = await readDataset(getFirestore(), sourceTenantId, context);
  const errors = validateDataset(dataset);
  const counts = Object.fromEntries(
    COLLECTIONS.map((collection) => [collection, dataset[collection].length]),
  );

  if (errors.length > 0) {
    console.log(JSON.stringify({
      success: false,
      apply: false,
      sourceTenantId,
      targetTenantId: context.tenantId,
      counts,
      errors,
    }, null, 2));
    process.exitCode = 2;
    return;
  }

  if (apply) {
    const baseUrl = required('SUPABASE_URL').replace(/\/$/, '');
    const serviceRoleKey = text(
      process.env.SUPABASE_SECRET_KEY,
      process.env.SUPABASE_SERVICE_ROLE_KEY,
    );
    if (!serviceRoleKey) {
      throw new Error(
        'Missing required environment variable: SUPABASE_SECRET_KEY',
      );
    }
    for (const collection of COLLECTIONS) {
      await upsertRows({ baseUrl, serviceRoleKey, collection, rows: dataset[collection] });
    }
  }

  // Counts and validation codes are safe to print; row contents may contain PII.
  console.log(JSON.stringify({
    success: true,
    apply,
    sourceTenantId,
    targetTenantId: context.tenantId,
    counts,
    validationErrors: 0,
  }, null, 2));
}

const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  main().catch((error) => {
    console.error(JSON.stringify({ success: false, message: error.message }, null, 2));
    process.exitCode = 1;
  });
}
