import 'package:flutter/material.dart';

/// Backwards-compatible app bar for older screens. Newer ERP screens use
/// SaasScaffold, but this widget follows the same Material 3 theme.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool menuenabled;
  final bool notificationenabled;
  final VoidCallback? ontap;

  const CommonAppBar({
    super.key,
    required this.title,
    required this.menuenabled,
    required this.notificationenabled,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: menuenabled
          ? IconButton(
              tooltip: 'Open menu',
              onPressed: ontap,
              icon: const Icon(Icons.menu_rounded),
            )
          : null,
      actions: <Widget>[
        if (notificationenabled)
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: Badge(
              backgroundColor: scheme.error,
              smallSize: 7,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68);
}
