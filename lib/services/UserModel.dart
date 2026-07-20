import 'models/user_role.dart';

/// Represents an authenticated app user, scoped to a single tenant.
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String tenantId;
  final UserRole role;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.tenantId = '',
    this.role = UserRole.student,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      tenantId: (map['tenantId'] as String?) ?? '',
      role: userRoleFromString(map['role'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'tenantId': tenantId,
        'role': role.value,
      };
}
