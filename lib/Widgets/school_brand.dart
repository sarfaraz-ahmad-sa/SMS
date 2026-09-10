import 'package:school_management/config/brand_config.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SchoolBrandMark extends StatelessWidget {
  const SchoolBrandMark({
    super.key,
    this.size = 44,
    this.logoUrl,
    this.borderColor,
    this.elevation = true,
  });

  final double size;
  final String? logoUrl;
  final Color? borderColor;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.245;
    final fallback = CustomPaint(
      size: Size.square(size),
      painter: const _SchoolMarkPainter(),
    );
    final trimmedLogoUrl = logoUrl?.trim() ?? BrandConfig.logoUrl;

    return Semantics(
      image: true,
      label: trimmedLogoUrl.isEmpty ? 'School logo' : 'School logo',
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.16),
          ),
          boxShadow: elevation
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x260B1636),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: trimmedLogoUrl.isEmpty
            ? fallback
            : Image.network(
                trimmedLogoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _SchoolMarkPainter extends CustomPainter {
  const _SchoolMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1024;
    canvas.scale(scale, scale);

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF4F46E5),
          Color(0xFF243B82),
          Color(0xFF101B40),
        ],
        stops: <double>[0, 0.52, 1],
      ).createShader(const Rect.fromLTWH(0, 0, 1024, 1024));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        const Radius.circular(232),
      ),
      background,
    );

    canvas.drawCircle(
      const Offset(512, 502),
      322,
      Paint()..color = Colors.white.withOpacity(0.055),
    );

    final cap = Path()
      ..moveTo(212, 374)
      ..lineTo(512, 226)
      ..lineTo(812, 374)
      ..lineTo(512, 522)
      ..close();
    canvas.drawPath(cap, Paint()..color = Colors.white);

    final capBand = Path()
      ..moveTo(512, 522)
      ..lineTo(288, 411)
      ..lineTo(288, 496)
      ..lineTo(512, 607)
      ..lineTo(736, 496)
      ..lineTo(736, 411)
      ..close();
    canvas.drawPath(capBand, Paint()..color = const Color(0xFFC7D2FE));

    final leftPage = Path()
      ..moveTo(284, 536)
      ..cubicTo(368, 539, 439, 568, 490, 622)
      ..lineTo(490, 805)
      ..cubicTo(432, 757, 362, 733, 284, 733)
      ..close();
    final rightPage = Path()
      ..moveTo(740, 536)
      ..cubicTo(656, 539, 585, 568, 534, 622)
      ..lineTo(534, 805)
      ..cubicTo(592, 757, 662, 733, 740, 733)
      ..close();
    final white = Paint()..color = Colors.white;
    canvas.drawPath(leftPage, white);
    canvas.drawPath(rightPage, white);

    canvas.drawLine(
      const Offset(512, 622),
      const Offset(512, 805),
      Paint()
        ..color = const Color(0xFFA5B4FC)
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(758, 401),
      const Offset(758, 559),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF5EEAD4), Color(0xFF10B981)],
        ).createShader(const Rect.fromLTWH(744, 401, 28, 158))
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(758, 596),
      42,
      Paint()..color = const Color(0xFFFBBF24),
    );
  }

  @override
  bool shouldRepaint(covariant _SchoolMarkPainter oldDelegate) => false;
}

class SchoolBrandLockup extends StatelessWidget {
  const SchoolBrandLockup({
    super.key,
    this.schoolName = BrandConfig.companyName,
    this.subtitle = 'SMART CAMPUS ERP',
    this.logoUrl,
    this.light = false,
    this.markSize = 42,
    this.compact = false,
  });

  final String schoolName;
  final String subtitle;
  final String? logoUrl;
  final bool light;
  final double markSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryText = light
        ? AppColors.navigationText
        : Theme.of(context).colorScheme.onSurface;
    final secondaryText = light
        ? AppColors.navigationMuted
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SchoolBrandMark(
          size: markSize,
          logoUrl: logoUrl,
          elevation: !compact,
        ),
        if (!compact) ...<Widget>[
          const SizedBox(width: 11),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.72,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
