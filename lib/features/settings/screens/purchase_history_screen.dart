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
                  content: Text('El historial se actualiza automáticamente al hacer compras.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
            )
          else if (_history.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Aún no tienes compras registradas.', 
                    style: TextStyle(color: AppTheme.textPrimary)
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _history[index];
                    return Card(
                      color: AppTheme.surfaceElevated,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Icono o círculo con la fecha
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                              ),
                              child: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppTheme.accentBlue),
                            ),
                            const SizedBox(width: 16),
                            // Detalles
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['producto_nombre'] ?? 'Desconocido',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Comprado en: ${item['tienda_nombre']}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Fecha: ${_formatDate(item['fecha_compra'])}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Precio y cantidad
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${item['cantidad']} UNIDADES',
                                  style: const TextStyle(color: AppTheme.statusGood, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'C/U a \$${(item['precio_unitario'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _history.length,
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}