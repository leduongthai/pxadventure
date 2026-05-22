import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool initialized = false;
  static String? lastError;

  static Future<bool> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options == null) {
      lastError = 'Firebase .env config is incomplete.';
      initialized = false;
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      initialized = true;
      lastError = null;
      return true;
    } catch (error, stackTrace) {
      initialized = false;
      lastError = error.toString();
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
