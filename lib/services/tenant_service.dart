import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'UserModel.dart';
import 'models/tenant.dart';

class TenantSession {
  final UserModel user;
  final Tenant tenant;
  final String? activeCampusId;
  final String? activeAcademicYearId;

  const TenantSession({
    required this.user,
    required this.tenant,
    this.activeCampusId,
    this.activeAcademicYearId,
  });
}

class TenantAccessException implements Exception {
  final String code;
  final String message;

  const TenantAccessException(this.code, this.message);

  @override
  String toString() => message;
}

/// Resolves Firebase identity into a school-specific membership.
///
/// Firestore layout:
/// users/{uid}
/// tenants/{tenantId}
/// tenants/{tenantId}/members/{uid}
/// tenants/{tenantId}/students/{studentId}
/// tenants/{tenantId}/events/{eventId}
class TenantService {
  TenantService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<TenantSession> loadSession(
    User firebaseUser, {
    String? tenantId,
  }) async {
    final userDocument =
        await _db.collection('users').doc(firebaseUser.uid).get();
    final userData = userDocument.data();

    if (!userDocument.exists || userData == null) {
      throw const TenantAccessException(
        'profile-not-found',
        'Your account is authenticated, but no school profile is assigned.',
      );
    }

    final resolvedTenantId = tenantId ?? _resolveActiveTenantId(userData);
    if (resolvedTenantId == null) {
      throw const TenantAccessException(
        'tenant-not-assigned',
        'No school has been assigned to this account.',
      );
    }

    final allowedTenantIds = _tenantIdsFromUser(userData);
    if (allowedTenantIds.isNotEmpty &&
        !allowedTenantIds.contains(resolvedTenantId)) {
      throw const TenantAccessException(
        'tenant-forbidden',
        'You do not have access to the selected school.',
      );
    }

    final memberDocument = await _db
        .collection('tenants')
        .doc(resolvedTenantId)
        .collection('members')
        .doc(firebaseUser.uid)
        .get();
    final memberData = memberDocument.data();

    // Legacy support: older data stored role/tenantId on users/{uid}.
    // New installations should always create a tenant membership document.
    final profileMap = <String, dynamic>{...userData};
    if (memberData != null) profileMap.addAll(memberData);
    profileMap['tenantId'] = resolvedTenantId;

    final profile = UserModel.fromMap(
      firebaseUser.uid,
      profileMap,
      fallbackTenantId: resolvedTenantId,
      fallbackEmail: firebaseUser.email,
      fallbackDisplayName: firebaseUser.displayName,
    );

    final membershipStatus =
        memberData?['status']?.toString().trim().toLowerCase();
    if (!profile.isActive ||
        membershipStatus == 'inactive' ||
        membershipStatus == 'suspended') {
      throw const TenantAccessException(
        'membership-inactive',
        'Your school membership is inactive. Contact the school administrator.',
      );
    }

    if (profile.roles.isEmpty) {
      throw const TenantAccessException(
        'role-not-assigned',
        'No role has been assigned to this school account.',
      );
    }

    final tenant = await getTenant(resolvedTenantId);
    if (!tenant.isActive) {
      throw const TenantAccessException(
        'tenant-inactive',
        'This school account is currently inactive.',
      );
    }
    if (!tenant.subscription.isUsable) {
      throw const TenantAccessException(
        'subscription-inactive',
        'This school subscription is inactive or expired.',
      );
    }

    return TenantSession(
      user: profile,
      tenant: tenant,
      activeCampusId: _firstNonEmpty(<dynamic>[
        memberData?['activeCampusId'],
        userData['activeCampusId'],
        profile.campusIds.isNotEmpty ? profile.campusIds.first : null,
      ]),
      activeAcademicYearId: _firstNonEmpty(<dynamic>[
        memberData?['activeAcademicYearId'],
        userData['activeAcademicYearId'],
        tenant.activeAcademicYearId,
      ]),
    );
  }

  Future<List<Tenant>> getAccessibleTenants(User firebaseUser) async {
    final userDocument =
        await _db.collection('users').doc(firebaseUser.uid).get();
    final userData = userDocument.data();
    if (userData == null) return const <Tenant>[];

    final ids = _tenantIdsFromUser(userData);
    final activeTenantId = _resolveActiveTenantId(userData);
    if (activeTenantId != null) ids.add(activeTenantId);

    final tenants = <Tenant>[];
    for (final id in ids) {
      try {
        final member = await _db
            .collection('tenants')
            .doc(id)
            .collection('members')
            .doc(firebaseUser.uid)
            .get();
        final status = member.data()?['status']?.toString().toLowerCase();
        if (status == 'inactive' || status == 'suspended') continue;

        final tenant = await getTenant(id);
        if (tenant.isActive && tenant.subscription.isUsable) {
          tenants.add(tenant);
        }
      } on TenantAccessException {
        // Skip inaccessible tenants while preserving valid memberships.
      } on FirebaseException {
        // A stale tenant ID or denied membership must not break all switching.
      }
    }

    tenants.sort((Tenant a, Tenant b) => a.name.compareTo(b.name));
    return tenants;
  }

  Future<TenantSession> selectTenant(
    User firebaseUser,
    String tenantId,
  ) async {
    final session = await loadSession(firebaseUser, tenantId: tenantId);

    // Persist only the selected context. Security rules prevent changing role,
    // membership, or tenantIds from the client.
    await _db.collection('users').doc(firebaseUser.uid).set(
      <String, dynamic>{
        'activeTenantId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return session;
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) return null;
    return (await loadSession(firebaseUser)).user;
  }

  Future<Tenant> getTenant(String tenantId) async {
    if (tenantId.trim().isEmpty) {
      throw const TenantAccessException(
        'tenant-not-assigned',
        'No school has been assigned to this account.',
      );
    }

    final document = await _db.collection('tenants').doc(tenantId).get();
    final data = document.data();
    if (!document.exists || data == null) {
      throw const TenantAccessException(
        'tenant-not-found',
        'The assigned school record could not be found.',
      );
    }
    return Tenant.fromMap(document.id, data);
  }

  Future<Tenant> updateTenantProfile({
    required Tenant current,
    required String name,
    required String code,
    required String timezone,
    required String currency,
    String? activeAcademicYearId,
    String? logoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final updated = current.copyWith(
      name: name.trim(),
      code: code.trim().toUpperCase(),
      timezone: timezone.trim(),
      currency: currency.trim().toUpperCase(),
      activeAcademicYearId: activeAcademicYearId?.trim(),
      logoUrl: logoUrl?.trim(),
    );

    if (user == null) return updated;

    await _db.collection('tenants').doc(current.id).update(
      <String, dynamic>{
        'name': updated.name,
        'code': updated.code,
        'timezone': updated.timezone,
        'currency': updated.currency,
        'activeAcademicYearId': updated.activeAcademicYearId,
        'logoUrl': updated.logoUrl,
        'updatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    return updated;
  }

  Future<void> createTenant(Tenant tenant) {
    throw UnsupportedError(
      'Tenant provisioning must run through a trusted Laravel API or Cloud Function.',
    );
  }

  String? _resolveActiveTenantId(Map<String, dynamic> userData) {
    return _firstNonEmpty(<dynamic>[
      userData['activeTenantId'],
      userData['tenantId'],
      _tenantIdsFromUser(userData).firstOrNull,
    ]);
  }

  Set<String> _tenantIdsFromUser(Map<String, dynamic> userData) {
    final ids = <String>{};
    final raw = userData['tenantIds'];
    if (raw is Iterable) {
      ids.addAll(
        raw
            .map((dynamic value) => value?.toString().trim() ?? '')
            .where((String value) => value.isNotEmpty),
      );
    }
    final legacy = userData['tenantId']?.toString().trim();
    if (legacy?.isNotEmpty == true) ids.add(legacy!);
    return ids;
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
