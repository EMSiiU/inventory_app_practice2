import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  final _categoryRepo = CategoryRepository();
  final _productRepo = ProductRepository();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _alarmActive = true;
  bool _isSaving = false;

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Busca las categorías. Si no hay, inyecta las opciones por defecto.
  Future<void> _loadCategories() async{
    try {
      var categories = await _categoryRepo.getAllCategories();

      // Si la base de datos está casi vacía, insertamos tus categorías
      if (categories.isEmpty || categories.length <= 1) {
        final defaultCategories = ['Lácteos', 'Carnes', 'Embutidos', 'Aderezos', 'Bebidas', 'Abarrotes', 'Frutas y Verduras'];

        for (var name in defaultCategories) {
          // Validar que no exista una con el mismo nombre
          if (!categories.any((c) => c.name == name)) {
            await _categoryRepo.insertCategory(CategoryModel(name: name));
          }
        }
        categories = await _categoryRepo.getAllCategories();
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _selectedCategoryId = categories.isNotEmpty?categories.first.id : null;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      // final categoryId = await _categoryRepo.getOrCreateDefaultCategoryId();
      if (_selectedCategoryId == null) return;
      final categoryId = _selectedCategoryId!;

      final newProduct = ProductModel(
        name: _nameController.text.trim(),
        categoryId: categoryId,
        securityStock: 1,
        isAlarmActive: _alarmActive,
        createdAt: DateTime.now(),
      );

      await _productRepo.insertProductWithInitialBatch(
        product: newProduct,
        expirationDate: _selectedDate,
        quantity: int.parse(_quantityController.text.trim()),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Error al guardar artículo: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el artículo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
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
        actions: [
          _roundActionButton(
            tooltip: 'Guardar artículo',
            icon: CupertinoIcons.checkmark_alt,
            onPressed: _isSaving ? null : _saveItem,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 24),
                    children: [
                      Text(
                        'Nuevo artículo',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: _fieldDecoration('Nombre del producto'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: _fieldDecoration('Categoría'),
                          dropdownColor: AppTheme.surfaceElevated,
                          items: _categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(
                                cat.name,
                                style: const TextStyle(color: AppTheme.textPrimary),
                              )
                            );
                          }).toList(), 
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) => 
                            value == null ? 'Seleccione una categoría' : null,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Lote inicial',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _selectExpirationDate,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Caducidad',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(_selectedDate),
                                      style: const TextStyle(
                                        color: AppTheme.accentBlue,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      color: AppTheme.textSecondary,
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppTheme.borderSeparator,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: _fieldDecoration(
                                  'Cantidad inicial',
                                  suffixText: 'unidades',
                                ),
                                validator: (value) {
                                  final quantity = int.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  if (quantity == null || quantity < 1) {
                                    return 'Ingrese una cantidad mayor que 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: const Text(
                            'Activar alarmas locales',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                          subtitle: const Text(
                            'Recordatorio por día de vencimiento',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          value: _alarmActive,
                          activeThumbColor: AppTheme.statusGood,
                          onChanged: (value) {
                            setState(() => _alarmActive = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.accentBlue
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
