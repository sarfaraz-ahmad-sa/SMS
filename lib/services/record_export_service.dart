import '../core/erp/erp_entity.dart';
import '../core/erp/erp_record.dart';
import 'record_export_service_stub.dart'
    if (dart.library.html) 'record_export_service_web.dart' as implementation;

class RecordExportService {
  const RecordExportService();

  Future<void> exportCsv({
    required ErpEntity entity,
    required List<ErpRecord> records,
  }) {
    final fields = entity.fields
        .where((field) => !field.internal)
        .map((field) => (field.key, field.label))
        .toList(growable: false);
    return implementation.exportCsv(
      fileName: '${entity.collection}-${DateTime.now().toIso8601String().split('T').first}.csv',
      headers: <String>['Record ID', ...fields.map((field) => field.$2)],
      rows: records
          .map(
            (record) => <String>[
              record.id,
              ...fields.map((field) => _safeCell(record.data[field.$1])),
            ],
          )
          .toList(growable: false),
    );
  }

  String _safeCell(dynamic value) {
    final text = value == null
        ? ''
        : value is Iterable
            ? value.join('; ')
            : value.toString();
    final trimmedLeft = text.trimLeft();
    if (trimmedLeft.startsWith('=') ||
        trimmedLeft.startsWith('+') ||
        trimmedLeft.startsWith('-') ||
        trimmedLeft.startsWith('@')) {
      return "'$text";
    }
    return text;
  }
}
