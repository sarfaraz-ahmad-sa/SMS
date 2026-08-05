import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../theme/app_theme.dart';

class _Room {
  final String number;
  final String block;
  final int capacity;
  int occupied;
  _Room(this.number, this.block, this.capacity, this.occupied);
}

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final List<_Room> _rooms = <_Room>[
    _Room('A-101', 'Boys Block A', 4, 4),
    _Room('A-102', 'Boys Block A', 4, 2),
    _Room('B-201', 'Girls Block B', 6, 5),
    _Room('B-202', 'Girls Block B', 6, 3),
    _Room('C-301', 'Junior Block', 2, 0),
  ];

  int get _capacity => _rooms.fold<int>(0, (int total, _Room room) => total + room.capacity);
  int get _occupied => _rooms.fold<int>(0, (int total, _Room room) => total + room.occupied);

  void _allocate(_Room room) {
    if (room.occupied >= room.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This room is already full.')));
      return;
    }
    setState(() => room.occupied++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bed allocated in room ${room.number}.')));
  }

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Hostel',
      activeRoute: '/modules',
      activeModuleId: 'hostel',
      body: JinnPage(
        maxWidth: 1220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            JinnResponsiveGrid(
              minItemWidth: 180,
              childAspectRatio: 2.35,
              children: <Widget>[
                _HostelMetric('Total Beds', '$_capacity', Icons.bed_rounded, AppColors.pastelBlue, const Color(0xFF4E68D8)),
                _HostelMetric('Occupied', '$_occupied', Icons.groups_rounded, AppColors.pastelGold, const Color(0xFFD89614)),
                _HostelMetric('Vacant', '${_capacity - _occupied}', Icons.meeting_room_rounded, AppColors.pastelGreen, const Color(0xFF27936B)),
                const _HostelMetric('Wardens', '6', Icons.admin_panel_settings_rounded, AppColors.pastelPurple, Color(0xFF7B5DC7)),
              ],
            ),
            const SizedBox(height: 20),
            const JinnSectionHeader(
              title: 'Rooms & Occupancy',
              subtitle: 'Review capacity and allocate available beds.',
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 720;
                final cards = _rooms.map(( _Room room) => _RoomCard(room: room, onAllocate: () => _allocate(room))).toList(growable: false);
                if (compact) {
                  return Column(
                    children: cards.map((Widget card) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card)).toList(growable: false),
                  );
                }
                return JinnResponsiveGrid(minItemWidth: 340, children: cards);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HostelMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _HostelMetric(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 42),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _Room room;
  final VoidCallback onAllocate;
  const _RoomCard({required this.room, required this.onAllocate});

  @override
  Widget build(BuildContext context) {
    final full = room.occupied >= room.capacity;
    final occupancy = room.capacity == 0 ? 0.0 : room.occupied / room.capacity;
    return JinnCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              JinnIconBadge(
                icon: Icons.meeting_room_outlined,
                color: full ? AppColors.danger : AppColors.success,
                background: full ? AppColors.pastelRose : AppColors.pastelGreen,
                size: 46,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Room ${room.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(room.block, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              JinnStatusPill(label: full ? 'Full' : 'Available', color: full ? AppColors.danger : AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 7,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(full ? AppColors.danger : AppColors.success),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(child: Text('${room.occupied} of ${room.capacity} beds occupied', style: Theme.of(context).textTheme.bodySmall)),
              TextButton(onPressed: full ? null : onAllocate, child: Text(full ? 'Full' : 'Allocate')),
            ],
          ),
        ],
      ),
    );
  }
}
