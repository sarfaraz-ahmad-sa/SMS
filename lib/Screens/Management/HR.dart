import 'package:flutter/material.dart';

import '../../core/erp/erp_catalog.dart';
import '../Enterprise/ErpModuleScreen.dart';

/// Compatibility route backed by the tenant-scoped HR/Payroll ERP module.
class HRScreen extends StatelessWidget {
  const HRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpModuleScreen(
      module: ErpCatalog.moduleForCollection('employees')!,
    );
  }
}
