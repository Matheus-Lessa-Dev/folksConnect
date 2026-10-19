import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../task.dart';

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => FolksColors.red,
  TaskPriority.medium => FolksColors.gold,
  TaskPriority.low => FolksColors.green,
};

Color statusColor(BoardStatus status) => switch (status) {
  BoardStatus.todo => FolksColors.blue,
  BoardStatus.inProgress => FolksColors.yellow,
  BoardStatus.waiting => FolksColors.gold,
  BoardStatus.done => FolksColors.green,
};

Color projectColor(String project) => switch (project) {
  'Recrutamento' => FolksColors.gold,
  'Triagem' => FolksColors.red,
  'Consultoria' => FolksColors.blue,
  'Financeiro' => FolksColors.green,
  _ => const Color(0xFFBDA1F5),
};

class ProjectBadge extends StatelessWidget {
  const ProjectBadge(this.project, {super.key});
  final String project;

  @override
  Widget build(BuildContext context) {
    final color = projectColor(project);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(project, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class Pipeline extends StatelessWidget {
  const Pipeline(this.stage, {super.key, this.labels = true});
  final RecruitmentStage stage;
  final bool labels;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Etapa atual: ${stage.label}',
    child: ExcludeSemantics(
      child: Row(
        children: RecruitmentStage.values
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: item.index <= stage.index
                              ? (item.index == 0
                                    ? FolksColors.green
                                    : FolksColors.gold)
                              : FolksColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (labels) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: FolksColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onMove,
  });
  final KanbanTask task;
  final VoidCallback onOpen;
  final ValueChanged<BoardStatus> onMove;

  @override
  Widget build(BuildContext context) => Material(
    color: FolksColors.card,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      key: ValueKey('open-${task.id}'),
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ProjectBadge(task.project),
                  ),
                ),
                Icon(
                  Icons.circle,
                  size: 5,
                  color: priorityColor(task.priority),
                ),
                const SizedBox(width: 4),
                Text(
                  task.priority.label,
                  style: TextStyle(
                    color: priorityColor(task.priority),
                    fontSize: 10,
                  ),
                ),
                PopupMenuButton<BoardStatus>(
                  tooltip: 'Mover tarefa',
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: FolksColors.muted,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: onMove,
                  itemBuilder: (_) => BoardStatus.values
                      .where((status) => status != task.status)
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text('Mover para ${status.label}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Text(
              task.title,
              style: FolksTheme.heading.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            Pipeline(task.stage, labels: false),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: FolksColors.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.assignee,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FolksColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  shortDate(task.end),
                  style: const TextStyle(
                    fontSize: 10,
                    color: FolksColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Semantics(label: label, child: child),
      ],
    ),
  );
}

class SheetActions extends StatelessWidget {
  const SheetActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel = 'Fechar',
    required this.onClose,
  });
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
      const SizedBox(height: 8),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: FolksColors.field),
        onPressed: onClose,
        child: Text(secondaryLabel),
      ),
    ],
  );
}

Future<T?> showFolksSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: child,
          ),
        ),
      ),
    );
