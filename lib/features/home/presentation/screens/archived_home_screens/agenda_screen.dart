import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({Key? key}) : super(key: key);

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Define start and end dates for the calendar
  late final DateTime _firstDay;
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    // Initialize the date range
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));
    _selectedDay = _focusedDay;
  }
  
  final Map<DateTime, List<Event>> _events = {
    DateTime.now(): [
      Event('Wandelen in het park', '14:00', 'Vondelpark'),
      Event('Museumbezoek', '16:30', 'Rijksmuseum'),
    ],
    DateTime.now().add(const Duration(days: 1)): [
      Event('Strandwandeling', '11:00', 'Zandvoort'),
    ],
  };

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Agenda',
                  style: GoogleFonts.openSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TableCalendar<Event>(
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration: BoxDecoration(
                      color: Color(0xFF2A6049),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getEventsForDay,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Geplande Activiteiten',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A6049),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._getEventsForDay(_selectedDay ?? _focusedDay)
                          .map((event) => _buildEventCard(event)),
                      const SizedBox(height: 16),
                      _buildAddEventButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF2A6049),
          child: Icon(Icons.event, color: Colors.white),
        ),
        title: Text(
          event.title,
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${event.time} - ${event.location}',
          style: GoogleFonts.openSans(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Implement event options menu
          },
        ),
      ),
    );
  }

  Widget _buildAddEventButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A6049),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        // TODO: Implement add event functionality
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add),
          const SizedBox(width: 8),
          Text(
            'Nieuwe Activiteit',
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final String time;
  final String location;

  Event(this.title, this.time, this.location);
} 