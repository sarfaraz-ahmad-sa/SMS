import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({Key? key}) : super(key: key);

  static const _stops = [
    ['Depot', '07:00 AM', true],
    ['Green Town', '07:15 AM', true],
    ['Main Boulevard', '07:30 AM', true],
    ['City Center', '07:45 AM', false],
    ['School', '08:00 AM', false],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0x1AF97316),
                    child: Icon(Icons.directions_bus,
                        color: Color(0xFFF97316), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Route 4 · Bus LEB-1234',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Driver: Mr. Aslam · +92 300 1234567'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.location_on, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Bus is currently near Main Boulevard · ETA 12 min',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Stops',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(_stops.length, (i) {
            final s = _stops[i];
            final done = s[2] as bool;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? AppColors.success : Colors.grey,
              ),
              title: Text(s[0] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text(s[1] as String,
                  style: TextStyle(color: Colors.grey.shade600)),
            );
          }),
        ],
      ),
    );
  }
}
