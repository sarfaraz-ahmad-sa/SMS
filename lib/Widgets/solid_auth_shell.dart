import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'jinn_ui.dart';
import 'school_brand.dart';

class SolidAuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final double maxWidth;
  final String? eyebrow;
  final Widget? footer;
  final bool showBack;

  const SolidAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.maxWidth = 520,
    this.eyebrow,
    this.footer,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final desktop = constraints.maxWidth >= 920;
            if (desktop) {
              return Row(
                children: <Widget>[
                  const Expanded(flex: 5, child: _AuthBrandPanel()),
                  Expanded(
                    flex: 6,
                    child: _AuthFormArea(
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      maxWidth: maxWidth,
                      eyebrow: eyebrow,
                      footer: footer,
                      showBack: showBack,
                      child: child,
                    ),
                  ),
                ],
              );
            }
            return _AuthFormArea(
              title: title,
              subtitle: subtitle,
              icon: icon,
              maxWidth: maxWidth,
              eyebrow: eyebrow,
              footer: footer,
              showBack: showBack,
              compact: true,
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.navigationGradient,
      ),
      padding: const EdgeInsets.all(52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SchoolBrandLockup(light: true),
          const Spacer(),
          const Text(
            'One school.\nOne connected workspace.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Admissions, academics, fees, communication and operations—designed for every screen.',
            style: TextStyle(color: Color(0xFFD9E2EA), height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _FeatureChip(Icons.verified_user_outlined, 'Secure access'),
              _FeatureChip(Icons.devices_rounded, 'Mobile + web'),
              _FeatureChip(Icons.school_outlined, 'School focused'),
            ],
          ),
          const Spacer(),
          Text('SEEF School ERP', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _AuthFormArea extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final double maxWidth;
  final String? eyebrow;
  final Widget? footer;
  final bool showBack;
  final bool compact;

  const _AuthFormArea({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.maxWidth,
    required this.eyebrow,
    required this.footer,
    required this.showBack,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: <Widget>[
        if (compact)
          Positioned(
            left: 20,
            top: 18,
            child: SchoolBrandLockup(
              markSize: 38,
              subtitle: 'SMART CAMPUS ERP',
            ),
          ),
        if (showBack && Navigator.canPop(context))
          Positioned(
            right: compact ? 14 : 22,
            top: compact ? 12 : 20,
            child: IconButton.filledTonal(
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(compact ? 18 : 40, compact ? 84 : 34, compact ? 18 : 40, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: JinnCard(
                padding: EdgeInsets.all(compact ? 22 : 30),
                shadow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: JinnIconBadge(
                        icon: icon,
                        color: theme.colorScheme.primary,
                        background: theme.colorScheme.primaryContainer,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (eyebrow != null) ...<Widget>[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: compact ? 23 : 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
                    const SizedBox(height: 24),
                    child,
                    if (footer != null) ...<Widget>[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF91E3BF), size: 16),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
