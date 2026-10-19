import 'package:flutter/material.dart';

/// Tokens compartilhados da referencia Folks Mobile (tema escuro).
abstract final class FolksColors {
  static const background = Color(0xFF140D2B);
  static const purple = Color(0xFF30145B);
  static const card = Color(0xFF382657);
  static const sheet = Color(0xFF12172C);
  static const field = Color(0xFF242B3D);
  static const navigation = Color(0xFF1E2453);
  static const primary = Color(0xFF4D1B9B);
  static const orange = Color(0xFFFF701D);
  static const gold = Color(0xFFD6AC47);
  static const white = Color(0xFFF7F5FA);
  static const muted = Color(0xFFBCB7CA);
  static const blue = Color(0xFF3298FF);
  static const yellow = Color(0xFFD4D84C);
  static const green = Color(0xFF55CE91);
  static const red = Color(0xFFFF737F);
  static const border = Color(0xFF4A425E);
}

abstract final class FolksTheme {
  static const background = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [FolksColors.purple, FolksColors.background],
  );

  static const heading = TextStyle(
    fontFamily: 'Times New Roman',
    fontFamilyFallback: ['Georgia', 'serif'],
    color: FolksColors.white,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FolksColors.background,
    fontFamily: 'Arial',
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
      bodyMedium: TextStyle(fontSize: 14, color: FolksColors.white),
      bodySmall: TextStyle(fontSize: 12, color: FolksColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FolksColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.gold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FolksColors.red),
      ),
      hintStyle: const TextStyle(color: FolksColors.muted, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Arial',
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
