import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Txn {
  String title;
  double amount;
  bool income;
  String date;
  _Txn(this.title, this.amount, this.income, this.date);
}

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({Key? key}) : super(key: key);

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final _txns = <_Txn>[
    _Txn('Fee Collection', 936000, true, 'Apr 2026'),
    _Txn('Staff Salaries', 520000, false, 'Apr 2026'),
    _Txn('Utility Bills', 85000, false, 'Apr 2026'),
    _Txn('Donation', 150000, true, 'Apr 2026'),
  ];

  double get _income =>
      _txns.where((t) => t.income).fold(0.0, (s, t) => s + t.amount);
  double get _expense =>
      _txns.where((t) => !t.income).fold(0.0, (s, t) => s + t.amount);

  void _add() {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final amount = TextEditingController();
    bool income = true;

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
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Transaction',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Income')),
                    ButtonSegment(value: false, label: Text('Expense')),
                  ],
                  selected: {income},
                  onSelectionChanged: (s) =>
                      setSheet(() => income = s.first),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                      labelText: 'Title', prefixIcon: Icon(Icons.title)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                      prefixIcon: Icon(Icons.currency_rupee)),
                  validator: (v) => (double.tryParse(v ?? '') == null)
                      ? 'Enter a valid amount'
                      : null,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _txns.insert(
                          0,
                          _Txn(title.text, double.parse(amount.text), income,
                              'Now')));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
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
    final balance = _income - _expense;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounting')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Balance',
                    style: TextStyle(color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 6),
                Text('Rs. ${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _stat('Income', _income, AppColors.success,
                      Icons.arrow_downward)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stat('Expense', _expense, AppColors.danger,
                      Icons.arrow_upward)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._txns.map((t) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (t.income ? AppColors.success : AppColors.danger)
                            .withOpacity(0.12),
                    child: Icon(
                        t.income
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color:
                            t.income ? AppColors.success : AppColors.danger),
                  ),
                  title: Text(t.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(t.date),
                  trailing: Text(
                    '${t.income ? '+' : '-'} Rs. ${t.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color:
                            t.income ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text('Rs. ${value.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
