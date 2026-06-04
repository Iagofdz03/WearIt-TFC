import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemaConfig {
  final String id;
  final String nombre;
  final String emoji;
  final Color background;
  final Color primary;
  final Color accent;
  final Color accentLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color cardBg;
  final Color error;
  final Color success;

  const TemaConfig({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.background,
    required this.primary,
    required this.accent,
    required this.accentLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.cardBg,
    required this.error,
    required this.success,
  });
}

class AppTemas {
  static final Map<String, TemaConfig> todos = {
    'neutro':      _neutro,
    'femenino':    _femenino,
    'masculino':   _masculino,
    'rock':        _rock,
    'streetwear':  _streetwear,
    'minimalista': _minimalista,
  };

  static TemaConfig get(String? id) => todos[id ?? 'neutro'] ?? _neutro;

  // ── Neutro — crema cálida + terracota ────────────────────────────────────
  static const _neutro = TemaConfig(
    id: 'neutro', nombre: 'Neutro', emoji: '🤍',
    background:    Color(0xFFF5F0EA),
    primary:       Color(0xFF1A1A1A),
    accent:        Color(0xFFB85C38),
    accentLight:   Color(0xFFE8956D),
    textPrimary:   Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6560),
    border:        Color(0xFFE0D8CE),
    cardBg:        Color(0xFFFAF7F3),
    error:         Color(0xFFB85C38),
    success:       Color(0xFF4A7C59),
  );

  // ── Femenino — fucsia vibrante sobre blanco rosado ───────────────────────
  static const _femenino = TemaConfig(
    id: 'femenino', nombre: 'Femenino', emoji: '🌸',
    background:    Color(0xFFFFF0F5),
    primary:       Color(0xFFAD1457),
    accent:        Color(0xFFE91E8C),
    accentLight:   Color(0xFFF48FB1),
    textPrimary:   Color(0xFF3B0A28),
    textSecondary: Color(0xFF9C4068),
    border:        Color(0xFFF8BBD9),
    cardBg:        Color(0xFFFCE4EC),
    error:         Color(0xFFC62828),
    success:       Color(0xFF558B2F),
  );

  // ── Masculino — azul marino + naranja eléctrico ──────────────────────────
  static const _masculino = TemaConfig(
    id: 'masculino', nombre: 'Masculino', emoji: '⚡',
    background:    Color(0xFF0A1628),
    primary:       Color(0xFFE8F0FE),
    accent:        Color(0xFF4285F4),
    accentLight:   Color(0xFF82B1FF),
    textPrimary:   Color(0xFFE8F0FE),
    textSecondary: Color(0xFF8BA3C7),
    border:        Color(0xFF1E3A5F),
    cardBg:        Color(0xFF112240),
    error:         Color(0xFFFF5252),
    success:       Color(0xFF69F0AE),
  );

  // ── Rock — negro total + rojo sangre + blanco roto ───────────────────────
  static const _rock = TemaConfig(
    id: 'rock', nombre: 'Rock', emoji: '🤘',
    background:    Color(0xFF0D0D0D),
    primary:       Color(0xFFF5F5F5),
    accent:        Color(0xFFB71C1C),
    accentLight:   Color(0xFFFF5252),
    textPrimary:   Color(0xFFF5F5F5),
    textSecondary: Color(0xFF757575),
    border:        Color(0xFF1F1F1F),
    cardBg:        Color(0xFF161616),
    error:         Color(0xFFFF1744),
    success:       Color(0xFF76FF03),
  );

  // ── Streetwear — negro + amarillo neón brutal ────────────────────────────
  static const _streetwear = TemaConfig(
    id: 'streetwear', nombre: 'Streetwear', emoji: '🔥',
    background:    Color(0xFF111111),
    primary:       Color(0xFFFFFF00),
    accent:        Color(0xFFFFD600),
    accentLight:   Color(0xFFFFFF72),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9E9E9E),
    border:        Color(0xFF222222),
    cardBg:        Color(0xFF1A1A1A),
    error:         Color(0xFFFF1744),
    success:       Color(0xFF00E676),
  );

  // ── Minimalista — blanco puro + negro + cero color ──────────────────────
  static const _minimalista = TemaConfig(
    id: 'minimalista', nombre: 'Minimal', emoji: '◻️',
    background:    Color(0xFFFFFFFF),
    primary:       Color(0xFF000000),
    accent:        Color(0xFF212121),
    accentLight:   Color(0xFF616161),
    textPrimary:   Color(0xFF000000),
    textSecondary: Color(0xFF9E9E9E),
    border:        Color(0xFFE0E0E0),
    cardBg:        Color(0xFFF5F5F5),
    error:         Color(0xFF212121),
    success:       Color(0xFF212121),
  );
}

// ─── AppTheme dinámico ────────────────────────────────────────────────────────
class AppTheme {
  static TemaConfig _current = AppTemas.get('neutro');

  static void setTema(String id) {
    _current = AppTemas.get(id);
  }

  static Color get background    => _current.background;
  static Color get primary       => _current.primary;
  static Color get accent        => _current.accent;
  static Color get accentLight   => _current.accentLight;
  static Color get textPrimary   => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get border        => _current.border;
  static Color get cardBg        => _current.cardBg;
  static Color get error         => _current.error;
  static Color get success       => _current.success;
  static String get temaActual   => _current.id;

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: _isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: background,
      secondary: accent,
      onSecondary: background,
      background: background,
      onBackground: textPrimary,
      surface: cardBg,
      onSurface: textPrimary,
      error: error,
      onError: background,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.cormorant(
          fontSize: 22, fontWeight: FontWeight.w500, color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: TextStyle(color: textSecondary),
      labelStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: 13),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
              (s) => s.contains(MaterialState.selected) ? accent : textSecondary),
      trackColor: MaterialStateProperty.resolveWith(
              (s) => s.contains(MaterialState.selected)
              ? accent.withOpacity(0.4)
              : border),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith(
              (s) => s.contains(MaterialState.selected) ? accent : Colors.transparent),
      checkColor: MaterialStateProperty.all(background),
      side: BorderSide(color: textSecondary),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: border,
      overlayColor: accent.withOpacity(0.2),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: textSecondary,
      indicatorColor: accent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardBg,
      textStyle: GoogleFonts.dmSans(color: textPrimary, fontSize: 13),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: background,
      titleTextStyle: GoogleFonts.cormorant(
          fontSize: 20, color: textPrimary, fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: GoogleFonts.dmSans(color: background),
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
  );

  static bool get _isDark =>
      _current.background.computeLuminance() < 0.5;
}