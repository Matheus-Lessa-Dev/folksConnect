import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/folks_theme.dart';
import 'kanban_controller.dart';
import 'task.dart';
import 'widgets/kanban_widgets.dart';
import 'widgets/new_task_sheet.dart';
import 'widgets/task_details_sheet.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key, this.controller});
  final KanbanController? controller;

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late final _controller = widget.controller ?? KanbanController();
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final task = await showFolksSheet<KanbanTask>(
      context,
      NewTaskSheet(controller: _controller),
    );
    if (!mounted || task == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tarefa criada.')));
  }

  void _open(KanbanTask task) => showFolksSheet<void>(
    context,
    TaskDetailsSheet(controller: _controller, taskId: task.id),
  );

  Widget _card(KanbanTask task) => TaskCard(
    task: task,
    onOpen: () => _open(task),
    onMove: (status) {
      _controller.update(task.copyWith(status: status));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarefa movida para ${status.label}.')),
      );
    },
  );

  Widget _board() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 700
          ? math.min(328.0, constraints.maxWidth * .84)
          : 328.0;
      return Scrollbar(
        controller: _horizontalScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: BoardStatus.values.map((status) {
              final tasks = _controller.visibleTasks
                  .where((task) => task.status == status)
                  .toList();
              return SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: statusColor(status),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              status.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tasks.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: FolksColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: tasks.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text(
                                  'Nenhuma tarefa nesta etapa.',
                                  style: TextStyle(
                                    color: FolksColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: tasks.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) => _card(tasks[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );

  Widget _list() {
    final tasks = _controller.visibleTasks;
    if (tasks.isEmpty) {
      return const Center(child: Text('Nenhuma tarefa neste projeto.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              tasks[index].status.label,
              style: const TextStyle(color: FolksColors.muted, fontSize: 12),
            ),
          ),
          _card(tasks[index]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: FolksTheme.background),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Quadro de Tarefas', style: FolksTheme.heading),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: KanbanController.projects.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, index) {
                    final label = index == 0
                        ? 'Todos'
                        : KanbanController.projects[index - 1];
                    return ChoiceChip(
                      label: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FolksColors.white,
                        ),
                      ),
                      selected: _controller.filter == label,
                      showCheckmark: false,
                      backgroundColor: FolksColors.card.withValues(alpha: .6),
                      selectedColor: const Color(0xFF615271),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => _controller.filterBy(label),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Kanban')),
                      ButtonSegment(value: true, label: Text('Lista')),
                    ],
                    selected: {_controller.listView},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: FolksColors.card.withValues(alpha: .5),
                      selectedBackgroundColor: const Color(0xFF514265),
                      side: const BorderSide(color: FolksColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSelectionChanged: (value) =>
                        _controller.setListView(value.first),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _controller.listView ? _list() : _board(),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: FloatingActionButton.small(
                          heroTag: 'new-task',
                          tooltip: 'Nova tarefa',
                          backgroundColor: FolksColors.gold,
                          foregroundColor: FolksColors.white,
                          shape: const CircleBorder(),
                          onPressed: _create,
                          child: const Icon(Icons.add, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _KanbanNavigation(),
            ],
          ),
        ),
      ),
    ),
  );
}

/// As demais abas ficam indisponiveis ate suas respectivas features existirem.
class _KanbanNavigation extends StatelessWidget {
  const _KanbanNavigation();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: FolksColors.navigation,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const IconButton(
              tooltip: 'Início (em breve)',
              onPressed: null,
              icon: Icon(Icons.home_rounded),
            ),
            Semantics(
              selected: true,
              label: 'Kanban',
              child: const Icon(
                Icons.assignment,
                color: FolksColors.orange,
                size: 26,
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: FolksColors.orange,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.hub_outlined,
                size: 36,
                color: FolksColors.white,
              ),
            ),
            const IconButton(
              tooltip: 'Funil de Vagas (em breve)',
              onPressed: null,
              icon: Icon(Icons.edit_square),
            ),
            const IconButton(
              tooltip: 'Configurações (em breve)',
              onPressed: null,
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
    ),
  );
}
