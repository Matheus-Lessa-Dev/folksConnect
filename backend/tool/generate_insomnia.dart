import 'dart:convert';
import 'dart:io';

// Executar a partir de backend/: dart run tool/generate_insomnia.dart
void main() {
  const pretty = JsonEncoder.withIndent('  ');
  const workspace = 'wrk_folksconnect';
  final resources = <Map<String, dynamic>>[
    {
      '_id': workspace,
      '_type': 'workspace',
      'parentId': null,
      'name': 'Folks Connect API',
      'scope': 'collection',
      'description':
          '35 endpoints. Inicie pelo Login e copie o token para o ambiente. Consulte docs/backend.md. IDs devem vir das respostas reais.'
    },
    {
      '_id': 'env_folksconnect',
      '_type': 'environment',
      'parentId': workspace,
      'name': 'Ambiente local',
      'data': {
        'base_url': 'http://localhost:8081/api',
        'email': 'admin@folks.local',
        'senha': 'FolksDev!2026',
        'token': '',
        'cargoId': 2,
        'projetoId': 1,
        'prioridadeId': 2,
        'responsavelId': 1,
        'clienteId': 1,
        'canalId': 1,
        'usuarioId': 2,
        'tarefaId': 1,
        'statusId': 2,
        'etapaId': 2,
        'itemId': 1,
        'anexoId': 1,
        'tokenRecuperacao': '',
        'configuracoes':
            'COPIE AQUI O JSON COMPLETO DE GET /configuracoes ANTES DE USAR PUT',
      },
      'dataPropertyOrder': null,
      'isPrivate': false,
      'color': null
    },
    {
      '_id': 'jar_folksconnect',
      '_type': 'cookie_jar',
      'parentId': workspace,
      'name': 'Default Jar',
      'cookies': []
    },
  ];
  var index = 0;
  void request(String group, String method, String path, String name,
      {Map<String, dynamic>? data,
      String? raw,
      bool public = false,
      bool multipart = false,
      String description = ''}) {
    final folder = 'fld_folks_${group.substring(0, 2)}';
    if (!resources.any((r) => r['_id'] == folder)) {
      resources.add({
        '_id': folder,
        '_type': 'request_group',
        'parentId': workspace,
        'name': group,
        'description': '',
        'environment': {},
        'metaSortKey': resources.length
      });
    }
    resources.add({
      '_id': 'req_folks_${++index}',
      '_type': 'request',
      'parentId': folder,
      'name': name,
      'method': method,
      'url': '{{ _.base_url }}$path',
      'description': description,
      'body': multipart
          ? {
              'mimeType': 'multipart/form-data',
              'params': [
                {
                  'id': 'pair_arquivo',
                  'name': 'arquivo',
                  'type': 'file',
                  'fileName': '',
                  'disabled': false
                },
              ]
            }
          : data != null || raw != null
              ? {
                  'mimeType': 'application/json',
                  'text': raw ?? pretty.convert(data)
                }
              : {},
      'parameters': [],
      'headers': [
        if (!public) {'name': 'Authorization', 'value': 'Bearer {{ _.token }}'},
        if (data != null || raw != null)
          {'name': 'Content-Type', 'value': 'application/json'},
      ],
      'authentication': {},
      'metaSortKey': index,
      'isPrivate': false,
      'settingStoreCookies': false,
      'settingSendCookies': false,
      'settingDisableRenderRequestBody': false,
      'settingEncodeUrl': true,
      'settingRebuildPath': true,
      'settingFollowRedirects': 'global'
    });
  }

  request('01 Serviço', 'GET', '', 'Identificação', public: true);
  request('01 Serviço', 'GET', '/health', 'Health com PostgreSQL',
      public: true);
  request('02 Autenticação', 'POST', '/auth/login', 'Login',
      public: true,
      data: {'email': '{{ _.email }}', 'senha': '{{ _.senha }}'},
      description:
          'Copie token da resposta para a variável token do ambiente. Sessão dura 12 horas.');
  request('02 Autenticação', 'POST', '/auth/logout', 'Logout');
  request('02 Autenticação', 'POST', '/auth/recuperar-senha',
      'Solicitar recuperação',
      public: true,
      data: {'email': '{{ _.email }}'},
      description:
          'Exige SMTP configurado. Token é enviado por e-mail e não é retornado pela API.');
  request('02 Autenticação', 'POST', '/auth/redefinir-senha', 'Redefinir senha',
      public: true,
      data: {
        'token': '{{ _.tokenRecuperacao }}',
        'senha': 'NovaSenhaSegura!2026'
      },
      description:
          'Use o token recebido por e-mail. Todas as sessões serão revogadas. Atualize senha no ambiente após redefinir.');
  request('03 Perfil e usuários', 'GET', '/usuarios/me', 'Meu perfil');
  request(
      '03 Perfil e usuários', 'PATCH', '/usuarios/me', 'Atualizar meu perfil',
      data: {'nome': 'Meu nome'});
  request('03 Perfil e usuários', 'GET', '/usuarios?page=1&limit=100',
      'Listar usuários');
  request('03 Perfil e usuários', 'POST', '/usuarios', 'Cadastrar usuário',
      raw: '''{
  "nome": "Analista",
  "email": "analista@example.com",
  "senha": "SenhaInicial!2026",
  "cargoId": {{ _.cargoId }},
  "projetoId": {{ _.projetoId }},
  "permissoes": []
}''',
      description:
          'Consulte permissões e escolha IDs a conceder. Operador comum só pode conceder permissões que possui.');
  request('03 Perfil e usuários', 'PATCH', '/usuarios/{{ _.usuarioId }}',
      'Alterar cargo',
      raw: '{"cargoId": {{ _.cargoId }}}');
  request('03 Perfil e usuários', 'DELETE', '/usuarios/{{ _.usuarioId }}',
      'Desativar usuário',
      description:
          'Revoga sessões e mantém vínculos. Não permite desativar a si mesmo ou o administrador de bootstrap.');
  for (final catalog in [
    'cargos',
    'permissoes',
    'projetos',
    'prioridades',
    'clientes',
    'divulgacoes'
  ]) {
    request(
        '04 Catálogos', 'GET', '/$catalog?page=1&limit=100', 'Listar $catalog');
  }
  request('04 Catálogos', 'POST', '/clientes', 'Cadastrar cliente',
      data: {
        'empresa': 'Nome da empresa',
        'representante': 'Contato responsável',
        'email': 'contato@example.com'
      },
      description:
          'Somente empresa é obrigatória. Salve id como clienteId no ambiente. CNPJ, representante, contato e email são opcionais.');
  request('04 Catálogos', 'POST', '/divulgacoes', 'Cadastrar canal',
      data: {'nome': 'LinkedIn', 'chave': 'linkedin'},
      description: 'Salve id como canalId no ambiente.');
  request(
      '05 Configurações', 'GET', '/configuracoes', 'Consultar configurações',
      description:
          'Copie o objeto JSON completo para a variável configuracoes antes de usar PUT.');
  request('05 Configurações', 'PUT', '/configuracoes', 'Salvar as três seções',
      raw: '{{ _.configuracoes }}',
      description:
          'Edite o JSON integral do GET. Preserve IDs existentes; novos itens sem id. Itens omitidos serão removidos. Etapas em uso são protegidas.');
  request('06 Tarefas', 'GET',
      '/tarefas?page=1&limit=20&projetoId={{ _.projetoId }}', 'Listar tarefas',
      description:
          'Filtros: projetoId, clienteId, statusId, etapaId, responsavelId, prioridadeId, busca, prazoInicial, prazoFinal.');
  request('06 Tarefas', 'POST', '/tarefas', 'Criar tarefa',
      raw: '''{
  "titulo": "Recrutamento para desenvolvimento",
  "descricao": "Validar os requisitos com o cliente",
  "cargo": "Desenvolvedor Sênior",
  "projetoId": {{ _.projetoId }},
  "clienteId": {{ _.clienteId }},
  "responsavelId": {{ _.responsavelId }},
  "prioridadeId": {{ _.prioridadeId }},
  "prazoInicial": "2026-11-03",
  "prazoFinal": "2026-11-30"
}''',
      description:
          'Salve id como tarefaId. Status/etapa iniciais e checklist vêm das configurações atuais.');
  request('06 Tarefas', 'GET', '/tarefas/{{ _.tarefaId }}',
      'Detalhes, checklist e anexos');
  request('06 Tarefas', 'PATCH', '/tarefas/{{ _.tarefaId }}', 'Editar tarefa',
      raw:
          '{"responsavelId": {{ _.responsavelId }}, "prioridadeId": {{ _.prioridadeId }}, "descricao": "Descrição atualizada"}');
  request('06 Tarefas', 'PATCH', '/tarefas/{{ _.tarefaId }}/status',
      'Mover no Kanban',
      raw: '{"statusId": {{ _.statusId }}}');
  request('06 Tarefas', 'POST', '/tarefas/{{ _.tarefaId }}/avancos',
      'Avançar recrutamento',
      raw:
          '{"etapaId": {{ _.etapaId }}, "responsavelId": {{ _.responsavelId }}}',
      description:
          'etapaId deve ser posterior à atual segundo a ordem configurada.');
  request('06 Tarefas', 'POST', '/tarefas/{{ _.tarefaId }}/checklist/itens',
      'Adicionar item de checklist',
      data: {'nome': 'Conferir documentos'},
      description: 'Salve id como itemId no ambiente.');
  request(
      '06 Tarefas',
      'PATCH',
      '/tarefas/{{ _.tarefaId }}/checklist/itens/{{ _.itemId }}',
      'Marcar ou desmarcar item',
      data: {'concluido': true});
  request('07 Anexos', 'POST', '/tarefas/{{ _.tarefaId }}/anexos',
      'Enviar arquivos',
      multipart: true,
      description:
          'Selecione arquivo no campo arquivo. Para vários, use campos arquivos (máximo 10). Cada arquivo até 10 MiB. Salve items[0].id como anexoId.');
  request('07 Anexos', 'GET',
      '/tarefas/{{ _.tarefaId }}/anexos/{{ _.anexoId }}', 'Baixar anexo');
  request('07 Anexos', 'DELETE',
      '/tarefas/{{ _.tarefaId }}/anexos/{{ _.anexoId }}', 'Remover anexo');
  request('08 Vagas', 'GET', '/vagas?page=1&limit=20', 'Listar vagas',
      description:
          'Filtros: clienteId, responsavelId, etapaId, canalId e busca. Indicadores sem fonte definida são nulos.');
  request('08 Vagas', 'POST', '/vagas', 'Criar vaga', raw: '''{
  "cargo": "Desenvolvedor Sênior",
  "perfilDesejado": "Experiência com Dart e PostgreSQL",
  "clienteId": {{ _.clienteId }},
  "responsavelId": {{ _.responsavelId }},
  "prazoInicial": "2026-11-03",
  "prazoFinal": "2026-11-30",
  "canais": [{{ _.canalId }}]
}''');

  final output = File('../docs/insomnia/folks-connect.json');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync('${pretty.convert({
        '_type': 'export',
        '__export_format': 4,
        '__export_date': '2026-11-03T00:00:00.000Z',
        '__export_source': 'folks-connect-backend',
        'resources': resources
      })}\n');
  stdout.writeln('Coleção gerada: $index requisições.');
  if (index != 35) {
    throw StateError('A coleção deve conter todos os 35 endpoints.');
  }
}
