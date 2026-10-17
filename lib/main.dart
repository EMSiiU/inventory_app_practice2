// Archivo: lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'core/notifications/expiration_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/inventory/screens/home_screen.dart';

// import 'features/inventory/screens/inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  unawaited(ExpirationNotificationService.instance.synchronizeActiveBatches());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
