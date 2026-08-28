import 'dart:convert';
import 'dart:html' as html;

Future<void> exportCsv({
  required String fileName,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  String encodeCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
  final csv = <List<String>>[headers, ...rows]
      .map((row) => row.map(encodeCell).join(','))
      .join('\r\n');
  final bytes = utf8.encode('\uFEFF$csv');
  final blob = html.Blob(<Object>[bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
