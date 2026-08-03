import 'package:flutter/material.dart';

import '../../core/erp/erp_catalog.dart';
import '../Enterprise/ErpModuleScreen.dart';

/// Compatibility route backed by the tenant-scoped Accounting ERP module.
class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpModuleScreen(
      module: ErpCatalog.moduleForCollection('chart_of_accounts')!,
    );
  }
}
