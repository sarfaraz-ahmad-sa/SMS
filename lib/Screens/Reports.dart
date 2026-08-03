import 'package:flutter/material.dart';

import '../core/erp/erp_catalog.dart';
import 'Enterprise/ErpModuleScreen.dart';

/// Compatibility route backed by the tenant-scoped Reports & Analytics module.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpModuleScreen(module: ErpCatalog.byId('reports')!);
  }
}
