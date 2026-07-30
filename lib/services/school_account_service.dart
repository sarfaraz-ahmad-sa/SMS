import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/user_role.dart';

enum AccountSetupMethod { temporaryPassword, emailLink }

class ProvisionAccountResult {
  const ProvisionAccountResult({
    required this.uid,
    required this.created,
    required this.requiresPasswordChange,
    required this.passwordEmailSent,
    this.passwordEmailError,
    this.existingAuthenticationAccount = false,
  });

  final String uid;
  final bool created;
  final bool requiresPasswordChange;
  final bool passwordEmailSent;
  final String? passwordEmailError;
  final bool existingAuthenticationAccount;
}

class SchoolAccountService {
  SchoolAccountService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMembers(String tenantId) {
    return _db
        .collection('tenants')
        .doc(tenantId)
        .collection('members')
        .limit(300)
        .snapshots();
  }

  Future<ProvisionAccountResult> provisionAccount({
    required String tenantId,
    required String email,
    required String displayName,
    required UserRole role,
    required List<String> campusIds,
    required AccountSetupMethod setupMethod,
    String? temporaryPassword,
    bool forcePasswordChange = true,
    String? recordType,
    String? recordId,
  }) async {
    final callable = _functions.httpsCallable('provisionSchoolUser');
    final response = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'tenantId': tenantId,
      'email': email.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'roles': <String>[role.value],
      'campusIds': campusIds,
      'recordType': recordType?.trim() ?? '',
      'recordId': recordId?.trim() ?? '',
      'setupMethod': setupMethod.name,
      'temporaryPassword': temporaryPassword ?? '',
      'forcePasswordChange': forcePasswordChange,
    });

    final data = response.data;
    var passwordEmailSent = false;
    String? passwordEmailError;
    if (setupMethod == AccountSetupMethod.emailLink) {
      try {
        await sendPasswordSetupEmail(email);
        passwordEmailSent = true;
      } on FirebaseAuthException catch (error) {
        passwordEmailError = error.message ?? error.code;
      }
    }

    return ProvisionAccountResult(
      uid: data['uid']?.toString() ?? '',
      created: data['created'] == true,
      requiresPasswordChange: data['requiresPasswordChange'] == true,
      passwordEmailSent: passwordEmailSent,
      passwordEmailError: passwordEmailError,
      existingAuthenticationAccount:
          data['existingAuthenticationAccount'] == true,
    );
  }

  Future<void> updateAccess({
    required String tenantId,
    required String targetUid,
    required String displayName,
    required List<UserRole> roles,
    required List<String> campusIds,
  }) async {
    await _functions.httpsCallable('manageSchoolUser').call(<String, dynamic>{
      'tenantId': tenantId,
      'targetUid': targetUid,
      'action': 'updateAccess',
      'displayName': displayName.trim(),
      'roles': roles.map((UserRole role) => role.value).toList(),
      'campusIds': campusIds,
    });
  }

  Future<void> setAccountActive({
    required String tenantId,
    required String targetUid,
    required bool active,
    String? reason,
  }) async {
    await _functions.httpsCallable('manageSchoolUser').call(<String, dynamic>{
      'tenantId': tenantId,
      'targetUid': targetUid,
      'action': active ? 'activate' : 'suspend',
      'reason': reason?.trim() ?? '',
    });
  }

  Future<void> resetTemporaryPassword({
    required String tenantId,
    required String targetUid,
    required String temporaryPassword,
  }) async {
    await _functions.httpsCallable('manageSchoolUser').call(<String, dynamic>{
      'tenantId': tenantId,
      'targetUid': targetUid,
      'action': 'resetPassword',
      'temporaryPassword': temporaryPassword,
    });
  }

  Future<void> completeInitialPasswordChange(
    String tenantId,
    String newPassword,
  ) async {
    await _functions.httpsCallable('completeInitialPasswordChange').call(
      <String, dynamic>{
        'tenantId': tenantId,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> recordSuccessfulLogin(String tenantId) async {
    await _functions
        .httpsCallable('recordSuccessfulLogin')
        .call(<String, dynamic>{'tenantId': tenantId});
  }

  Future<void> sendPasswordSetupEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}
