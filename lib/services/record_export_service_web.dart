import 'csv_encoding.dart';
import 'dart:convert';
import 'dart:html' as html;

Future<void> exportCsv({
  required String fileName,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  final csv = <List<String>>[headers, ...rows]
      .map((row) => row.map(encodeCsvCell).join(','))
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
