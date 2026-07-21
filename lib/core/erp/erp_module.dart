import 'package:flutter/material.dart';

import 'erp_entity.dart';

class ErpModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String viewPermission;
  final String managePermission;
  final List<ErpEntity> entities;
  final int priority;

  bool isVisibleFor(bool Function(String permission) hasPermission) {
    return hasPermission(viewPermission) ||
        entities.any((ErpEntity entity) => hasPermission(entity.viewPermission));
  }

  const ErpModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.viewPermission,
    required this.managePermission,
    required this.entities,
    this.priority = 100,
  });
}
