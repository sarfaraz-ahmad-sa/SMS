import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/models/user_role.dart';
import 'package:school_management/services/supabase_tenant_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps PostgreSQL tenant fields into the shared tenant model', () {
    final tenant =
        SupabaseTenantMapper.tenant('pilot_school', <String, dynamic>{
      'name': 'SEEF Pilot School',
      'code': 'PILOT',
      'timezone': 'Asia/Karachi',
      'currency': 'PKR',
      'is_active': true,
      'active_academic_year_id': '2026-2027',
      'created_at': '2026-08-03T10:00:00Z',
      'subscription': <String, dynamic>{
        'tier': 'trial',
        'status': 'active',
      },
    });

    expect(tenant.id, 'pilot_school');
    expect(tenant.name, 'SEEF Pilot School');
    expect(tenant.activeAcademicYearId, '2026-2027');
    expect(tenant.subscription.isUsable, isTrue);
  });

  test('maps tenant membership without trusting client-side defaults', () {
    const authUser = User(
      id: '95daff89-a841-4a9b-a757-9082d5bca2df',
      appMetadata: <String, dynamic>{},
      userMetadata: <String, dynamic>{},
      aud: 'authenticated',
      createdAt: '2026-08-03T10:00:00Z',
      email: 'owner@example.com',
    );

    final user = SupabaseTenantMapper.user(
      authUser: authUser,
      tenantId: 'pilot_school',
      membership: <String, dynamic>{
        'email': 'owner@example.com',
        'display_name': 'Sarfaraz Ahmad',
        'roles': <String>['schoolOwner'],
        'permissions': <String>['*'],
        'denied_permissions': <String>[],
        'campus_ids': <String>[],
        'is_active': true,
        'must_change_password': false,
      },
      profile: const <String, dynamic>{'theme_mode': 'system'},
    );

    expect(user.tenantId, 'pilot_school');
    expect(user.roles, <UserRole>[UserRole.schoolOwner]);
    expect(user.hasPermission('any.permission'), isTrue);
    expect(user.displayName, 'Sarfaraz Ahmad');
  });
}
