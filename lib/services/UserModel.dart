import 'models/app_permission.dart';
import 'models/user_role.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String tenantId;
  final List<UserRole> roles;
  final Set<String> permissions;
  final Set<String> deniedPermissions;
  final List<String> campusIds;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.tenantId,
    required this.roles,
    this.email,
    this.displayName,
    this.photoUrl,
    this.permissions = const <String>{},
    this.deniedPermissions = const <String>{},
    this.campusIds = const <String>[],
    this.isActive = true,
  });

  UserRole get role => roles.isNotEmpty ? roles.first : UserRole.student;

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? tenantId,
    List<UserRole>? roles,
    Set<String>? permissions,
    Set<String>? deniedPermissions,
    List<String>? campusIds,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      tenantId: tenantId ?? this.tenantId,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      deniedPermissions: deniedPermissions ?? this.deniedPermissions,
      campusIds: campusIds ?? this.campusIds,
      isActive: isActive ?? this.isActive,
    );
  }

  String get roleLabel => roles.isEmpty
      ? 'No Role'
      : roles.map((UserRole role) => role.label).join(', ');

  Set<String> get effectivePermissions {
    final result = <String>{...permissions};
    for (final role in roles) {
      result.addAll(role.defaultPermissions);
    }
    if (!result.contains(AppPermission.wildcard)) {
      result.removeAll(deniedPermissions);
    }
    return result;
  }

  bool hasRole(UserRole requiredRole) => roles.contains(requiredRole);

  bool hasPermission(String permission) {
    final granted = effectivePermissions;
    return granted.contains(AppPermission.wildcard) ||
        granted.contains(permission);
  }

  bool hasAnyPermission(Iterable<String> requiredPermissions) {
    final granted = effectivePermissions;
    if (granted.contains(AppPermission.wildcard)) return true;
    return requiredPermissions.any(granted.contains);
  }

  factory UserModel.fromMap(
    String uid,
    Map<String, dynamic> map, {
    String? fallbackTenantId,
    String? fallbackEmail,
    String? fallbackDisplayName,
  }) {
    final roles = <UserRole>[];
    final rawRoles = map['roles'];
    if (rawRoles is Iterable) {
      for (final value in rawRoles) {
        final role = tryUserRoleFromString(value?.toString());
        if (role != null && !roles.contains(role)) roles.add(role);
      }
    }

    final legacyRole = tryUserRoleFromString(map['role']?.toString());
    if (legacyRole != null && !roles.contains(legacyRole)) {
      roles.add(legacyRole);
    }

    Set<String> parseSet(dynamic value) {
      if (value is! Iterable) return <String>{};
      return value
          .map((dynamic item) => item?.toString().trim() ?? '')
          .where((String item) => item.isNotEmpty)
          .toSet();
    }

    List<String> parseList(dynamic value) {
      if (value is! Iterable) return <String>[];
      return value
          .map((dynamic item) => item?.toString().trim() ?? '')
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    final mappedTenantId = map['tenantId']?.toString().trim();

    return UserModel(
      uid: uid,
      email: map['email']?.toString() ?? fallbackEmail,
      displayName: map['displayName']?.toString() ?? fallbackDisplayName,
      photoUrl: map['photoUrl']?.toString(),
      tenantId: mappedTenantId?.isNotEmpty == true
          ? mappedTenantId!
          : (fallbackTenantId ?? ''),
      roles: roles,
      permissions: parseSet(map['permissions']),
      deniedPermissions: parseSet(map['deniedPermissions']),
      campusIds: parseList(map['campusIds']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'tenantId': tenantId,
        'roles': roles.map((UserRole role) => role.value).toList(),
        'permissions': permissions.toList(),
        'deniedPermissions': deniedPermissions.toList(),
        'campusIds': campusIds,
        'isActive': isActive,
      };
}
