// Tarjeta de producto s

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/theme/app_theme.dart';

enum ProductStatus { good, warning, low, expired }

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String store;
  final String statusText;
  final int quantity;
  final ProductStatus status;
  final String? imagePath;
  final VoidCallback onAddToCart;
  final VoidCallback onConsume;

  const ProductCard({
    Key? key,
    required this.name,
    required this.category,
    required this.store,
    required this.statusText,
    required this.quantity,
    required this.status,
    this.imagePath,
    required this.onAddToCart,
    required this.onConsume,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status) {
      case ProductStatus.good:
        return AppTheme.statusGood;
      case ProductStatus.warning:
        return AppTheme.statusWarning;
      case ProductStatus.low:
        return AppTheme.statusLow;
      case ProductStatus.expired:
        return AppTheme.statusExpired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final imagePath = this.imagePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Slidable(
        key: ValueKey(name),
        // Acción al deslizar hacia la derecha
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onAddToCart(),
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              icon: CupertinoIcons.cart_badge_plus,
              label: 'Carrito',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        // Acción al deslizar hacia la izquierda
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onConsume(),
              backgroundColor: AppTheme.statusWarning,
              foregroundColor: Colors.white,
              icon: CupertinoIcons.minus_circle,
              label: 'Consumir',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen Placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath == null || imagePath.isEmpty
                    ? _placeholderIcon()
                    : Image.file(
                        File(imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholderIcon(),
                      ),
              ),
              const SizedBox(width: 16),
              // Textos descriptivos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$category · $store',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge circular de cantidad
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'UN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Icon(CupertinoIcons.cube_box, color: AppTheme.textSecondary);
  }
}
