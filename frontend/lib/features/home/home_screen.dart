import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folks_theme.dart';
import '../../core/widgets/folks_navigation.dart';
import '../kanban/kanban_controller.dart';
import '../kanban/task.dart';
import '../kanban/widgets/kanban_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller, this.userName});

  final KanbanController controller;
  final String? userName;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: FolksTheme.background),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _content(context),
                  ),
                ),
              ),
            ),
            const FolksNavigation(selectedRoute: '/inicio'),
          ],
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    final name = userName?.trim();
    final today = DateUtils.dateOnly(DateTime.now());
    final tasks = controller.tasks;
    final pending = tasks.where((task) => task.status != BoardStatus.done);
    final recent = pending.toList().reversed.take(3);
    final deliveries = tasks.where(
      (task) => task.status == BoardStatus.done && task.completedAt != null,
    );
    final onTime = deliveries
        .where((task) => !_day(task.completedAt!).isAfter(_day(task.end)))
        .length;
    final onTimeLabel = deliveries.isEmpty
        ? '—'
        : '${(onTime * 100 / deliveries.length).round()}%';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Olá, ${name == null || name.isEmpty ? '---' : name}!',
                  style: FolksTheme.heading.copyWith(fontSize: 36),
                ),
              ),
              const SizedBox(width: 12),
              const _FolksWordmark(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Column(
            children: [
              _pair(
                _Metric(
                  '${pending.where((task) => _day(task.end) == today).length}',
                  'Tarefas hoje',
                  FolksColors.white,
                ),
                _Metric(
                  '${pending.where((task) => _day(task.end).isBefore(today)).length}',
                  'Atrasadas',
                  _HomePalette.late,
                ),
              ),
              const SizedBox(height: 20),
              _pair(
                _Metric('${pending.length}', 'Pendentes', FolksColors.gold),
                _Metric(onTimeLabel, 'Entregas no Prazo', _HomePalette.onTime),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: InkWell(
            onTap: () => context.go('/kanban'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('PRIORIDADES DE HOJE', style: _sectionTitle),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (recent.isEmpty)
          const _Panel(
            padding: EdgeInsets.all(20),
            child: Text('Nenhuma tarefa pendente.'),
          )
        else
          for (final task in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _PriorityCard(
                task: task,
                today: today,
                onTap: () => context.go('/kanban'),
              ),
            ),
        if (recent.isEmpty) const SizedBox(height: 20),
        const Text('ACESSO RÁPIDO', style: _sectionTitle),
        const SizedBox(height: 16),
        _pair(
          _QuickAccess(
            'Funil de Vagas',
            'Acompanhar candidato por etapa',
            onTap: () => context.go('/funil-vagas'),
          ),
          const _QuickAccess('Desempenho', 'Avaliação por pessoa e etapa'),
          gap: 32,
        ),
      ],
    );
  }
}

DateTime _day(DateTime date) => DateUtils.dateOnly(date.toLocal());

const _sectionTitle = TextStyle(
  color: FolksColors.white,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

abstract final class _HomePalette {
  static const late = Color(0xFFFF434D);
  static const onTime = Color(0xFF26D556);
  static const progress = Color(0xFF676077);
  static const projectBlue = Color(0xFF7EABFF);
}

Widget _pair(Widget left, Widget right, {double gap = 22}) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: left),
      SizedBox(width: gap),
      Expanded(child: right),
    ],
  ),
);

class _FolksWordmark extends StatelessWidget {
  const _FolksWordmark();

  @override
  Widget build(BuildContext context) {
    // Recorta apenas a palavra e a assinatura da marca original do Figma.
    const scale = 66 / 1067;
    return Semantics(
      image: true,
      label: 'Folks RH',
      child: SizedBox(
        width: 66,
        height: 438 * scale,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 1973 * scale,
            maxWidth: 1973 * scale,
            minHeight: 747 * scale,
            maxHeight: 747 * scale,
            child: Transform.translate(
              offset: const Offset(-817 * scale, -194 * scale),
              child: Image.asset(
                'assets/brand/folks-white.png',
                excludeFromSemantics: true,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    required this.padding,
    this.onTap,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double elevation;

  @override
  Widget build(BuildContext context) => Material(
    color: FolksColors.card,
    borderRadius: BorderRadius.circular(9),
    clipBehavior: Clip.antiAlias,
    elevation: elevation,
    child: onTap == null
        ? Padding(padding: padding, child: child)
        : InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.fromLTRB(16, 11, 12, 14),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: FolksTheme.heading.copyWith(
              fontSize: 38,
              height: 1.02,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: FolksColors.white),
          ),
        ],
      ),
    ),
  );
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.task,
    required this.today,
    required this.onTap,
  });

  final KanbanTask task;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final end = _day(task.end);
    final daysLate = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(end.year, end.month, end.day)).inDays;
    final dateLabel = daysLate > 0
        ? 'Atrasada $daysLate ${daysLate == 1 ? 'dia' : 'dias'}'
        : daysLate == 0
        ? 'Vence hoje'
        : 'Prazo ${shortDate(end)}';
    final color = switch (task.project) {
      'Mentoria' || 'Financeiro' => _HomePalette.projectBlue,
      _ => projectColor(task.project),
    };
    return _Panel(
      onTap: onTap,
      elevation: 3,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      child: Text(
                        task.project,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                size: 8,
                color: task.priority == TaskPriority.high
                    ? _HomePalette.late
                    : priorityColor(task.priority),
              ),
              const SizedBox(width: 4),
              Text(
                task.priority.label,
                style: const TextStyle(fontSize: 10, color: FolksColors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: FolksTheme.heading.copyWith(fontSize: 19, height: 1.15),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Etapa atual: ${task.stage.label}',
            child: Row(
              children: [
                for (final stage in RecruitmentStage.values) ...[
                  if (stage.index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: stage.index < task.stage.index
                            ? _HomePalette.onTime
                            : stage == task.stage
                            ? FolksColors.gold
                            : _HomePalette.progress,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: FolksColors.sheet,
                radius: 9,
                child: Icon(Icons.person, size: 13, color: FolksColors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.assignee,
                  style: const TextStyle(
                    color: FolksColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: daysLate > 0 ? _HomePalette.late : FolksColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess(this.title, this.description, {this.onTap});
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: _Panel(
      elevation: 2,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FolksColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            description,
            style: const TextStyle(color: FolksColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
