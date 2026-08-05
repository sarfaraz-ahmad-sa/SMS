import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../theme/app_theme.dart';

class _Application {
  final String name;
  final String className;
  final String guardian;
  final String phone;
  final String applicationNo;
  String status;

  _Application(
    this.name,
    this.className,
    this.guardian,
    this.phone,
    this.applicationNo, {
    this.status = 'Pending',
  });
}

class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'All';

  final List<_Application> _applications = <_Application>[
    _Application('Bilal Ahmed', '9', 'Ahmed Khan', '+92 300 1231234', 'ADM-2026-1042', status: 'Approved'),
    _Application('Fatima Zahra', '6', 'Zahra Bibi', '+92 301 5675678', 'ADM-2026-1043'),
    _Application('Hamza Ali', '4', 'Asif Ali', '+92 302 3421188', 'ADM-2026-1044', status: 'Under Review'),
    _Application('Maryam Noor', '8', 'Nadeem Noor', '+92 303 9931040', 'ADM-2026-1045', status: 'Rejected'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _count(String status) => _applications.where(( _Application item) => item.status == status).length;

  List<_Application> get _filtered {
    final normalized = _query.trim().toLowerCase();
    return _applications
        .where(( _Application item) {
          final matchesStatus = _statusFilter == 'All' || item.status == _statusFilter;
          final matchesQuery = normalized.isEmpty ||
              '${item.name} ${item.guardian} ${item.applicationNo} ${item.className}'.toLowerCase().contains(normalized);
          return matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }

  void _openNewAdmission() {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final className = TextEditingController();
    final guardian = TextEditingController();
    final phone = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const JinnSectionHeader(title: 'New Admission', subtitle: 'Create a student admission application.'),
                  const SizedBox(height: 17),
                  _sheetField(name, 'Student Name', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _sheetField(className, 'Applying for Class', Icons.school_outlined),
                  const SizedBox(height: 12),
                  _sheetField(guardian, 'Guardian Name', Icons.family_restroom_rounded),
                  const SizedBox(height: 12),
                  _sheetField(phone, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        final applicationNo = 'ADM-2026-${1042 + _applications.length}';
                        setState(() {
                          _applications.insert(
                            0,
                            _Application(
                              name.text.trim(),
                              className.text.trim(),
                              guardian.text.trim(),
                              phone.text.trim(),
                              applicationNo,
                            ),
                          );
                        });
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admission application submitted.')));
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      name.dispose();
      className.dispose();
      guardian.dispose();
      phone.dispose();
    });
  }

  Widget _sheetField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SaasScaffold(
      title: 'Admissions',
      activeRoute: '/modules',
      activeModuleId: 'admissions',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAdmission,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Admission'),
      ),
      actions: <Widget>[
        IconButton(tooltip: 'New admission', onPressed: _openNewAdmission, icon: const Icon(Icons.person_add_alt_1_rounded)),
      ],
      body: JinnPage(
        maxWidth: 1260,
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            JinnResponsiveGrid(
              minItemWidth: 175,
              childAspectRatio: 2.35,
              children: <Widget>[
                _AdmissionMetric('Applications', '${_applications.length}', Icons.inbox_rounded, AppColors.pastelBlue, const Color(0xFF4E68D8)),
                _AdmissionMetric('Approved', '${_count('Approved')}', Icons.verified_rounded, AppColors.pastelGreen, const Color(0xFF27936B)),
                _AdmissionMetric('Under Review', '${_count('Under Review') + _count('Pending')}', Icons.hourglass_top_rounded, AppColors.pastelGold, const Color(0xFFD89614)),
                _AdmissionMetric('Rejected', '${_count('Rejected')}', Icons.cancel_rounded, AppColors.pastelRose, const Color(0xFFE05D65)),
              ],
            ),
            const SizedBox(height: 16),
            JinnCard(
              padding: const EdgeInsets.all(13),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxWidth < 680;
                  final search = JinnSearchField(
                    controller: _searchController,
                    hintText: 'Search applicant, guardian or application no...',
                    onChanged: (String value) => setState(() => _query = value),
                  );
                  final filter = DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.filter_alt_outlined)),
                    items: const <String>['All', 'Pending', 'Under Review', 'Approved', 'Rejected']
                        .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                        .toList(growable: false),
                    onChanged: (String? value) => setState(() => _statusFilter = value ?? 'All'),
                  );
                  if (compact) {
                    return Column(children: <Widget>[search, const SizedBox(height: 10), filter]);
                  }
                  return Row(children: <Widget>[Expanded(child: search), const SizedBox(width: 10), SizedBox(width: 230, child: filter)]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const JinnEmptyState(icon: Icons.person_search_rounded, title: 'No applications found', message: 'Adjust the search or status filter.')
                  : LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        if (constraints.maxWidth >= 900) {
                          return _AdmissionTable(
                            applications: filtered,
                            onStatusChanged: ( _Application item, String status) => setState(() => item.status = status),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 92),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (BuildContext context, int index) {
                            final item = filtered[index];
                            return _AdmissionCard(
                              application: item,
                              onStatusChanged: (String status) => setState(() => item.status = status),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdmissionMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _AdmissionMetric(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 42),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdmissionCard extends StatelessWidget {
  final _Application application;
  final ValueChanged<String> onStatusChanged;
  const _AdmissionCard({required this.application, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status);
    return JinnCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.pastelGold,
            child: Text(application.name[0].toUpperCase(), style: const TextStyle(color: AppColors.navigation, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(application.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('Class ${application.className}  ·  ${application.applicationNo}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text('${application.guardian}  ·  ${application.phone}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Change status',
            onSelected: onStatusChanged,
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'Approved', child: Text('Approve')),
              PopupMenuItem<String>(value: 'Under Review', child: Text('Under Review')),
              PopupMenuItem<String>(value: 'Pending', child: Text('Pending')),
              PopupMenuItem<String>(value: 'Rejected', child: Text('Reject')),
            ],
            child: JinnStatusPill(label: application.status, color: color),
          ),
        ],
      ),
    );
  }
}

class _AdmissionTable extends StatelessWidget {
  final List<_Application> applications;
  final void Function(_Application item, String status) onStatusChanged;
  const _AdmissionTable({required this.applications, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('APPLICANT', style: _headerStyle)),
                Expanded(flex: 2, child: Text('CLASS', style: _headerStyle)),
                Expanded(flex: 3, child: Text('GUARDIAN', style: _headerStyle)),
                Expanded(flex: 2, child: Text('APPLICATION', style: _headerStyle)),
                SizedBox(width: 145, child: Text('STATUS', style: _headerStyle)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: applications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final item = applications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('Class ${item.className}', style: Theme.of(context).textTheme.bodySmall)),
                      Expanded(flex: 3, child: Text(item.guardian, style: Theme.of(context).textTheme.bodySmall)),
                      Expanded(flex: 2, child: Text(item.applicationNo, style: Theme.of(context).textTheme.bodySmall)),
                      SizedBox(
                        width: 145,
                        child: PopupMenuButton<String>(
                          onSelected: (String value) => onStatusChanged(item, value),
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(value: 'Approved', child: Text('Approve')),
                            PopupMenuItem<String>(value: 'Under Review', child: Text('Under Review')),
                            PopupMenuItem<String>(value: 'Pending', child: Text('Pending')),
                            PopupMenuItem<String>(value: 'Rejected', child: Text('Reject')),
                          ],
                          child: Align(alignment: Alignment.centerLeft, child: JinnStatusPill(label: item.status, color: _statusColor(item.status))),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4);

Color _statusColor(String status) {
  if (status == 'Approved') return AppColors.success;
  if (status == 'Rejected') return AppColors.danger;
  if (status == 'Under Review') return AppColors.info;
  return AppColors.warning;
}
