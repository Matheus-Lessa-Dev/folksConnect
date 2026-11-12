import '../kanban/task.dart';

class DashboardMetrics {
  DashboardMetrics(Iterable<KanbanTask> tasks, DateTime now, int days)
    : activities = {for (final stage in RecruitmentStage.values) stage: 0},
      daily = List.generate(
        days,
        (index) => DailyDeliveries(
          DateTime(now.year, now.month, now.day - days + 1 + index),
        ),
      ) {
    final byDay = {for (final bucket in daily) bucket.date: bucket};
    for (final task in tasks) {
      if (task.status != BoardStatus.done) {
        activities.update(task.stage, (count) => count + 1);
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

  final Map<RecruitmentStage, int> activities;
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
