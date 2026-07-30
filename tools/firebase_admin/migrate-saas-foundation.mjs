import process from 'node:process';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

const defaultLimits = Object.freeze({
  trial: Object.freeze({
    students: 30,
    staffUsers: 10,
    campuses: 1,
    storageMb: 512,
    smsPerMonth: 100,
    emailPerMonth: 500,
    aiActionsPerMonth: 25,
  }),
  starter: Object.freeze({
    students: 250,
    staffUsers: 40,
    campuses: 1,
    storageMb: 5120,
    smsPerMonth: 2000,
    emailPerMonth: 10000,
    aiActionsPerMonth: 250,
  }),
  pro: Object.freeze({
    students: 2000,
    staffUsers: 250,
    campuses: 10,
    storageMb: 51200,
    smsPerMonth: 20000,
    emailPerMonth: 100000,
    aiActionsPerMonth: 5000,
  }),
  enterprise: Object.freeze({
    students: 0,
    staffUsers: 0,
    campuses: 0,
    storageMb: 0,
    smsPerMonth: 0,
    emailPerMonth: 0,
    aiActionsPerMonth: 0,
  }),
  custom: Object.freeze({
    students: 0,
    staffUsers: 0,
    campuses: 0,
    storageMb: 0,
    smsPerMonth: 0,
    emailPerMonth: 0,
    aiActionsPerMonth: 0,
  }),
});

const projectId = required('FIREBASE_PROJECT_ID');
const requestedTenantId = process.env.TENANT_ID?.trim() || null;
const fallbackTier = process.env.DEFAULT_SAAS_TIER?.trim().toLowerCase() || 'enterprise';
if (!Object.hasOwn(defaultLimits, fallbackTier)) {
  throw new Error('DEFAULT_SAAS_TIER must be trial, starter, pro, enterprise or custom.');
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

function accountCategoryForRoles(roles) {
  const normalized = Array.isArray(roles) ? roles : [];
  return normalized.length > 0 &&
    normalized.every((role) => ['student', 'parent'].includes(role))
    ? 'portal'
    : 'staff';
}

const tenantSnapshots = requestedTenantId
  ? [await db.collection('tenants').doc(requestedTenantId).get()]
  : (await db.collection('tenants').get()).docs;

let migrated = 0;
for (const tenantSnapshot of tenantSnapshots) {
  if (!tenantSnapshot.exists) {
    throw new Error(`Tenant not found: ${requestedTenantId}`);
  }
  const tenantId = tenantSnapshot.id;
  const tenantRef = tenantSnapshot.ref;
  const tenant = tenantSnapshot.data() ?? {};
  const existingSubscription = tenant.subscription ?? {};
  const tier = String(existingSubscription.tier ?? fallbackTier).toLowerCase();
  const safeTier = Object.hasOwn(defaultLimits, tier) ? tier : fallbackTier;
  const status = String(existingSubscription.status ?? 'active');

  const [students, members, campuses, usageSnapshot] = await Promise.all([
    tenantRef.collection('students').where('isArchived', '==', false).count().get(),
    tenantRef.collection('members').get(),
    tenantRef.collection('campuses').where('isArchived', '==', false).count().get(),
    tenantRef.collection('saas_usage').doc('current').get(),
  ]);

  const memberUpdates = [];
  let staffUsers = 0;
  for (const memberDocument of members.docs) {
    const member = memberDocument.data() ?? {};
    const roles = Array.isArray(member.roles)
      ? member.roles
      : (member.role ? [member.role] : []);
    const accountCategory = accountCategoryForRoles(roles);
    if (member.isActive === true && accountCategory === 'staff') staffUsers += 1;
    if (member.accountCategory !== accountCategory) {
      memberUpdates.push({ reference: memberDocument.ref, accountCategory });
    }
  }

  const priorUsage = usageSnapshot.data() ?? {};
  const now = FieldValue.serverTimestamp();
  const subscription = {
    ...existingSubscription,
    tier: safeTier,
    status,
    active: !['cancelled', 'suspended', 'expired'].includes(status.toLowerCase()),
    cancelAtPeriodEnd: existingSubscription.cancelAtPeriodEnd === true,
    enabledFeatures: Array.isArray(existingSubscription.enabledFeatures)
      ? existingSubscription.enabledFeatures
      : [],
    limits: {
      ...defaultLimits[safeTier],
      ...(existingSubscription.limits ?? {}),
    },
  };

  if (memberUpdates.length > 0) {
    const writer = db.bulkWriter();
    for (const update of memberUpdates) {
      writer.set(
        update.reference,
        { accountCategory: update.accountCategory, updatedAt: now },
        { merge: true },
      );
    }
    await writer.close();
  }

  const batch = db.batch();
  batch.set(
    tenantRef,
    {
      subscription,
      updatedAt: now,
      saasMigratedAt: now,
    },
    { merge: true },
  );
  batch.set(
    tenantRef.collection('saas_usage').doc('current'),
    {
      students: students.data().count,
      staffUsers,
      campuses: campuses.data().count,
      storageMb: Number(priorUsage.storageMb ?? 0),
      smsThisMonth: Number(priorUsage.smsThisMonth ?? 0),
      emailThisMonth: Number(priorUsage.emailThisMonth ?? 0),
      aiActionsThisMonth: Number(priorUsage.aiActionsThisMonth ?? 0),
      updatedAt: now,
      updatedBy: 'saas-migration',
    },
    { merge: true },
  );
  batch.create(tenantRef.collection('audit_logs').doc(), {
    tenantId,
    actorUid: 'saas-migration',
    action: 'saas.foundation.migrated',
    module: 'administration-saas',
    recordCollection: 'tenants',
    recordId: tenantId,
    before: { subscription: existingSubscription },
    after: { subscription },
    reason: 'Version 2.3 SaaS control-plane and account-category migration',
    occurredAt: now,
  });
  await batch.commit();
  migrated += 1;
  console.log(`Migrated ${tenantId} (${safeTier}, ${status})`);
}

console.log(JSON.stringify({ success: true, projectId, migrated }, null, 2));
