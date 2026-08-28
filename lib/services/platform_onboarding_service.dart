import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

enum OwnerSetupMethod { emailLink, temporaryPassword }

class PlatformSchoolOnboardingResult {
  const PlatformSchoolOnboardingResult({
    required this.tenantId,
    required this.schoolCode,
    required this.ownerUserId,
    required this.ownerEmail,
    required this.campusId,
    required this.academicYearId,
    required this.accountCreated,
    required this.existingOwnerAccount,
    required this.invitationSent,
    required this.requiresPasswordChange,
  });

  final String tenantId;
  final String schoolCode;
  final String ownerUserId;
  final String ownerEmail;
  final String campusId;
  final String academicYearId;
  final bool accountCreated;
  final bool existingOwnerAccount;
  final bool invitationSent;
  final bool requiresPasswordChange;

  factory PlatformSchoolOnboardingResult.fromMap(
    Map<String, dynamic> map,
  ) {
    return PlatformSchoolOnboardingResult(
      tenantId: map['tenantId']?.toString() ?? '',
      schoolCode: map['schoolCode']?.toString() ?? '',
      ownerUserId: map['ownerUserId']?.toString() ?? '',
      ownerEmail: map['ownerEmail']?.toString() ?? '',
      campusId: map['campusId']?.toString() ?? '',
      academicYearId: map['academicYearId']?.toString() ?? '',
      accountCreated: map['accountCreated'] == true,
      existingOwnerAccount: map['existingOwnerAccount'] == true,
      invitationSent: map['invitationSent'] == true,
      requiresPasswordChange: map['requiresPasswordChange'] == true,
    );
  }
}

class PlatformOnboardingService {
  PlatformOnboardingService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<PlatformSchoolOnboardingResult> createSchool({
    required String schoolName,
    required String schoolCode,
    required String ownerName,
    required String ownerEmail,
    required String campusName,
    required String campusCode,
    required String academicYearName,
    required DateTime academicYearStart,
    required DateTime academicYearEnd,
    required String plan,
    required int trialDays,
    required OwnerSetupMethod setupMethod,
    String? temporaryPassword,
    String timezone = 'Asia/Karachi',
    String currency = 'PKR',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'platform-onboarding',
        body: <String, dynamic>{
          'action': 'createSchool',
          'schoolName': schoolName.trim(),
          'schoolCode': schoolCode.trim().toUpperCase(),
          'ownerName': ownerName.trim(),
          'ownerEmail': ownerEmail.trim().toLowerCase(),
          'campusName': campusName.trim(),
          'campusCode': campusCode.trim().toUpperCase(),
          'academicYearName': academicYearName.trim(),
          'academicYearStart': _date(academicYearStart),
          'academicYearEnd': _date(academicYearEnd),
          'timezone': timezone.trim(),
          'currency': currency.trim().toUpperCase(),
          'plan': plan,
          'trialDays': trialDays,
          'setupMethod': setupMethod.name,
          'temporaryPassword': setupMethod == OwnerSetupMethod.temporaryPassword
              ? temporaryPassword ?? ''
              : '',
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw PlatformOnboardingException(_message(response.data));
      }
      if (response.data is! Map) {
        throw const PlatformOnboardingException(
          'School onboarding returned no result.',
        );
      }
      final result = PlatformSchoolOnboardingResult.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (result.tenantId.isEmpty || result.ownerUserId.isEmpty) {
        throw const PlatformOnboardingException(
          'School onboarding returned an incomplete result.',
        );
      }
      return result;
    } on FunctionException catch (error) {
      throw PlatformOnboardingException(_message(error.details));
    }
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _message(dynamic value) {
    if (value is Map) {
      return value['error']?.toString() ??
          value['message']?.toString() ??
          'School onboarding failed.';
    }
    return value?.toString() ?? 'School onboarding failed.';
  }
}

class PlatformOnboardingException implements Exception {
  const PlatformOnboardingException(this.message);

  final String message;

  @override
  String toString() => message;
}
