import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Christian Golfers Cape Town dark golf-club design system.
class AppTheme {
  const AppTheme._();

  // --- Brand Colors ---------------------------------------------------------
  /// Lime accent sampled from the approved scorecard direction.
  static const primaryGreen = Color(0xFFD2EB35);
  static const primaryGreenDark = Color(0xFFB6D52B);
  static const primaryGreenLight = Color(0xFFE2F46A);
  static const primaryGreenBg = Color(0xFF3A442A);

  /// Backward compatibility aliases
  static const primaryBlue = primaryGreen;
  static const primaryBlueDark = primaryGreenDark;
  static const primaryBlueLight = primaryGreenLight;
  static const primaryBlueBg = primaryGreenBg;

  /// Charcoal surfaces for the app shell, cards and app bars.
  static const darkNavy = Color(0xFF20292D);
  static const darkNavyLight = Color(0xFF2B3539);

  /// Main app page background, including safe areas and navigation shell.
  static const pageBg = Color(0xFF20292D);

  /// Standard raised charcoal surface.
  static const card = Color(0xFF2B3539);

  /// Secondary surface used for controls and alternate scorecard rows.
  static const cardSecondary = Color(0xFF333D41);

  /// Hairline dividers and borders.
  static const line = Color(0xFF3D484C);
  static const lineDark = Color(0xFF465256);

  // --- Text Colors ----------------------------------------------------------
  static const textPrimary = Color(0xFFF2F4F2);
  static const textMuted = Color(0xFFAAB3B2);
  static const textFaint = Color(0xFF7F8A8B);
  static const textOnDark = Color(0xFFFFFFFF);
  static const onLight = Color(0xFFFFFFFF);

  // --- Compatibility / Legacy Aliases ----------------------------------------
  static const gold = primaryGreen;
  static const goldBright = primaryGreenLight;
  static const goldDeep = primaryGreenDark;
  static const goldLine = primaryGreen;
  static const forestDeep = pageBg;
  static const forest = darkNavy;
  static const cardRaised = cardSecondary;

  @Deprecated('Use textMuted')
  static const muted = textMuted;

  @Deprecated('Use cardSecondary')
  static const mint = cardSecondary;

  @Deprecated('Use cardSecondary')
  static const mintStrong = cardSecondary;

  @Deprecated('Use cardSecondary')
  static const sand = cardSecondary;

  @Deprecated('Use card')
  static const forestCard = card;

  @Deprecated('Use textPrimary')
  static const charcoal = textPrimary;

  // --- Signal Colors --------------------------------------------------------
  static const birdie = primaryGreen;
  static const par = textPrimary;
  static const bogey = textMuted;
  static const doubleBogey = Color(0xFFDC2626);
  static const positive = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);

  // --- Shape ----------------------------------------------------------------
  static const radiusCard = 16.0;
  static const radiusTile = 14.0;
  static const radiusPill = 999.0;

  static BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get tileRadius => BorderRadius.circular(radiusTile);

  /// Standard card decoration: white fill, soft border, subtle shadow.
  static BoxDecoration cardDecoration({
    Color? colour,
    Color? border,
    double radius = radiusCard,
  }) {
    return BoxDecoration(
      color: colour ?? card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? line, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Primary action gradient fill.
  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB6D52B), Color(0xFFD2EB35)],
  );

  static const blueGradient = greenGradient;
  static const goldGradient = greenGradient;

  // --- Typography -----------------------------------------------------------
  static TextStyle display(double size, {Color? colour, double? spacing}) =>
      GoogleFonts.inter(
        fontSize: size,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: spacing ?? -0.5,
        color: colour ?? textPrimary,
      );

  /// Script font for taglines ("Play with Purpose").
  static TextStyle scriptAccent(double size, {Color? colour}) =>
      GoogleFonts.dancingScript(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: colour ?? primaryGreen,
      );

  static TextStyle label(double size, {Color? colour, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        letterSpacing: 0.5,
        color: colour ?? textMuted,
      );

  static TextStyle body(double size, {Color? colour, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        height: 1.4,
        fontWeight: weight ?? FontWeight.w500,
        color: colour ?? textPrimary,
      );

  static TextStyle numeric(double size, {Color? colour, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        height: 1.0,
        fontWeight: weight ?? FontWeight.w800,
        letterSpacing: -0.5,
        color: colour ?? textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // --- ThemeData ------------------------------------------------------------
  static ThemeData get theme {
    final scheme = const ColorScheme.dark(
      primary: primaryGreen,
      onPrimary: Color(0xFF19201D),
      secondary: primaryGreenDark,
      onSecondary: Color(0xFF19201D),
      surface: card,
      onSurface: textPrimary,
      error: danger,
      onError: Colors.white,
    );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: pageBg,
      canvasColor: pageBg,
      dividerColor: line,
      splashFactory: InkSparkle.splashFactory,

      textTheme: base.textTheme.copyWith(
        displayLarge: display(44),
        displayMedium: display(36),
        headlineLarge: display(30),
        headlineMedium: display(24),
        headlineSmall: display(20),
        titleLarge: body(18, weight: FontWeight.w700),
        titleMedium: body(16, weight: FontWeight.w700),
        titleSmall: body(14, weight: FontWeight.w700),
        bodyLarge: body(16),
        bodyMedium: body(14),
        bodySmall: body(12, colour: textMuted),
        labelLarge: body(14, weight: FontWeight.w700),
        labelMedium: label(11),
        labelSmall: label(10),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: line),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: const Color(0xFF19201D),
          disabledBackgroundColor: cardSecondary,
          disabledForegroundColor: textFaint,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: line, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: body(14, colour: textFaint),
        labelStyle: body(14, colour: textMuted),
        prefixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: danger),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primaryGreen
                : cardSecondary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF19201D)
                : textMuted,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: line)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryGreenBg,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? primaryGreen
                : textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primaryGreen
                : textMuted,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: display(20),
        contentTextStyle: body(14, colour: textMuted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkNavy,
        contentTextStyle: body(13.5, colour: Colors.white),
        actionTextColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryGreen,
        dividerColor: line,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: primaryGreen,
        textColor: textPrimary,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    );
  }

  static ThemeData get darkTheme => theme;
  static ThemeData get lightTheme => theme;
}
