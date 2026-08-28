import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class JinnPage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final bool scrollable;
  final ScrollController? controller;

  const JinnPage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 1440,
    this.scrollable = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolvedPadding = padding ?? EdgeInsets.fromLTRB(
      width >= 1024 ? AppSpacing.desktopPage : AppSpacing.page,
      width >= 1024 ? 22 : 14,
      width >= 1024 ? AppSpacing.desktopPage : AppSpacing.page,
      width < 720 ? 28 : 36,
    );

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );

    if (!scrollable) return content;
    return SingleChildScrollView(controller: controller, child: content);
  }
}

class JinnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool shadow;

  const JinnCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.radius = AppRadius.card,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: dark
                      ? Colors.black.withOpacity(0.24)
                      : const Color(0xFF101B40).withOpacity(0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class JinnSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const JinnSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class JinnIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  const JinnIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? Color.alphaBlend(color.withOpacity(0.12), scheme.surface),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class JinnStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const JinnStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class JinnEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const JinnEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          JinnIconBadge(
            icon: icon,
            color: Theme.of(context).colorScheme.primary,
            background: Theme.of(context).colorScheme.primaryContainer,
            size: 58,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

class JinnSearchField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final TextEditingController? controller;
  final bool readOnly;

  const JinnSearchField({
    super.key,
    this.onChanged,
    this.onTap,
    this.hintText = 'Search students, teachers or documents...',
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: const Icon(Icons.tune_rounded, size: 18),
      ),
    );
  }
}

class JinnResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;

  const JinnResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 230,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final count = (constraints.maxWidth / minItemWidth).floor().clamp(1, 6).toInt();
        final width = (constraints.maxWidth - (count - 1) * spacing) / count;
        final height = childAspectRatio == null ? null : width / childAspectRatio!;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (Widget child) => SizedBox(
                  width: width,
                  height: height,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
