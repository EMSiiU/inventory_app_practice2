import 'package:flutter/material.dart';
import 'package:inventory_app_practice2/core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // TODO: Conectar con BatchRepository para obtener fechas reales de caducidad
  List<String> _getEventsForDay (DateTime day) {
    if (day.day == 15 || day.day == 22) {
      return ['Lote por caducar'];
    }
    return [];
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
      body: Column(
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
                  // TODO: Mostrar ModalBottomSheet con los productos que caducan ese día
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}