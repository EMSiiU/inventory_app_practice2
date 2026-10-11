// Agregar un nuevo articulo

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_batch_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/batch_repository.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({Key? key}) : super(key: key);

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _alarmActive = true;
  
  final _productRepo = ProductRepository();
  final _batchRepo = BatchRepository();

  // Guarda el producto y su primer lote en la base de datos
  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Crear el producto
        final newProduct = ProductModel(
          name: _nameController.text,
          categoryId: 1, // TODO: Implementar selector dinámico de categorías
          securityStock: 1,
          isAlarmActive: _alarmActive,
          createdAt: DateTime.now(),
        );
        
        final productId = await _productRepo.insertProduct(newProduct);

        // 2. Crear el lote inicial vinculado al producto
        final initialBatch = ProductBatchModel(
          productId: productId,
          expirationDate: _selectedDate,
          quantity: int.parse(_quantityController.text),
        );
        
        await _batchRepo.insertBatch(initialBatch);

        if (mounted) {
          Navigator.pop(context); // Regresa a la pantalla anterior tras guardar
        }
      } catch (e) {
        debugPrint('Error al guardar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nuevo artículo', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: AppTheme.accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.accentBlue),
            onPressed: _saveItem,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Campo de Nombre
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 16),
            
            // Selector de fecha de caducidad (Estilo Cupertino)
            ListTile(
              tileColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Caducidad', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(color: AppTheme.accentBlue, fontSize: 16),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Selector de cantidad
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cantidad inicial',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Switch de alarmas
            SwitchListTile(
              title: const Text('Activar alarmas locales', style: TextStyle(color: Colors.white)),
              value: _alarmActive,
              activeColor: AppTheme.accentBlue,
              tileColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onChanged: (bool value) {
                setState(() => _alarmActive = value);
              },
            ),
            const SizedBox(height: 32),

            // Botón de guardado
            ElevatedButton(
              onPressed: _saveItem,
              child: const Text('Guardar artículo'),
            ),
          ],
        ),
      ),
    );
  }
}