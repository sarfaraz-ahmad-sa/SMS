import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Employee {
  String name;
  String designation;
  double salary;
  String status; // Present / On Leave
  _Employee(this.name, this.designation, this.salary, {this.status = 'Present'});
}

class HRScreen extends StatefulWidget {
  const HRScreen({Key? key}) : super(key: key);

  @override
  State<HRScreen> createState() => _HRScreenState();
}

class _HRScreenState extends State<HRScreen> {
  final _employees = <_Employee>[
    _Employee('Mr. Khan', 'Senior Teacher', 85000),
    _Employee('Ms. Ali', 'Teacher', 65000),
    _Employee('Mr. Aslam', 'Driver', 35000, status: 'On Leave'),
    _Employee('Ms. Nadia', 'Receptionist', 40000),
    _Employee('Mr. Bilal', 'IT Admin', 90000),
  ];

  void _addEmployee() {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final desig = TextEditingController();
    final salary = TextEditingController();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Employee',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _tf(name, 'Full Name', Icons.person_outline),
              _tf(desig, 'Designation', Icons.work_outline),
              _tf(salary, 'Monthly Salary (Rs.)', Icons.payments_outlined,
                  type: TextInputType.number, isNumber: true),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => _employees.add(_Employee(
                        name.text, desig.text, double.parse(salary.text))));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salarySlip(_Employee e) {
    final basic = e.salary;
    final allowance = basic * 0.15;
    final tax = basic * 0.05;
    final net = basic + allowance - tax;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Salary Slip · ${e.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Designation', e.designation),
            _row('Basic', 'Rs. ${basic.toStringAsFixed(0)}'),
            _row('Allowance (15%)', 'Rs. ${allowance.toStringAsFixed(0)}'),
            _row('Tax (5%)', '- Rs. ${tax.toStringAsFixed(0)}'),
            const Divider(),
            _row('Net Pay', 'Rs. ${net.toStringAsFixed(0)}', bold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onLeave = _employees.where((e) => e.status == 'On Leave').length;
    return Scaffold(
      appBar: AppBar(title: const Text('HR & Payroll')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEmployee,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Employee'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Row(
            children: [
              Expanded(
                  child: _summary('Employees', '${_employees.length}',
                      AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _summary('On Leave', '$onLeave', AppColors.warning)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Staff',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._employees.map((e) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withOpacity(0.12),
                    child: Text(e.name[0],
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(e.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('${e.designation} · Rs. ${e.salary.toStringAsFixed(0)}/mo'),
                  trailing: IconButton(
                    icon: const Icon(Icons.receipt_long_outlined),
                    tooltip: 'Salary Slip',
                    onPressed: () => _salarySlip(e),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _summary(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter $label';
          if (isNumber && double.tryParse(v) == null) return 'Enter a number';
          return null;
        },
      ),
    );
  }
}
