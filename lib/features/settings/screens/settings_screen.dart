import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'manage_categories_screen.dart';
import 'manage_store_screen.dart';
import 'manage_products_screen.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28
          ),
        ),
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsTile(
            title: 'Mis Productos', 
            icon: CupertinoIcons.cube_box_fill, 
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ManageProductsScreen(),)
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'Mis Categorías', 
            icon: CupertinoIcons.tag_fill, 
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ManageCategoriesScreen(),)
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'Mis Tiendas',
            icon: CupertinoIcons.building_2_fill,
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ManageStoreScreen(),)
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'Historial de Compras',
            icon: CupertinoIcons.clock_solid,
            onTap: () {
              // TODO: Navegar a historial
              debugPrint('Ir a historial');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      tileColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.accentBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}