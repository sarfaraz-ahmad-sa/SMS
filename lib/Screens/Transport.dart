import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../theme/app_theme.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  static const List<_Stop> _stops = <_Stop>[
    _Stop('Depot', '07:00 AM', true),
    _Stop('Green Town', '07:15 AM', true),
    _Stop('Main Boulevard', '07:30 AM', true),
    _Stop('City Center', '07:45 AM', false),
    _Stop('School', '08:00 AM', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Transport',
      activeRoute: '/modules',
      activeModuleId: 'transport',
      body: JinnPage(
        maxWidth: 1120,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final desktop = constraints.maxWidth >= 820;
            final routeCard = _RouteCard();
            final stopsCard = _StopsCard(stops: _stops);
            if (!desktop) {
              return Column(
                children: <Widget>[
                  routeCard,
                  const SizedBox(height: 14),
                  stopsCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 4, child: routeCard),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: stopsCard),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        JinnCard(
          padding: const EdgeInsets.all(18),
          color: AppColors.navigation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  JinnIconBadge(
                    icon: Icons.directions_bus_rounded,
                    color: AppColors.navigation,
                    background: Colors.white,
                    size: 52,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Route 4 · Bus LEB-1234', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Driver: Mr. Aslam', style: TextStyle(color: Color(0xFFD9E2EA), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.location_on_rounded, color: Color(0xFF91E3BF), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Near Main Boulevard · ETA 12 min', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        JinnResponsiveGrid(
          minItemWidth: 130,
          childAspectRatio: 2.2,
          children: const <Widget>[
            _RouteMetric('Next stop', 'City Center', Icons.flag_rounded, AppColors.pastelGold, Color(0xFFD89614)),
            _RouteMetric('Students', '28 onboard', Icons.groups_rounded, AppColors.pastelBlue, Color(0xFF4E68D8)),
          ],
        ),
      ],
    );
  }
}

class _RouteMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _RouteMetric(this.label, this.value, this.icon, this.background, this.foreground);

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
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsCard extends StatelessWidget {
  final List<_Stop> stops;
  const _StopsCard({required this.stops});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const JinnSectionHeader(title: 'Route Stops', subtitle: 'Live trip progress for today.'),
          const SizedBox(height: 14),
          ...List<Widget>.generate(stops.length, (int index) {
            final stop = stops[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: stop.completed ? AppColors.success : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: stop.completed ? AppColors.success : AppColors.border, width: 2),
                      ),
                      child: Icon(stop.completed ? Icons.check_rounded : Icons.circle, size: stop.completed ? 14 : 7, color: stop.completed ? Colors.white : AppColors.textSecondary),
                    ),
                    if (index != stops.length - 1)
                      Container(width: 2, height: 34, color: stop.completed ? AppColors.success.withOpacity(0.35) : AppColors.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(stop.time, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Stop {
  final String name;
  final String time;
  final bool completed;
  const _Stop(this.name, this.time, this.completed);
}
