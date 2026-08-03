import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

class SupabaseErrorReporter {
  SupabaseErrorReporter._();

  static bool _installed = false;
  static bool _reporting = false;

  static void install() {
    if (_installed) return;
    _installed = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousFlutterHandler?.call(details);
      unawaited(
        report(
          details.exception,
          details.stack ?? StackTrace.current,
          severity: details.silent ? 'warning' : 'error',
          context: <String, dynamic>{
            if (details.library != null) 'library': details.library,
            if (details.context != null) 'context': details.context.toString(),
          },
        ),
      );
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(report(error, stack, severity: 'fatal'));
      return previousPlatformHandler?.call(error, stack) ?? true;
    };
  }

  static Future<void> report(
    Object error,
    StackTrace stack, {
    String severity = 'error',
    String? route,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    if (_reporting) return;
    final client = SupabaseBootstrap.client;
    if (client.auth.currentUser == null) return;

    _reporting = true;
    try {
      await client.rpc(
        'report_client_error',
        params: <String, dynamic>{
          'p_message': sanitize(error.toString(), maxLength: 2000),
          'p_stack_trace': sanitize(stack.toString(), maxLength: 12000),
          'p_route': route,
          'p_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'p_app_version': const String.fromEnvironment(
            'APP_VERSION',
            defaultValue: '2.4.2+9',
          ),
          'p_severity': severity,
          'p_context': context.map(
            (key, value) => MapEntry(
              sanitize(key, maxLength: 100),
              sanitize(value.toString(), maxLength: 1000),
            ),
          ),
        },
      );
    } catch (_) {
      // Error reporting must never create an application failure loop.
    } finally {
      _reporting = false;
    }
  }

  @visibleForTesting
  static String sanitize(String value, {required int maxLength}) {
    final normalized = value
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength).trimRight();
  }
}
