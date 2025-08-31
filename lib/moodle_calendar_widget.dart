import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'calendar_provider.dart';
import 'moodle_event.dart';

class MoodleCalendarHomePage extends StatelessWidget {
  const MoodleCalendarHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            _buildAppHeader(context),
            // Calendar Section
            Expanded(
              child: MoodleCalendarWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange, // Changed to orange
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Calendar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Changed to white for contrast
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8), // Changed to white
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white, // Changed to white
            ),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
    );
  }
}

class MoodleCalendarWidget extends StatefulWidget {
  const MoodleCalendarWidget({Key? key}) : super(key: key);

  @override
  State<MoodleCalendarWidget> createState() => _MoodleCalendarWidgetState();
}

class _MoodleCalendarWidgetState extends State<MoodleCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Calendar Container
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar<MoodleEvent>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => calendarProvider.getEventsForDay(day),

            // Calendar styling - ALL ORANGE CHANGES
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2), // Changed to orange
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange, // Changed to orange
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white, // Changed to white for contrast
                fontWeight: FontWeight.bold,
              ),
              defaultTextStyle: TextStyle(
                color: theme.colorScheme.onBackground,
              ),
              weekendTextStyle: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange, // Changed to orange
                shape: BoxShape.circle,
              ),
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
            ),

            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1), // Changed to orange
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2), // Changed to orange
                ),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.orange, // Changed to orange
                fontWeight: FontWeight.w600,
              ),
              titleTextStyle: TextStyle(
                color: theme.colorScheme.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Colors.orange, // Changed to orange
                size: 28,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Colors.orange, // Changed to orange
                size: 28,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
            ),

            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                // Enhanced badge with event preview
                return Stack(
                  children: [
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange, // Changed to orange
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          events.length.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white, // Changed to white for contrast
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Add a small indicator for important events
                    if (events.any((event) => event.isOverdue))
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
              // Add day builder with long press functionality
              defaultBuilder: (context, date, focusedDay) {
                final events = calendarProvider.getEventsForDay(date);
                final isSelected = isSameDay(_selectedDay, date);
                final isToday = isSameDay(DateTime.now(), date);

                return GestureDetector(
                  onLongPress: () {
                    if (events.isNotEmpty) {
                      _showDayPreview(context, date, events);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange // Changed to orange
                          : isToday
                          ? Colors.orange.withOpacity(0.2) // Changed to orange
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white // Changed to white for contrast
                              : isToday
                              ? theme.colorScheme.onBackground
                              : theme.colorScheme.onBackground,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Selected date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Events for ${DateFormat('EEEE, MMMM d').format(_selectedDay!)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const Spacer(),
              if (_selectedDay != null && !isSameDay(_selectedDay, DateTime.now()))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = DateTime.now();
                      _focusedDay = DateTime.now();
                    });
                  },
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: Colors.orange, // Changed to orange
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Events list
        Expanded(
          child: _buildEventList(calendarProvider),
        ),
      ],
    );
  }

  Widget _buildEventList(CalendarProvider calendarProvider) {
    final theme = Theme.of(context);

    if (calendarProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.orange, // Changed to orange
            ),
            const SizedBox(height: 16),
            Text(
              'Loading events...',
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (calendarProvider.errorMessage != null &&
        calendarProvider.errorMessage!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              calendarProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                calendarProvider.loadEvents();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Changed to orange
                foregroundColor: Colors.white, // Changed to white for contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final dayEvents =
    _selectedDay != null ? calendarProvider.getEventsForDay(_selectedDay!) : [];

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No events for selected day',
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return _buildEventCard(event, theme);
      },
    );
  }

  Widget _buildEventCard(MoodleEvent event, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEventDetails(event),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: event.eventColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onBackground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(event.startTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.class_,
                            size: 15,
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.activityName,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      if (event.cleanDescription.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.cleanDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  void _showEventDetails(MoodleEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildEventBottomSheet(event);
      },
    );
  }

  void _showDayPreview(BuildContext context, DateTime date, List<MoodleEvent> events) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Icon(
                    Icons.event,
                    color: event.eventColor,
                  ),
                  title: Text(event.name),
                  subtitle: Text(
                    '${_formatTime(event.startTime)} - ${event.activityName}',
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventBottomSheet(MoodleEvent event) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: event.eventColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            _formatTime(event.startTime),
            theme,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.class_,
            'Activity',
            event.activityName,
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.cleanDescription.isNotEmpty
                ? event.cleanDescription
                : 'No description available',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          if (event.isOverdue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This event is overdue',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Changed to orange
                foregroundColor: Colors.white, // Changed to white for contrast
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onBackground.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}