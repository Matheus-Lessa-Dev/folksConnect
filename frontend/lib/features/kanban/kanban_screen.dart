import 'package:flutter/material.dart';

import '../../core/theme/folks_theme.dart';

/// Initial board destination. There are no persisted tasks in the current API.
class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  static const _projects = [
    'Todos',
    'Recrutamento',
    'Triagem',
    'Consultoria',
    'Financeiro',
  ];
  static const _stages = [
    (title: 'A FAZER', color: FolksColors.todo),
    (title: 'EM ANDAMENTO', color: FolksColors.inProgress),
    (title: 'AGUARDANDO', color: FolksColors.waiting),
    (title: 'CONCLUÍDO', color: FolksColors.done),
  ];

  String _project = 'Todos';
  bool _listView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolksColors.boardBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FolksColors.boardTop, FolksColors.boardBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Quadro de Tarefas',
                        style: TextStyle(
                          color: FolksColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout, color: FolksColors.white),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _projects.map((project) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(project),
                        selected: _project == project,
                        onSelected: (_) => setState(() => _project = project),
                        showCheckmark: false,
                        selectedColor: FolksColors.boardCard,
                        backgroundColor: FolksColors.boardTop,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: FolksColors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Kanban')),
                    ButtonSegment(value: true, label: Text('Lista')),
                  ],
                  selected: {_listView},
                  onSelectionChanged: (selection) {
                    setState(() => _listView = selection.single);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: FolksColors.white,
                    selectedForegroundColor: FolksColors.white,
                    backgroundColor: FolksColors.boardTop,
                    selectedBackgroundColor: FolksColors.boardCard,
                    side: const BorderSide(color: FolksColors.boardCard),
                  ),
                ),
              ),
              Expanded(
                child: _listView
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma tarefa cadastrada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: FolksColors.white),
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _stages.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final stage = _stages[index];
                          return SizedBox(
                            width: 280,
                            child: ListView(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: stage.color,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        stage.title,
                                        style: const TextStyle(
                                          color: FolksColors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '0',
                                      style: TextStyle(
                                        color: FolksColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: FolksColors.boardCard,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Nenhuma tarefa nesta etapa.',
                                    style: TextStyle(color: FolksColors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                color: FolksColors.boardNavigation,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, color: FolksColors.orange),
                    SizedBox(width: 8),
                    Text('Kanban', style: TextStyle(color: FolksColors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
