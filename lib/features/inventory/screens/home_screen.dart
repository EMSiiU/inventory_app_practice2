// Archivo: lib/features/inventory/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/widgets/docked_navigation_bar.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'inventory_screen.dart';
// import '../../calendar/screens/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Lista de pantallas para cada pestaña
  final List<Widget> _screens = [
    const InventoryScreen(),
    const CalendarScreen(), // Pestaña "Alacena/Calendario"
    const SettingsScreen(),
    const Center(child: Text('Pantalla de Escáner (En desarrollo)')),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: DockedNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}