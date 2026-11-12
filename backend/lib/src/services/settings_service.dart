import '../repositories/settings_repository.dart';

import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../security.dart';

class SettingsService {
  final Database db;
  final SettingsRepository repository = SettingsRepository();
  SettingsService(this.db);
  static const sections = <String, (String, String, String, String)>{
    'kanban': ('etapas_kanban', 'id', 'G', 'H'),
    'funil': ('etapas_funil', 'id', 'I', 'J'),
    'checklist': ('checklists', 'id_checklist', 'K', 'L'),
  };

  Future<Row> read(Database tx) async {
    final result = <String, dynamic>{};
    for (final entry in sections.entries) {
      final (table, key, _, _) = entry.value;
      result[entry.key] = await repository.readSection(tx, table, key);
    }
    return result;
  }

  Future<Row> get() => db.transaction((tx) async {
        await repository.snapshot(tx);
        return await read(tx);
      });

  Future<Row> put(JsonInput input, Identity user) async {
    final data = input.only(sections.keys.toSet());
    final desired = <String, List<Row>>{};
    for (final section in sections.keys) {
      final raw = data[section];
      if (raw is! List || raw.isEmpty || raw.length > 100) {
        invalid('$section deve ter de 1 a 100 itens.');
      }
      final names = <String>{};
      final orders = <int>{};
      final identifiers = <int>{};
      desired[section] = raw.map((item) {
        if (item is! Map<String, dynamic> ||
            item.keys.toSet().difference({'id', 'nome', 'ordem'}).isNotEmpty) {
          invalid('Item inválido em $section.');
        }
        final name = string(item, 'nome');
        final order = integer(item['ordem'], 'ordem', min: 0, max: 10000);
        final id = item['id'] == null ? null : integer(item['id'], 'id');
        if (!names.add(name.toLowerCase()) ||
            !orders.add(order) ||
            (id != null && !identifiers.add(id))) {
          invalid('$section contém nome, ordem ou ID repetido.');
        }
        return <String, dynamic>{'id': id, 'nome': name, 'ordem': order};
      }).toList();
    }
    return db.transaction((tx) async {
      await repository.lockConfiguration(tx);
      final current = await read(tx);
      for (final entry in sections.entries) {
        final (table, key, createPermission, editPermission) = entry.value;
        final old = (current[entry.key] as List<Row>);
        final next = desired[entry.key]!;
        final oldById = {for (final row in old) row['id'] as int: row};
        final retained = <int>{};
        var changed = false;
        for (final row in next) {
          final id = row['id'] as int?;
          if (id == null) {
            user.require(createPermission);
            continue;
          }
          final before = oldById[id];
          if (before == null) invalid('ID de $table inexistente: $id.');
          retained.add(id);
          if (before['nome'] != row['nome'] ||
              before['ordem'] != row['ordem']) {
            changed = true;
          }
        }
        final removed = oldById.keys.toSet().difference(retained);
        if (changed || removed.isNotEmpty) user.require(editPermission);
        for (final id in removed) {
          // As FKs bloqueiam etapas em uso, inclusive no histórico de avanços.
          await repository.deleteSectionItem(tx, table, key, {'id': id});
        }
        // Permite trocar dois nomes sem violar a unicidade durante a transação.
        if (changed) {
          final temporary = randomToken(12);
          for (final id in retained) {
            await repository.temporaryName(
                tx, table, key, {'id': id, 'nome': '__$temporary-$id'});
          }
        }
        for (final row in next) {
          if (row['id'] == null) {
            await repository.insertSectionItem(
                tx, table, {'nome': row['nome'], 'ordem': row['ordem']});
          } else if (changed) {
            await repository.updateSectionItem(tx, table, key, row);
          }
        }
      }
      return await read(tx);
    });
  }
}
