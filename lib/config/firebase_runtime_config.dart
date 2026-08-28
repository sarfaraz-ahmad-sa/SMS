import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes the optional Firebase compatibility backend without depending
/// on a generated, git-ignored `firebase_options.dart` file.
class FirebaseRuntimeConfig {
  FirebaseRuntimeConfig._();

  static Future<FirebaseApp> initialize() {
    if (!kIsWeb) return Firebase.initializeApp();

    const options = FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId:
          String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
    if (options.apiKey.isEmpty ||
        options.appId.isEmpty ||
        options.messagingSenderId.isEmpty ||
        options.projectId.isEmpty) {
      throw StateError(
        'Firebase compatibility mode on web requires FIREBASE_API_KEY, '
        'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID and '
        'FIREBASE_PROJECT_ID dart-defines.',
      );
    }
    return Firebase.initializeApp(options: options);
  }
}
