import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/models/tenant.dart';

class AppColors {
  AppColors._();

  // Solid school-app palette based on the supplied references.
  static const Color primary = Color(0xFF435C73);
  static const Color primaryDark = Color(0xFF30475D);
  static const Color secondary = Color(0xFF2DAF78);
  static const Color accent = Color(0xFF4E68D8);
  static const Color navigation = Color(0xFF3F566C);

  static const Color success = Color(0xFF16B36B);
  static const Color warning = Color(0xFFF0B429);
  static const Color danger = Color(0xFFF25F62);
  static const Color info = Color(0xFF4E6BDA);

  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F9FC);
  static const Color textPrimary = Color(0xFF26384A);
  static const Color textSecondary = Color(0xFF7A8795);
  static const Color border = Color(0xFFE3E9EF);

  static const Color darkBackground = Color(0xFF172331);
  static const Color darkSurface = Color(0xFF203041);
  static const Color darkSurfaceRaised = Color(0xFF293C4F);

  static const Color pastelBlue = Color(0xFFE8EEFF);
  static const Color pastelCyan = Color(0xFFE3F6F7);
  static const Color pastelGold = Color(0xFFFFF3D8);
  static const Color pastelRose = Color(0xFFFFE8E8);
  static const Color pastelGreen = Color(0xFFE4F7EE);
  static const Color pastelPurple = Color(0xFFF0E9FF);

  // Kept for compatibility with existing authentication/branding widgets.
  // It is intentionally subtle and never used as a glassmorphism background.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, primaryDark],
  );

  static Color tenantPrimary(Tenant? tenant) {
    final raw = tenant?.brandColor;
    if (raw == null) return primary;
    final value = raw <= 0xFFFFFF ? 0xFF000000 | raw : raw;
    final tenantColor = Color(value);
    // Blend tenant branding into the reference palette so contrast and visual
    // consistency remain predictable across schools.
    return Color.lerp(primary, tenantColor, 0.32) ?? primary;
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

  static const double control = 10;
  static const double card = 14;
  static const double hero = 18;
  static const double sheet = 20;
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
      scrim: const Color(0x660F2740),
      inverseSurface: AppColors.navigation,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFB8C6D4),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
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
        toolbarHeight: 64,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.navigation,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: Colors.white,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.pastelBlue,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navigation,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navigation,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 46),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.navigation,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.navigation,
        dividerColor: AppColors.border,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
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
        headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
        dataTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
        dividerThickness: 1,
        horizontalMargin: 18,
        columnSpacing: 24,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navigation,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(99),
        thickness: WidgetStateProperty.resolveWith<double?>((states) => states.contains(WidgetState.hovered) ? 7 : 4),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) => AppColors.navigation.withOpacity(states.contains(WidgetState.hovered) ? 0.55 : 0.28)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? AppColors.navigation : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? AppColors.navigation : null),
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
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
    );
    final base = lightFor(tenant);
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(base.textTheme, const Color(0xFFF2F6FA), const Color(0xFFA8B6C4)),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: const Color(0xFFF2F6FA),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(color: Color(0xFFF2F6FA), fontSize: 17, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurfaceRaised,
        labelStyle: const TextStyle(color: Color(0xFFA8B6C4)),
        hintStyle: const TextStyle(color: Color(0xFF7D8D9D)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08)),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF17283A), surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.darkSurfaceRaised),
        headingTextStyle: const TextStyle(color: Color(0xFFA8B6C4), fontWeight: FontWeight.w700, fontSize: 12),
        dataTextStyle: const TextStyle(color: Color(0xFFF2F6FA), fontSize: 12.5),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(backgroundColor: AppColors.darkSurfaceRaised),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
