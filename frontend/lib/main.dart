import 'package:flutter/material.dart';

import 'core/theme/folks_theme.dart';
import 'features/kanban/kanban_controller.dart';
import 'features/kanban/kanban_screen.dart';
import 'features/vacancy_funnel/vacancy_funnel_controller.dart';
import 'features/vacancy_funnel/vacancy_funnel_screen.dart';

void main() {
  runApp(const FolksConnectApp());
}

class FolksConnectApp extends StatefulWidget {
  const FolksConnectApp({super.key});

  @override
  State<FolksConnectApp> createState() => _FolksConnectAppState();
}

class _FolksConnectAppState extends State<FolksConnectApp> {
  final _kanban = KanbanController();
  final _funnel = VacancyFunnelController();

  @override
  void dispose() {
    _kanban.dispose();
    _funnel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      debugShowCheckedModeBanner: false,
      theme: FolksTheme.dark,
      home: KanbanScreen(controller: _kanban),
      routes: {
        '/kanban': (_) => KanbanScreen(controller: _kanban),
        '/funil-vagas': (_) => VacancyFunnelScreen(controller: _funnel),
      },
    );
  }
}
