import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static const _fallbackApiKey = 'AIzaSyAntNQ4XKPxk_7PNpDk_Hmvg_IlEJnAIKM';
  static const _fallbackAppId = '1:761876867956:web:0e96fa57f0d80cac395a21';
  static const _fallbackMessagingSenderId = '761876867956';
  static const _fallbackProjectId = 'pixel-adventure-20762';
  static const _fallbackAuthDomain = 'pixel-adventure-20762.firebaseapp.com';
  static const _fallbackStorageBucket =
      'pixel-adventure-20762.firebasestorage.app';
  static const _fallbackMeasurementId = 'G-NL0DE9D0MY';

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
    final apiKey = _required('FIREBASE_API_KEY', _fallbackApiKey);
    final appId = _required('FIREBASE_APP_ID', _fallbackAppId);
    final messagingSenderId = _required(
      'FIREBASE_MESSAGING_SENDER_ID',
      _fallbackMessagingSenderId,
    );
    final projectId = _required('FIREBASE_PROJECT_ID', _fallbackProjectId);

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
      authDomain: _optional('FIREBASE_AUTH_DOMAIN', _fallbackAuthDomain),
      storageBucket:
          _optional('FIREBASE_STORAGE_BUCKET', _fallbackStorageBucket),
      measurementId:
          _optional('FIREBASE_MEASUREMENT_ID', _fallbackMeasurementId),
    );
  }

  static String? _required(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static String? _optional(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
