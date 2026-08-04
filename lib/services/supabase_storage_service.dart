import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

class SupabaseStorageService {
  SupabaseStorageService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const String documentsBucket = 'school-documents';
  static const String exportsBucket = 'school-exports';

  Future<String> uploadDocument({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final path = scopedPath(
      tenantId: tenantId,
      campusId: campusId,
      academicYearId: academicYearId,
      fileName: fileName,
    );
    await _client.storage.from(documentsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType.trim(),
            upsert: false,
          ),
        );
    return path;
  }

  Future<String> createDocumentDownloadUrl(
    String path, {
    int expiresInSeconds = 300,
  }) {
    return _client.storage
        .from(documentsBucket)
        .createSignedUrl(path, expiresInSeconds.clamp(60, 900));
  }

  Future<String> createExportDownloadUrl(
    String path, {
    int expiresInSeconds = 300,
  }) {
    return _client.storage
        .from(exportsBucket)
        .createSignedUrl(path, expiresInSeconds.clamp(60, 900));
  }

  static String scopedPath({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    required String fileName,
  }) {
    final tenant = _segment('tenantId', tenantId);
    final campus = _segment('campusId', campusId);
    final year = _segment('academicYearId', academicYearId);
    final name = _fileName(fileName);
    return '$tenant/$campus/$year/$name';
  }

  static String _segment(String field, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.contains('/') ||
        normalized.contains('\\')) {
      throw ArgumentError.value(value, field, 'Invalid storage path segment.');
    }
    return normalized;
  }

  static String _fileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.contains('/') ||
        normalized.contains('\\')) {
      throw ArgumentError.value(value, 'fileName', 'Invalid file name.');
    }
    return normalized;
  }
}
