import 'package:flutter/material.dart';

import 'core/theme/folks_theme.dart';
import 'features/kanban/kanban_screen.dart';

void main() {
  runApp(const FolksConnectApp());
}

class FolksConnectApp extends StatelessWidget {
  const FolksConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      home: const KanbanScreen(),
      routes: {'/kanban': (_) => const KanbanScreen()},
    );
  }
}
