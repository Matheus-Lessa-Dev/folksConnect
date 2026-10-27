import 'package:flutter/material.dart';

/// Tokens compartilhados da referencia Folks Mobile (tema escuro).
abstract final class FolksColors {
  static const authBackground = Color(0xFF3D3D3D);
  static const background = Color(0xFF160C30);
  static const purple = Color(0xFF250D63);
  static const card = Color(0x33666666);
  static const sheet = Color(0xFF12182A);
  static const field = card;
  static const navigation = Color(0xFF1B224E);
  static const primary = Color(0xFF250D63);
  static const orange = Color(0xFFFF6C1E);
  static const brandOrange = Color(0xFFFF671D);
  static const gold = Color(0xFFD9A441);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFFC6C6C6);
  static const blue = Color(0xFF3298FF);
  static const yellow = Color(0xFFD4D84C);
  static const green = Color(0xFF55CE91);
  static const red = Color(0xFFFF737F);
  static const border = Color(0xFF4A425E);
}

abstract final class FolksTheme {
  static final auth = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FolksColors.authBackground,
    colorScheme: const ColorScheme.dark(
      primary: FolksColors.orange,
      onPrimary: FolksColors.white,
      surface: FolksColors.authBackground,
      onSurface: FolksColors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FolksColors.orange,
      selectionColor: Color(0x66FF671D),
      selectionHandleColor: FolksColors.orange,
    ),
  );

  static const background = RadialGradient(
    center: Alignment(.7782, -.2052),
    radius: 1,
    transform: _FigmaEllipseGradient(1.1625, .7895, Alignment(.7782, -.2052)),
    stops: [0, .1628, .2882, .5885],
    colors: [
      Color(0xFF2F1F59),
      Color(0xFF250D63),
      Color(0xFF241250),
      Color(0xFF160C30),
    ],
  );

  static const primaryGradient = RadialGradient(
    center: Alignment(-.0664, .1428),
    radius: 1,
    transform: _FigmaEllipseGradient(1.3371, 62.2923, Alignment(-.0664, .1428)),
    stops: [0, .5121, .6788, .9012, 1],
    colors: [
      Color(0xFF2F1F59),
      Color(0xFF250D63),
      Color(0xFF241250),
      Color(0xFF190D36),
      Color(0xFF160C30),
    ],
  );

  static const heading = TextStyle(
    fontFamily: 'InriaSerif',
    color: FolksColors.white,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FolksColors.background,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: FolksColors.primary,
      onPrimary: FolksColors.white,
      secondary: FolksColors.orange,
      onSecondary: FolksColors.white,
      secondaryContainer: FolksColors.card,
      onSecondaryContainer: FolksColors.white,
      surface: FolksColors.sheet,
      onSurface: FolksColors.white,
      error: FolksColors.red,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(fontSize: 15, color: FolksColors.white),
      bodyMedium: TextStyle(fontSize: 14, color: FolksColors.white),
      bodySmall: TextStyle(fontSize: 12, color: FolksColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FolksColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.card),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.card),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.gold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.red),
      ),
      hintStyle: const TextStyle(color: Color(0x91666666), fontSize: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: FolksColors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FolksColors.white,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: FolksColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: FolksColors.field,
        foregroundColor: FolksColors.white,
        selectedBackgroundColor: const Color(0xFF3A3E51),
        selectedForegroundColor: FolksColors.white,
        side: const BorderSide(color: FolksColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: FolksColors.sheet),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: FolksColors.sheet,
      modalBarrierColor: Color(0xAA050611),
      showDragHandle: true,
      dragHandleColor: FolksColors.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}

/// Proporcoes elipticas e centro do CSS copiado no painel de propriedades.
/// O proprio Figma avisa que a exportacao CSS nao preserva sua rotacao interna.
class _FigmaEllipseGradient extends GradientTransform {
  const _FigmaEllipseGradient(this.horizontal, this.vertical, this.center);
  final double horizontal;
  final double vertical;
  final Alignment center;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final origin = center.withinRect(bounds);
    final scaleX = bounds.width * horizontal / bounds.shortestSide;
    final scaleY = bounds.height * vertical / bounds.shortestSide;
    return Matrix4.diagonal3Values(
      scaleX,
      scaleY,
      1,
    )..setTranslationRaw(origin.dx * (1 - scaleX), origin.dy * (1 - scaleY), 0);
  }
}
