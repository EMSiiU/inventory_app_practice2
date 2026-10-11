// Archivo: lib/main.dart

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/inventory/screens/inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InventoryScreen(),
    );
  }
}