import 'package:flutter/material.dart';

import '../../core/erp/erp_catalog.dart';
import '../Enterprise/ErpEntityListScreen.dart';

/// Compatibility route for older navigation links.
///
/// Teacher records are backed by the tenant-scoped `teachers` Firestore
/// collection through the shared ERP service.
class TeacherManagementScreen extends StatelessWidget {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpEntityListScreen(
      entity: ErpCatalog.entityByCollection('teachers')!,
    );
  }
}
