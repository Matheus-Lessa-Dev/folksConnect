import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';

Future<void> reference(Database db, String table, String column, int id,
    {bool active = false}) async {
  // Os identificadores vêm exclusivamente de constantes do código.
  final result = await db.one(
      'SELECT $column FROM $table WHERE $column = @id${active ? ' AND ativo' : ''} FOR SHARE',
      {'id': id});
  if (result == null) invalid('Referência inválida: $table/$id.');
}

Future<Row> page(Database db, QueryInput query, String select, String from,
    String where, Map<String, Object?> params, String order,
    {Row Function(Row)? map}) async {
  final current = query.page;
  final limit = query.limit;
  return db.transaction((tx) async {
    await tx.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    final count =
        await tx.one('SELECT count(*) AS total $from WHERE $where', params);
    final items = await tx.query(
        'SELECT $select $from WHERE $where ORDER BY $order LIMIT @limit OFFSET @offset',
        {...params, 'limit': limit, 'offset': (current - 1) * limit});
    return {
      'items': map == null ? items : items.map(map).toList(),
      'total': count!['total'],
      'page': current,
      'limit': limit
    };
  });
}
