// lib/platform_setup.dart
// Platform setup for desktop (Windows, Linux, macOS)

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initializePlatform() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
