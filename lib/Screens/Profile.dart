import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  late final TextEditingController _nameController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: SessionState.instance.user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _profileService.updateDisplayName(_nameController.text);
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final user = SessionState.instance.user;
        final tenant = SessionState.instance.tenant;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: <Widget>[
              IconButton(
                tooltip: _editing ? 'Cancel editing' : 'Edit profile',
                icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          _editing = !_editing;
                          if (!_editing) {
                            _nameController.text = user?.displayName ?? '';
                          }
                        });
                      },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: <Widget>[
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.displayName?.trim().isNotEmpty == true
                              ? user!.displayName!.trim()
                              : 'User',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.roleLabel ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                              enabled: _editing && !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (String? value) {
                                final name = value?.trim() ?? '';
                                if (name.length < 2) {
                                  return 'Enter at least 2 characters';
                                }
                                if (name.length > 120) {
                                  return 'Maximum 120 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Email address',
                              value: user?.email ?? 'Not available',
                              icon: Icons.mail_outline,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'School',
                              value: tenant?.name ?? 'Not assigned',
                              icon: Icons.school_outlined,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Role',
                              value: user?.roleLabel ?? 'Not assigned',
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Campus access',
                              value: user?.campusIds.isNotEmpty == true
                                  ? user!.campusIds.join(', ')
                                  : 'All authorized campuses',
                              icon: Icons.location_city_outlined,
                            ),
                            if (_editing) ...<Widget>[
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Changes'),
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
      },
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: Text(value),
    );
  }
}
