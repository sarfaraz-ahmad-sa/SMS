import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/erp/erp_entity.dart';
import '../../core/erp/erp_field.dart';
import '../../core/erp/erp_record.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../theme/app_theme.dart';

Future<bool?> showErpEntityForm({
  required BuildContext context,
  required ErpEntity entity,
  ErpRecord? record,
}) {
  final content = ErpEntityForm(entity: entity, record: record);
  if (MediaQuery.sizeOf(context).width >= 760) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: content,
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(heightFactor: 0.92, child: content),
    ),
  );
}

class ErpEntityForm extends StatefulWidget {
  final ErpEntity entity;
  final ErpRecord? record;

  const ErpEntityForm({
    super.key,
    required this.entity,
    this.record,
  });

  @override
  State<ErpEntityForm> createState() => _ErpEntityFormState();
}

class _ErpEntityFormState extends State<ErpEntityForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TenantErpService _service = TenantErpService();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _booleans = <String, bool>{};
  final Map<String, String?> _dropdowns = <String, String?>{};
  bool _saving = false;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.entity.fields) {
      if (field.internal) continue;
      final raw = widget.record?.data[field.key] ?? field.defaultValue;
      if (field.type == ErpFieldType.boolean) {
        _booleans[field.key] = raw == true;
      } else if (field.type == ErpFieldType.dropdown) {
        final value = raw?.toString();
        _dropdowns[field.key] = field.options.contains(value) ? value : null;
      } else {
        _controllers[field.key] = TextEditingController(
          text: _displayInitialValue(raw),
        );
      }
    }
  }

  String _displayInitialValue(dynamic value) {
    if (value is Timestamp) return _dateText(value.toDate());
    if (value is DateTime) return _dateText(value);
    if (value is Iterable) return value.join(', ');
    return value?.toString() ?? '';
  }

  String _dateText(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final values = <String, dynamic>{};
      for (final field in widget.entity.fields) {
        if (field.internal) continue;
        if (field.readOnly) continue;
        if (field.type == ErpFieldType.boolean) {
          values[field.key] = _booleans[field.key] ?? false;
          continue;
        }
        if (field.type == ErpFieldType.dropdown) {
          values[field.key] = _dropdowns[field.key];
          continue;
        }

        final text = _controllers[field.key]?.text.trim() ?? '';
        switch (field.type) {
          case ErpFieldType.integer:
            values[field.key] = text.isEmpty ? null : int.tryParse(text);
            break;
          case ErpFieldType.decimal:
          case ErpFieldType.money:
            values[field.key] = text.isEmpty
                ? null
                : double.tryParse(text.replaceAll(',', ''));
            break;
          default:
            if (field.key.endsWith('Uids')) {
              values[field.key] = text
                  .split(',')
                  .map((String value) => value.trim())
                  .where((String value) => value.isNotEmpty)
                  .toList();
            } else {
              values[field.key] = text;
            }
        }
      }

      if (_editing) {
        await _service.update(widget.entity, widget.record!.id, values);
      } else {
        await _service.create(widget.entity, values);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'The record could not be saved.');
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.entity.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.entity.icon, color: widget.entity.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _editing
                          ? 'Edit ${widget.entity.singularTitle}'
                          : 'Add ${widget.entity.singularTitle}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.entity.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: widget.entity.fields
                  .where((ErpField field) => !field.internal)
                  .map((ErpField field) => _field(field))
                  .toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
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
                label: Text(_editing ? 'Save changes' : 'Create record'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(ErpField field) {
    if (field.type == ErpFieldType.boolean) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(field.label),
          subtitle: field.helperText == null ? null : Text(field.helperText!),
          value: _booleans[field.key] ?? false,
          onChanged: field.readOnly
              ? null
              : (bool value) => setState(() => _booleans[field.key] = value),
        ),
      );
    }

    if (field.type == ErpFieldType.dropdown) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: _dropdowns[field.key],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
            prefixIcon: field.icon == null ? null : Icon(field.icon),
          ),
          items: field.options
              .map(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: field.readOnly
              ? null
              : (String? value) => setState(() => _dropdowns[field.key] = value),
          validator: (String? value) {
            if (field.required && (value == null || value.trim().isEmpty)) {
              return '${field.label} is required';
            }
            return null;
          },
        ),
      );
    }

    final controller = _controllers[field.key]!;
    final isDate = field.type == ErpFieldType.date;
    final multiline = field.type == ErpFieldType.multiline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: field.readOnly || isDate,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 6 : 1,
        keyboardType: _keyboardType(field.type),
        textInputAction: multiline ? TextInputAction.newline : TextInputAction.next,
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.helperText,
          prefixIcon: field.icon == null ? null : Icon(field.icon),
          suffixIcon: isDate ? const Icon(Icons.calendar_today_outlined) : null,
        ),
        onTap: isDate ? () => _pickDate(field, controller) : null,
        validator: (String? value) {
          final text = value?.trim() ?? '';
          if (field.required && text.isEmpty) {
            return '${field.label} is required';
          }
          if (text.isNotEmpty && field.type == ErpFieldType.email) {
            final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
            if (!valid) return 'Enter a valid email address';
          }
          if (text.isNotEmpty && field.type == ErpFieldType.integer) {
            if (int.tryParse(text) == null) return 'Enter a whole number';
          }
          if (text.isNotEmpty &&
              <ErpFieldType>{ErpFieldType.decimal, ErpFieldType.money}
                  .contains(field.type)) {
            if (double.tryParse(text.replaceAll(',', '')) == null) {
              return 'Enter a valid number';
            }
          }
          return null;
        },
      ),
    );
  }

  TextInputType _keyboardType(ErpFieldType type) {
    switch (type) {
      case ErpFieldType.email:
        return TextInputType.emailAddress;
      case ErpFieldType.phone:
        return TextInputType.phone;
      case ErpFieldType.integer:
        return TextInputType.number;
      case ErpFieldType.decimal:
      case ErpFieldType.money:
        return const TextInputType.numberWithOptions(decimal: true);
      case ErpFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _pickDate(
    ErpField field,
    TextEditingController controller,
  ) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      helpText: field.label,
    );
    if (selected != null) controller.text = _dateText(selected);
  }
}
