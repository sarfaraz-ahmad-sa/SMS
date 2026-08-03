import process from 'node:process';
import { writeFile } from 'node:fs/promises';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const COLLECTIONS = Object.freeze([
  'admission_inquiries',
  'announcements',
  'employees',
  'generated_reports',
  'role_templates',
  'user_access',
]);

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function text(...values) {
  for (const value of values) {
    const normalized = value?.toString().trim();
    if (normalized) return normalized;
  }
  return null;
}

function jsonSafe(value) {
  if (value == null || typeof value === 'string' || typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value === 'bigint') return value.toString();
  if (value instanceof Date) return value.toISOString();
  if (Buffer.isBuffer(value)) return value.toString('base64');
  if (typeof value?.toDate === 'function') return value.toDate().toISOString();
  if (typeof value?.latitude === 'number' && typeof value?.longitude === 'number') {
    return { latitude: value.latitude, longitude: value.longitude };
  }
  if (typeof value?.path === 'string' && value?.firestore) {
    return { firestorePath: value.path };
  }
  if (Array.isArray(value)) return value.map(jsonSafe);
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([, item]) => item !== undefined)
        .map(([key, item]) => [key, jsonSafe(item)]),
    );
  }
  return value.toString();
}

function literal(value) {
  if (value == null) return 'null';
  return `'${value.toString().replaceAll("'", "''")}'`;
}

function timestamp(value) {
  const normalized = jsonSafe(value);
  if (typeof normalized !== 'string') return null;
  const parsed = new Date(normalized);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function rowSql({ collection, id, source, context }) {
  const safe = jsonSafe(source);
  safe.tenantId = context.targetTenantId;
  safe.campusId = text(source.campusId, source.campus_id, context.campusId);
  safe.academicYearId = text(
    source.academicYearId,
    source.academic_year_id,
    context.academicYearId,
  );
  delete safe.tenant_id;
  delete safe.campus_id;
  delete safe.academic_year_id;

  const payload = JSON.stringify(safe);
  if (Buffer.byteLength(payload, 'utf8') > 65536) {
    throw new Error(`${collection} contains a record larger than 64 KiB`);
  }

  const status = text(source.status)?.toLowerCase().replaceAll(' ', '_');
  const archived = source.isArchived === true || source.is_archived === true;
  const createdAt = timestamp(source.createdAt ?? source.created_at);
  const updatedAt = timestamp(source.updatedAt ?? source.updated_at);
  const idempotencyKey = `firebase:${context.sourceTenantId}:${collection}:${id}`;

  return `(
    ${literal(context.targetTenantId)}, ${literal(collection)}, ${literal(id)},
    ${literal(safe.campusId)}, ${literal(safe.academicYearId)}, ${literal(status)},
    ${literal(payload)}::jsonb, ${literal(idempotencyKey)}, ${archived},
    coalesce(${literal(createdAt)}::timestamptz, now()),
    coalesce(${literal(updatedAt)}::timestamptz, now())
  )`;
}

async function main() {
  const projectId = required('FIREBASE_PROJECT_ID');
  const outputFile = required('OUTPUT_SQL_FILE');
  const context = {
    sourceTenantId: required('SOURCE_FIREBASE_TENANT_ID'),
    targetTenantId: required('TARGET_SUPABASE_TENANT_ID'),
    campusId: required('DEFAULT_CAMPUS_ID'),
    academicYearId: required('DEFAULT_ACADEMIC_YEAR_ID'),
  };

  initializeApp({ credential: applicationDefault(), projectId });
  const db = getFirestore();
  const tenantReference = db.collection('tenants').doc(context.sourceTenantId);
  const values = [];
  const counts = {};

  for (const collection of COLLECTIONS) {
    const snapshot = await tenantReference.collection(collection).get();
    counts[collection] = snapshot.size;
    for (const document of snapshot.docs) {
      values.push(rowSql({
        collection,
        id: document.id,
        source: document.data(),
        context,
      }));
    }
  }

  const sql = values.length === 0
    ? `select 'no Firebase ERP records to import' as result;\n`
    : `begin;\n
insert into public.erp_records (
  tenant_id, collection, id, campus_id, academic_year_id, status,
  data, idempotency_key, is_archived, created_at, updated_at
)
values
${values.join(',\n')}
on conflict (tenant_id, collection, id) do update set
  campus_id = excluded.campus_id,
  academic_year_id = excluded.academic_year_id,
  status = excluded.status,
  data = excluded.data,
  idempotency_key = excluded.idempotency_key,
  is_archived = excluded.is_archived,
  updated_at = excluded.updated_at;

commit;

select collection, count(*)::bigint as count
from public.erp_records
where tenant_id = ${literal(context.targetTenantId)}
group by collection
order by collection;\n`;

  await writeFile(outputFile, sql, { encoding: 'utf8', mode: 0o600 });
  console.log(JSON.stringify({
    success: true,
    recordCount: values.length,
    counts,
    outputFile,
  }, null, 2));
}

main().catch((error) => {
  console.error(JSON.stringify({
    success: false,
    error: error instanceof Error ? error.message : String(error),
  }, null, 2));
  process.exitCode = 1;
});
