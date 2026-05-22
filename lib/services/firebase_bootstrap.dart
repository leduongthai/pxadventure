import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool initialized = false;
  static String? lastError;

  static Future<void> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options == null) {
      lastError = 'Firebase .env config is incomplete.';
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      initialized = true;
      lastError = null;
    } catch (error, stackTrace) {
      initialized = false;
      lastError = error.toString();
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
