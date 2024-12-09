// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKmii6NgBg6noj1styd8xh3G77F8lqmYw',
    appId: '1:552286847463:web:e4139a9e4e5901c226bd42',
    messagingSenderId: '552286847463',
    projectId: 'transaksi-3ed7c',
    authDomain: 'transaksi-3ed7c.firebaseapp.com',
    storageBucket: 'transaksi-3ed7c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAwx9PJJfOsxVIA0Ac7kgN0lV4EW2CmAkU',
    appId: '1:552286847463:android:83704d76dfd753e626bd42',
    messagingSenderId: '552286847463',
    projectId: 'transaksi-3ed7c',
    storageBucket: 'transaksi-3ed7c.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCKmii6NgBg6noj1styd8xh3G77F8lqmYw',
    appId: '1:552286847463:web:cf89a5c5ed9686fd26bd42',
    messagingSenderId: '552286847463',
    projectId: 'transaksi-3ed7c',
    authDomain: 'transaksi-3ed7c.firebaseapp.com',
    storageBucket: 'transaksi-3ed7c.firebasestorage.app',
  );
}