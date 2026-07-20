import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class LeaveApply extends StatefulWidget {
  const LeaveApply({Key? key}) : super(key: key);

  @override
  State<LeaveApply> createState() => _LeaveApplyState();
}

class _LeaveRequest {
  final String type;
  final DateTime from;
  final DateTime to;
  final String reason;
  String status;
  _LeaveRequest(this.type, this.from, this.to, this.reason,
      {this.status = 'Pending'});
}

class _LeaveApplyState extends State<LeaveApply> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  static const _types = [
    'Sick Leave',
    'Casual Leave',
    'Family / Emergency',
    'Medical Leave',
    'Other',
  ];

  String? _type;
  DateTime? _from;
  DateTime? _to;

  final List<_LeaveRequest> _history = [
    _LeaveRequest('Sick Leave', DateTime(2026, 4, 2), DateTime(2026, 4, 3),
        'Fever and rest advised', status: 'Approved'),
    _LeaveRequest('Casual Leave', DateTime(2026, 3, 15), DateTime(2026, 3, 15),
        'Family function', status: 'Rejected'),
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(_from!)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both dates'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_to!.isBefore(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('"To" date cannot be before "From" date'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!valid) return;

    setState(() {
      _history.insert(
        0,
        _LeaveRequest(_type!, _from!, _to!, _reason.text.trim()),
      );
      _type = null;
      _from = null;
      _to = null;
      _reason.clear();
      _formKey.currentState!.reset();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave application submitted'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Application',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Leave Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _types
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v),
                      validator: (v) =>
                          v == null ? 'Please select a leave type' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _dateField('From', _from,
                                () => _pickDate(isFrom: true))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dateField('To', _to,
                                () => _pickDate(isFrom: false))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _reason,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Please give a brief reason'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Submit Application'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Leave History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No leave applications yet')),
            )
          else
            ..._history.map(_historyCard),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(_fmt(value),
            style: TextStyle(
                color: value == null
                    ? Colors.grey.shade600
                    : AppColors.textPrimary)),
      ),
    );
  }

  Widget _historyCard(_LeaveRequest r) {
    final colors = {
      'Approved': AppColors.success,
      'Rejected': AppColors.danger,
      'Pending': AppColors.warning,
    };
    final c = colors[r.status] ?? AppColors.warning;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.12),
          child: Icon(Icons.event_note_outlined, color: c),
        ),
        title:
            Text(r.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_fmt(r.from)} → ${_fmt(r.to)}\n${r.reason}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(r.status,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
