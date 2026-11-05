# Folks Connect — Rotas do backend

Documento de planejamento baseado no código, nas telas implementadas e no [Figma Folks Mobile](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile).

Base local: `http://localhost:8081/api`.

Somente `GET /api` e `GET /api/health` estão implementados. As demais rotas deste documento são propostas de contrato e precisam ser desenvolvidas. As telas atuais usam dados em memória.

## 1. Autenticação e perfil

| Método | Rota | Finalidade |
|---|---|---|
| POST | `/api/auth/login` | Autenticar com e-mail e senha e iniciar sessão. |
| POST | `/api/auth/logout` | Encerrar a sessão. |
| GET | `/api/usuarios/me` | Retornar perfil, cargo e permissões do usuário autenticado. |
| PATCH | `/api/usuarios/me` | Atualizar os dados editáveis do próprio perfil. |
| POST | `/api/auth/recuperar-senha` | Solicitar recuperação pelo link do login. |
| POST | `/api/auth/redefinir-senha` | Definir nova senha usando o token de recuperação. |

Se a autenticação usar tokens com renovação, acrescentar `POST /api/auth/refresh`. Essa necessidade depende da estratégia de sessão escolhida.

A alteração de cargo no próprio perfil precisa de regra de autorização; não deve permitir elevação de acesso por decisão do cliente.

## 2. Kanban e tarefas

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/api/tarefas` | Listar tarefas para quadro e lista, com filtros e paginação. |
| POST | `/api/tarefas` | Cadastrar tarefa. |
| GET | `/api/tarefas/{id}` | Consultar detalhes, checklist e metadados dos anexos. |
| PATCH | `/api/tarefas/{id}` | Atualizar responsável, prioridade e descrição. |
| PATCH | `/api/tarefas/{id}/status` | Mover entre A fazer, Em andamento, Aguardando e Concluído. |
| POST | `/api/tarefas/{id}/avancos` | Confirmar avanço da etapa de recrutamento e atribuir responsável. |
| POST | `/api/tarefas/{id}/checklist/itens` | Adicionar item ao checklist da tarefa. |
| PATCH | `/api/tarefas/{id}/checklist/itens/{itemId}` | Marcar ou desmarcar item. |
| POST | `/api/tarefas/{id}/anexos` | Enviar arquivos, com limite atual de 10 MB por arquivo. |
| GET | `/api/tarefas/{id}/anexos/{anexoId}` | Acessar ou baixar anexo. |
| DELETE | `/api/tarefas/{id}/anexos/{anexoId}` | Remover anexo. |

Exemplo de filtro: `GET /api/tarefas?projetoId=1&statusId=2&page=1&limit=20`.

Regras:

- Quadro e lista consomem a mesma rota.
- Status do quadro e etapa de recrutamento são independentes.
- O avanço deve validar uma etapa posterior à atual e salvar etapa e responsável na mesma transação.
- A criação contempla título, projeto, empresa, cargo, responsável, datas e prioridade.

## 3. Funil de vagas, clientes e divulgação

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/api/vagas` | Listar cartões com cliente, cargo, datas, etapa e indicadores. |
| POST | `/api/vagas` | Cadastrar vaga com perfil desejado, responsável, período e canais. |
| GET | `/api/clientes` | Consultar e pesquisar clientes para os seletores. |
| POST | `/api/clientes` | Cadastrar cliente dentro do formulário da vaga. |
| GET | `/api/divulgacoes` | Listar canais disponíveis. |
| POST | `/api/divulgacoes` | Cadastrar canal pelo botão de adicionar. |

Os canais selecionados podem ser enviados como uma lista de IDs no próprio `POST /api/vagas`.

A listagem deve fornecer os dados para os indicadores de inscritos, candidatos ideais e erros. A origem desses dados e a fórmula de candidatos ideais precisam ser definidas.

O formulário de cliente contempla empresa, CNPJ, representante, contato e e-mail. No frontend atual, apenas a empresa é obrigatória; e-mail informado deve ter formato válido. A regra definitiva precisa ser confirmada.

A janela de três dias para apresentar “Perto de Fechar” é uma regra provisória do frontend.

## 4. Usuários, cargos e permissões

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/api/usuarios` | Listar usuários e alimentar seletores de responsáveis. |
| POST | `/api/usuarios` | Cadastrar nome, e-mail, cargo e permissões. |
| PATCH | `/api/usuarios/{id}` | Alterar cargo do usuário, conforme a tela atual. |
| DELETE | `/api/usuarios/{id}` | Remover ou desativar usuário, preservando vínculos necessários. |
| GET | `/api/cargos` | Listar cargos/papéis internos dos usuários. |
| GET | `/api/permissoes` | Listar permissões disponíveis no cadastro. |

As permissões podem ser enviadas junto ao cadastro. Uma rota específica para alterá-las posteriormente depende da definição desse fluxo.

O backend deve verificar autorização em cada operação protegida. O cadastro atual da interface não define como serão criadas ou entregues as credenciais reais de acesso.

Permissões apresentadas na tela:

- Importar Planilha.
- Cadastrar Tarefas.
- Cadastrar Vaga.
- Editar Vaga.
- Cadastrar Usuário.
- Editar Usuário.
- Cadastrar Etapas do Kanban.
- Editar Etapas do Kanban.
- Cadastrar Etapas do Funil de Vendas.
- Editar Etapas do Funil de Vendas.
- Cadastrar Etapas do CheckList.
- Editar Etapas do CheckList.

“Funil de Vendas” reproduz o rótulo das permissões atuais; a tela do aplicativo é Funil de Vagas. A nomenclatura deve ser unificada ao definir o contrato.

## 5. Configurações gerais e catálogos

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/api/configuracoes` | Carregar etapas do Kanban, etapas do funil e checklist padrão. |
| PUT | `/api/configuracoes` | Salvar integralmente as três seções na mesma transação. |
| GET | `/api/projetos` | Alimentar filtros e cadastro de tarefas. |
| GET | `/api/prioridades` | Alimentar opções de prioridade. |

O `PUT /api/configuracoes` atende à edição, adição e remoção de itens antes de clicar em “Salvar Alteração”.

Regras:

- Cada item precisa de identificador estável e ordenação.
- Cada seção exige ao menos um item, sem nomes vazios ou repetidos.
- Excluir etapas em uso exige bloqueio ou indicação de substituta.
- Alterações de configurações precisam ser integradas aos dados reais do Kanban e do funil; hoje os controllers são independentes.

## 6. Funcionalidades previstas com fluxo pendente

O Figma apresenta Dashboard com “Atividades Alocadas” e “Entregas”, ainda sem tela implementada no Flutter.

| Método | Rota proposta | Finalidade e pendência |
|---|---|---|
| GET | `/api/dashboard/atividades` | Agregar atividades por etapa; confirmar quais registros entram na contagem. |
| GET | `/api/dashboard/entregas` | Retornar entregas por período; confirmar significado das séries e filtros. |
| PATCH | `/api/vagas/{id}` | Editar vaga; existe permissão, mas o fluxo atual não implementa edição. |
| POST | `/api/importacoes` | Receber planilha; definir formato, destino dos dados e tratamento de erros. |

Não há evidência suficiente para especificar CRUD de candidatos ou integrações de publicação nos canais.

## 7. Necessidades de persistência a definir

Esta seção descreve necessidades das telas, não um schema definitivo. Nenhuma migration acompanha este documento.

- Usuários: nome, e-mail, papel, permissões e estratégia de credenciais, sessões e recuperação de senha.
- Tarefas: título, descrição, datas, prioridade, responsável, projeto, cliente, cargo, status e etapa de recrutamento.
- Checklist: modelo padrão separado dos itens e do estado de conclusão de cada tarefa.
- Anexos: armazenamento dos arquivos e metadados vinculados à tarefa.
- Clientes: empresa, CNPJ, representante, contato e e-mail, com obrigatoriedade a confirmar.
- Etapas: identificadores estáveis, ordenação e regras para alteração de itens em uso.
- Vagas: etapa, responsável, cliente, período, perfil desejado e múltiplos canais.
- Indicadores: origem, cálculo e atualização de inscritos, candidatos ideais, erros e entregas.
- Cargos: distinguir o papel interno do usuário, como Analista/Gerente, do cargo da oportunidade, como Desenvolvedor Sênior.

## 8. Ordem sugerida de implementação

1. Autenticação e perfil.
2. Catálogos e usuários.
3. Tarefas, checklist e anexos.
4. Vagas, clientes e canais.
5. Configurações integradas aos dados reais.
6. Dashboard e importação, após definição das regras pendentes.

## 9. Referências

- `backend/bin/server.dart`.
- `frontend/lib/features/auth/authentication_service.dart`.
- `frontend/lib/features/kanban/kanban_controller.dart` e `task.dart`.
- `frontend/lib/features/vacancy_funnel/vacancy_funnel_controller.dart` e `vacancy.dart`.
- `frontend/lib/features/settings/settings_controller.dart`.
- `docs/kanban.md`, `docs/funil-vagas.md`, `docs/configuracoes.md` e `docs/figma/README.md`.
- [Figma Folks Mobile](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile).
