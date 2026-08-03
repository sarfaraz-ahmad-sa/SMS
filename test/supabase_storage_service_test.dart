import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/supabase_storage_service.dart';

void main() {
  test('builds an explicit tenant campus and academic-year path', () {
    expect(
      SupabaseStorageService.scopedPath(
        tenantId: 'pilot_school',
        campusId: 'main-campus',
        academicYearId: '2026-2027',
        fileName: 'Fee Voucher.pdf',
      ),
      'pilot_school/main-campus/2026-2027/Fee_Voucher.pdf',
    );
  });

  test('rejects path traversal and cross-scope path segments', () {
    expect(
      () => SupabaseStorageService.scopedPath(
        tenantId: '../other-school',
        campusId: 'main-campus',
        academicYearId: '2026-2027',
        fileName: 'report.pdf',
      ),
      throwsArgumentError,
    );
    expect(
      () => SupabaseStorageService.scopedPath(
        tenantId: 'pilot_school',
        campusId: 'main-campus',
        academicYearId: '2026-2027',
        fileName: '../report.pdf',
      ),
      throwsArgumentError,
    );
  });
}
