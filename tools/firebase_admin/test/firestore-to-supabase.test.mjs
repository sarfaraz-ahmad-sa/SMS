import test from 'node:test';
import assert from 'node:assert/strict';

import {
  synthesizeReferenceData,
  transformRecord,
  validateDataset,
} from '../firestore-to-supabase.mjs';

const context = {
  tenantId: 'pilot_school',
  campusId: 'main-campus',
  academicYearId: '2026-2027',
};

test('student transformation preserves ID and applies explicit school scope', () => {
  const row = transformRecord('students', 'student-1', {
    admissionNo: 'A-001',
    fullName: 'Test Student',
    classId: 'class-1',
    sectionId: 'section-1',
  }, context);

  assert.equal(row.tenant_id, 'pilot_school');
  assert.equal(row.campus_id, 'main-campus');
  assert.equal(row.academic_year_id, '2026-2027');
  assert.equal(row.admission_no, 'A-001');
  assert.equal(row.auth_user_id, null);
});

test('missing master data is synthesized from scoped student labels', () => {
  const studentSource = {
    campusId: 'main-campus',
    academicYearId: '2026-2027',
    className: '1',
    sectionName: 'A',
    admissionNo: 'A-001',
    fullName: 'Test Student',
  };
  const student = transformRecord('students', 'student-1', studentSource, context);
  const dataset = {
    campuses: [],
    academic_years: [],
    classes: [],
    sections: [],
    subjects: [],
    students: [student],
    guardians: [],
    student_guardians: [],
  };

  synthesizeReferenceData(dataset, [{ id: 'student-1', data: studentSource }], context);

  assert.equal(dataset.campuses[0].id, 'main-campus');
  assert.equal(dataset.academic_years[0].id, '2026-2027');
  assert.equal(dataset.classes[0].id, student.class_id);
  assert.equal(dataset.sections[0].id, student.section_id);
  assert.deepEqual(validateDataset(dataset), []);
});

test('dataset validation rejects broken relational references', () => {
  const empty = {
    campuses: [],
    academic_years: [],
    classes: [],
    sections: [],
    subjects: [],
    students: [{
      id: 'student-1',
      campus_id: 'missing-campus',
      academic_year_id: 'missing-year',
      admission_no: 'A-001',
      full_name: 'Test Student',
      class_id: 'missing-class',
      section_id: null,
    }],
    guardians: [],
    student_guardians: [],
  };

  const codes = validateDataset(empty).map((error) => error.code);
  assert.ok(codes.includes('unknown_campus_id'));
  assert.ok(codes.includes('unknown_academic_year_id'));
  assert.ok(codes.includes('unknown_class_id'));
});
