import '../database.dart';
import '../models/models.dart';

Row serializeCatalog(String name, Row row) {
  switch (name) {
    case 'cargos':
      final model = Cargo(
          idCargo: row['id_cargo'] as int,
          chave: row['chave'] as String,
          nome: row['nome'] as String);
      return {'id': model.idCargo, 'chave': model.chave, 'nome': model.nome};
    case 'projetos':
      final model = Projeto(
          idProjeto: row['id_projeto'] as int, nome: row['nome'] as String);
      return {'id': model.idProjeto, 'nome': model.nome};
    case 'prioridades':
      final model = Prioridade(
          idPrioridade: row['id_prioridade'] as int,
          nome: row['nome'] as String,
          valor: row['valor'] as int);
      return {
        'id': model.idPrioridade,
        'nome': model.nome,
        'valor': model.valor
      };
    case 'permissoes':
      final model = Permissao(
          idPermissoes: row['id_permissoes'] as int,
          nome: row['nome'] as String,
          chave: row['chave'] as String);
      return {
        'id': model.idPermissoes,
        'nome': model.nome,
        'chave': model.chave
      };
    case 'divulgacoes':
      final model = Divulgacao(
          idDivulgacao: row['id_divulgacao'] as int,
          nome: row['nome'] as String,
          chave: row['chave'] as String);
      return {
        'id': model.idDivulgacao,
        'nome': model.nome,
        'chave': model.chave
      };
    default:
      final model = Cliente(
          idCliente: row['id_cliente'] as int,
          nome: row['nome'] as String,
          cnpj: row['cnpj'] as String?,
          representante: row['representante'] as String?);
      return {
        'id': model.idCliente,
        'empresa': model.nome,
        'cnpj': model.cnpj,
        'representante': model.representante,
        'contato': row['contato'],
        'email': row['email']
      };
  }
}
