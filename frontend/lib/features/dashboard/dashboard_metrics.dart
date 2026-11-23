import '../kanban/task.dart';
import '../../core/funnel_stages.dart';

class DashboardMetrics {
  DashboardMetrics(
    Iterable<KanbanTask> tasks,
    DateTime now,
    int days, {
    int? stageCount,
  }) : activities = List.filled(stageCount ?? FunnelStages.defaults.length, 0),
      daily = List.generate(
        days,
        (index) => DailyDeliveries(
          DateTime(now.year, now.month, now.day - days + 1 + index),
        ),
      ) {
    final byDay = {for (final bucket in daily) bucket.date: bucket};
    for (final task in tasks) {
      if (task.status != BoardStatus.done) {
        final stage = task.stage >= activities.length
            ? activities.length - 1
            : task.stage;
        activities[stage]++;
        continue;
      }
      deliveries.add(task);
      final completed = task.completedAt?.toLocal();
      if (completed == null) continue;
      final bucket = byDay[_dateOnly(completed)];
      if (bucket == null) continue;
      if (_dateOnly(completed).isAfter(_dateOnly(task.end.toLocal()))) {
        bucket.late++;
      } else {
        bucket.onTime++;
      }
    }
    deliveries.sort((a, b) {
      if (a.completedAt == null) return b.completedAt == null ? 0 : 1;
      if (b.completedAt == null) return -1;
      return b.completedAt!.compareTo(a.completedAt!);
    });
  }

  /// Atividades em aberto por etapa do funil, na ordem das Configurações.
  final List<int> activities;
  final List<DailyDeliveries> daily;
  final List<KanbanTask> deliveries = [];

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class DailyDeliveries {
  DailyDeliveries(this.date);
  final DateTime date;
  int onTime = 0;
  int late = 0;
  int get total => onTime + late;
}
