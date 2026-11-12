import '../repositories/catalogs_repository.dart';
import '../dto/catalog_dto.dart';

import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../security.dart';

class CatalogService {
  final Database db;
  final CatalogRepository repository = CatalogRepository();
  CatalogService(this.db);

  Future<Row> list(QueryInput query, String name) =>
      repository.list(db, query, name);

  Future<Row> createClient(JsonInput input, Identity user) async {
    user.require('C');
    final data =
        input.only({'empresa', 'cnpj', 'representante', 'contato', 'email'});
    final company = string(data, 'empresa', max: 110);
    String? cnpj;
    if (data['cnpj'] != null) {
      cnpj = string(data, 'cnpj', max: 18).replaceAll(RegExp(r'[./-]'), '');
      if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
        invalid('cnpj deve ter 14 dígitos.');
      }
    }
    final row = await repository.insertClient(db, {
      'nome': company,
      'cnpj': cnpj,
      'representante': data['representante'] == null
          ? null
          : string(data, 'representante', max: 100),
      'contato':
          data['contato'] == null ? null : string(data, 'contato', max: 100),
      'email': data['email'] == null ? null : email(data, 'email'),
    });
    return serializeCatalog('clientes', row!);
  }

  Future<Row> createChannel(JsonInput input, Identity user) async {
    user.require('C');
    final data = input.only({'nome', 'chave'});
    final key = string(data, 'chave', max: 60).toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(key)) {
      invalid('chave deve usar letras minúsculas, números, _ ou -.');
    }
    final row = await repository.insertChannel(
        db, {'nome': string(data, 'nome', max: 60), 'chave': key});
    return serializeCatalog('divulgacoes', row!);
  }
}
