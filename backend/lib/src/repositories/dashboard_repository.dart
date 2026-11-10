import '../database.dart';
import '../dto/dashboard_filter.dart';

class DashboardRepository {
  static const taskWhere =
      '''t.prazo_inicial BETWEEN CAST(@inicio AS date) AND CAST(@fim AS date)
    AND (CAST(@responsavel AS integer) IS NULL OR t.id_usuario = @responsavel)
    AND (CAST(@projeto AS integer) IS NULL OR t.id_projeto = @projeto)''';
  static const deliveryWhere =
      '''d.concluido_em >= CAST(@inicio AS date)::timestamp AT TIME ZONE 'UTC'
    AND d.concluido_em < (CAST(@fim AS date) + 1)::timestamp AT TIME ZONE 'UTC'
    AND (CAST(@responsavel AS integer) IS NULL OR d.responsavel_id = @responsavel)
    AND (CAST(@projeto AS integer) IS NULL OR d.projeto_id = @projeto)''';
  Future<Row> activities(Database db, DashboardFilter filter) =>
      db.transaction((tx) async {
        await tx.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
        final status = await tx
            .query('''SELECT e.id, e.nome, e.ordem, count(t.id_tarefa) AS total
      FROM etapas_kanban e LEFT JOIN tarefas t ON t.status_id = e.id AND $taskWhere
      GROUP BY e.id ORDER BY e.ordem, e.id''', filter.parameters);
        final stages = await tx
            .query('''SELECT e.id, e.nome, e.ordem, count(t.id_tarefa) AS total
      FROM etapas_funil e LEFT JOIN tarefas t ON t.etapa_id = e.id AND $taskWhere
      GROUP BY e.id ORDER BY e.ordem, e.id''', filter.parameters);
        return {
          'filtros': filter.json,
          'total': status.fold<int>(0, (sum, r) => sum + (r['total'] as int)),
          'porStatus': status,
          'porEtapa': stages
        };
      });
  Future<Row> deliveries(Database db, DashboardFilter filter) =>
      db.transaction((tx) async {
        await tx.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
        final daily = await tx.query(
            '''SELECT to_char(d.concluido_em AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS dia, count(*) AS total
      FROM entregas_tarefa d WHERE $deliveryWhere GROUP BY dia ORDER BY dia''',
            filter.parameters);
        final responsible = await tx.query(
            '''SELECT u.id_usuario AS id, u.nome, count(*) AS total
      FROM entregas_tarefa d JOIN usuarios u ON u.id_usuario = d.responsavel_id
      WHERE $deliveryWhere GROUP BY u.id_usuario ORDER BY u.id_usuario''',
            filter.parameters);
        return {
          'filtros': filter.json,
          'total': daily.fold<int>(0, (sum, r) => sum + (r['total'] as int)),
          'porDia': daily,
          'porResponsavel': responsible
        };
      });
}
