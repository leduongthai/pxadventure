import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final options = currentPlatformOrNull;
    if (options == null) {
      throw UnsupportedError(
        'Firebase config is missing. Fill FIREBASE_API_KEY, '
        'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and '
        'FIREBASE_PROJECT_ID in .env.',
      );
    }
    return options;
  }

  static FirebaseOptions? get currentPlatformOrNull {
    final apiKey = _required('FIREBASE_API_KEY');
    final appId = _required('FIREBASE_APP_ID');
    final messagingSenderId = _required('FIREBASE_MESSAGING_SENDER_ID');
    final projectId = _required('FIREBASE_PROJECT_ID');

    if (apiKey == null ||
        appId == null ||
        messagingSenderId == null ||
        projectId == null) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _optional('FIREBASE_AUTH_DOMAIN'),
      storageBucket: _optional('FIREBASE_STORAGE_BUCKET'),
      measurementId: _optional('FIREBASE_MEASUREMENT_ID'),
    );
  }

  static String? _required(String key) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String? _optional(String key) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
