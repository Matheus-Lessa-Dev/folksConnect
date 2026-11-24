import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../task.dart';

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => FolksColors.red,
  TaskPriority.medium => FolksColors.gold,
  TaskPriority.low => FolksColors.green,
};

Color statusColor(BoardStatus status) {
  if (status == BoardStatus.todo) return FolksColors.blue;
  if (status == BoardStatus.inProgress) return FolksColors.yellow;
  if (status == BoardStatus.done) return FolksColors.green;
  return FolksColors.gold;
}

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
      child: Text(
        project,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: project == 'Recrutamento' ? const Color(0xFFAC7103) : color,
        ),
      ),
    );
  }
}

/// Status do cartao conforme a etapa atual do funil. Havendo etapa seguinte,
/// o toque permite escolher a proxima.
class StageBadge extends StatelessWidget {
  const StageBadge(this.label, {super.key, this.onTap, this.last = false});
  final String label;
  final VoidCallback? onTap;

  /// Etapa final do funil: o selo fica verde.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = last ? FolksColors.green : FolksColors.gold;
    final textColor = last ? FolksColors.green : const Color(0xFFAC7103);
    return Semantics(
      button: onTap != null,
      label: onTap == null
          ? 'Status: $label'
          : 'Status: $label. Escolher a próxima etapa',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: color.withValues(alpha: .13),
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: .6)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: EdgeInsets.only(left: 12, right: onTap == null ? 12 : 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_drop_down, size: 20, color: textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barrinhas de progresso: uma por etapa cadastrada em Configurações.
class Pipeline extends StatelessWidget {
  const Pipeline({
    super.key,
    required this.stages,
    required this.current,
    this.labels = true,
  });
  final List<String> stages;
  final int current;
  final bool labels;

  @override
  Widget build(BuildContext context) {
    final active = current >= stages.length ? stages.length - 1 : current;
    return Semantics(
      label: 'Etapa atual: ${stages[active]}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < stages.length; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: index < active
                              ? FolksColors.green
                              : index == active
                              ? FolksColors.gold
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (labels) ...[
                        const SizedBox(height: 5),
                        Text(
                          stages[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onMove,
    required this.stages,
    required this.boardStatuses,
    this.showStageLabels = false,
  });
  final KanbanTask task;
  final List<String> stages;
  final List<BoardStatus> boardStatuses;
  final VoidCallback onOpen;
  final ValueChanged<BoardStatus> onMove;
  final bool showStageLabels;

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
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: FolksColors.muted,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: onMove,
                  itemBuilder: (_) => boardStatuses
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
            Text(task.title, style: FolksTheme.heading.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Pipeline(
              stages: stages,
              current: task.stage,
              labels: showStageLabels,
            ),
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
                      fontSize: 10,
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

/// Titulo + campo. Enquanto um campo de texto ou lista do bloco esta
/// selecionado, o titulo sai de cima e passa a aparecer sobre a borda superior.
class FieldLabel extends StatefulWidget {
  const FieldLabel(this.label, {super.key, required this.child});
  final String label;
  final Widget child;

  @override
  State<FieldLabel> createState() => _FieldLabelState();
}

class _FieldLabelState extends State<FieldLabel> {
  bool _editing = false;

  void _focusChanged(bool hasFocus) {
    var editing = false;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (hasFocus && focused != null) {
      if (focused.widget is EditableText) editing = true;
      focused.visitAncestorElements((element) {
        if (element.widget is EditableText ||
            element.widget is DropdownButton) {
          editing = true;
          return false;
        }
        return true;
      });
    }
    if (editing != _editing) setState(() => _editing = editing);
  }

  /// Rotulo sobre a borda superior. A caixa tem a cor do fundo acima da borda e
  /// a cor do campo abaixo dela, para "recortar" a borda sem parecer um
  /// retangulo solto.
  Widget _borderLabel(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final inside = Color.alphaBlend(FolksColors.field, surface);
    return Positioned(
      left: 10,
      top: -8,
      child: IgnorePointer(
        child: Container(
          height: 16,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [surface, surface, inside, inside],
              stops: const [0, .5, .5, 1],
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w600,
              color: FolksColors.fieldLabel,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: _editing ? 0 : 1,
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FolksColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: _focusChanged,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(label: widget.label, child: widget.child),
              if (_editing) _borderLabel(context),
            ],
          ),
        ),
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
      PrimaryAction(label: primaryLabel, onPressed: onPrimary),
      const SizedBox(height: 8),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: FolksColors.field),
        onPressed: onClose,
        child: Text(secondaryLabel),
      ),
    ],
  );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: onPressed == null ? null : FolksTheme.primaryGradient,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: FolksColors.sheet,
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
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
