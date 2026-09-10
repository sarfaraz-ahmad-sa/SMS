import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/csv_encoding.dart';

void main() {
  test('all cells including identifiers neutralize spreadsheet formulas', () {
    for (final value in [
      '=1+1',
      '  +1',
      '-1',
      '@SUM(A1)',
      '\t=1',
      '\r=1',
      '\n=1'
    ]) {
      expect(encodeCsvCell(value).startsWith("\"'"), isTrue);
    }
    expect(encodeCsvCell('normal, cell'), '"normal, cell"');
    expect(encodeCsvCell('a"b'), '"a""b"');
  });
}
