import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/notifications/expiration_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/store_model.dart';
import '../../../data/models/product_batch_model.dart';

import '../../../data/repositories/store_repository.dart';
import '../../../data/repositories/batch_repository.dart';
import '../../../data/repositories/purchase_history_repository.dart';

import '../cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StoreRepository _storeRepo = StoreRepository();
  final BatchRepository _batchRepo = BatchRepository();
  final PurchaseHistoryRepository _historyRepo = PurchaseHistoryRepository();
  final ExpirationNotificationService _notificationService =
      ExpirationNotificationService.instance;

  List<StoreModel> _stores = [];
  int? _selectedStoreId;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Mapas para guardar los datos de cada producto (ID de producto -> valor)
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, DateTime> _expirationDates = {};

  @override
  void initState() {
    super.initState();
    _loadStores();
    _initializeControllers();
  }

  void _initializeControllers() {
    final items = CartManager.instance.cartItems.value;
    for (var item in items) {
      _qtyControllers[item.productId] = TextEditingController(
        text: item.quantity.toString(),
      );
      _priceControllers[item.productId] = TextEditingController();
      // Por defecto, sugerimos caducidad de 1 semana para agilizar
      _expirationDates[item.productId] = DateTime.now().add(
        const Duration(days: 7),
      );
    }
  }

  Future<void> _loadStores() async {
    final stores = await _storeRepo.getAllStores();
    setState(() {
      _stores = stores;
      if (stores.isNotEmpty) {
        _selectedStoreId = stores.first.id;
        _isLoading = false;
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(int productId) async {
    final initialDate = _expirationDates[productId] ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      setState(() {
        _expirationDates[productId] = pickedDate;
      });
    }
  }

  Future<void> _processCheckout() async {
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una tienda para la compra'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = CartManager.instance.cartItems.value;
      final alarmEnabledByProduct = <int, bool>{};
      for (final item in items) {
        alarmEnabledByProduct[item.productId] = await _batchRepo
            .isAlarmActiveForProduct(item.productId);
      }

      var notificationPermissionGranted = false;
      var notificationWarning = false;
      if (_notificationService.isSupported &&
          alarmEnabledByProduct.values.any((enabled) => enabled)) {
        try {
          notificationPermissionGranted = await _notificationService
              .requestPermission();
        } catch (error, stackTrace) {
          debugPrint(
            'Error al solicitar permiso para alarmas de caducidad: '
            '$error\n$stackTrace',
          );
          notificationWarning = true;
        }
        if (!notificationPermissionGranted) notificationWarning = true;
      }

      for (var item in items) {
        final int qty =
            int.tryParse(_qtyControllers[item.productId]!.text) ?? 1;
        final double price =
            double.tryParse(_priceControllers[item.productId]!.text) ?? 0.0;
        final DateTime expDate = _expirationDates[item.productId]!;

        // 1. Crear el lote
        final batchId = await _batchRepo.insertBatch(
          ProductBatchModel(
            productId: item.productId,
            expirationDate: expDate,
            quantity: qty,
          ),
        );

        if (alarmEnabledByProduct[item.productId] == true &&
            notificationPermissionGranted) {
          try {
            final scheduled = await _notificationService
                .scheduleBatchExpiration(
                  batchId: batchId,
                  productName: item.productName,
                  expirationDate: expDate,
                );
            if (!scheduled) notificationWarning = true;
          } catch (error, stackTrace) {
            debugPrint(
              'Error al programar alarma de compra: $error\n$stackTrace',
            );
            notificationWarning = true;
          }
        }

        // 2. Registrar el historial
        await _historyRepo.registerPurchaseAndUpdateStore(
          item.productId,
          _selectedStoreId!,
          qty,
          price,
        );
      }

      // 3. Vaciar carrito y volver
      CartManager.instance.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Compra registrada con éxito!'),
            duration: Duration(seconds: 2),
          ),
        );
        if (notificationWarning) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La compra se guardó, pero algunas alarmas no se activaron. '
                'Revisa los permisos de notificación.',
              ),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error en checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la compra'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: _roundActionButton(
          tooltip: 'Cerrar',
          icon: CupertinoIcons.xmark,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: CartManager.instance.cartItems,
              builder: (context, items, child) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'El carrito está vacío',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Selector de tienda
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedStoreId,
                        decoration: _fieldDecoration('Tienda'),
                        dropdownColor: AppTheme.surfaceElevated,
                        items: _stores.map((store) {
                          return DropdownMenuItem<int>(
                            value: store.id,
                            child: Text(
                              store.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStoreId = value),
                      ),
                    ),

                    // Lista de productos
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            color: AppTheme.surfaceCard,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          CupertinoIcons.delete,
                                          color: AppTheme.badgeAccent,
                                        ),
                                        onPressed: () => CartManager.instance
                                            .removeFromCart(item.productId),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _qtyControllers[item.productId],
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                          ),
                                          decoration: _fieldDecoration(
                                            'Cantidad',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _priceControllers[item.productId],
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _fieldDecoration(
                                            'Precio unitario \$',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text(
                                        'Caducidad: ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _selectDate(item.productId),
                                        child: Text(
                                          "${_expirationDates[item.productId]!.day}/${_expirationDates[item.productId]!.month}/${_expirationDates[item.productId]!.year}",
                                          style: const TextStyle(
                                            color: AppTheme.accentBlue,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Boton de checkout
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.accentBlue
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _processCheckout,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Guardar artículo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _roundActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.surfaceCard,
          foregroundColor: AppTheme.accentBlue,
          fixedSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accentBlue),
      ),
    );
  }
}
