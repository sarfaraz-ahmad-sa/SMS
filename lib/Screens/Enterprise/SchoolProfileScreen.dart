import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Widgets/saas_scaffold.dart';

import '../../config/backend_config.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/models/app_permission.dart';
import '../../services/session_state.dart';
import '../../services/supabase_tenant_service.dart';
import '../../services/tenant_service.dart';
import '../../theme/app_theme.dart';

class SchoolProfileScreen extends StatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TenantService? _tenantService =
      BackendConfig.isSupabasePrimary ? null : TenantService();
  final SupabaseTenantService _supabaseTenantService = SupabaseTenantService();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _currencyController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _logoUrlController;

  bool _saving = false;

  bool get _canManage =>
      SessionState.instance.hasPermission(AppPermission.tenantManage) ||
      SessionState.instance.hasPermission(AppPermission.schoolSetupManage);

  @override
  void initState() {
    super.initState();
    final tenant = SessionState.instance.tenant;
    _nameController = TextEditingController(text: tenant?.name ?? '');
    _codeController = TextEditingController(text: tenant?.code ?? '');
    _timezoneController =
        TextEditingController(text: tenant?.timezone ?? 'Asia/Karachi');
    _currencyController =
        TextEditingController(text: tenant?.currency ?? 'PKR');
    _academicYearController =
        TextEditingController(text: tenant?.activeAcademicYearId ?? '');
    _logoUrlController = TextEditingController(text: tenant?.logoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _timezoneController.dispose();
    _currencyController.dispose();
    _academicYearController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canManage || !_formKey.currentState!.validate()) return;
    final tenant = SessionState.instance.tenant;
    if (tenant == null) return;

    setState(() => _saving = true);
    try {
      final updated = BackendConfig.isSupabasePrimary
          ? await _supabaseTenantService.updateTenantProfile(
              current: tenant,
              name: _nameController.text,
              code: _codeController.text,
              timezone: _timezoneController.text,
              currency: _currencyController.text,
              activeAcademicYearId: _academicYearController.text,
              logoUrl: _logoUrlController.text,
            )
          : await _tenantService!.updateTenantProfile(
              current: tenant,
              name: _nameController.text,
              code: _codeController.text,
              timezone: _timezoneController.text,
              currency: _currencyController.text,
              activeAcademicYearId: _academicYearController.text,
              logoUrl: _logoUrlController.text,
            );
      SessionState.instance.updateTenant(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('School profile updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'School profile could not be updated.');
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = SessionState.instance.tenant;
    if (tenant == null) {
      return const SaasScaffold(
        title: 'School Profile',
        activeRoute: '/erp-module',
        activeModuleId: 'school-setup',
        body: Center(child: Text('No active school session.')),
      );
    }

    return SaasScaffold(
      title: 'School Profile',
      activeRoute: '/erp-module',
      activeModuleId: 'school-setup',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navigation,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white24,
                      backgroundImage: tenant.logoUrl?.trim().isNotEmpty == true
                          ? NetworkImage(tenant.logoUrl!)
                          : null,
                      child: tenant.logoUrl?.trim().isNotEmpty == true
                          ? null
                          : const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tenant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tenant.code ?? tenant.id} • ${tenant.subscription.planLabel}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.86),
                            ),
                          ),
                          if (TenantErpService().isDemoMode) ...<Widget>[
                            const SizedBox(height: 8),
                            const Text(
                              'Demo changes remain on this device session.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          enabled: _canManage && !_saving,
                          decoration: const InputDecoration(
                            labelText: 'School name',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          validator: (String? value) =>
                              (value?.trim().length ?? 0) < 2
                                  ? 'Enter the school name'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _codeController,
                          enabled: _canManage && !_saving,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'School code',
                            prefixIcon: Icon(Icons.tag_outlined),
                          ),
                          validator: (String? value) =>
                              (value?.trim().length ?? 0) < 2
                                  ? 'Enter a school code'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final fields = <Widget>[
                              TextFormField(
                                controller: _timezoneController,
                                enabled: _canManage && !_saving,
                                decoration: const InputDecoration(
                                  labelText: 'Timezone',
                                  prefixIcon: Icon(Icons.schedule_outlined),
                                  helperText: 'Example: Asia/Karachi',
                                ),
                                validator: (String? value) =>
                                    value?.trim().isEmpty == true
                                        ? 'Timezone is required'
                                        : null,
                              ),
                              TextFormField(
                                controller: _currencyController,
                                enabled: _canManage && !_saving,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Base currency',
                                  prefixIcon:
                                      Icon(Icons.currency_exchange_outlined),
                                  helperText: 'Example: PKR',
                                ),
                                validator: (String? value) =>
                                    (value?.trim().length ?? 0) != 3
                                        ? 'Use a 3-letter currency code'
                                        : null,
                              ),
                            ];
                            if (constraints.maxWidth >= 620) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: fields[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: fields[1]),
                                ],
                              );
                            }
                            return Column(
                              children: <Widget>[
                                fields[0],
                                const SizedBox(height: 14),
                                fields[1],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _academicYearController,
                          enabled: _canManage && !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Active academic year',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                            helperText: 'Example: 2026-2027',
                          ),
                          validator: (String? value) =>
                              value?.trim().isEmpty == true
                                  ? 'Select an academic year'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _logoUrlController,
                          enabled: _canManage && !_saving,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL',
                            prefixIcon: Icon(Icons.image_outlined),
                            helperText:
                                'Use a tenant-scoped Storage download URL.',
                          ),
                        ),
                        if (_canManage) ...<Widget>[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save School Profile'),
                          ),
                        ] else ...<Widget>[
                          const SizedBox(height: 16),
                          const Text(
                            'You have view-only access to the school profile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
