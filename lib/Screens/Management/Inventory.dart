import 'package:flutter/material.dart';

import '../../core/erp/erp_catalog.dart';
import '../Enterprise/ErpModuleScreen.dart';

/// Compatibility route backed by the tenant-scoped Inventory ERP module.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpModuleScreen(
      module: ErpCatalog.moduleForCollection('inventory_items')!,
    );
  }
}
