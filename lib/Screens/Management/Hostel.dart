import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Room {
  String number;
  int capacity;
  int occupied;
  _Room(this.number, this.capacity, this.occupied);
}

class HostelScreen extends StatefulWidget {
  const HostelScreen({Key? key}) : super(key: key);

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final _rooms = <_Room>[
    _Room('A-101', 4, 4),
    _Room('A-102', 4, 2),
    _Room('B-201', 6, 5),
    _Room('B-202', 6, 3),
    _Room('C-301', 2, 0),
  ];

  int get _capacity => _rooms.fold(0, (s, r) => s + r.capacity);
  int get _occupied => _rooms.fold(0, (s, r) => s + r.occupied);

  void _allocate(_Room r) {
    if (r.occupied >= r.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Room is full'),
            backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => r.occupied++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Bed allocated in ${r.number}'),
          backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hostel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                  child: _stat('Total Beds', '$_capacity', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stat('Occupied', '$_occupied', AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stat('Vacant', '${_capacity - _occupied}',
                      AppColors.success)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Rooms',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._rooms.map((r) {
            final full = r.occupied >= r.capacity;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (full ? AppColors.danger : AppColors.success)
                      .withOpacity(0.12),
                  child: Icon(Icons.meeting_room_outlined,
                      color: full ? AppColors.danger : AppColors.success),
                ),
                title: Text('Room ${r.number}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${r.occupied}/${r.capacity} beds occupied'),
                trailing: TextButton(
                  onPressed: full ? null : () => _allocate(r),
                  child: Text(full ? 'Full' : 'Allocate'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
