import 'package:flutter/material.dart';

/// Colors sampled from the exported Login frame (402 x 874) in Folks Mobile.
abstract final class FolksColors {
  static const background = Color(0xFF3D3D3D);
  static const orange = Color(0xFFFF671D);
  static const white = Color(0xFFFFFFFF);

  // Kanban surfaces follow the purple board in the Folks Mobile reference.
  static const boardTop = Color(0xFF25113F);
  static const boardBottom = Color(0xFF160B38);
  static const boardCard = Color(0xFF3C2B60);
  static const boardNavigation = Color(0xFF24205A);
  static const todo = Color(0xFF0098FF);
  static const inProgress = Color(0xFFC4D72D);
  static const waiting = Color(0xFFFFC62A);
  static const done = Color(0xFF39B96C);
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
