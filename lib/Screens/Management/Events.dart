import 'package:flutter/material.dart';

import 'package:school_management/services/event_service.dart';
import 'package:school_management/services/models/school_event.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _service = EventService();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _listView = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _prevMonth() => setState(() =>
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
  void _nextMonth() => setState(() =>
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  Map<String, List<SchoolEvent>> _group(List<SchoolEvent> events) {
    final map = <String, List<SchoolEvent>>{};
    for (final e in events) {
      map.putIfAbsent(e.dateKey, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            tooltip: _listView ? 'Calendar view' : 'List view',
            icon: Icon(_listView ? Icons.calendar_month : Icons.view_list),
            onPressed: () => setState(() => _listView = !_listView),
          ),
        ],
      ),
      body: StreamBuilder<List<SchoolEvent>>(
        stream: _service.streamEvents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? [];
          final byDate = _group(events);
          if (_listView) return _buildList(events);
          return _buildCalendar(byDate);
        },
      ),
    );
  }

  Widget _buildCalendar(Map<String, List<SchoolEvent>> byDate) {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final offset = first.weekday % 7; // Sunday-first
    final gridStart = first.subtract(Duration(days: offset));
    final today = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton.filledTonal(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton.filledTonal(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Row(
          children: _weekdays
              .map((d) => Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(d,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemCount: 42,
            itemBuilder: (_, i) {
              final date = gridStart.add(Duration(days: i));
              final inMonth = date.month == _visibleMonth.month;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final key = SchoolEvent.keyFor(date);
              final dayEvents = byDate[key] ?? const [];
              return InkWell(
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: Text(
                          '${date.day}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w500,
                            color: !inMonth
                                ? Colors.grey.shade400
                                : (isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (dayEvents.isNotEmpty)
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            physics: const NeverScrollableScrollPhysics(),
                            children: dayEvents.take(2).map((e) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (dayEvents.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 2),
                          child: Text('+${dayEvents.length - 2}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600)),
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
    final sorted = [...events]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    if (sorted.isEmpty) {
      return const Center(child: Text('No events yet. Tap a date to add one.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = sorted[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: const Icon(Icons.event, color: AppColors.secondary),
            ),
            title: Text(e.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e.type} · ${e.dateKey}'),
            trailing: e.id == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: () => _service.deleteEvent(e.id!),
                  ),
          ),
        );
      },
    );
  }

  void _openDay(DateTime date, List<SchoolEvent> dayEvents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day} ${_months[date.month - 1]} ${date.year}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (dayEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No events on this day'),
              )
            else
              ...dayEvents.map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.event, color: AppColors.secondary),
                    title: Text(e.title),
                    subtitle: e.description == null || e.description!.isEmpty
                        ? null
                        : Text(e.description!),
                    trailing: e.id == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () {
                              _service.deleteEvent(e.id!);
                              Navigator.pop(ctx);
                            },
                          ),
                  )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addEvent(date);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addEvent(DateTime date) {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final desc = TextEditingController();
    final type = TextEditingController(text: 'General');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Event · ${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.event_outlined)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: type,
                  decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: desc,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => saving = true);
                            try {
                              await _service.addEvent(SchoolEvent(
                                title: title.text.trim(),
                                description: desc.text.trim(),
                                type: type.text.trim().isEmpty
                                    ? 'General'
                                    : type.text.trim(),
                                dateKey: SchoolEvent.keyFor(date),
                                tenantId:
                                    SessionState.instance.user?.tenantId ?? '',
                              ));
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setSheet(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Save failed: $e'),
                                      backgroundColor: AppColors.danger),
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
        ),
      ),
    );
  }
}
