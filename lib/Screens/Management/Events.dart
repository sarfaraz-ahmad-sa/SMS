import 'package:flutter/material.dart';

import '../../services/event_service.dart';
import '../../services/models/app_permission.dart';
import '../../services/models/school_event.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _service = EventService();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _listView = false;

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdays = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  bool get _canManage =>
      SessionState.instance.hasPermission(AppPermission.eventsManage);

  void _previousMonth() => setState(
        () => _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month - 1),
      );

  void _nextMonth() => setState(
        () => _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month + 1),
      );

  Map<String, List<SchoolEvent>> _group(List<SchoolEvent> events) {
    final grouped = <String, List<SchoolEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.dateKey, () => <SchoolEvent>[]).add(event);
    }
    return grouped;
  }

  Future<void> _archiveEvent(SchoolEvent event) async {
    if (!_canManage || event.id == null) return;
    try {
      await _service.archiveEvent(event.id!);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: <Widget>[
          IconButton(
            tooltip: _listView ? 'Calendar view' : 'List view',
            icon: Icon(
              _listView ? Icons.calendar_month_outlined : Icons.view_list,
            ),
            onPressed: () => setState(() => _listView = !_listView),
          ),
        ],
      ),
      body: StreamBuilder<List<SchoolEvent>>(
        stream: _service.streamEvents(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<SchoolEvent>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load events: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final events = snapshot.data ?? <SchoolEvent>[];
          if (_listView) return _buildList(events);
          return _buildCalendar(_group(events));
        },
      ),
    );
  }

  Widget _buildCalendar(Map<String, List<SchoolEvent>> eventsByDate) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final sundayOffset = firstDay.weekday % 7;
    final gridStart = firstDay.subtract(Duration(days: sundayOffset));
    final today = DateTime.now();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              IconButton.filledTonal(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Row(
          children: _weekdays
              .map(
                (String day) => Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemCount: 42,
            itemBuilder: (BuildContext context, int index) {
              final date = gridStart.add(Duration(days: index));
              final inMonth = date.month == _visibleMonth.month;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final dayEvents =
                  eventsByDate[SchoolEvent.keyFor(date)] ?? <SchoolEvent>[];

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openDay(date, dayEvents),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withOpacity(0.10)
                        : null,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: Text(
                          '${date.day}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: !inMonth
                                ? Colors.grey.shade400
                                : isToday
                                    ? AppColors.primary
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (dayEvents.isNotEmpty)
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            physics: const NeverScrollableScrollPhysics(),
                            children: dayEvents.take(2).map(
                              (SchoolEvent event) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      if (dayEvents.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 2),
                          child: Text(
                            '+${dayEvents.length - 2}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<SchoolEvent> events) {
    final sorted = <SchoolEvent>[...events]
      ..sort((SchoolEvent a, SchoolEvent b) => a.dateKey.compareTo(b.dateKey));

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          _canManage
              ? 'No events yet. Open a date to add one.'
              : 'No events have been published.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final event = sorted[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: const Icon(Icons.event, color: AppColors.secondary),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${event.type} · ${event.dateKey}'),
            trailing: _canManage && event.id != null
                ? IconButton(
                    tooltip: 'Archive event',
                    icon: const Icon(
                      Icons.archive_outlined,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _archiveEvent(event),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _openDay(DateTime date, List<SchoolEvent> dayEvents) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${date.day} ${_months[date.month - 1]} ${date.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (dayEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No events on this day'),
                )
              else
                ...dayEvents.map(
                  (SchoolEvent event) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event,
                      color: AppColors.secondary,
                    ),
                    title: Text(event.title),
                    subtitle: event.description?.isNotEmpty == true
                        ? Text(event.description!)
                        : null,
                    trailing: _canManage && event.id != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.archive_outlined,
                              color: AppColors.danger,
                            ),
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await _archiveEvent(event);
                            },
                          )
                        : null,
                  ),
                ),
              if (_canManage) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _addEvent(date);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _addEvent(DateTime date) {
    if (!_canManage) return;

    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    final type = TextEditingController(text: 'General');
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'New Event · ${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter title'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              try {
                                await _service.addEvent(
                                  SchoolEvent(
                                    title: title.text.trim(),
                                    description: description.text.trim(),
                                    type: type.text.trim().isEmpty
                                        ? 'General'
                                        : type.text.trim(),
                                    dateKey: SchoolEvent.keyFor(date),
                                    tenantId:
                                        SessionState.instance.tenant?.id ?? '',
                                  ),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                setSheetState(() => saving = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Save failed: $error'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(saving ? 'Saving…' : 'Save Event'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      title.dispose();
      description.dispose();
      type.dispose();
    });
  }
}
