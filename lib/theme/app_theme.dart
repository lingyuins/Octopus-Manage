import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const double radiusNone = 0.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 22.0;
  static const double radiusXXLarge = 28.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 28.0;

  static List<BoxShadow> getShadow(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];
  static List<BoxShadow> getShadowLarge(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static Color getSurfaceLowest(ColorScheme cs) =>
      cs.brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF000000);
  static Color getSurfaceLow(ColorScheme cs) =>
      cs.brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF1C1C1E);
  static Color getSurface(ColorScheme cs) => cs.brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF2C2C2E);
  static Color getSurfaceHigh(ColorScheme cs) =>
      cs.brightness == Brightness.light
      ? const Color(0xFFE5E5EA)
      : const Color(0xFF3A3A3C);
  static Color getSurfaceHighest(ColorScheme cs) =>
      cs.brightness == Brightness.light
      ? const Color(0xFFD1D1D6)
      : const Color(0xFF48484A);

  static Color getLevel0Bg(ColorScheme cs) => getSurfaceLowest(cs);
  static Color getLevel1Bg(ColorScheme cs) => getSurfaceLow(cs);
  static Color getLevel2Bg(ColorScheme cs) => getSurface(cs);
  static Color getLevel3Bg(ColorScheme cs) => getSurfaceHigh(cs);

  static Gradient? getSurfaceGradient(ColorScheme colorScheme) => null;

  static Color getGroupedBackground(ColorScheme cs) => getSurfaceLowest(cs);
  static Color getGroupedCellBackground(ColorScheme cs) => getSurfaceLow(cs);

  static ThemeData getTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: getSurfaceLowest(colorScheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: getSurfaceLow(colorScheme),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: getSurfaceLowest(colorScheme),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.light
            ? const Color(0xFFE5E5EA)
            : const Color(0xFF3A3A3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingXs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide.none,
        backgroundColor: getSurfaceHigh(colorScheme),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 0.5,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXXLarge),
        ),
        elevation: 0,
        backgroundColor: getSurfaceLow(colorScheme),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXXLarge),
          ),
        ),
        backgroundColor: getSurfaceLow(colorScheme),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.brightness == Brightness.light
            ? const Color(0xFFF9F9F9).withValues(alpha: 0.94)
            : const Color(0xFF1C1C1E).withValues(alpha: 0.94),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
        height: 56,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: colorScheme.brightness,
        primaryColor: colorScheme.primary,
        scaffoldBackgroundColor: getSurfaceLowest(colorScheme),
      ),
    );
  }
}

class Responsive {
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static int getGridCrossCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 900) return 3;
    return 2;
  }

  static int getFoldThreshold(
    BuildContext context, {
    int defaultThreshold = 5,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 3;
    if (width < 600) return defaultThreshold - 1;
    return defaultThreshold;
  }
}

extension ColorSchemeExtension on ColorScheme {
  Color get success => const Color(0xFF34C759);
  Color get warning => const Color(0xFFFF9500);
  Color get info => const Color(0xFF007AFF);
}

extension TextThemeExtension on TextTheme {
  TextStyle? get display => headlineMedium?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontSize: 34,
  );

  TextStyle? get largeTitle => headlineLarge?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    fontSize: 34,
  );

  TextStyle? get heading => titleLarge?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontSize: 17,
  );

  TextStyle? get label =>
      titleMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 15);

  TextStyle? get body =>
      bodyMedium?.copyWith(fontWeight: FontWeight.w400, fontSize: 17);

  TextStyle? get caption => bodySmall?.copyWith(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: const Color(0xFF8E8E93),
  );

  TextStyle? get footnote => bodySmall?.copyWith(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    letterSpacing: -0.08,
  );
}
