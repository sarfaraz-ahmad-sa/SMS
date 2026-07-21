import 'package:flutter/material.dart';

enum ErpFieldType {
  text,
  multiline,
  email,
  phone,
  integer,
  decimal,
  money,
  date,
  dropdown,
  boolean,
}

class ErpField {
  final String key;
  final String label;
  final ErpFieldType type;
  final bool required;
  final bool showInList;
  final bool searchable;
  final bool readOnly;
  final bool internal;
  final List<String> options;
  final String? helperText;
  final dynamic defaultValue;
  final IconData? icon;

  const ErpField({
    required this.key,
    required this.label,
    this.type = ErpFieldType.text,
    this.required = false,
    this.showInList = false,
    this.searchable = false,
    this.readOnly = false,
    this.internal = false,
    this.options = const <String>[],
    this.helperText,
    this.defaultValue,
    this.icon,
  });
}
