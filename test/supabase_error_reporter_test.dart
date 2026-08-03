import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/supabase_error_reporter.dart';

void main() {
  test('sanitizes multiline errors and enforces the payload limit', () {
    expect(
      SupabaseErrorReporter.sanitize(
        '  first line\n\tsecond   line  ',
        maxLength: 18,
      ),
      'first line second',
    );
  });
}
