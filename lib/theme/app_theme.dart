import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/models/tenant.dart';

class AppColors {
  AppColors._();

  // Premium education-SaaS palette: confident indigo, calm emerald and
  // high-contrast navy. Tenant branding is blended into this foundation.
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF312E81);
  static const Color secondary = Color(0xFF0F9F75);
  static const Color accent = Color(0xFF2563EB);
  static const Color navigation = Color(0xFF172554);
  static const Color navigationRaised = Color(0xFF1E3270);
  static const Color navigationText = Color(0xFFF8FAFF);
  static const Color navigationMuted = Color(0xFFB8C5E0);
  static const Color navigationActive = Color(0xFFF0F4FF);

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFD);
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  static const Color darkBackground = Color(0xFF080F1D);
  static const Color darkSurface = Color(0xFF111B2E);
  static const Color darkSurfaceRaised = Color(0xFF1A2740);
  static const Color darkTextPrimary = Color(0xFFF1F5FF);
  static const Color darkTextSecondary = Color(0xFFA9B7CC);
  static const Color darkBorder = Color(0xFF263652);

  static const Color pastelBlue = Color(0xFFEEF2FF);
  static const Color pastelCyan = Color(0xFFECFEFF);
  static const Color pastelGold = Color(0xFFFFF7E6);
  static const Color pastelRose = Color(0xFFFEF2F2);
  static const Color pastelGreen = Color(0xFFECFDF5);
  static const Color pastelPurple = Color(0xFFF5F3FF);

  // Kept for compatibility with existing authentication/branding widgets.
  // It is intentionally subtle and never used as a glassmorphism background.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, primaryDark],
  );

  static const LinearGradient navigationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[navigationRaised, navigation, Color(0xFF101B40)],
    stops: <double>[0, 0.48, 1],
  );

  static Color tenantPrimary(Tenant? tenant) {
    final raw = tenant?.brandColor;
    if (raw == null) return primary;
    final value = raw <= 0xFFFFFF ? 0xFF000000 | raw : raw;
    final tenantColor = Color(value);
    // Blend tenant branding into the reference palette so contrast and visual
    // consistency remain predictable across schools.
    return Color.lerp(primary, tenantColor, 0.38) ?? primary;
  }

  static LinearGradient tenantGradient(Tenant? tenant) {
    final color = tenantPrimary(tenant);
    final darker = Color.lerp(color, primaryDark, 0.48) ?? primaryDark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[color, darker],
    );
  }
}

class AppSpacing {
  AppSpacing._();

  static const double page = 16;
  static const double desktopPage = 24;
  static const double section = 24;
  static const double card = 16;
}

class AppRadius {
  AppRadius._();

  static const double control = 12;
  static const double card = 16;
  static const double hero = 22;
  static const double sheet = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => lightFor(null);
  static ThemeData get dark => darkFor(null);

  static ThemeData lightFor(Tenant? tenant) {
    final primary = AppColors.tenantPrimary(tenant);
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.pastelBlue,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.pastelGreen,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.pastelPurple,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.pastelRose,
      onErrorContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: const Color(0x140F2740),
      scrim: const Color(0x80101B40),
      inverseSurface: AppColors.navigation,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFC7D2FE),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // InkRipple is substantially cheaper to paint on lower-end Android
      // devices and Flutter web while preserving Material touch feedback.
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.8,
        shadowColor: const Color(0x140F1D3A),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: Color(0xFFDDE5F0)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.navigation,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.navigationActive,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.navigation),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: const IconThemeData(color: Color(0xFFCFD9E2)),
        unselectedLabelTextStyle: const TextStyle(color: Color(0xFFCFD9E2), fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.pastelBlue,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return TextStyle(
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : AppColors.textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: primary.withOpacity(0.25),
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 5,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        minLeadingWidth: 30,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
        shape: Border(),
        collapsedShape: Border(),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.pastelBlue,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: primary,
        dividerColor: AppColors.border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x290F1D3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
        headingTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.25,
        ),
        dataTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
        dividerThickness: 1,
        horizontalMargin: 18,
        columnSpacing: 24,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 5,
        shadowColor: const Color(0x1F0F1D3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF172033),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(99),
        thickness: WidgetStateProperty.resolveWith<double?>((states) => states.contains(WidgetState.hovered) ? 7 : 4),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) =>
            primary.withOpacity(states.contains(WidgetState.hovered) ? 0.55 : 0.25)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) =>
            states.contains(WidgetState.selected) ? primary : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) =>
            states.contains(WidgetState.selected) ? primary : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.navigation, borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData darkFor(Tenant? tenant) {
    final primary = Color.lerp(AppColors.tenantPrimary(tenant), Colors.white, 0.18) ?? AppColors.primary;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF252A66),
      onPrimaryContainer: AppColors.darkTextPrimary,
      secondary: const Color(0xFF38CFA0),
      onSecondary: const Color(0xFF042E23),
      secondaryContainer: const Color(0xFF103D33),
      onSecondaryContainer: const Color(0xFFB7F7E2),
      tertiary: const Color(0xFF7BA7FF),
      onTertiary: const Color(0xFF071F49),
      tertiaryContainer: const Color(0xFF1C3767),
      onTertiaryContainer: const Color(0xFFD8E5FF),
      error: const Color(0xFFFF6B73),
      onError: const Color(0xFF4A0007),
      errorContainer: const Color(0xFF5B171D),
      onErrorContainer: const Color(0xFFFFDADC),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceRaised,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      shadow: Colors.black,
      scrim: const Color(0xB3000000),
      inverseSurface: AppColors.darkTextPrimary,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.primaryDark,
    );
    final base = lightFor(tenant);
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(base.textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.8,
        shadowColor: const Color(0x66000000),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurfaceRaised,
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF8190A8), fontSize: 13),
        prefixIconColor: AppColors.darkTextSecondary,
        suffixIconColor: AppColors.darkTextSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.navigation, surfaceTintColor: Colors.transparent),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: const Color(0xFF252A66),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) => TextStyle(
          fontSize: 10.5,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? primary : AppColors.darkTextSecondary,
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkTextSecondary,
        textColor: AppColors.darkTextPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        minLeadingWidth: 30,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.control))),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.darkSurfaceRaised,
        selectedColor: const Color(0xFF252A66),
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: primary,
        dividerColor: AppColors.darkBorder,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x99000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.darkSurfaceRaised),
        headingTextStyle: const TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w800, fontSize: 11.5),
        dataTextStyle: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12.5),
        dividerThickness: 1,
        horizontalMargin: 18,
        columnSpacing: 24,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppColors.darkSurfaceRaised,
        contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: const Color(0x99000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(99),
        thickness: WidgetStateProperty.resolveWith<double?>((states) => states.contains(WidgetState.hovered) ? 7 : 4),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) =>
            primary.withOpacity(states.contains(WidgetState.hovered) ? 0.62 : 0.34)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.darkSurfaceRaised, borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color foreground, Color secondary) {
    return base.apply(bodyColor: foreground, displayColor: foreground).copyWith(
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.35),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      bodySmall: base.bodySmall?.copyWith(color: secondary, height: 1.35),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
