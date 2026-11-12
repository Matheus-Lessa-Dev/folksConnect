import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import 'shared_repository.dart';
import '../dto/catalog_dto.dart';

class CatalogRepository {
  Future<Row> list(Database db, QueryInput query, String name) async {
    query.only({'busca', 'page', 'limit'});
    final specs = <String, (String, String)>{
      'cargos': ('cargos', 'id_cargo'),
      'projetos': ('projetos', 'id_projeto'),
      'prioridades': ('prioridades', 'id_prioridade'),
      'permissoes': ('permissoes', 'id_permissoes'),
      'clientes': ('clientes', 'id_cliente'),
      'divulgacoes': ('divulgacoes', 'id_divulgacao'),
    };
    final spec = specs[name]!;
    final search = query.values['busca'] ?? '';
    if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
    return page(db, query, '*', 'FROM ${spec.$1}', 'nome ILIKE @search',
        {'search': '%$search%'}, spec.$2,
        map: (row) => serializeCatalog(name, row));
  }

  Future<Row?> insertChannel(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'INSERT INTO divulgacoes (nome, chave) VALUES (@nome, @chave) RETURNING *',
          args);

  Future<Row?> insertClient(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          '''INSERT INTO clientes (nome, cnpj, representante, contato, email)
      VALUES (@nome, @cnpj, @representante, @contato, @email) RETURNING *''',
          args);
}
