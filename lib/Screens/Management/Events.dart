import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../services/event_service.dart';
import '../../services/models/app_permission.dart';
import '../../services/models/school_event.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _service = EventService();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _mobileListView = false;

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

  static const List<String> _weekdays = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  bool get _canManage => SessionState.instance.hasPermission(AppPermission.eventsManage);

  void _previousMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
  void _nextMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archive failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Events',
      activeRoute: '/modules',
      activeModuleId: 'events',
      actions: <Widget>[
        IconButton(
          tooltip: _mobileListView ? 'Calendar view' : 'List view',
          onPressed: () => setState(() => _mobileListView = !_mobileListView),
          icon: Icon(_mobileListView ? Icons.calendar_month_outlined : Icons.view_list_rounded),
        ),
      ],
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _addEvent(DateTime.now()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Event'),
            )
          : null,
      body: StreamBuilder<List<SchoolEvent>>(
        stream: _service.streamEvents(),
        builder: (BuildContext context, AsyncSnapshot<List<SchoolEvent>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return JinnPage(
              maxWidth: 700,
              child: JinnEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load events',
                message: snapshot.error.toString(),
              ),
            );
          }

          final events = snapshot.data ?? <SchoolEvent>[];
          final grouped = _group(events);
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final desktop = constraints.maxWidth >= 1000;
              return JinnPage(
                maxWidth: 1380,
                scrollable: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _EventMetrics(events: events),
                    const SizedBox(height: 14),
                    Expanded(
                      child: desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(flex: 7, child: _calendarPanel(grouped, compact: false)),
                                const SizedBox(width: 14),
                                Expanded(flex: 3, child: _eventListPanel(events, embedded: true)),
                              ],
                            )
                          : _mobileListView
                              ? _eventListPanel(events, embedded: true)
                              : _calendarPanel(grouped, compact: true),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _calendarPanel(Map<String, List<SchoolEvent>> eventsByDate, {required bool compact}) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final sundayOffset = firstDay.weekday % 7;
    final gridStart = firstDay.subtract(Duration(days: sundayOffset));
    final today = DateTime.now();

    return JinnCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: <Widget>[
                IconButton.filledTonal(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text('${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('Select a date to view or add events', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
                    ],
                  ),
                ),
                IconButton.filledTonal(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              border: Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: _weekdays
                  .map((String day) => Expanded(
                        child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
                      ))
                  .toList(growable: false),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(7),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: compact ? 0.78 : 1.2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (BuildContext context, int index) {
                final date = gridStart.add(Duration(days: index));
                final inMonth = date.month == _visibleMonth.month;
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final dayEvents = eventsByDate[SchoolEvent.keyFor(date)] ?? <SchoolEvent>[];
                return _CalendarDay(
                  date: date,
                  inMonth: inMonth,
                  isToday: isToday,
                  events: dayEvents,
                  compact: compact,
                  onTap: () => _openDay(date, dayEvents),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventListPanel(List<SchoolEvent> events, {required bool embedded}) {
    final sorted = <SchoolEvent>[...events]..sort((SchoolEvent a, SchoolEvent b) => a.dateKey.compareTo(b.dateKey));
    return JinnCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          JinnSectionHeader(
            title: 'Upcoming Events',
            subtitle: '${sorted.length} published school events',
            trailing: _canManage
                ? IconButton.filledTonal(
                    tooltip: 'Add event',
                    onPressed: () => _addEvent(DateTime.now()),
                    icon: const Icon(Icons.add_rounded, size: 19),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sorted.isEmpty
                ? JinnEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No events yet',
                    message: _canManage ? 'Select a date or add a new school event.' : 'No events have been published.',
                  )
                : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final event = sorted[index];
                      return _EventListCard(
                        event: event,
                        canManage: _canManage,
                        onArchive: () => _archiveEvent(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openDay(DateTime date, List<SchoolEvent> dayEvents) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              JinnSectionHeader(
                title: '${date.day} ${_months[date.month - 1]} ${date.year}',
                subtitle: dayEvents.isEmpty ? 'No events scheduled' : '${dayEvents.length} scheduled event${dayEvents.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 13),
              if (dayEvents.isEmpty)
                const JinnEmptyState(icon: Icons.event_available_rounded, title: 'Free Day', message: 'No school events are scheduled for this date.')
              else
                ...dayEvents.map((SchoolEvent event) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _EventListCard(
                        event: event,
                        canManage: _canManage,
                        onArchive: () async {
                          Navigator.pop(sheetContext);
                          await _archiveEvent(event);
                        },
                      ),
                    )),
              if (_canManage) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _addEvent(date);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Event on This Date'),
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
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      JinnSectionHeader(
                        title: 'New School Event',
                        subtitle: '${date.day} ${_months[date.month - 1]} ${date.year}',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.event_outlined)),
                        validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter event title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: type,
                        decoration: const InputDecoration(labelText: 'Event Type', prefixIcon: Icon(Icons.category_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description (optional)', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_outlined)),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ?? false)) return;
                                  setSheetState(() => saving = true);
                                  try {
                                    await _service.addEvent(
                                      SchoolEvent(
                                        title: title.text.trim(),
                                        description: description.text.trim(),
                                        type: type.text.trim().isEmpty ? 'General' : type.text.trim(),
                                        dateKey: SchoolEvent.keyFor(date),
                                        tenantId: SessionState.instance.tenant?.id ?? '',
                                      ),
                                    );
                                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                                  } catch (error) {
                                    setSheetState(() => saving = false);
                                    if (sheetContext.mounted) {
                                      ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('Save failed: $error')));
                                    }
                                  }
                                },
                          icon: saving
                              ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(saving ? 'Saving…' : 'Save Event'),
                        ),
                      ),
                    ],
                  ),
                ),
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

class _EventMetrics extends StatelessWidget {
  final List<SchoolEvent> events;
  const _EventMetrics({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final thisMonth = events.where((SchoolEvent event) => event.dateKey.startsWith(monthKey)).length;
    final upcoming = events.where((SchoolEvent event) => event.dateKey.compareTo(SchoolEvent.keyFor(now)) >= 0).length;
    return JinnResponsiveGrid(
      minItemWidth: 180,
      childAspectRatio: 2.45,
      children: <Widget>[
        _EventMetric('All Events', '${events.length}', Icons.event_note_rounded, AppColors.pastelBlue, const Color(0xFF4E68D8)),
        _EventMetric('This Month', '$thisMonth', Icons.calendar_month_rounded, AppColors.pastelGold, const Color(0xFFD89614)),
        _EventMetric('Upcoming', '$upcoming', Icons.upcoming_rounded, AppColors.pastelGreen, const Color(0xFF27936B)),
        const _EventMetric('Categories', '6', Icons.category_rounded, AppColors.pastelPurple, Color(0xFF7B5DC7)),
      ],
    );
  }
}

class _EventMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _EventMetric(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 40),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final List<SchoolEvent> events;
  final bool compact;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.events,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isToday ? AppColors.pastelBlue : inMonth ? AppColors.surface : AppColors.surfaceMuted.withOpacity(0.55),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: isToday ? AppColors.info.withOpacity(0.4) : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: isToday ? const BoxDecoration(color: AppColors.navigation, shape: BoxShape.circle) : null,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday ? Colors.white : inMonth ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.55),
                    fontSize: 10.5,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            if (compact)
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: events.take(4).map((SchoolEvent _) => Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle))).toList(growable: false),
              )
            else
              ...events.take(2).map((SchoolEvent event) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.pastelGreen, borderRadius: BorderRadius.circular(5)),
                    child: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: Color(0xFF27936B), fontWeight: FontWeight.w700)),
                  )),
            if (!compact && events.length > 2)
              Text('+${events.length - 2} more', style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  final SchoolEvent event;
  final bool canManage;
  final VoidCallback onArchive;
  const _EventListCard({required this.event, required this.canManage, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: <Widget>[
          const JinnIconBadge(icon: Icons.event_rounded, color: Color(0xFF4E68D8), background: AppColors.pastelBlue, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('${event.type}  ·  ${event.dateKey}', style: Theme.of(context).textTheme.bodySmall),
                if (event.description?.isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(event.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
                ],
              ],
            ),
          ),
          if (canManage && event.id != null)
            IconButton(tooltip: 'Archive event', onPressed: onArchive, icon: const Icon(Icons.archive_outlined, color: AppColors.warning, size: 20)),
        ],
      ),
    );
  }
}
