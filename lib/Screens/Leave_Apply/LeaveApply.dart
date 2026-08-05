import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../theme/app_theme.dart';

class LeaveApply extends StatefulWidget {
  const LeaveApply({super.key});

  @override
  State<LeaveApply> createState() => _LeaveApplyState();
}

class _LeaveRequest {
  final String type;
  final DateTime from;
  final DateTime to;
  final String reason;
  final String status;
  const _LeaveRequest(this.type, this.from, this.to, this.reason, {this.status = 'Pending'});
}

class _LeaveApplyState extends State<LeaveApply> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();
  static const List<String> _types = <String>['Sick Leave', 'Casual Leave', 'Family / Emergency', 'Medical Leave', 'Other'];

  String? _type;
  DateTime? _from;
  DateTime? _to;

  final List<_LeaveRequest> _history = <_LeaveRequest>[
    _LeaveRequest('Sick Leave', DateTime(2026, 4, 2), DateTime(2026, 4, 3), 'Fever and rest advised', status: 'Approved'),
    _LeaveRequest('Casual Leave', DateTime(2026, 3, 15), DateTime(2026, 3, 15), 'Family function', status: 'Rejected'),
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) => date == null ? 'Select date' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both dates.')));
      return;
    }
    if (_to!.isBefore(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The end date cannot be before the start date.')));
      return;
    }
    setState(() {
      _history.insert(0, _LeaveRequest(_type!, _from!, _to!, _reason.text.trim()));
      _type = null;
      _from = null;
      _to = null;
      _reason.clear();
      _formKey.currentState?.reset();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted.')));
  }

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Leave Management',
      activeRoute: '/modules',
      activeModuleId: 'attendance',
      body: JinnPage(
        maxWidth: 1220,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final desktop = constraints.maxWidth >= 860;
            final form = _ApplicationForm(
              formKey: _formKey,
              type: _type,
              types: _types,
              from: _from,
              to: _to,
              reason: _reason,
              formatDate: _formatDate,
              onTypeChanged: (String? value) => setState(() => _type = value),
              onPickFrom: () => _pickDate(from: true),
              onPickTo: () => _pickDate(from: false),
              onSubmit: _submit,
            );
            final history = _LeaveHistory(history: _history, formatDate: _formatDate);
            if (!desktop) {
              return Column(
                children: <Widget>[form, const SizedBox(height: 16), history],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 4, child: form),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: history),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ApplicationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? type;
  final List<String> types;
  final DateTime? from;
  final DateTime? to;
  final TextEditingController reason;
  final String Function(DateTime?) formatDate;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSubmit;

  const _ApplicationForm({
    required this.formKey,
    required this.type,
    required this.types,
    required this.from,
    required this.to,
    required this.reason,
    required this.formatDate,
    required this.onTypeChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const JinnSectionHeader(title: 'New Leave Request', subtitle: 'Complete the form and submit for approval.'),
            const SizedBox(height: 17),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Leave Type', prefixIcon: Icon(Icons.category_outlined)),
              items: types.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(growable: false),
              onChanged: onTypeChanged,
              validator: (String? value) => value == null ? 'Select a leave type' : null,
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 430;
                final fromField = _DateField(label: 'From', value: formatDate(from), selected: from != null, onTap: onPickFrom);
                final toField = _DateField(label: 'To', value: formatDate(to), selected: to != null, onTap: onPickTo);
                if (compact) {
                  return Column(children: <Widget>[fromField, const SizedBox(height: 12), toField]);
                }
                return Row(children: <Widget>[Expanded(child: fromField), const SizedBox(width: 12), Expanded(child: toField)]);
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: reason,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
              validator: (String? value) => (value ?? '').trim().length < 5 ? 'Enter a brief reason' : null,
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.send_rounded, size: 18), label: const Text('Submit Application')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today_outlined, size: 19)),
        child: Text(value, style: TextStyle(color: selected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _LeaveHistory extends StatelessWidget {
  final List<_LeaveRequest> history;
  final String Function(DateTime?) formatDate;
  const _LeaveHistory({required this.history, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const JinnSectionHeader(title: 'Leave History', subtitle: 'Track submitted requests and approval status.'),
          const SizedBox(height: 13),
          if (history.isEmpty)
            const JinnEmptyState(icon: Icons.event_busy_rounded, title: 'No leave requests', message: 'New applications will appear here.')
          else
            ...history.map(( _LeaveRequest request) => _LeaveHistoryCard(request: request, formatDate: formatDate)),
        ],
      ),
    );
  }
}

class _LeaveHistoryCard extends StatelessWidget {
  final _LeaveRequest request;
  final String Function(DateTime?) formatDate;
  const _LeaveHistoryCard({required this.request, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final color = request.status == 'Approved' ? AppColors.success : request.status == 'Rejected' ? AppColors.danger : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: Icons.event_note_rounded, color: color, background: color.withOpacity(0.1), size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(request.type, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${formatDate(request.from)} → ${formatDate(request.to)}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(request.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          JinnStatusPill(label: request.status, color: color),
        ],
      ),
    );
  }
}
