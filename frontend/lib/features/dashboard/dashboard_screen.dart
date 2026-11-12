import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/folks_theme.dart';
import '../../core/widgets/folks_navigation.dart';
import '../kanban/kanban_controller.dart';
import '../kanban/task.dart';
import 'dashboard_metrics.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});
  final KanbanController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: FolksTheme.background),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final metrics = DashboardMetrics(
                    widget.controller.tasks,
                    DateTime.now(),
                    _days,
                  );
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        children: [
                          const Text('Dashboard', style: FolksTheme.heading),
                          const SizedBox(height: 16),
                          _Panel(
                            child: _Activities(counts: metrics.activities),
                          ),
                          const SizedBox(height: 16),
                          _Panel(child: _deliveries(metrics)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const FolksNavigation(selectedRoute: '/dashboard'),
          ],
        ),
      ),
    ),
  );

  Widget _deliveries(DashboardMetrics metrics) {
    final onTime = metrics.daily.fold(0, (sum, day) => sum + day.onTime);
    final late = metrics.daily.fold(0, (sum, day) => sum + day.late);
    final peak = metrics.daily.fold(1, (max, day) => math.max(max, day.total));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            const Text('Entregas', style: _panelHeading),
            PopupMenuButton<int>(
              tooltip: 'Período de entregas',
              initialValue: _days,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 7, child: Text('Uma semana')),
                PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
              ],
              onSelected: (value) => setState(() => _days = value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _days == 7 ? 'Uma semana' : 'Últimos 30 dias',
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
        Text('${metrics.deliveries.length} concluídas no total'),
        const SizedBox(height: 12),
        if (onTime + late == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhuma entrega no período.'),
          )
        else ...[
          Semantics(
            label:
                'Entregas nos últimos $_days dias: '
                '$onTime no prazo, $late em atraso.',
            image: true,
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomPaint(
                painter: _DeliveriesChart(daily: metrics.daily, peak: peak),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shortDate(metrics.daily.first.date)),
              Text(shortDate(metrics.daily.last.date)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _Legend(color: FolksColors.green, label: 'No prazo', count: onTime),
            _Legend(color: FolksColors.red, label: 'Em atraso', count: late),
          ],
        ),
        if (metrics.deliveries.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Ver tarefas concluídas'),
            children: [
              for (final task in metrics.deliveries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(task.title),
                  subtitle: Text(
                    task.completedAt == null
                        ? 'Data de conclusão não registrada'
                        : 'Concluída em ${shortDate(task.completedAt!.toLocal())}',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

const _panelHeading = TextStyle(
  fontFamily: 'InriaSerif',
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: FolksColors.card,
    borderRadius: BorderRadius.circular(10),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

const _stageColors = [
  Color(0xFFCD3AE5),
  Color(0xFFE7AC34),
  Color(0xFF7539DD),
  FolksColors.green,
];

class _Activities extends StatelessWidget {
  const _Activities({required this.counts});
  final Map<RecruitmentStage, int> counts;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final stage in RecruitmentStage.values) counts[stage]!,
    ];
    final pie = ExcludeSemantics(
      child: SizedBox.square(
        dimension: 128,
        child: CustomPaint(painter: _ActivitiesChart(values)),
      ),
    );
    final legend = Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final stage in RecruitmentStage.values)
          _Legend(
            color: _stageColors[stage.index],
            label: stage.label,
            count: counts[stage]!,
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Atividades alocadas', style: _panelHeading),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 19
              ? Row(
                  children: [
                    pie,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                )
              : Column(children: [pie, const SizedBox(height: 12), legend]),
        ),
        if (values.every((value) => value == 0)) ...[
          const SizedBox(height: 12),
          const Text('Nenhuma atividade em aberto.'),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.count,
  });
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, color: color, size: 10),
      const SizedBox(width: 5),
      Flexible(child: Text('$label: $count')),
    ],
  );
}

class _ActivitiesChart extends CustomPainter {
  const _ActivitiesChart(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0, (sum, count) => sum + count);
    final rect = Offset.zero & size;
    if (total == 0) {
      canvas.drawOval(rect, Paint()..color = FolksColors.border);
      return;
    }
    var angle = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      if (values[index] == 0) continue;
      final sweep = 2 * math.pi * values[index] / total;
      canvas.drawArc(
        rect,
        angle,
        sweep,
        true,
        Paint()..color = _stageColors[index],
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_ActivitiesChart oldDelegate) =>
      oldDelegate.values != values;
}

class _DeliveriesChart extends CustomPainter {
  const _DeliveriesChart({required this.daily, required this.peak});
  final List<DailyDeliveries> daily;
  final int peak;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = FolksColors.border;
    for (var index = 0; index <= 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final slot = size.width / daily.length;
    final width = math.min(22.0, slot * .62);
    for (var index = 0; index < daily.length; index++) {
      final day = daily[index];
      final onTime = size.height * day.onTime / peak;
      final late = size.height * day.late / peak;
      final x = index * slot + (slot - width) / 2;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - onTime, width, onTime),
        Paint()..color = FolksColors.green,
      );
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - onTime - late, width, late),
        Paint()..color = FolksColors.red,
      );
    }
  }

  @override
  bool shouldRepaint(_DeliveriesChart oldDelegate) =>
      oldDelegate.daily != daily;
}
