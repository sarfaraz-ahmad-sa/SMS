import 'package:flutter/material.dart';

import '../services/session_state.dart';
import '../theme/app_theme.dart';

class UserDetailCard extends StatelessWidget {
  const UserDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final user = state.user;
    final scheme = Theme.of(context).colorScheme;
    final displayName = user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'School user';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();

    return Semantics(
      container: true,
      label: '$name, ${user?.roleLabel ?? 'school user'}',
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 3),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primary,
              Color.lerp(scheme.primary, AppColors.navigation, 0.62)!,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.hero),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.16),
              foregroundColor: Colors.white,
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user?.roleLabel ?? 'School user',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.tenant?.name ?? 'SEEF School ERP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open profile',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
