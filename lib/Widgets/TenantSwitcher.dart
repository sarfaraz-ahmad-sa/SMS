import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_state.dart';
import '../services/tenant_service.dart';
import '../theme/app_theme.dart';

class TenantSwitcher extends StatelessWidget {
  final bool compact;

  const TenantSwitcher({Key? key, this.compact = false}) : super(key: key);

  Future<void> _switchTenant(BuildContext context, String tenantId) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null ||
        tenantId == SessionState.instance.tenant?.id) {
      return;
    }

    SessionState.instance.setSwitchingTenant(true);
    try {
      final service = TenantService();
      final session = await service.selectTenant(firebaseUser, tenantId);
      final tenants = await service.getAccessibleTenants(firebaseUser);
      SessionState.instance.setSession(
        user: session.user,
        tenant: session.tenant,
        availableTenants: tenants,
        activeCampusId: session.activeCampusId,
        activeAcademicYearId: session.activeAcademicYearId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${session.tenant.name}')),
      );
    } on TenantAccessException catch (error) {
      SessionState.instance.setSwitchingTenant(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      SessionState.instance.setSwitchingTenant(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch school. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _showPicker(BuildContext context) async {
    final state = SessionState.instance;
    if (!state.canSwitchTenant || state.switchingTenant) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Select school',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...state.availableTenants.map(
                (tenant) => RadioListTile<String>(
                  value: tenant.id,
                  groupValue: state.tenant?.id,
                  title: Text(tenant.name),
                  subtitle: Text(
                    <String>[
                      if (tenant.code?.isNotEmpty == true) tenant.code!,
                      tenant.subscription.tier.label,
                    ].join(' • '),
                  ),
                  onChanged: (String? value) =>
                      Navigator.pop(sheetContext, value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await _switchTenant(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        if (!state.canSwitchTenant) return const SizedBox.shrink();

        if (compact) {
          return IconButton(
            tooltip: 'Switch school',
            onPressed: state.switchingTenant ? null : () => _showPicker(context),
            icon: state.switchingTenant
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.swap_horiz_rounded),
          );
        }

        return OutlinedButton.icon(
          onPressed: state.switchingTenant ? null : () => _showPicker(context),
          icon: state.switchingTenant
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Switch school'),
        );
      },
    );
  }
}
