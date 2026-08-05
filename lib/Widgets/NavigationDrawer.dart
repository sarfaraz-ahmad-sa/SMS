import 'package:flutter/material.dart';

import 'MainDrawer.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: MainDrawer(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
