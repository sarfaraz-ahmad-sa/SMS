import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Item {
  String name;
  String category;
  int qty;
  int reorder;
  _Item(this.name, this.category, this.qty, this.reorder);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _items = <_Item>[
    _Item('A4 Paper (ream)', 'Stationery', 40, 20),
    _Item('Whiteboard Markers', 'Stationery', 12, 25),
    _Item('Desktops', 'Assets', 60, 10),
    _Item('Projectors', 'Assets', 8, 5),
    _Item('First-Aid Kits', 'Medical', 4, 10),
  ];

  void _add() {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final cat = TextEditingController(text: 'Stationery');
    final qty = TextEditingController();
    final reorder = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Stock Item',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _tf(name, 'Item Name', Icons.inventory_2_outlined),
                _tf(cat, 'Category', Icons.category_outlined),
                Row(children: [
                  Expanded(
                      child: _tf(qty, 'Quantity', Icons.numbers,
                          isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _tf(reorder, 'Reorder at', Icons.warning_amber,
                          isNumber: true)),
                ]),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _items.add(_Item(
                          name.text,
                          cat.text,
                          int.parse(qty.text),
                          int.parse(reorder.text))));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final low = _items.where((i) => i.qty <= i.reorder).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (low > 0)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$low item(s) below reorder level',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ..._items.map((i) {
            final lowStock = i.qty <= i.reorder;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary),
                ),
                title: Text(i.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(i.category),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${i.qty}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: lowStock
                                ? AppColors.danger
                                : AppColors.textPrimary)),
                    Text(lowStock ? 'Low' : 'In stock',
                        style: TextStyle(
                            fontSize: 11,
                            color: lowStock
                                ? AppColors.danger
                                : Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter $label';
          if (isNumber && int.tryParse(v) == null) return 'Number only';
          return null;
        },
      ),
    );
  }
}
