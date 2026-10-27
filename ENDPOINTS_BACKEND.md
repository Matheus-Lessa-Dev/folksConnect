# Folks Connect — levantamento de endpoints do backend

Data da análise: **26/10/2026**. Branch: `feature/documentacao-endpoints`, criada a partir de `develop`.

Fonte de verdade: [Folks Mobile no Figma](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile).

## 1. Escopo e resultado

Foram lidos, pelo Playwright MCP, os **18 frames de interface da Page 1** e suas **3.424 camadas**, incluindo formulários, sobreposições e cópias das telas de fundo. A contagem inclui grupos, ícones e outros elementos gráficos. A página também contém logos, ícones e o mapa visual; esses elementos não originam endpoints de negócio.

O catálogo abaixo propõe **40 combinações de método HTTP e rota** para atender aos comportamentos identificados. Os caminhos, nomes de campos e métodos de serviço são uma proposta de contrato: o Figma define a interface, não a API. A seção 7 separa extensões condicionais que não devem ser tratadas como requisitos confirmados.

Classificação da evidência:

- **O — observado:** há campo, ação ou informação correspondente nos frames.
- **T — técnico:** suporte de backend inferido para sustentar o fluxo, sem tela específica.
- **P — parcial:** existe botão, link ou intenção, mas faltam telas ou regras para fechar o contrato.

Todas as rotas de negócio deste documento **precisam ser criadas**. Em `backend/bin/server.dart`, existem somente `GET /api` e `GET /api/health`. Os modelos e a migration inicial não constituem implementações de endpoints.

## 2. Inventário das telas e rastreabilidade

Os nomes abaixo preservam a escrita do arquivo Figma. Os links levam ao frame correspondente.

| Frame | Camadas lidas | Comportamentos que afetam o backend |
| --- | ---: | --- |
| [Iniciando](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=9-1163) | 18 | Abertura e acesso ao login; não exige uma rota própria. |
| [Login](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=9-1164) | 32 | Usuário, senha, entrar e link “Esqueceu a Senha?”. |
| [config geral](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-332) | 81 | Adicionar/remover etapas do Kanban e do funil, manter checklist padrão e salvar alterações. |
| [Funil_Vagas +](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-595) | 273 | Cadastrar vaga: cargo, perfil desejado, canais, cliente, responsável e prazos. |
| [Funil_Vagas + 4](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-1056) | 292 | Cadastro de cliente dentro do cadastro de vaga: empresa, CNPJ, representante, contato e e-mail. |
| [Funil_vagas + 2](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-828) | 276 | Selecionar cliente existente ou “+ Novo Cliente”. |
| [Configurações — perfil](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-272) | 60 | Nome, e-mail, foto e seletor de cargo do usuário; acesso às configurações gerais. |
| [Usuários](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=175-80) | 133 | Listar usuários e papéis, selecionar cargo, ação “X” e cadastrar usuário. |
| [Usuários+](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=176-260) | 136 | Nome completo, e-mail, cargo e seleção de permissões no cadastro. |
| [Configurações — administração](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-29) | 68 | Perfil e acessos a usuários/papéis e configurações do Kanban, funil e checklist. |
| [Vaga](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=183-59) | 298 | Consultar/editar vaga, prazos, responsável, canais, perfil, inscritos, candidatos ideais e erros de triagem; contato do representante. |
| [Funil de Vagas](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=68-2) | 217 | Listagem com cliente, dias em aberto, situação de prazo, métricas e etapas. |
| [KanBanInformaçãoAvaçar](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-501) | 358 | Confirmar avanço de etapa e escolher o responsável de destino. |
| [KanBanInformação](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=155-284) | 335 | Detalhe da tarefa, etapa, responsável, prioridade, prazos, descrição, checklist e anexos. |
| [KanBan+](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=155-5) | 296 | Criar tarefa com título, projeto, empresa, cargo da vaga, responsável, prazos e prioridade. |
| [Dashboard](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-881) | 201 | Atividades alocadas por etapa e atividades entregues por data, com seletor de período. |
| [KanBan](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=39-10) | 239 | Quadro/lista, filtros de projeto/categoria, contagens por coluna, cartões e “+ Planilha”. |
| [Tela Inicial](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=99-127) | 111 | Saudação, tarefas de hoje, pendentes, atrasadas, entregas no prazo, prioridades e acessos a funil/desempenho. |

Há elementos de fundo repetidos em vários frames. Eles reutilizam as mesmas rotas. Não foram encontrados frames próprios para recuperação/redefinição de senha, importação de planilha ou detalhamento de desempenho por pessoa. Esses limites estão indicados no catálogo.

## 3. Convenções propostas

- Base local: `http://localhost:8081/api`. Nas tabelas, os caminhos são relativos a `/api`.
- JSON em UTF-8; uploads com `multipart/form-data`; download com o tipo real do arquivo.
- Autenticação por sessão/token. Somente login, recuperação e redefinição de senha são públicos; refresh usa a credencial de renovação.
- IDs no contrato são identificadores dos recursos; o backend resolve as chaves SQL. Não expor nomes de FKs como campos obrigatórios da interface.
- Datas de prazo em `YYYY-MM-DD`; instantes de criação/conclusão em ISO 8601 com fuso. O fuso de negócio e o corte diário precisam ser definidos.
- Listagens paginadas com `page`, `page_size` e ordenação permitida. Resposta sugerida: `{ "items": [], "page": 1, "page_size": 20, "total": 0 }`.
- `201` em criação, `200` em consulta/atualização, `204` em remoção/logout e `202` no processamento assíncrono de importações.
- Erros padronizados: `{ "code": "validation_error", "message": "...", "fields": {} }`. Usar `400` para requisição malformada, `401` para falta de autenticação, `403` para permissão, `404` para recurso inexistente/inacessível, `409` para conflito, `413` para arquivo grande, `415` para formato incompatível e `422` para validação de domínio.
- Aplicar autorização também nas leituras, no acesso a anexos e nos IDs recebidos. Cargo e permissões são dados distintos; o servidor não deve confiar em permissões enviadas pelo cliente.
- Os métodos de serviço abaixo são sugestões para a organização em Dart; não existem atualmente.

## 4. Catálogo principal — 40 operações a criar

### 4.1. Acesso e perfil — 7 operações

Origem: Login e Configurações/perfil.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| A01 · O | POST | `/auth/login` | Receber `identificador` e `senha`; autenticar e devolver a sessão e o usuário com permissões. Definir se o identificador é e-mail ou nome de usuário. | `AuthService.login()` |
| A02 · T | POST | `/auth/refresh` | Renovar sessão com credencial válida de renovação; rotacionar/inutilizar a anterior. Necessário se a estratégia escolhida usar access/refresh tokens. | `AuthService.refreshSession()` |
| A03 · T | POST | `/auth/logout` | Revogar a sessão atual e sua renovação. A ação visual de sair não está detalhada; é suporte ao ciclo de sessão. | `AuthService.logout()` |
| A04 · P | POST | `/auth/recuperacao-senha` | Receber `email`; iniciar recuperação com resposta genérica, sem revelar se a conta existe. O link está no Figma; o formulário e o canal de entrega não estão. | `AuthService.requestPasswordReset()` |
| A05 · T | POST | `/auth/redefinicao-senha` | Receber `token` de recuperação e `nova_senha`; validar expiração/uso único e concluir a recuperação. Depende da definição do fluxo de A04. | `AuthService.resetPassword()` |
| A06 · O | GET | `/me` | Retornar `id`, `nome`, `email`, `cargo`, `foto_url`, projetos acessíveis e permissões efetivas; alimentar perfil e saudação. | `UserService.getCurrentUser()` |
| A07 · P | PATCH | `/me` | Atualizar os campos pessoais aprovados, inicialmente `nome` e `email`. Há campos no perfil, mas falta uma ação de salvar explícita nesse frame. Alterar o próprio cargo exige autorização administrativa. | `UserService.updateCurrentUser()` |

Se for adotada sessão por cookie, A02 pode ser absorvida pelo mecanismo de renovação da sessão. Não implementar simultaneamente estratégias de autenticação concorrentes sem necessidade. Definir confirmação de mudança de e-mail e política de senha antes da implementação.

### 4.2. Catálogos de apoio — 4 operações

Origem: seletores de tarefa, filtros de projetos e cadastro de usuários.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| B01 · O | GET | `/projetos` | Listar projetos/categorias acessíveis, com `id` e `nome`, para filtros e nova tarefa. Conferir a equivalência entre projeto e categoria antes de fixar a modelagem. | `CatalogService.listProjects()` |
| B02 · O | GET | `/cargos` | Listar cargos/papéis dos usuários, como Assistente, Analista, Gerente e Diretor. Não usar esta lista automaticamente como catálogo de cargos de vagas. | `CatalogService.listUserRoles()` |
| B03 · O | GET | `/prioridades` | Retornar prioridades com `id`, `nome` e ordem/valor; o formulário apresenta Alta, Média e Baixa. | `CatalogService.listPriorities()` |
| B04 · O | GET | `/permissoes` | Retornar identificadores, nomes e agrupamentos de permissões atribuíveis ao cadastrar/editar usuários, limitados ao que o administrador pode conceder. | `PermissionService.listAssignablePermissions()` |

Seletores de responsável reutilizam C01 com uma projeção mínima autorizada; seletores de cliente reutilizam D01. O campo de cargo da vaga pode reutilizar G01 filtrado por cliente quando representar uma vaga existente.

### 4.3. Usuários e papéis — 4 operações

Origem: Usuários e Usuários+.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| C01 · O | GET | `/usuarios` | Listar usuários; aceitar `q`, `cargo_id`, `projeto_id` e `finalidade=atribuicao`. Para atribuição, retornar apenas `id`, `nome`, `cargo` e `foto_url`, sem expor dados administrativos. | `UserService.listUsers()` |
| C02 · O | POST | `/usuarios` | Cadastrar com `nome`, `email`, `cargo_id` e `permissao_ids`. Vincular projetos conforme regra ainda a definir; retornar o usuário criado. Não há campo de senha nesse formulário. | `UserService.createUser()` |
| C03 · O | PATCH | `/usuarios/{usuarioId}` | Atualizar dados autorizados, cargo e/ou conjunto de permissões. Usado pelo seletor de cargo da lista e pela permissão visível “Editar Usuário”. | `UserService.updateUser()` |
| C04 · P | DELETE | `/usuarios/{usuarioId}` | Atender à ação “X” da lista. Proposta: desativação lógica com revogação de sessões, preservando autoria e histórico. Confirmar se “X” significa remover acesso ou excluir cadastro. | `UserService.deactivateUser()` |

O primeiro acesso de um usuário criado precisa ser definido: convite para definir senha, recuperação inicial ou provedor de identidade. Não gerar/devolver senha em texto puro. Cargo do usuário, cargo de vaga e permissões não devem ser confundidos. O schema exige projeto para usuário, mas o formulário não o solicita; resolver isso sem inventar um valor fixo.

### 4.4. Clientes — 3 operações

Origem: Funil_vagas + 2, Funil_Vagas + 4 e Vaga.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| D01 · O | GET | `/clientes` | Buscar/selecionar cliente existente; filtros `q` e `cnpj`; retornar `id`, `nome` e os dados mínimos da seleção. | `ClientService.listClients()` |
| D02 · T | GET | `/clientes/{clienteId}` | Consultar empresa e representante, com nome, telefone/contato e e-mail. Pode ser absorvido pela resposta expandida de G02 se não houver consulta independente. | `ClientService.getClient()` |
| D03 · O | POST | `/clientes` | Salvar o formulário “+ Novo Cliente”: `nome`, `cnpj`, `representante`, `contato` e `email`; retornar o ID para preencher a vaga. | `ClientService.createClient()` |

Validar CNPJ normalizado e duplicidade. Definir se contato/e-mail pertencem à empresa ou ao representante. Os links de WhatsApp e e-mail podem usar `wa.me`/`mailto:` no frontend, sem endpoint para envio de mensagens. Cadastrar cliente e cancelar a vaga são ações distintas; definir a retenção desse cliente já salvo.

### 4.5. Canais de divulgação — 1 operação

Origem: cadastro e detalhe da vaga.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| E01 · O | GET | `/divulgacoes` | Listar canais com `id` e `nome`, como LinkedIn e Indicação. A seleção de vários canais é enviada junto da vaga. | `CatalogService.listPublicationChannels()` |

“+ Adicionar” não esclarece se cria um novo canal de catálogo ou apenas associa outro canal existente; a criação de canal está entre as extensões condicionais.

### 4.6. Tarefas e Kanban — 6 operações

Origem: KanBan, KanBan+, KanBanInformação e KanBanInformaçãoAvaçar.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| F01 · O | GET | `/tarefas` | Listar cartões/linhas e totais por coluna; filtros `projeto_id`, `cliente_id`, `responsavel_id`, `etapa_kanban_id`, `etapa_funil_id`, `prioridade_id`, datas e `prioridades_hoje`. Kanban e Lista usam os mesmos dados. | `TaskService.listTasks()` |
| F02 · O | GET | `/tarefas/{tarefaId}` | Retornar detalhe com título, projeto, cliente/vaga vinculada, etapa do quadro, etapa do funil, responsável, prioridade, prazos, descrição, checklist e metadados dos anexos. | `TaskService.getTask()` |
| F03 · O | POST | `/tarefas` | Criar tarefa com título, projeto, empresa/cliente, referência ao cargo/vaga, responsável, início, fim e prioridade. Aplicar etapa inicial e copiar o checklist padrão conforme a regra aprovada. | `TaskService.createTask()` |
| F04 · O | PATCH | `/tarefas/{tarefaId}` | Persistir alterações de descrição, prioridade, responsável, prazos e demais campos editáveis. Definir autosave ou confirmação, pois o detalhe não apresenta um botão geral “Salvar”. | `TaskService.updateTask()` |
| F05 · T | PATCH | `/tarefas/{tarefaId}/etapa-kanban` | Mover a tarefa entre colunas com `{ "etapa_kanban_id": 2 }`; aceitar `posicao` somente se houver ordenação persistida. O gesto/menu de movimentação não está detalhado nos frames. | `TaskService.moveOnBoard()` |
| F06 · O | POST | `/tarefas/{tarefaId}/avancos-etapa` | Confirmar avanço com `etapa_destino_id`, `responsavel_id` e versão esperada; validar a transição e gravar etapa e responsável atomicamente. | `TaskService.advanceStage()` |

Regras para esses endpoints:

- **Etapa do Kanban e etapa do funil são dimensões diferentes.** O quadro usa A fazer/Em andamento/Aguardando/Concluído; o funil usa Triagem/Entrevista/Retorno/Contratação. O movimento de coluna não deve avançar o funil implicitamente.
- As etapas são configuráveis. Usar IDs e ordem cadastrada, sem persistir apenas os textos ou índices fixos do desenho.
- A listagem deve fornecer totais coerentes com os filtros, incluindo colunas vazias. Paginação de cartões não pode alterar o total de uma coluna.
- A mudança de responsável e etapa em F06 deve ocorrer numa transação; rejeitar versão desatualizada com `409`. Proposta de suporte: `versao` e uma chave de idempotência para evitar avanço repetido.
- Confirmar se o avanço altera a tarefa atual, cria uma próxima tarefa ou também atualiza a vaga vinculada. O Figma não fecha essa regra; não sincronizar tarefa e vaga por suposição.
- Datas finais anteriores às iniciais e vínculos com cliente/projeto/responsável incompatíveis devem ser rejeitados.
- O seletor de “cargo” de KanBan+ está no grupo `Cargo`, mas seu texto visual repete “EMPRESA” e apresenta “Analista Financeiro Jr.”. Isso indica uma ambiguidade de rótulo/modelagem que deve ser resolvida antes de ligar esse campo à tabela `cargos`.

### 4.7. Checklist da tarefa — 2 operações

Origem: KanBanInformação. A leitura dos itens já está incluída em F02.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| H01 · O | POST | `/tarefas/{tarefaId}/checklist/itens` | Adicionar um item com `descricao`; retornar `id`, `descricao`, `concluido` e `ordem`. | `TaskChecklistService.addItem()` |
| H02 · O | PATCH | `/tarefas/{tarefaId}/checklist/itens/{itemId}` | Marcar/desmarcar com `concluido`; permitir editar `descricao` somente se esse comportamento for aprovado. | `TaskChecklistService.updateItem()` |

O estado de conclusão é individual por tarefa, mesmo quando o texto vem de um modelo comum. Alterar o padrão não deve reescrever silenciosamente checklists de tarefas existentes. Não confundir o item de checklist com um registro global de modelo.

### 4.8. Anexos da tarefa — 2 operações

Origem: “Adicionar Anexos” e arquivo PDF em KanBanInformação. Os metadados já vêm em F02.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| I01 · O | POST | `/tarefas/{tarefaId}/anexos` | Receber arquivo em multipart; armazenar conteúdo e metadados; retornar `id`, `nome`, `mime_type`, `tamanho_bytes` e data de envio. | `AttachmentService.uploadTaskAttachment()` |
| I02 · T | GET | `/tarefas/{tarefaId}/anexos/{anexoId}/conteudo` | Abrir/baixar o anexo autorizado, com `Content-Type` e `Content-Disposition` adequados. URL temporária assinada é uma alternativa. | `AttachmentService.downloadTaskAttachment()` |

O Figma não fixa limite de tamanho, formatos permitidos ou remoção de anexos. Definir esses limites no contrato e validar no servidor, sem tomar valores de demonstração do frontend como requisito do desenho. O vínculo tarefa/anexo deve ser validado em cada operação.

### 4.9. Vagas e funil — 4 operações

Origem: Funil de Vagas, seus três estados de cadastro e Vaga.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| G01 · O | GET | `/vagas` | Listar vagas, filtrando por cliente, responsável, etapa e situação de prazo; retornar cargo, cliente, dias em aberto, etapa atual, inscritos, percentual de ideais e erros de triagem. | `VacancyService.listVacancies()` |
| G02 · O | GET | `/vagas/{vagaId}` | Retornar cargo, cliente/representante e contato, perfil desejado, canais, responsável, prazos, etapa atual e métricas da vaga. | `VacancyService.getVacancy()` |
| G03 · O | POST | `/vagas` | Receber `cargo`, `perfil_desejado`, `cliente_id`, `responsavel_id`, `prazo_inicial`, `prazo_final` e `divulgacao_ids`; criar vaga e associações numa transação. | `VacancyService.createVacancy()` |
| G04 · O | PATCH | `/vagas/{vagaId}` | Salvar alterações autorizadas de dados da vaga, responsável, prazos, perfil, canais e contadores de inscritos/ideais/erros. Validar também alterações parciais contra o estado já persistido. | `VacancyService.updateVacancy()` |

Decisões necessárias:

- O card mostra candidatos ideais em percentual, enquanto o detalhe mostra o campo de candidatos ideais e o SQL tem um inteiro. Proposta: armazenar quantidades e calcular `percentual_ideais = candidatos_ideais / candidatos_inscritos * 100`, com regra explícita para denominador zero e arredondamento. Confirmar a definição antes de implementar.
- Confirmar o significado de erros de triagem e seus limites; não assumir que sempre representam candidatos distintos. Contadores devem ser inteiros não negativos.
- “Em dia”, “Atenção” e “Perto de Fechar” precisam de uma regra aprovada. Não inventar os limites de dias a partir dos exemplos estáticos.
- Dias em aberto exigem data de abertura, que não deve ser confundida automaticamente com o início planejado.
- Não há lista/ficha de candidatos individuais nos frames. Contadores e textos sobre candidatos não bastam para exigir CRUD de candidatos, currículos por candidato ou decisões automatizadas de seleção.

### 4.10. Configurações gerais — 2 operações

Origem: config geral e atalhos de Configurações. A tela tem uma única ação “Salvar Alteração”.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| J01 · O | GET | `/configuracoes-gerais` | Retornar `versao`, `etapas_kanban`, `etapas_funil` e `checklist_padrao`, com IDs, textos e ordem. Reutilizar no quadro, funil, nova tarefa e editor de configurações. | `SettingsService.getGeneralSettings()` |
| J02 · O | PUT | `/configuracoes-gerais` | Salvar o conjunto completo das três listas numa transação, com a versão esperada. Incluir novos itens, atualizar existentes e tratar removidos conforme regras de vínculo. | `SettingsService.replaceGeneralSettings()` |

Esta proposta usa uma gravação agregada para corresponder ao formulário. Não exige também endpoints POST/PATCH/DELETE separados para cada etapa/item. Se o produto adotar salvamento individual, substituir J02 por operações de recurso; isso é uma alternativa de contrato, não trabalho adicional obrigatório.

Regras de J02:

- Cada item existente mantém seu ID. Itens novos devem usar identificadores temporários de cliente ou um marcador de criação distinto; o servidor devolve IDs definitivos.
- A resposta deve retornar as listas normalizadas e a nova versão. Campos omitidos num PUT não podem apagar listas por acidente: exigir a representação completa.
- Comparar a versão e retornar `409` em concorrência. Validar nomes, duplicidade, ordem e a existência de etapas utilizáveis.
- Não apagar uma etapa em uso sem uma política explícita: rejeitar com `409` e informar dependências ou exigir migração para uma etapa de destino. Preservar histórico.
- Verificar separadamente permissões de criação, edição e remoção em cada diferença do documento enviado; uma permissão de editar não deve conceder automaticamente criação/exclusão.
- Definir se essas configurações são globais ou por projeto. Caso sejam por projeto, adicionar escopo de projeto validado tanto em J01 quanto em J02.
- J01 pode ser acessível para leitura operacional sem conceder acesso administrativo de escrita.

### 4.11. Início e indicadores — 3 operações

Origem: Tela Inicial e Dashboard.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| K01 · O | GET | `/inicio` | Retornar totais de tarefas de hoje, pendentes e atrasadas, percentual de entregas no prazo e cartões de prioridades de hoje. Aceitar escopo autorizado de projeto/responsável. A saudação usa A06. | `DashboardService.getHomeSummary()` |
| K02 · O | GET | `/dashboard/atividades-alocadas` | Agregar atividades por etapa do funil; devolver IDs, nomes e quantidades, com filtros de projeto, responsável e período quando aplicáveis. | `DashboardService.getAllocatedActivities()` |
| K03 · O | GET | `/dashboard/atividades-entregues` | Retornar série temporal de entregas, com `inicio`, `fim`, `agrupamento` e filtros de projeto/responsável. Sustentar o seletor “Uma Semana”. | `DashboardService.getDeliveredActivities()` |

Definir o que caracteriza tarefa de hoje, pendência, atraso e entrega: prazo inicial/final, etapa do quadro e/ou conclusão do funil. Os percentuais precisam de denominador, período, tratamento de ausência de dados e política para tarefas reabertas. Calcular no backend sobre o mesmo escopo de autorização das listagens.

O atalho “Desempenho” fala em avaliação por pessoa e etapa, mas não há frame próprio. K02/K03 podem atender inicialmente com filtro de responsável; métricas adicionais dependem de detalhamento. Os atalhos de navegação não exigem uma API própria.

### 4.12. Importação de planilha — 2 operações

Origem: botão “+ Planilha” no Kanban e permissão “Importar Planilha” em Usuários+. O fluxo de importação não foi desenhado.

| ID / evidência | Método | Endpoint | Finalidade e contrato mínimo proposto | Método de serviço sugerido |
| --- | --- | --- | --- | --- |
| L01 · P | POST | `/importacoes/tarefas` | Receber planilha por multipart; validar acesso e iniciar processamento. Proposta assíncrona: responder `202` com `importacao_id` e estado inicial. | `TaskImportService.startImport()` |
| L02 · T | GET | `/importacoes/{importacaoId}` | Consultar estado, quantidade processada/importada/rejeitada e erros por linha/campo, sem expor dados de outras importações. | `TaskImportService.getImportStatus()` |

Antes de implementar: confirmar se a planilha importa tarefas, vagas ou ambas; formato CSV/XLSX, colunas, mapeamento de nomes para IDs, limites, duplicidade, comportamento em erro e se haverá prévia/confirmação. O caminho `/importacoes/tarefas` é uma hipótese baseada na localização do botão. Uma importação síncrona pequena pode dispensar L02; prévia e confirmação exigiriam um contrato adicional aprovado.

## 5. Formatos de dados propostos

São exemplos de DTOs da API, **não declarações de colunas já existentes**. Valores numéricos são ilustrativos. Campos obrigatórios e opcionais devem ser fechados junto das decisões da seção 9.

### Nova tarefa — F03

```json
{
  "titulo": "Triagem — Analista Financeiro Jr.",
  "projeto_id": 1,
  "cliente_id": 10,
  "vaga_id": 20,
  "responsavel_id": 3,
  "prazo_inicial": "2026-10-26",
  "prazo_final": "2026-10-30",
  "prioridade_id": 2
}
```

`vaga_id` é uma proposta para representar a vaga/cargo selecionado. Para tarefas sem vaga, como consultoria ou financeiro, confirmar se o vínculo pode ser nulo e quais campos permanecem exigidos. Não enviar um `cargo_id` de papel administrativo para representar “Analista Financeiro Jr.”.

### Avanço de etapa — F06

```json
{
  "etapa_destino_id": 3,
  "responsavel_id": 8,
  "versao_esperada": 4
}
```

Confirmar se é permitido pular etapas, voltar etapas, avançar com checklist incompleto e concluir a última etapa. “Cancelar” e “Fechar” não enviam mutações. Usar uma transição autorizada pelo servidor, sem aceitar qualquer ID de destino por simples escolha do cliente.

### Nova vaga — G03

```json
{
  "cargo": "Analista Financeiro Jr.",
  "perfil_desejado": "Requisitos e competências da vaga",
  "cliente_id": 10,
  "responsavel_id": 8,
  "prazo_inicial": "2026-10-26",
  "prazo_final": "2026-11-10",
  "divulgacao_ids": [1, 2]
}
```

### Configurações gerais — J01/J02

```json
{
  "versao": 5,
  "etapas_kanban": [
    { "id": 1, "nome": "A fazer", "ordem": 1 },
    { "id": 2, "nome": "Em andamento", "ordem": 2 },
    { "id": 3, "nome": "Aguardando", "ordem": 3 },
    { "id": 4, "nome": "Concluído", "ordem": 4 }
  ],
  "etapas_funil": [
    { "id": 1, "nome": "Triagem", "ordem": 1 },
    { "id": 2, "nome": "Entrevista", "ordem": 2 },
    { "id": 3, "nome": "Retorno", "ordem": 3 },
    { "id": 4, "nome": "Contratação", "ordem": 4 }
  ],
  "checklist_padrao": [
    { "id": 1, "descricao": "Coletar currículos inscritos", "ordem": 1 },
    { "id": 2, "descricao": "Filtrar por requisitos mínimos", "ordem": 2 }
  ]
}
```

O exemplo representa uma configuração já carregada. J02 deve definir explicitamente como representar novas entradas e remoções, além de preservar as referências existentes.

## 6. Permissões observadas no Figma

O formulário de novo usuário contém as permissões abaixo. A associação a operações é uma proposta; permissões de consulta, exclusão, anexos e avanço ainda precisam ser definidas.

| Texto observado | Operações correspondentes |
| --- | --- |
| Cadastrar Tarefas | F03; definir se cobre criação de itens/anexos. |
| Importar Planilha | L01/L02, além de acesso ao escopo importado. |
| Cadastrar Vaga | G03; definir se inclui cadastrar cliente durante a vaga. |
| Cadastrar Usuário | C02 e concessão apenas de permissões autorizadas. |
| Cadastrar Etapas do Kanban | Criações em `etapas_kanban` de J02. |
| Cadastrar Etapas do Funil de Vendas | Criações em `etapas_funil` de J02. O restante da interface chama o recurso de funil de vagas. |
| Editar Etapas do Funil de Vendas | Edições em `etapas_funil` de J02. |
| Cadastrar Etapas do CheckList | Criações em `checklist_padrao` de J02. |
| Editar Etapas do CheckList | Edições em `checklist_padrao` de J02. |
| Editar Etapas do Kanban | Edições em `etapas_kanban` de J02. |
| Editar Usuário | C03; não implica permissão irrestrita de elevar o próprio acesso. |
| Editar Vaga | G04. |

Autorizar pelo usuário autenticado e pelos vínculos reais de projeto/cliente/recurso. O backend deve impedir a concessão de acesso superior ao permitido ao concedente. Definir proteção contra desativação do último administrador e tratamento de tarefas/vagas de um usuário desativado.

## 7. Extensões condicionais — não entram nas 40 operações

Estes endpoints só devem ser criados se o comportamento for confirmado. A presença de uma imagem, de um ícone genérico ou de uma entidade no SQL não obriga um CRUD completo.

| Método | Endpoint possível | Condição para incluir |
| --- | --- | --- |
| POST | `/me/foto` | Confirmar que a foto do perfil pode ser enviada/trocada; a imagem está no Figma, mas o fluxo de upload não. |
| DELETE | `/me/foto` | Confirmar ação de remover foto. |
| PATCH | `/clientes/{clienteId}` | Confirmar edição do cadastro do cliente; a tela de vaga mostra seus contatos, mas não um formulário próprio de edição. |
| POST | `/divulgacoes` | Confirmar que “+ Adicionar” cria um canal de catálogo, além de selecionar um existente. |
| DELETE | `/tarefas/{tarefaId}` | Confirmar exclusão/arquivamento de tarefa e política de histórico. |
| DELETE | `/tarefas/{tarefaId}/checklist/itens/{itemId}` | Confirmar remoção de item de checklist da tarefa; o “X” foi observado nas configurações do padrão. |
| DELETE | `/tarefas/{tarefaId}/anexos/{anexoId}` | Confirmar remoção de anexo, retenção e autorização. |
| POST | `/vagas/{vagaId}/avancos-etapa` | Confirmar avanço direto da vaga, independente da ação exibida no detalhe da tarefa; evitar duplicar F06 sem regra de sincronização. |
| DELETE | `/vagas/{vagaId}` | Confirmar exclusão, cancelamento ou arquivamento da vaga; são comportamentos distintos. |
| POST | `/usuarios/{usuarioId}/convites` | Incluir se o primeiro acesso/reenvio de acesso for feito por convite. |

Também não há evidência suficiente para exigir CRUD de cargos, projetos e permissões, notificações, chat, envio de WhatsApp/e-mail pelo backend, exportação de relatórios, WebSocket, cadastro de candidatos ou um painel administrativo adicional.

## 8. Confronto com o backend e o banco atuais

Arquivos verificados: `backend/bin/server.dart`, `backend/database/migrations/001_initial_schema.sql`, estrutura de modelos em `backend/lib/src/models/` e `docker-compose.yml`. Esta análise considera o SQL versionado; não afirma que uma instância de banco em execução tenha schema idêntico.

| Recurso | O que o SQL confirma | Lacuna para atender às telas |
| --- | --- | --- |
| Autenticação | `usuarios.email` é único. | Não há credencial, hash de senha, sessão, refresh ou recuperação. Definir autenticação local ou provedor externo e seu armazenamento. |
| Usuários/perfil | ID, e-mail, FK obrigatória de cargo e de projeto. | Não há nome, foto ou estado ativo; não há regra documentada de primeiro acesso. Definir projeto do novo usuário. |
| Permissões | `permissoes` e associação `usuarios_has_permissoes`. | Mapear as permissões do Figma; `permissoes.chave` tem somente 1 caractere. Se forem adotadas chaves semânticas longas, ampliar por migration. |
| Clientes | Nome, CNPJ único e representante como texto. | Não há contato/telefone nem e-mail. Definir se há um representante ou uma entidade de contatos. |
| Tarefas | Cargo do usuário, usuário, prazo inicial e referências opcionais de cliente, projeto e prioridade. | Não há título, descrição, prazo final, etapa do quadro, etapa do funil, vínculo com vaga, posição, criação/conclusão ou versão. |
| Cargo da vaga | `vagas.cargo` é texto; `tarefas.id_cargo` referencia `cargos`. | Confirmar a semântica de `tarefas.id_cargo`; o seletor ocupacional da tarefa não deve ser ligado automaticamente ao cargo administrativo do usuário. |
| Vagas | Cargo, `perfil_deixado`, prazos, divulgação, contadores e referências a cliente/usuário/cargo. | Não há etapa do funil nem data explícita de abertura/conclusão. Confirmar mapeamento de `perfil_deixado` para perfil desejado e de `cand_ideias` para candidatos ideais. |
| Divulgação | Catálogo `divulgacoes`, uma FK em `vagas` e associação N:N `divulgacoes_has_vagas`. | A tela aceita vários canais. Escolher uma representação canônica ou distinguir canal principal dos adicionais; gravar de forma consistente. |
| Checklist | `checklists` com nome e associação `checklists_has_tarefas`. | Não há conclusão/ordem por item de tarefa, nem distinção explícita entre modelo padrão e cópia da tarefa. |
| Etapas/configurações | Não há tabelas específicas de etapas do quadro/funil no SQL inicial. | Persistir definições ordenadas, referências dos recursos, escopo e versão das configurações. |
| Anexos | Nenhuma tabela correspondente. | Metadados, vínculo, armazenamento do conteúdo e autorização de download. |
| Indicadores | Existem prazos e contadores básicos. | Datas/eventos de entrega/conclusão e regras de agregação para séries e percentual no prazo. |
| Importações | Nenhuma tabela correspondente. | Se assíncronas, persistir execução, estado, autoria, escopo e relatório de erros. |

Todas as mudanças estruturais necessárias devem virar migrations PostgreSQL versionadas em `backend/database/migrations/`. Não editar a migration inicial como substituto de uma atualização de banco já instalado. O volume do Compose monta as migrations em `/docker-entrypoint-initdb.d`; isso executa scripts na inicialização de um banco novo, não resolve sozinho a evolução de volumes já existentes.

## 9. Decisões que faltam para fechar os contratos

1. **Acesso:** identificador do login, estratégia de sessão, primeiro acesso de usuários, recuperação e edição de perfil/e-mail.
2. **Escopo:** projeto e categoria são o mesmo conceito? Usuário pode pertencer a vários projetos? As configurações são globais ou por projeto?
3. **Vínculos:** qual a relação entre tarefa, vaga e cargo ocupacional? Como tratar tarefas de consultoria/financeiro sem vaga?
4. **Avanço:** atualizar tarefa existente ou criar a próxima? Sincronizar vaga? Permitir salto/retorno e exigir checklist concluído?
5. **Persistência do detalhe:** salvar automaticamente ou por confirmação? O Figma mostra “Salvar” na vaga, mas não um equivalente geral no detalhe da tarefa.
6. **Indicadores:** definições de pendente/atrasada/entregue, situação do prazo da vaga, candidatos ideais e erros de triagem.
7. **Remoções:** significado dos “X”, dependências de etapas em uso, desativação de usuários e preservação de histórico.
8. **Catálogos:** “+ Adicionar” nos canais cria um novo cadastro ou apenas acrescenta uma seleção?
9. **Arquivos:** formatos, tamanho, armazenamento e retenção de anexos; especificação da planilha e sua entidade de destino.
10. **Permissões:** leitura, edição de tarefas, avanço, movimentação, criação de clientes, anexos e exclusões não têm uma matriz completa no desenho.

## 10. Ordem sugerida de implementação e critérios de aceite

1. Fechar decisões de acesso, escopo e vínculos; criar migrations e autenticação/autorização.
2. Implementar catálogos, usuários, clientes e configurações gerais.
3. Implementar tarefas, checklist, anexos e transições com persistência transacional.
4. Implementar vagas/funil e a regra aprovada de integração com tarefas.
5. Implementar indicadores com eventos/datas consistentes.
6. Fechar o fluxo de planilha e implementar a importação.

Para considerar as telas integradas, validar: dados mantidos após recarregar; listas e contagens consistentes; permissões conferidas no servidor; validação de datas e vínculos; conflitos de edição tratados; cancelamentos sem gravação; acesso a anexos restrito; configurações sem perda de referências; percentuais com tratamento de zero; e importações com retorno de erros utilizável.

Este arquivo é um levantamento de API. Nenhum endpoint, tabela ou comportamento descrito como proposta foi implementado por esta alteração.
