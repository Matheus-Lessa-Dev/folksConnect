import 'package:flutter/material.dart';

/// Colors sampled from the exported Login frame (402 x 874) in Folks Mobile.
abstract final class FolksColors {
  static const background = Color(0xFF3D3D3D);
  static const orange = Color(0xFFFF671D);
  static const white = Color(0xFFFFFFFF);
}

abstract final class FolksTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FolksColors.background,
    colorScheme: const ColorScheme.dark(
      primary: FolksColors.orange,
      onPrimary: FolksColors.white,
      surface: FolksColors.background,
      onSurface: FolksColors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FolksColors.orange,
      selectionColor: Color(0x66FF671D),
      selectionHandleColor: FolksColors.orange,
    ),
  );
}
