import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/purchase_history_repository.dart';
import '../../../shared/widgets/custom_sliver_app_bar.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

IconData _eventIcon(String type, bool isDepleted) {
  if (type == 'compra') return CupertinoIcons.checkmark_seal_fill;
  return isDepleted
      ? CupertinoIcons.exclamationmark_circle_fill
      : CupertinoIcons.minus_circle_fill;
}

Color _eventColor(String type, bool isDepleted) {
  if (type == 'compra') return AppTheme.statusGood;
  return isDepleted ? AppTheme.statusExpired : AppTheme.statusWarning;
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final PurchaseHistoryRepository _historyRepo = PurchaseHistoryRepository();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyRepo.getPurchaseHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  // Helper para formatear la fecha a algo más legible
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Historial',
            onAddPressed: () {
              // Es una pantalla de solo lectura, mostramos un aviso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'El historial se actualiza automáticamente con compras y consumos.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_history.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Aún no tienes movimientos registrados.',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _history[index];
                  final isPurchase = item['tipo'] == 'compra';
                  final isDepleted = (item['agotado'] as num?)?.toInt() == 1;
                  final timestamp = item['fecha'] as String;

                  return InventoryHistoryEntryCard(
                    productName:
                        item['producto_nombre'] as String? ?? 'Desconocido',
                    imagePath: item['producto_imagen_url'] as String?,
                    isPurchase: isPurchase,
                    isDepleted: isDepleted,
                    quantity: (item['cantidad'] as num).toInt(),
                    dateLabel: _formatDate(timestamp),
                    storeName: item['tienda_nombre'] as String?,
                    unitPrice: item['precio_unitario'] as num?,
                    remainingStock: (item['stock_restante'] as num?)?.toInt(),
                  );
                }, childCount: _history.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class InventoryHistoryEntryCard extends StatelessWidget {
  const InventoryHistoryEntryCard({
    required this.productName,
    required this.imagePath,
    required this.isPurchase,
    required this.isDepleted,
    required this.quantity,
    required this.dateLabel,
    this.storeName,
    this.unitPrice,
    this.remainingStock,
    super.key,
  });

  final String productName;
  final String? imagePath;
  final bool isPurchase;
  final bool isDepleted;
  final int quantity;
  final String dateLabel;
  final String? storeName;
  final num? unitPrice;
  final int? remainingStock;

  @override
  Widget build(BuildContext context) {
    final eventType = isPurchase ? 'compra' : 'consumo';
    return Card(
      color: AppTheme.surfaceElevated,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: _buildProductImage(eventType),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPurchase
                        ? 'Comprado en: ${storeName ?? 'Tienda desconocida'}'
                        : isDepleted
                        ? 'El artículo quedó agotado'
                        : 'Consumo de inventario',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fecha: $dateLabel',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPurchase ? '+' : '-'}$quantity UNIDADES',
                  style: TextStyle(
                    color: _eventColor(eventType, isDepleted),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (isPurchase && unitPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'C/U a \$${unitPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (!isPurchase) ...[
                  const SizedBox(height: 4),
                  Text(
                    isDepleted
                        ? 'Producto agotado'
                        : 'Restan ${remainingStock ?? 0}',
                    style: TextStyle(
                      color: isDepleted
                          ? AppTheme.statusExpired
                          : AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String eventType) {
    final fallbackIcon = Icon(
      _eventIcon(eventType, isDepleted),
      color: _eventColor(eventType, isDepleted),
    );
    if (imagePath == null || imagePath!.isEmpty) return fallbackIcon;

    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallbackIcon,
    );
  }
}
