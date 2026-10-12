//barra inferior de navegación

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DockedNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DockedNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Aplica el efecto de desenfoque al fondo de la barra
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: AppTheme.surfaceCard.withOpacity(0.75), // Translúcido
          selectedItemColor: AppTheme.accentBlue,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_stack_3d_up_fill),
              label: 'Artículos',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_grid_2x2_fill),
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.barcode_viewfinder),
              label: 'Escáner',
            ),
          ],
        ),
      ),
    );
  }
}