import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Event {
  String title;
  String date;
  String type;
  _Event(this.title, this.date, this.type);
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _events = <_Event>[
    _Event('Annual Sports Day', 'Apr 25, 2026', 'Sports'),
    _Event('Parent-Teacher Meeting', 'Apr 30, 2026', 'Meeting'),
    _Event('Science Exhibition', 'May 02, 2026', 'Academic'),
    _Event('Independence Day', 'Aug 14, 2026', 'National'),
  ];

  void _add() {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final type = TextEditingController(text: 'Academic');
    DateTime? date;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Event',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: 'Event Title',
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
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) setSheet(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(date == null
                      ? 'Pick date'
                      : '${date!.day}/${date!.month}/${date!.year}'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate() || date == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Enter title and pick a date')),
                        );
                        return;
                      }
                      setState(() => _events.insert(
                          0,
                          _Event(
                              title.text,
                              '${date!.day}/${date!.month}/${date!.year}',
                              type.text)));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = _events[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.12),
                child: const Icon(Icons.event, color: AppColors.secondary),
              ),
              title: Text(e.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.type} · ${e.date}'),
            ),
          );
        },
      ),
    );
  }
}
