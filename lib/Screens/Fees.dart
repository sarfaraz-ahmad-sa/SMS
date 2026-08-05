import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../theme/app_theme.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  double _due = 15000;
  final List<_Payment> _history = <_Payment>[
    const _Payment('April 2026', 15000, 'Paid'),
    const _Payment('March 2026', 15000, 'Paid'),
    const _Payment('February 2026', 15000, 'Paid'),
  ];

  void _openPayForm() {
    final formKey = GlobalKey<FormState>();
    final amount = TextEditingController(text: _due.toStringAsFixed(0));
    String method = 'Card';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const JinnSectionHeader(title: 'Pay School Fees', subtitle: 'Choose the amount and payment method.'),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount (Rs.)', prefixIcon: Icon(Icons.payments_outlined)),
                        validator: (String? value) {
                          final number = double.tryParse(value ?? '');
                          if (number == null || number <= 0) return 'Enter a valid amount';
                          if (number > _due) return 'Amount exceeds outstanding balance';
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                      DropdownButtonFormField<String>(
                        value: method,
                        decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                        items: const <String>['Card', 'Bank Transfer', 'Easypaisa', 'JazzCash']
                            .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                            .toList(growable: false),
                        onChanged: (String? value) => setSheetState(() => method = value ?? method),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.lock_rounded, size: 18),
                          label: const Text('Pay Securely'),
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            final paid = double.parse(amount.text);
                            Navigator.pop(sheetContext);
                            setState(() {
                              _due -= paid;
                              _history.insert(0, _Payment('Today', paid, 'Paid'));
                            });
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Rs. ${paid.toStringAsFixed(0)} paid through $method.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Fees',
      activeRoute: '/modules',
      activeModuleId: 'fees',
      body: JinnPage(
        maxWidth: 1180,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final desktop = constraints.maxWidth >= 800;
            final overview = _FeeOverview(due: _due, onPay: _due <= 0 ? null : _openPayForm);
            final history = _PaymentHistory(history: _history);
            if (!desktop) {
              return Column(
                children: <Widget>[
                  overview,
                  const SizedBox(height: 15),
                  history,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 4, child: overview),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: history),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeeOverview extends StatelessWidget {
  final double due;
  final VoidCallback? onPay;
  const _FeeOverview({required this.due, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        JinnCard(
          color: AppColors.navigation,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  JinnIconBadge(icon: Icons.account_balance_wallet_rounded, color: AppColors.navigation, background: Colors.white, size: 48),
                  Spacer(),
                  JinnStatusPill(label: 'May 2026', color: Color(0xFF91E3BF)),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Outstanding Balance', style: TextStyle(color: Color(0xFFD9E2EA), fontSize: 12)),
              const SizedBox(height: 5),
              Text('Rs. ${due.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(due <= 0 ? 'All dues are cleared' : 'Due by 10 May 2026', style: const TextStyle(color: Color(0xFFD9E2EA), fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navigation),
                  onPressed: onPay,
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: Text(due <= 0 ? 'Paid in Full' : 'Pay Fees'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const JinnResponsiveGrid(
          minItemWidth: 135,
          childAspectRatio: 2.25,
          children: <Widget>[
            _FeeMetric('Monthly Fee', 'Rs. 15,000', Icons.calendar_month_rounded, AppColors.pastelBlue, Color(0xFF4E68D8)),
            _FeeMetric('Scholarship', 'Rs. 2,500', Icons.workspace_premium_rounded, AppColors.pastelGold, Color(0xFFD89614)),
          ],
        ),
      ],
    );
  }
}

class _FeeMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _FeeMetric(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final List<_Payment> history;
  const _PaymentHistory({required this.history});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const JinnSectionHeader(title: 'Payment History', subtitle: 'Recent fee transactions and receipts.'),
          const SizedBox(height: 13),
          ...history.map(( _Payment item) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const JinnIconBadge(icon: Icons.receipt_long_rounded, color: AppColors.success, background: AppColors.pastelGreen, size: 42),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Rs. ${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(item.period, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    JinnStatusPill(label: item.status, color: AppColors.success),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Payment {
  final String period;
  final double amount;
  final String status;
  const _Payment(this.period, this.amount, this.status);
}
