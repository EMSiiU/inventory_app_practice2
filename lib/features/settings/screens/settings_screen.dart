import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/notifications/expiration_notification_service.dart';
import 'manage_categories_screen.dart';
import 'manage_store_screen.dart';
import 'manage_products_screen.dart';
import 'purchase_history_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/management_analytics_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
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
                MaterialPageRoute(
                  builder: (context) => const ManageProductsScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const ManageStoreScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'Historial de Movimientos',
            icon: CupertinoIcons.clock_solid,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryScreen(),
                ),
              );
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            const _NotificationTestTile(),
          ],
          const SizedBox(height: 16),
          const ManagementAnalyticsSection(),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
    );
  }
}

class _NotificationTestTile extends StatefulWidget {
  const _NotificationTestTile();

  @override
  State<_NotificationTestTile> createState() => _NotificationTestTileState();
}

class _NotificationTestTileState extends State<_NotificationTestTile> {
  bool _isScheduling = false;

  Future<void> _scheduleTestNotification() async {
    if (_isScheduling) return;
    setState(() => _isScheduling = true);

    try {
      final notificationService = ExpirationNotificationService.instance;
      final permissionGranted = await notificationService.requestPermission();
      if (!permissionGranted) {
        throw StateError(
          'Permite las notificaciones de la aplicación en los ajustes '
          'de Android para ejecutar la prueba.',
        );
      }

      await notificationService.scheduleTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prueba programada: llegará en aproximadamente 1 minuto.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'No se pudo programar la notificación de prueba: '
        '$error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo programar la prueba: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: _isScheduling ? null : _scheduleTestNotification,
      tileColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(CupertinoIcons.bell_fill, color: AppTheme.accentBlue),
      ),
      title: const Text(
        'Probar alarma (1 minuto)',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text(
        'Solo disponible en esta compilación de depuración',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: _isScheduling
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
    );
  }
}
