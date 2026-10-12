import 'package:flutter/material.dart';
import 'package:inventory_app_practice2/core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/models/product_batch_model.dart';
import '../../../data/repositories/batch_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final BatchRepository _batchRepo = BatchRepository();

  // Mapa para agrupar los lotes por fecha de caducidad
  Map<DateTime, List<ProductBatchModel>> _eventsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  // Carga los datos de SQLite y los agrupa por fecha
  Future<void> _loadBatches() async{
    try {
      final batches = await _batchRepo.getAllActiveBatches();
      final Map<DateTime, List<ProductBatchModel>> newEventsMap = {};

      for (var batch in batches) {
        // Normalizamos la fecha quitando horas y minutos
        final date = DateTime.utc(
          batch.expirationDate.year,
          batch.expirationDate.month,
          batch.expirationDate.day
        );

        if (newEventsMap[date] == null) {
          newEventsMap[date] = [];
        }

        newEventsMap[date]!.add(batch);
      }

      if (mounted) {
        setState(() {
          _eventsMap = newEventsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando lotes: $e');
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Devuelve la lista de lotes para un día específico
  List<ProductBatchModel> _getEventsForDay (DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[normalizedDay] ?? [];
  }

  // Muestra el detalle de los lotes que caducan en un día específico
  void _showDayDetailsModal(DateTime day, List<ProductBatchModel> batches) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Cabecera
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Caducidades: ${day.day}/${day.month}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.accentBlue,),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Divider(color: AppTheme.surfaceElevated, thickness: 1, height: 1),
                // Lista
                Expanded(
                  child: batches.isEmpty
                    ? Center(
                      child: Text(
                        'No hay artículos por caducar',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                    controller: controller,
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.statusWarning.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: AppTheme.statusWarning),
                        ),
                        title: Text(
                          'Producto ID: ${batch.productId}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Cantidad restante: ${batch.quantity} unidades',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Caducidades', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28
          ),
        ),
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
      ),
      body:
      _isLoading ? Center(child: CircularProgressIndicator(color: AppTheme.accentBlue)):
        Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
                    weekendTextStyle: TextStyle(color: AppTheme.textSecondary),
                    outsideTextStyle: TextStyle(color: Color(0xFF38383A)),
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppTheme.statusWarning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                    titleTextStyle: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.accentBlue,),
                    rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.accentBlue,),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // DEBUG: Puedes imprimir en consola para verificar que lee los datos al tocar
                    // final events = _getEventsForDay(selectedDay);
                    // debugPrint('Lotes que caducan este día: ${events.length}');

                    // Mostrar ModalBottomSheet con los productos que caducan ese día
                    final events = _getEventsForDay(selectedDay);
                    _showDayDetailsModal(selectedDay, events);

                  },
                ),
              ),
            )
          ],
        ),
    );
  }
}