import 'package:flutter/material.dart';

import '../Widgets/saas_scaffold.dart';

import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_record.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'Enterprise/ErpEntityListScreen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final announcement = ErpCatalog.entityByCollection('announcements');
    final event = ErpCatalog.entityByCollection('events');

    if (announcement == null || event == null) {
      return const SaasScaffold(
        title: 'Notifications & Updates',
        activeRoute: '/notifications',
        body: Center(child: Text('Notification modules are unavailable.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: SaasScaffold(
        title: 'Notifications & Updates',
        activeRoute: '/notifications',
        actions: <Widget>[
          if (SessionState.instance
              .hasPermission(AppPermission.communicationManage))
            IconButton(
              tooltip: 'Manage announcements',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ErpEntityListScreen(entity: announcement),
                ),
              ),
              icon: const Icon(Icons.edit_notifications_outlined),
            ),
        ],
        body: Column(
          children: <Widget>[
            const Material(
              color: Colors.transparent,
              child: TabBar(
                tabs: <Widget>[
                  Tab(text: 'Announcements', icon: Icon(Icons.campaign_outlined)),
                  Tab(text: 'Events', icon: Icon(Icons.event_outlined)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _RecordFeed(
                    entity: announcement,
                    emptyMessage: 'No announcements have been published yet.',
                  ),
                  _RecordFeed(
                    entity: event,
                    emptyMessage: 'No upcoming events are available.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordFeed extends StatelessWidget {
  final ErpEntity entity;
  final String emptyMessage;

  const _RecordFeed({required this.entity, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ErpRecord>>(
      stream: TenantErpService().watch(entity),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<ErpRecord>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _FeedMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Updates could not be loaded',
            message: snapshot.error.toString(),
          );
        }

        final records = snapshot.data ?? const <ErpRecord>[];
        if (records.isEmpty) {
          return _FeedMessage(
            icon: entity.icon,
            title: 'Nothing new',
            message: emptyMessage,
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final record = records[index];
                return _FeedCard(entity: entity, record: record);
              },
            ),
          ),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final ErpEntity entity;
  final ErpRecord record;

  const _FeedCard({required this.entity, required this.record});

  @override
  Widget build(BuildContext context) {
    final title = record.data[entity.primaryField]?.toString().trim();
    final secondary = entity.secondaryField == null
        ? null
        : record.data[entity.secondaryField]?.toString().trim();
    final description = _description(record.data);
    final status = entity.statusField == null
        ? null
        : record.data[entity.statusField]?.toString().trim();

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entity.icon, color: entity.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title?.isNotEmpty == true
                                ? title!
                                : entity.singularTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (status?.isNotEmpty == true)
                          _StatusBadge(label: status!, color: entity.color),
                      ],
                    ),
                    if (secondary?.isNotEmpty == true) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        secondary!,
                        style: TextStyle(
                          color: entity.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _timestampLabel(record),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _description(Map<String, dynamic> data) {
    const candidates = <String>[
      'message',
      'description',
      'details',
      'venue',
      'audience',
    ];
    for (final key in candidates) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _timestampLabel(ErpRecord record) {
    final date = record.updatedAt ?? record.createdAt;
    if (date == null) return 'School update';
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}-${two(local.month)}-${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => FractionallySizedBox(
        heightFactor: 0.78,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(entity.icon, color: entity.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    record.data[entity.primaryField]?.toString() ??
                        entity.singularTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...entity.fields
                .where((field) => !field.internal)
                .map((field) {
              final value = record.data[field.key];
              if (value == null || value.toString().trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: field.label),
                  child: Text(value.toString()),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
