import 'package:flutter/material.dart';

import 'erp_field.dart';

class ErpEntity {
  final String id;
  final String title;
  final String singularTitle;
  final String collection;
  final String description;
  final IconData icon;
  final Color color;
  final String viewPermission;
  final String managePermission;
  final List<ErpField> fields;
  final String primaryField;
  final String? secondaryField;
  final String? statusField;
  final List<Map<String, dynamic>> demoRecords;
  final bool allowSelfServiceCreate;
  final String? selfServicePermission;

  const ErpEntity({
    required this.id,
    required this.title,
    required this.singularTitle,
    required this.collection,
    required this.description,
    required this.icon,
    required this.color,
    required this.viewPermission,
    required this.managePermission,
    required this.fields,
    required this.primaryField,
    this.secondaryField,
    this.statusField,
    this.demoRecords = const <Map<String, dynamic>>[],
    this.allowSelfServiceCreate = false,
    this.selfServicePermission,
  });

  List<ErpField> get listFields {
    final explicit = fields
        .where((ErpField field) => field.showInList && !field.internal)
        .toList();
    if (explicit.isNotEmpty) return explicit;
    return fields.where((ErpField field) => !field.internal).take(4).toList();
  }

  List<ErpField> get searchableFields =>
      fields
          .where((ErpField field) => field.searchable && !field.internal)
          .toList();
}
