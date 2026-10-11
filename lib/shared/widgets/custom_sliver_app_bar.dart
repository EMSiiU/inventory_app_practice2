// Encabezado

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/theme/app_theme.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final int cartCount;
  final VoidCallback onAddPressed;
  final VoidCallback onCartPressed;

  const CustomSliverAppBar({
    Key? key,
    required this.title,
    this.cartCount = 0,
    required this.onAddPressed,
    required this.onCartPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            title: Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            background: Container(
              color: AppTheme.bgCanvas.withOpacity(0.6),
            ),
          ),
        ),
      ),
      actions: [
        _buildCircularIconButton(
          icon: badges.Badge(
            showBadge: cartCount > 0,
            badgeContent: Text(
              '$cartCount',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: AppTheme.badgeAccent,
              padding: EdgeInsets.all(4),
            ),
            child: const Icon(CupertinoIcons.cart_fill, color: AppTheme.textPrimary, size: 22),
          ),
          onPressed: onCartPressed,
        ),
        const SizedBox(width: 12),
        _buildCircularIconButton(
          icon: const Icon(CupertinoIcons.add, color: AppTheme.accentBlue, size: 24),
          onPressed: onAddPressed,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Genera los botones circulares con fondo gris oscuro
  Widget _buildCircularIconButton({required Widget icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: CircleAvatar(
        backgroundColor: AppTheme.surfaceElevated,
        radius: 18,
        child: icon,
      ),
    );
  }
}