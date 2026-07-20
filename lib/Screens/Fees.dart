import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({Key? key}) : super(key: key);

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  double _due = 15000;
  final List<List<String>> _history = [
    ['Apr 2026', 'Rs. 15,000', 'Paid'],
    ['Mar 2026', 'Rs. 15,000', 'Paid'],
    ['Feb 2026', 'Rs. 15,000', 'Paid'],
  ];

  void _openPayForm() {
    final formKey = GlobalKey<FormState>();
    final amount = TextEditingController(text: _due.toStringAsFixed(0));
    String method = 'Card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pay Fees',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Rs.)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        if (n > _due) return 'Amount exceeds due (Rs. ${_due.toStringAsFixed(0)})';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: const ['Card', 'Bank Transfer', 'Easypaisa', 'JazzCash']
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setSheet(() => method = v ?? 'Card'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final paid = double.parse(amount.text);
                          Navigator.pop(ctx);
                          setState(() {
                            _due -= paid;
                            _history.insert(0, [
                              'Now',
                              'Rs. ${paid.toStringAsFixed(0)}',
                              'Paid'
                            ]);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Payment of Rs. ${paid.toStringAsFixed(0)} via $method successful'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                Text('Outstanding Balance',
                    style: TextStyle(color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${_due.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_due <= 0 ? 'All dues cleared' : 'Due by 10th of this month',
                    style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _due <= 0 ? null : _openPayForm,
              icon: const Icon(Icons.payment),
              label: const Text('Pay Fees'),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Payment History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._history.map((h) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A22C55E),
                    child: Icon(Icons.check, color: AppColors.success),
                  ),
                  title: Text(h[1],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(h[0]),
                  trailing: Text(h[2],
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }
}
