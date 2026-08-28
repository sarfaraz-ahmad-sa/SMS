import 'package:flutter/material.dart';

import '../Widgets/PermissionGate.dart';
import '../Widgets/saas_scaffold.dart';
import 'AccountManagement.dart';
import '../config/backend_config.dart';
import '../services/access_request_service.dart';
import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class AccessRequestsScreen extends StatefulWidget {
  const AccessRequestsScreen({super.key});

  @override
  State<AccessRequestsScreen> createState() => _AccessRequestsScreenState();
}

class _AccessRequestsScreenState extends State<AccessRequestsScreen> {
  final AccessRequestService _service = AccessRequestService();
  late Future<List<AccessRequestRecord>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    if (BackendConfig.isSupabasePrimary &&
        SessionState.instance.hasPermission(AppPermission.usersManage)) {
      _reload();
    } else {
      _future = Future<List<AccessRequestRecord>>.value(
        const <AccessRequestRecord>[],
      );
    }
  }

  void _reload() {
    final tenantId = SessionState.instance.tenant?.id ?? '';
    _future = _service.listForSchool(tenantId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _review(AccessRequestRecord request, String decision) async {
    setState(() => _busyId = request.id);
    try {
      await _service.review(
        tenantId: SessionState.instance.tenant?.id ?? '',
        requestId: request.id,
        decision: decision,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request marked $decision.')),
      );
      if (decision == 'approved') {
        await _openAccountSetup(request);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request could not be reviewed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openAccountSetup(AccessRequestRecord request) async {
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AccountManagementScreen(
          initialDisplayName: request.name,
          initialEmail: request.email,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = BackendConfig.isSupabasePrimary &&
        SessionState.instance.hasPermission(AppPermission.usersManage);
    if (!canManage) {
      return const SaasScaffold(
        title: 'Login Requests',
        activeRoute: '/access-requests',
        body: PermissionDeniedView(),
      );
    }
    return SaasScaffold(
      title: 'Login Requests',
      activeRoute: '/access-requests',
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh requests',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: FutureBuilder<List<AccessRequestRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Could not load requests — try again'),
              ),
            );
          }
          final records = snapshot.data ?? const <AccessRequestRecord>[];
          if (records.isEmpty) {
            return const Center(
              child: Text('No login requests have been submitted.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = records[index];
                final pending = request.status == 'pending';
                final busy = _busyId == request.id;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(request.name.isEmpty
                          ? '?'
                          : request.name[0].toUpperCase()),
                    ),
                    title: Text(request.name),
                    subtitle: Text(
                      '${request.email} • ${request.phone}\n'
                      '${request.rollOrEmployeeId} • ${request.classOrDepartment}',
                    ),
                    isThreeLine: true,
                    trailing: pending
                        ? Wrap(
                            spacing: 4,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Reject',
                                onPressed: busy
                                    ? null
                                    : () => _review(request, 'rejected'),
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.danger),
                              ),
                              IconButton(
                                tooltip: 'Approve and create account',
                                onPressed: busy
                                    ? null
                                    : () => _review(request, 'approved'),
                                icon: const Icon(Icons.check_rounded,
                                    color: AppColors.success),
                              ),
                            ],
                          )
                        : request.status == 'approved'
                            ? IconButton(
                                tooltip: 'Create or link account',
                                onPressed: busy
                                    ? null
                                    : () => _openAccountSetup(request),
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: AppColors.success,
                                ),
                              )
                            : Chip(label: Text(request.status)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
