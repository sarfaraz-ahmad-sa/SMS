import 'package:flutter/material.dart';

import 'package:school_management/services/models/student.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/services/student_service.dart';
import 'package:school_management/services/supabase_student_service.dart';
import 'package:school_management/config/backend_config.dart';
import 'package:school_management/theme/app_theme.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StudentService();
  final _supabaseService = SupabaseStudentService();

  // Personal
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _nationality = TextEditingController();
  final _phone = TextEditingController();
  final _idCard = TextEditingController();
  DateTime? _birthday;
  String _gender = 'Male';
  String _bloodType = 'A+';
  String _religion = 'Islam';

  // Address
  final _address = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();

  // Parents
  final _fatherName = TextEditingController();
  final _fatherPhone = TextEditingController();
  final _motherName = TextEditingController();
  final _motherPhone = TextEditingController();
  final _parentAddress = TextEditingController();

  // Academic
  String? _className;
  String? _sectionValue;
  final _boardReg = TextEditingController();

  bool _saving = false;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloods = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const _religions = [
    'Islam',
    'Christianity',
    'Hinduism',
    'Sikhism',
    'Other'
  ];
  static const _classes = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
  ];
  static const _sections = ['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    for (final c in [
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
      _boardReg
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_className == null || _sectionValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign a class and section'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final student = Student(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      birthday: _birthday == null
          ? null
          : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
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
          throw StateError('School, campus, or academic year is not selected.');
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
            admissionNo: _idCard.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BackendConfig.isSupabasePrimary
                ? 'Student saved to Supabase'
                : 'Student saved to Firebase',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Personal Information'),
            Row(children: [
              Expanded(child: _tf(_firstName, 'First Name *')),
              const SizedBox(width: 12),
              Expanded(child: _tf(_lastName, 'Last Name *')),
            ]),
            _tf(_email, 'Email *',
                type: TextInputType.emailAddress, isEmail: true),
            _dateField(),
            Row(children: [
              Expanded(
                  child: _dropdown('Gender *', _gender, _genders,
                      (v) => setState(() => _gender = v!))),
              const SizedBox(width: 12),
              Expanded(
                  child: _tf(_nationality, 'Nationality *',
                      hint: 'e.g. Pakistani')),
            ]),
            Row(children: [
              Expanded(
                  child: _dropdown('Blood Type *', _bloodType, _bloods,
                      (v) => setState(() => _bloodType = v!))),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown('Religion *', _religion, _religions,
                      (v) => setState(() => _religion = v!))),
            ]),
            _tf(_phone, 'Phone *',
                type: TextInputType.phone, hint: '+92 3XX XXXXXXX'),
            _tf(_idCard, 'Id Card Number *', hint: 'e.g. 2021-03-01-02-01'),
            _section('Address'),
            _tf(_address, 'Address *'),
            _tf(_address2, 'Address 2',
                required: false, hint: 'Apartment, studio, or floor'),
            Row(children: [
              Expanded(child: _tf(_city, 'City *')),
              const SizedBox(width: 12),
              Expanded(child: _tf(_zip, 'Zip', required: false)),
            ]),
            _section("Parents' Information"),
            Row(children: [
              Expanded(child: _tf(_fatherName, 'Father Name *')),
              const SizedBox(width: 12),
              Expanded(
                  child: _tf(_fatherPhone, "Father's Phone *",
                      type: TextInputType.phone)),
            ]),
            Row(children: [
              Expanded(child: _tf(_motherName, 'Mother Name *')),
              const SizedBox(width: 12),
              Expanded(
                  child: _tf(_motherPhone, "Mother's Phone *",
                      type: TextInputType.phone)),
            ]),
            _tf(_parentAddress, 'Address *'),
            _section('Academic Information'),
            _dropdown('Assign to class *', _className, _classes,
                (v) => setState(() => _className = v),
                hint: 'Please select a class'),
            const SizedBox(height: 12),
            _dropdown('Assign to section *', _sectionValue, _sections,
                (v) => setState(() => _sectionValue = v),
                hint: 'Please select a section'),
            _tf(_boardReg, 'Board Registration No.', required: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Student'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      );

  Widget _tf(TextEditingController c, String label,
      {TextInputType? type,
      String? hint,
      bool required = true,
      bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged,
      {String? hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: hint == null ? null : Text(hint),
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickBirthday,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Birthday *',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
          child: Text(
            _birthday == null
                ? 'dd/mm/yyyy'
                : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
            style: TextStyle(
                color: _birthday == null
                    ? Colors.grey.shade600
                    : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
