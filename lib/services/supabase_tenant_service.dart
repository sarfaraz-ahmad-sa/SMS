import 'package:supabase_flutter/supabase_flutter.dart';

import 'UserModel.dart';
import 'models/tenant.dart';
import 'supabase_bootstrap.dart';
import 'tenant_service.dart';

/// Resolves a Supabase identity into the tenant context allowed by PostgreSQL
/// row-level security. This remains isolated from the Firebase session until
/// the ERP repositories are migrated.
class SupabaseTenantService {
  SupabaseTenantService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<TenantSession> loadSession({String? tenantId}) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const TenantAccessException(
        'not-authenticated',
        'Sign in before loading a school session.',
      );
    }

    final responses = await Future.wait<dynamic>(<Future<dynamic>>[
      _client
          .from('profiles')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle(),
      _client
          .from('tenant_members')
          .select('*, tenant:tenants(*)')
          .eq('user_id', authUser.id)
          .eq('is_active', true)
          .eq('status', 'active'),
    ]);

    final profileRow = _asNullableMap(responses[0]);
    final membershipRows = _asMapList(responses[1]);
    if (membershipRows.isEmpty) {
      throw const TenantAccessException(
        'tenant-not-assigned',
        'This account has no active school membership.',
      );
    }

    final preferredTenantId = _optionalText(tenantId) ??
        _optionalText(profileRow?['active_tenant_id']);
    final membership = preferredTenantId == null
        ? membershipRows.first
        : membershipRows.cast<Map<String, dynamic>?>().firstWhere(
              (Map<String, dynamic>? row) =>
                  row?['tenant_id']?.toString() == preferredTenantId,
              orElse: () => null,
            );
    if (membership == null) {
      throw const TenantAccessException(
        'tenant-forbidden',
        'You do not have access to the selected school.',
      );
    }

    final resolvedTenantId = membership['tenant_id']?.toString() ?? '';
    final tenantRow = _asNullableMap(membership['tenant']);
    if (resolvedTenantId.isEmpty || tenantRow == null) {
      throw const TenantAccessException(
        'tenant-not-found',
        'The assigned school record could not be found.',
      );
    }

    final tenant = SupabaseTenantMapper.tenant(resolvedTenantId, tenantRow);
    final user = SupabaseTenantMapper.user(
      authUser: authUser,
      tenantId: resolvedTenantId,
      membership: membership,
      profile: profileRow,
    );
    _validate(user, tenant);

    final campusIds = user.campusIds;
    final activeCampusFuture = campusIds.isNotEmpty
        ? Future<String?>.value(campusIds.first)
        : _firstCampusId(resolvedTenantId);
    final activeYearFuture = tenant.activeAcademicYearId != null
        ? Future<String?>.value(tenant.activeAcademicYearId)
        : _activeAcademicYearId(resolvedTenantId);
    final context = await Future.wait<String?>(
      <Future<String?>>[activeCampusFuture, activeYearFuture],
    );

    return TenantSession(
      user: user,
      tenant: tenant,
      activeCampusId: context[0],
      activeAcademicYearId: context[1],
    );
  }

  Future<TenantSession> selectTenant(String tenantId) async {
    final session = await loadSession(tenantId: tenantId);
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const TenantAccessException(
        'not-authenticated',
        'Sign in before selecting a school.',
      );
    }
    await _client.from('profiles').update(<String, dynamic>{
      'active_tenant_id': tenantId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', user.id);
    return session;
  }

  Future<List<Tenant>> getAccessibleTenants() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <Tenant>[];
    final response = await _client
        .from('tenant_members')
        .select('tenant:tenants(*)')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .eq('status', 'active')
        .limit(100);
    return _asMapList(response)
        .map((row) {
          final tenantRow = _asNullableMap(row['tenant']);
          if (tenantRow == null) return null;
          final id = tenantRow['id']?.toString() ?? '';
          return id.isEmpty ? null : SupabaseTenantMapper.tenant(id, tenantRow);
        })
        .whereType<Tenant>()
        .toList(growable: false);
  }

  Future<Tenant> updateTenantProfile({
    required Tenant current,
    required String name,
    required String code,
    required String timezone,
    required String currency,
    required String activeAcademicYearId,
    required String logoUrl,
  }) async {
    final response = await _client.rpc('update_tenant_profile', params: {
      'p_tenant_id': current.id,
      'p_name': name.trim(),
      'p_code': code.trim(),
      'p_timezone': timezone.trim(),
      'p_currency': currency.trim(),
      'p_active_academic_year_id': activeAcademicYearId.trim(),
      'p_logo_url': logoUrl.trim(),
    });
    final row = response is Map
        ? Map<String, dynamic>.from(response)
        : response is List && response.isNotEmpty && response.first is Map
            ? Map<String, dynamic>.from(response.first as Map)
            : throw const FormatException('School update returned no row.');
    return SupabaseTenantMapper.tenant(current.id, row);
  }

  Future<String?> _firstCampusId(String tenantId) async {
    final row = await _client
        .from('campuses')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('is_archived', false)
        .order('name')
        .limit(1)
        .maybeSingle();
    return _optionalText(row?['id']);
  }

  Future<String?> _activeAcademicYearId(String tenantId) async {
    final row = await _client
        .from('academic_years')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'active')
        .eq('is_archived', false)
        .order('starts_on', ascending: false)
        .limit(1)
        .maybeSingle();
    return _optionalText(row?['id']);
  }

  void _validate(UserModel user, Tenant tenant) {
    if (!user.isActive) {
      throw const TenantAccessException(
        'membership-inactive',
        'Your school membership is inactive.',
      );
    }
    if (user.roles.isEmpty) {
      throw const TenantAccessException(
        'role-not-assigned',
        'No role has been assigned to this school account.',
      );
    }
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
  }
}

class SupabaseTenantMapper {
  const SupabaseTenantMapper._();

  static Tenant tenant(String id, Map<String, dynamic> row) {
    final subscription =
        _asNullableMap(row['subscription']) ?? const <String, dynamic>{};
    return Tenant.fromMap(id, <String, dynamic>{
      'name': row['name'],
      'code': row['code'],
      'logoUrl': row['logo_url'],
      'brandColor': row['brand_color'],
      'timezone': row['timezone'],
      'currency': row['currency'],
      'activeAcademicYearId': row['active_academic_year_id'],
      'isActive': row['is_active'],
      'createdAt': row['created_at'],
      'subscription': <String, dynamic>{
        ...subscription,
        'currentPeriodEnd': subscription['current_period_end'],
        'trialEndsAt': subscription['trial_ends_at'],
        'gracePeriodEndsAt': subscription['grace_period_ends_at'],
        'cancelAtPeriodEnd': subscription['cancel_at_period_end'],
        'enabledFeatures': subscription['enabled_features'],
      },
    });
  }

  static UserModel user({
    required User authUser,
    required String tenantId,
    required Map<String, dynamic> membership,
    Map<String, dynamic>? profile,
  }) {
    return UserModel.fromMap(
      authUser.id,
      <String, dynamic>{
        'tenantId': tenantId,
        'email': membership['email'],
        'displayName': _optionalText(profile?['display_name']) ??
            membership['display_name'],
        'roles': membership['roles'],
        'permissions': membership['permissions'],
        'deniedPermissions': membership['denied_permissions'],
        'campusIds': membership['campus_ids'],
        'isActive': membership['is_active'],
        'mustChangePassword': membership['must_change_password'],
        'linkedRecordType': membership['linked_record_type'],
        'linkedRecordId': membership['linked_record_id'],
        'themeMode': profile?['theme_mode'],
      },
      fallbackTenantId: tenantId,
      fallbackEmail: authUser.email,
      fallbackDisplayName: authUser.userMetadata?['display_name']?.toString(),
    );
  }
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! Iterable) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
      .toList();
}

String? _optionalText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
