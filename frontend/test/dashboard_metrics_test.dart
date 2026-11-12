import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/dashboard_metrics.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/task.dart';

void main() {
  KanbanTask task(String id, {required DateTime due, DateTime? completed}) =>
      KanbanTask(
        id: id,
        title: id,
        project: 'Recrutamento',
        company: 'Empresa',
        role: 'Cargo',
        assignee: 'Pessoa',
        start: DateTime(2026, 10, 1),
        end: due,
        status: completed == null ? BoardStatus.todo : BoardStatus.done,
        completedAt: completed,
      );

  test('periodo usa dia de conclusao e separa prazo de atraso', () {
    final today = DateTime(2026, 11, 12);
    final tasks = [
      task('hoje', due: today, completed: DateTime(2026, 11, 12, 23)),
      task(
        'atrasada',
        due: DateTime(2026, 11, 5),
        completed: DateTime(2026, 11, 6),
      ),
      task(
        'anterior',
        due: DateTime(2026, 11, 5),
        completed: DateTime(2026, 11, 5),
      ),
      task('aberta', due: today),
      task('sem data', due: today).copyWith(status: BoardStatus.done),
    ];
    final week = DashboardMetrics(tasks, today, 7);
    expect(week.activities[RecruitmentStage.screening], 1);
    expect(week.deliveries.map((task) => task.id), [
      'hoje',
      'atrasada',
      'anterior',
      'sem data',
    ]);
    expect(week.daily.first.late, 1);
    expect(week.daily.last.onTime, 1);
    expect(week.daily.fold(0, (sum, day) => sum + day.total), 2);
    final month = DashboardMetrics(tasks, today, 30);
    expect(month.daily.fold(0, (sum, day) => sum + day.total), 3);
  });

  test('editar mantem a data; reabrir remove e reconcluir registra outra', () {
    var now = DateTime(2026, 11, 12);
    final controller = KanbanController(
      tasks: [task('tarefa', due: now)],
      now: () => now,
    );
    addTearDown(controller.dispose);
    KanbanTask current() => controller.tasks.single;
    controller.update(current().copyWith(status: BoardStatus.done));
    final firstCompletion = now;
    now = DateTime(2026, 11, 13);
    controller.update(current().copyWith(description: 'Editada'));
    expect(current().completedAt, firstCompletion);
    controller.update(current().copyWith(status: BoardStatus.waiting));
    expect(current().completedAt, isNull);
    controller.update(current().copyWith(status: BoardStatus.done));
    expect(current().completedAt, now);
  });
}
