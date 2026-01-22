import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;

Future<void> exitApp() async {
  // On Android, SystemNavigator.pop() closes the app.
  // On iOS, SystemNavigator.pop() is ignored; using exit(0) to force close.
  if (Platform.isIOS) {
    exit(0);
  } else {
    await SystemNavigator.pop();
  }
}
