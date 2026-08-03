import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Widgets/saas_scaffold.dart';
import '../../config/backend_config.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/models/app_permission.dart';
import '../../services/models/approval_request.dart';
import '../../services/saas_admin_service.dart';
import '../../services/session_state.dart';
import '../../services/supabase_bootstrap.dart';
import '../../theme/app_theme.dart';

class ApprovalInboxScreen extends StatefulWidget {
  const ApprovalInboxScreen({super.key});

  @override
  State<ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends State<ApprovalInboxScreen> {
  ApprovalStatus? _statusFilter;
  String? _busyId;

  @override
  Widget build(BuildContext context) {
    final canDecide = SessionState.instance.hasAnyPermission(const <String>[
      AppPermission.saasAdminManage,
      AppPermission.accountingManage,
      AppPermission.feesManage,
      AppPermission.payrollManage,
      AppPermission.examsManage,
      AppPermission.studentsManage,
      AppPermission.leaveManage,
    ]);

    return SaasScaffold(
      title: 'Approval Inbox',
      activeRoute: '/approvals',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: <Widget>[
              _Header(
                selected: _statusFilter,
                onChanged: (ApprovalStatus? value) {
                  setState(() => _statusFilter = value);
                },
              ),
              Expanded(
                child: StreamBuilder<List<ApprovalRequest>>(
                  stream: _watchApprovals(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<ApprovalRequest>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(message: snapshot.error.toString());
                    }
                    final all = snapshot.data ?? const <ApprovalRequest>[];
                    final approvals = _statusFilter == null
                        ? all
                        : all
                            .where(
                              (ApprovalRequest item) =>
                                  item.status == _statusFilter,
                            )
                            .toList(growable: false);
                    if (approvals.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: approvals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final approval = approvals[index];
                        return _ApprovalCard(
                          approval: approval,
                          canDecide: canDecide,
                          busy: _busyId == approval.id,
                          onApprove: () => _decide(approval, 'approved'),
                          onReject: () => _decide(approval, 'rejected'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<List<ApprovalRequest>> _watchApprovals() {
    if (TenantErpService().isDemoMode) {
      final now = DateTime.now();
      return Stream<List<ApprovalRequest>>.value(<ApprovalRequest>[
        ApprovalRequest(
          id: 'demo-refund',
          tenantId: 'demo-school',
          type: 'fee-refund',
          title: 'Fee refund — INV-2026-0712',
          requesterUid: 'demo-cashier',
          status: ApprovalStatus.submitted,
          recordCollection: 'fee_refunds',
          recordId: 'refund-001',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        ApprovalRequest(
          id: 'demo-payroll',
          tenantId: 'demo-school',
          type: 'payroll-run',
          title: 'July 2026 payroll run',
          requesterUid: 'demo-hr',
          status: ApprovalStatus.underReview,
          recordCollection: 'payroll_runs',
          recordId: 'payroll-2026-07',
          createdAt: now.subtract(const Duration(days: 1)),
          currentStep: 2,
          totalSteps: 2,
        ),
      ]);
    }

    final tenantId = SessionState.instance.tenant?.id;
    if (tenantId == null || tenantId.isEmpty) {
      return Stream<List<ApprovalRequest>>.value(const <ApprovalRequest>[]);
    }

    if (BackendConfig.isSupabasePrimary) {
      return Stream<List<ApprovalRequest>>.fromFuture(
        _loadSupabaseApprovals(tenantId),
      );
    }

    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('approval_requests')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                    ApprovalRequest.fromMap(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  Future<List<ApprovalRequest>> _loadSupabaseApprovals(String tenantId) async {
    final state = SessionState.instance;
    final rows = await SupabaseBootstrap.client
        .from('erp_records')
        .select('id,collection,status,data,created_by,created_at')
        .eq('tenant_id', tenantId)
        .eq('campus_id', state.activeCampusId ?? '')
        .eq('academic_year_id', state.activeAcademicYearId ?? '')
        .eq('is_archived', false)
        .inFilter('collection', const <String>[
          'fee_refunds',
          'payroll_runs',
          'journal_entries',
          'expenses',
          'budgets',
          'payslips',
          'exam_results',
        ])
        .inFilter('status', const <String>[
          'Requested',
          'Under Review',
          'Submitted',
          'Approved',
          'Rejected',
        ])
        .order('created_at', ascending: false)
        .limit(100);
    return rows.whereType<Map>().map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final data = row['data'] is Map
          ? Map<String, dynamic>.from(row['data'] as Map)
          : const <String, dynamic>{};
      final collection = row['collection']?.toString() ?? '';
      final recordId = row['id']?.toString() ?? '';
      final statusText = row['status']?.toString() ?? '';
      final title = <dynamic>[
        data['refundNo'],
        data['period'],
        data['voucherNo'],
        data['expenseNo'],
        data['name'],
        data['studentName'],
      ].map((value) => value?.toString().trim() ?? '').firstWhere(
            (value) => value.isNotEmpty,
            orElse: () => collection.replaceAll('_', ' '),
          );
      return ApprovalRequest(
        id: '$collection:$recordId',
        tenantId: tenantId,
        type: collection.replaceAll('_', '-'),
        title: title,
        requesterUid: row['created_by']?.toString() ?? '',
        status: switch (statusText) {
          'Requested' || 'Submitted' => ApprovalStatus.submitted,
          'Under Review' => ApprovalStatus.underReview,
          'Approved' => ApprovalStatus.approved,
          'Rejected' => ApprovalStatus.rejected,
          _ => ApprovalStatus.draft,
        },
        recordCollection: collection,
        recordId: recordId,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList(growable: false);
  }

  Future<void> _decide(ApprovalRequest approval, String decision) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
            decision == 'approved' ? 'Approve request?' : 'Reject request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(approval.title),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: decision == 'approved'
                    ? 'Decision note (optional)'
                    : 'Rejection reason',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(decision == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;
    if (decision == 'rejected' && reason.isEmpty) {
      _message('A rejection reason is required.', error: true);
      return;
    }

    setState(() => _busyId = approval.id);
    try {
      await SaasAdminService().decideApproval(
        approvalId: approval.id,
        decision: decision,
        reason: reason,
      );
      if (!mounted) return;
      _message('Approval marked as $decision.');
    } catch (error) {
      if (!mounted) return;
      _message(_friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '');
  }
}

class _Header extends StatelessWidget {
  final ApprovalStatus? selected;
  final ValueChanged<ApprovalStatus?> onChanged;

  const _Header({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final heading = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Operational approvals',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Review submitted finance, payroll, academic and student operations.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          );
          final filter = DropdownButton<ApprovalStatus?>(
            value: selected,
            hint: const Text('All statuses'),
            items: <DropdownMenuItem<ApprovalStatus?>>[
              const DropdownMenuItem<ApprovalStatus?>(
                value: null,
                child: Text('All statuses'),
              ),
              ...ApprovalStatus.values.map(
                (ApprovalStatus status) => DropdownMenuItem<ApprovalStatus?>(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
              ),
            ],
            onChanged: onChanged,
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[heading, const SizedBox(height: 12), filter],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: heading),
              filter,
            ],
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest approval;
  final bool canDecide;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.approval,
    required this.canDecide,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final pending = approval.status == ApprovalStatus.submitted ||
        approval.status == ApprovalStatus.underReview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final details = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _StatusIcon(status: approval.status),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            approval.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _StatusPill(status: approval.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${approval.type} • ${approval.recordCollection}/${approval.recordId}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested ${_relativeDate(approval.createdAt)} • Step ${approval.currentStep}/${approval.totalSteps}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = pending && canDecide
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: busy ? null : onReject,
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: busy ? null : onApprove,
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                    ],
                  )
                : null;
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  details,
                  if (actions != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: details),
                if (actions != null) ...<Widget>[
                  const SizedBox(width: 16),
                  actions,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ApprovalStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(Icons.approval_outlined, color: color),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ApprovalStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.task_alt, size: 54, color: AppColors.success),
            SizedBox(height: 12),
            Text('No approvals require attention.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Could not load approvals. $message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
    );
  }
}

String _statusLabel(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.underReview:
      return 'Under review';
    default:
      final name = status.name;
      return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

Color _statusColor(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.approved:
    case ApprovalStatus.completed:
      return AppColors.success;
    case ApprovalStatus.rejected:
    case ApprovalStatus.cancelled:
      return AppColors.danger;
    case ApprovalStatus.submitted:
    case ApprovalStatus.underReview:
      return AppColors.warning;
    case ApprovalStatus.draft:
      return AppColors.info;
  }
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 30) return '${difference.inDays}d ago';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
