import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores do Bonum. Verde-sálvia = "fazer o bem"; dourado-sol = "perceber o bem".
@immutable
class BonumPalette extends ThemeExtension<BonumPalette> {
  const BonumPalette({
    required this.sage,
    required this.sageSoft,
    required this.sun,
    required this.sunSoft,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
  });

  final Color sage;
  final Color sageSoft;
  final Color sun;
  final Color sunSoft;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;

  static const light = BonumPalette(
    sage: Color(0xFF4F7F5F),
    sageSoft: Color(0xFFE7F0E8),
    sun: Color(0xFFD99A2B),
    sunSoft: Color(0xFFFBF0DA),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF2B3530),
    muted: Color(0xFF7D877F),
    line: Color(0xFFECE6DC),
  );

  static const dark = BonumPalette(
    sage: Color(0xFF8DBB99),
    sageSoft: Color(0xFF243128),
    sun: Color(0xFFEBBE63),
    sunSoft: Color(0xFF3A3122),
    card: Color(0xFF1E2320),
    ink: Color(0xFFE9EDE9),
    muted: Color(0xFF9AA49C),
    line: Color(0xFF2E3530),
  );

  @override
  BonumPalette copyWith() => this;

  @override
  BonumPalette lerp(ThemeExtension<BonumPalette>? other, double t) {
    if (other is! BonumPalette) return this;
    return BonumPalette(
      sage: Color.lerp(sage, other.sage, t)!,
      sageSoft: Color.lerp(sageSoft, other.sageSoft, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      sunSoft: Color.lerp(sunSoft, other.sunSoft, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

extension BonumThemeX on BuildContext {
  BonumPalette get palette => Theme.of(this).extension<BonumPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? BonumPalette.light : BonumPalette.dark;
  final background = brightness == Brightness.light ? const Color(0xFFFAF7F2) : const Color(0xFF141816);
  final scheme = ColorScheme.fromSeed(
    seedColor: BonumPalette.light.sage,
    brightness: brightness,
  ).copyWith(primary: p.sage, secondary: p.sun, surface: background, onSurface: p.ink);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);

  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: p.sageSoft,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? const Color(0xFFF5F1EA) : const Color(0xFF232926),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: p.line),
      labelStyle: textTheme.labelMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
