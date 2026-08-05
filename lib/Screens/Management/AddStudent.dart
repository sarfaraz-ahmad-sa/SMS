import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../config/backend_config.dart';
import '../../services/models/student.dart';
import '../../services/session_state.dart';
import '../../services/student_service.dart';
import '../../services/supabase_student_service.dart';
import '../../theme/app_theme.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final StudentService _service = StudentService();
  final SupabaseStudentService _supabaseService = SupabaseStudentService();

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _nationality = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _idCard = TextEditingController();
  DateTime? _birthday;
  String _gender = 'Male';
  String _bloodType = 'A+';
  String _religion = 'Islam';

  final TextEditingController _address = TextEditingController();
  final TextEditingController _address2 = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _zip = TextEditingController();

  final TextEditingController _fatherName = TextEditingController();
  final TextEditingController _fatherPhone = TextEditingController();
  final TextEditingController _motherName = TextEditingController();
  final TextEditingController _motherPhone = TextEditingController();
  final TextEditingController _parentAddress = TextEditingController();

  String? _className;
  String? _sectionValue;
  final TextEditingController _boardReg = TextEditingController();
  bool _saving = false;

  static const List<String> _genders = <String>['Male', 'Female', 'Other'];
  static const List<String> _bloods = <String>['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const List<String> _religions = <String>['Islam', 'Christianity', 'Hinduism', 'Sikhism', 'Other'];
  static const List<String> _classes = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  static const List<String> _sections = <String>['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _firstName,
      _lastName,
      _email,
      _nationality,
      _phone,
      _idCard,
      _address,
      _address2,
      _city,
      _zip,
      _fatherName,
      _fatherPhone,
      _motherName,
      _motherPhone,
      _parentAddress,
      _boardReg,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    if (_birthday == null || _className == null || _sectionValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select birthday, class and section.')));
      return;
    }

    setState(() => _saving = true);
    final student = Student(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      birthday: '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
      gender: _gender,
      bloodType: _bloodType,
      religion: _religion,
      nationality: _nationality.text.trim(),
      phone: _phone.text.trim(),
      idCardNumber: _idCard.text.trim(),
      address: _address.text.trim(),
      address2: _address2.text.trim(),
      city: _city.text.trim(),
      zip: _zip.text.trim(),
      fatherName: _fatherName.text.trim(),
      fatherPhone: _fatherPhone.text.trim(),
      motherName: _motherName.text.trim(),
      motherPhone: _motherPhone.text.trim(),
      parentAddress: _parentAddress.text.trim(),
      className: _className!,
      section: _sectionValue!,
      boardRegNo: _boardReg.text.trim(),
      tenantId: SessionState.instance.user?.tenantId ?? '',
    );

    try {
      if (BackendConfig.isSupabasePrimary) {
        final state = SessionState.instance;
        final tenantId = state.tenant?.id;
        final campusId = state.activeCampusId;
        final academicYearId = state.activeAcademicYearId;
        if (tenantId == null || campusId == null || academicYearId == null) {
          throw StateError('School, campus or academic year is not selected.');
        }
        final placement = await _supabaseService.resolvePlacement(
          tenantId: tenantId,
          campusId: campusId,
          academicYearId: academicYearId,
          className: _className!,
          sectionName: _sectionValue!,
        );
        await _supabaseService.create(
          tenantId: tenantId,
          student: SupabaseStudentDraft(
            campusId: campusId,
            academicYearId: academicYearId,
            admissionNo: _idCard.text.trim(),
            fullName: student.fullName,
            classId: placement.classId,
            sectionId: placement.sectionId,
            dateOfBirth: _birthday,
            gender: _gender,
          ),
        );
      } else {
        await _service.addStudent(student);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BackendConfig.isSupabasePrimary ? 'Student saved to Supabase.' : 'Student saved to Firebase.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Add Student',
      activeRoute: '/modules',
      activeModuleId: 'students',
      actions: <Widget>[
        IconButton(
          tooltip: 'Save student',
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
        ),
      ],
      body: JinnPage(
        maxWidth: 1180,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _FormIntroduction(),
              const SizedBox(height: 16),
              _FormSection(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: 'Identity, contact and demographic details.',
                child: _ResponsiveFormGrid(
                  children: <_FormFieldSpec>[
                    _FormFieldSpec(child: _textField(_firstName, 'First Name *')),
                    _FormFieldSpec(child: _textField(_lastName, 'Last Name *')),
                    _FormFieldSpec(child: _textField(_email, 'Email *', keyboardType: TextInputType.emailAddress, email: true)),
                    _FormFieldSpec(child: _birthdayField()),
                    _FormFieldSpec(child: _dropdown('Gender *', _gender, _genders, (String? value) => setState(() => _gender = value ?? _gender))),
                    _FormFieldSpec(child: _textField(_nationality, 'Nationality *', hint: 'e.g. Pakistani')),
                    _FormFieldSpec(child: _dropdown('Blood Type *', _bloodType, _bloods, (String? value) => setState(() => _bloodType = value ?? _bloodType))),
                    _FormFieldSpec(child: _dropdown('Religion *', _religion, _religions, (String? value) => setState(() => _religion = value ?? _religion))),
                    _FormFieldSpec(child: _textField(_phone, 'Phone *', keyboardType: TextInputType.phone, hint: '+92 3XX XXXXXXX')),
                    _FormFieldSpec(child: _textField(_idCard, 'ID / Admission Number *', hint: 'e.g. STD-2026-001')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                icon: Icons.location_on_outlined,
                title: 'Address',
                subtitle: 'Residential and postal information.',
                child: _ResponsiveFormGrid(
                  children: <_FormFieldSpec>[
                    _FormFieldSpec(child: _textField(_address, 'Address *'), fullWidth: true),
                    _FormFieldSpec(child: _textField(_address2, 'Address 2', requiredField: false, hint: 'Apartment, floor or landmark'), fullWidth: true),
                    _FormFieldSpec(child: _textField(_city, 'City *')),
                    _FormFieldSpec(child: _textField(_zip, 'Postal Code', requiredField: false)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                icon: Icons.family_restroom_rounded,
                title: 'Parents & Guardian',
                subtitle: 'Primary family contacts for communication.',
                child: _ResponsiveFormGrid(
                  children: <_FormFieldSpec>[
                    _FormFieldSpec(child: _textField(_fatherName, 'Father Name *')),
                    _FormFieldSpec(child: _textField(_fatherPhone, "Father's Phone *", keyboardType: TextInputType.phone)),
                    _FormFieldSpec(child: _textField(_motherName, 'Mother Name *')),
                    _FormFieldSpec(child: _textField(_motherPhone, "Mother's Phone *", keyboardType: TextInputType.phone)),
                    _FormFieldSpec(child: _textField(_parentAddress, 'Parent / Guardian Address *'), fullWidth: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                icon: Icons.school_outlined,
                title: 'Academic Placement',
                subtitle: 'Assign class, section and registration details.',
                child: _ResponsiveFormGrid(
                  children: <_FormFieldSpec>[
                    _FormFieldSpec(child: _dropdown('Class *', _className, _classes, (String? value) => setState(() => _className = value), hint: 'Select class')),
                    _FormFieldSpec(child: _dropdown('Section *', _sectionValue, _sections, (String? value) => setState(() => _sectionValue = value), hint: 'Select section')),
                    _FormFieldSpec(child: _textField(_boardReg, 'Board Registration No.', requiredField: false), fullWidth: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save Student'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? hint,
    bool requiredField = true,
    bool email = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (String? value) {
        final text = (value ?? '').trim();
        if (requiredField && text.isEmpty) return 'Required';
        if (email && text.isNotEmpty && (!text.contains('@') || !text.contains('.'))) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {String? hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: hint == null ? null : Text(hint),
      items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(growable: false),
      onChanged: onChanged,
      validator: (String? selected) => selected == null ? 'Required' : null,
    );
  }

  Widget _birthdayField() {
    return InkWell(
      onTap: _pickBirthday,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Birthday *', prefixIcon: Icon(Icons.cake_outlined)),
        child: Text(
          _birthday == null
              ? 'Select date'
              : '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}',
          style: TextStyle(color: _birthday == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }
}

class _FormIntroduction extends StatelessWidget {
  const _FormIntroduction();

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      color: AppColors.navigation,
      padding: const EdgeInsets.all(18),
      child: const Row(
        children: <Widget>[
          JinnIconBadge(icon: Icons.person_add_alt_1_rounded, color: AppColors.navigation, background: Colors.white, size: 52),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Create Student Profile', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Complete the four sections below. Required fields are marked with an asterisk.', style: TextStyle(color: Color(0xFFD9E2EA), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _FormSection({required this.icon, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              JinnIconBadge(icon: icon, color: AppColors.primary, background: AppColors.pastelBlue, size: 42),
              const SizedBox(width: 11),
              Expanded(child: JinnSectionHeader(title: title, subtitle: subtitle)),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }
}

class _FormFieldSpec {
  final Widget child;
  final bool fullWidth;
  const _FormFieldSpec({required this.child, this.fullWidth = false});
}

class _ResponsiveFormGrid extends StatelessWidget {
  final List<_FormFieldSpec> children;
  const _ResponsiveFormGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final twoColumns = constraints.maxWidth >= 700;
        const gap = 12.0;
        final halfWidth = twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: 13,
          children: children
              .map(( _FormFieldSpec spec) => SizedBox(width: spec.fullWidth || !twoColumns ? constraints.maxWidth : halfWidth, child: spec.child))
              .toList(growable: false),
        );
      },
    );
  }
}
