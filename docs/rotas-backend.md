# Contrato implementado do backend

Referência de escopo: `../rotas-backend-folks.md`, preservado sem alterações.
Base: `http://localhost:8081/api`. JSON em UTF-8. Datas: `YYYY-MM-DD`.
IDs são inteiros positivos. Campos desconhecidos são recusados (400), inclusive
tentativas de alterar cargo, permissões ou administrador no próprio perfil.

## Autorização

Somente `/api`, `/api/health`, login e as duas rotas de recuperação são públicas.
As demais exigem Bearer. Leituras estão disponíveis a usuários ativos autenticados.
Não há regra de isolamento por projeto definida no repositório; o contrato atual
é compartilhado entre usuários autenticados.

Permissões são explícitas por usuário; cargo interno é informação distinta do
cargo textual de tarefa/vaga. Nenhum cargo concede permissões implicitamente.
Somente o administrador de bootstrap tem acesso a todas as operações.

| Chave | Operações autorizadas |
|---|---|
| B — Cadastrar Tarefas | Criar/editar tarefas, mover status, avançar recrutamento, alterar checklist, enviar/remover anexos. |
| C — Cadastrar Vaga | Criar vagas, candidatos, clientes e canais de divulgação usados no cadastro. |
| A — Importar Planilha | Importação CSV; também exige C porque cria vagas. Consulta de lote exige A e vínculo com o autor, ou administração. |
| D — Editar Vaga | Editar vaga e editar/remover seus candidatos. |
| E — Cadastrar Usuário | Criar usuário; só pode conceder permissões que o próprio operador possui. |
| F — Editar Usuário | Alterar cargo e permissões, desativar usuário; consultar usuários inativos. Só concede permissões que possui. |
| G / H | Adicionar / editar ou remover etapas do Kanban. |
| I / J | Adicionar / editar ou remover etapas do funil. |
| K / L | Adicionar / editar ou remover itens de checklist padrão. |

A permissão B cobre o ciclo de tarefa porque não existe uma permissão separada
de edição no catálogo original; C cobre os cadastros auxiliares do formulário
de vaga pelo mesmo motivo. O PUT de configurações exige as permissões das
alterações efetivas de cada seção, e não das seções mantidas sem alteração.
Usuários não podem desativar a si mesmos nem desativar o administrador de bootstrap.
Um operador comum não pode alterar o cargo de administrador.

## Operações e corpos

Todos os nomes abaixo são relativos a `/api`. As respostas de criação usam 201;
leituras/edições, 200; logout, redefinição e exclusões, 204; recuperação, 202.

| Método | Rota | Corpo JSON ou finalidade |
|---|---|---|
| GET | `/` (sem barra final: `/api`) | Identificação da API. |
| GET | `/health` | Disponibilidade e conexão ao banco. |
| POST | `/auth/login` | `{"email":"...","senha":"..."}` → token, expiraEm e usuario. |
| POST | `/auth/logout` | Revoga a sessão Bearer atual. Sem corpo. |
| POST | `/auth/recuperar-senha` | `{"email":"..."}`. Envia token por SMTP; não o devolve na resposta. |
| POST | `/auth/redefinir-senha` | `{"token":"...","senha":"..."}`. Revoga todas as sessões da conta. |
| GET | `/usuarios/me` | Perfil, cargo, permissões explícitas e sinalizador administrador. |
| PATCH | `/usuarios/me` | `{"nome":"...","email":"..."}`; ao menos um campo. |
| GET | `/usuarios` | Usuários ativos para seletores; `busca`, `ativo=true/false`. |
| POST | `/usuarios` | `{"nome":"...","email":"...","senha":"...","cargoId":2,"projetoId":1,"permissoes":[2,3]}`. Projeto opcional, permissões vazias por padrão. |
| PATCH | `/usuarios/{id}` | `{"cargoId":2,"permissoes":[2,3]}`; ambos opcionais, ao menos um obrigatório. A lista substitui as permissões explícitas e admite `[]`. |
| DELETE | `/usuarios/{id}` | Desativa, preserva vínculos e revoga sessões e recuperações. |
| GET | `/cargos` | Cargos internos. |
| GET | `/permissoes` | Permissões e suas chaves. |
| GET | `/projetos` | Projetos provisionados no banco. |
| GET | `/prioridades` | Prioridades, incluindo valor. |
| GET | `/clientes` | Clientes; aceita `busca` por empresa. |
| POST | `/clientes` | `{"empresa":"...","cnpj":"...","representante":"...","contato":"...","email":"..."}`. Somente empresa obrigatória. |
| GET | `/divulgacoes` | Canais disponíveis. |
| POST | `/divulgacoes` | `{"nome":"...","chave":"linkedin"}`. Chave única com letras/números, `_` ou `-`. |
| GET | `/configuracoes` | Objeto com listas `kanban`, `funil`, `checklist`. |
| PUT | `/configuracoes` | As três listas completas na mesma transação. Veja abaixo. |
| GET | `/tarefas` | Tarefas para quadro e lista, filtros e paginação. |
| POST | `/tarefas` | Cadastro completo. Veja exemplo abaixo. |
| GET | `/tarefas/{id}` | Dados da tarefa, checklist, metadados de anexos e avanços persistidos. |
| PATCH | `/tarefas/{id}` | `{"responsavelId":1,"prioridadeId":2,"descricao":"..."}`; ao menos um campo. Descrição admite string vazia. |
| PATCH | `/tarefas/{id}/status` | `{"statusId":2}`. Não altera etapa de recrutamento. |
| POST | `/tarefas/{id}/avancos` | `{"etapaId":2,"responsavelId":1}`. Etapa posterior por ordem; ambos os campos gravados atomicamente. |
| POST | `/tarefas/{id}/checklist/itens` | `{"nome":"Conferir documentos"}`. |
| PATCH | `/tarefas/{id}/checklist/itens/{itemId}` | `{"concluido":true}` ou `false`. Item deve pertencer à tarefa da URL. |
| POST | `/tarefas/{id}/anexos` | Multipart `arquivo`/`arquivos` ou corpo binário com X-File-Name. Até 10 arquivos, cada um com até 10 MiB. |
| GET | `/tarefas/{id}/anexos/{anexoId}` | Download autenticado; anexo deve pertencer à tarefa. |
| DELETE | `/tarefas/{id}/anexos/{anexoId}` | Remove conteúdo e metadados juntos. |
| GET | `/vagas` | Vagas com cliente, responsável, datas, etapa, canais e indicadores dos candidatos vinculados. |
| POST | `/vagas` | Cadastro com múltiplos canais. Veja exemplo abaixo. |
| GET | `/vagas/{id}` | Detalhes e indicadores da vaga. |
| PATCH | `/vagas/{id}` | Campos do cadastro e/ou `etapaId`; ao menos um campo. Etapa atual pode ser mantida ou avançar por ordem; retrocesso retorna 409. |
| GET | `/vagas/{id}/candidatos` | Listagem paginada; filtros `busca`, `status`, `page`, `limit`. |
| POST | `/vagas/{id}/candidatos` | Nome e e-mail obrigatórios; telefone, perfilIdeal, status e motivoErro opcionais. |
| GET | `/vagas/{id}/candidatos/{candidatoId}` | Candidato pertencente à vaga. |
| PATCH | `/vagas/{id}/candidatos/{candidatoId}` | Campos do cadastro de candidato; ao menos um. |
| DELETE | `/vagas/{id}/candidatos/{candidatoId}` | Remove o vínculo/cadastro daquela vaga. |
| POST | `/importacoes` | CSV UTF-8 como corpo, `Content-Type: text/csv` e `X-Idempotency-Key`. 201 novo; 200 repetição idêntica. |
| GET | `/importacoes/{id}` | Quantidade, data e IDs das vagas importadas; restrito ao autor ou administrador, com permissão A. |
| GET | `/dashboard/atividades` | Contagem de tarefas por status e etapa no período de prazo inicial. |
| GET | `/dashboard/entregas` | Conclusões registradas por dia UTC e responsável no momento da conclusão. |

## Paginação e filtros

Todas as listagens de entidades retornam:

```json
{"items":[],"total":0,"page":1,"limit":20}
```

`page`: a partir de 1, máximo 1.000.000. `limit`: de 1 a 100, padrão 20.
`GET /configuracoes` retorna diretamente as três listas. Pesquisa é parcial e
não diferencia maiúsculas/minúsculas. Cada consulta paginada usa um snapshot
transacional consistente para total e itens.

- Catálogos: `busca`, `page`, `limit`.
- Usuários: os anteriores, mais `ativo`; inativos exigem F.
- Tarefas: `projetoId`, `clienteId`, `statusId`, `etapaId`, `responsavelId`,
  `prioridadeId`, `busca` (título, descrição ou cargo), `prazoInicial`, `prazoFinal`.
  O intervalo exige início da tarefa >= prazoInicial e fim <= prazoFinal.
- Vagas: `clienteId`, `responsavelId`, `etapaId`, `canalId`, `busca` (cargo/empresa).

Filtros desconhecidos ou valores inválidos retornam 400.
Exemplo: `/tarefas?projetoId=1&statusId=2&page=1&limit=20`.

## Tarefa

```json
{
  "titulo": "Recrutamento para desenvolvimento",
  "descricao": "Validar os requisitos com o cliente",
  "projetoId": 1,
  "clienteId": 1,
  "cargo": "Desenvolvedor Sênior",
  "responsavelId": 1,
  "prazoInicial": "2026-11-03",
  "prazoFinal": "2026-11-30",
  "prioridadeId": 2
}
```

Todos os campos acima são obrigatórios, exceto descrição. Responsável deve estar
ativo. As datas devem ser válidas e o fim não pode anteceder o início. A tarefa
nasce na primeira etapa do Kanban e na primeira etapa de recrutamento, conforme
a ordem atual das configurações. O checklist padrão é copiado como snapshot:
alterar/remover padrões não muda nomes nem conclusão das tarefas existentes.
Não existe relação tarefa-vaga definida no schema original; não há atualização
implícita entre essas entidades.

## Configurações

```json
{
  "kanban": [{"id": 1, "nome": "A fazer", "ordem": 0}],
  "funil": [{"id": 1, "nome": "Aberta", "ordem": 0}],
  "checklist": [{"id": 1, "nome": "Conferir requisitos", "ordem": 0}]
}
```

Este é um exemplo mínimo de formato, **não um comando para substituir suas
etapas atuais**. Use o GET completo como base. Cada seção exige entre 1 e 100
itens. Nomes e ordens são únicos dentro da seção; ordem aceita 0 a 10.000.
IDs existentes devem ser preservados. Para adicionar um item, omita `id` ou
envie `null`. Para remover, omita o item da lista. ID desconhecido é erro.
Etapas usadas por tarefas, vagas ou histórico de avanços não podem ser apagadas
(409). Renomear e reordenar continua permitido; a ordem atual define os avanços
futuros. Checklist padrão pode ser removido porque as tarefas guardam snapshot.

## Vaga

```json
{
  "cargo": "Desenvolvedor Sênior",
  "perfilDesejado": "Experiência com Dart e PostgreSQL",
  "clienteId": 1,
  "responsavelId": 1,
  "prazoInicial": "2026-11-03",
  "prazoFinal": "2026-11-30",
  "canais": [1, 2]
}
```

Todos os campos são obrigatórios; canais admite lista vazia ou até 100 IDs
distintos. Cada canal deve existir. A vaga nasce na primeira etapa do funil.
O campo legado `perfil_deixado` é preservado no banco/model, mas o contrato usa
`perfilDesejado`. O antigo canal único continua compatível com o primeiro
selecionado, e a relação N:N guarda todos os canais. Não há publicação externa.

Resposta `indicadores`:

```json
{"inscritos":0,"candidatosIdeais":0,"erros":0,"disponiveis":true}
```

Os indicadores contam candidatos vinculados à vaga: todos os registros em
`inscritos`, marcação manual `perfilIdeal=true` em `candidatosIdeais` e status
`erro` em `erros`. A marcação de perfil não é uma avaliação automática. Contadores
legados permanecem preservados no banco, separados dessa fonte operacional.
A regra provisória de três dias para “Perto de Fechar” não é calculada na API.

## Validação e erros

```json
{"erro":{"codigo":"validacao","mensagem":"Informe ao menos um campo editável."}}
```

| HTTP | Situação |
|---|---|
| 400 | JSON, campos, referências de cadastro ou valores inválidos. |
| 401 | Credenciais/sessão inválidas, sessão expirada ou revogada. |
| 403 | Sem permissão para a operação. |
| 404 | Rota, recurso ou vínculo da URL não encontrado. |
| 409 | E-mail/CNPJ/chave duplicados, etapa em uso, avanço repetido ou retroativo. |
| 408 / 413 / 415 | Tempo de recebimento, tamanho ou tipo do corpo inválido. |
| 429 | Limite de tentativas de autenticação/recuperação excedido. |
| 503 | SMTP não configurado/falhou ou conexão ao banco indisponível. |
| 500 | Falha interna sem exposição de SQL, senha ou stack ao cliente. |

Limites: nome/título até 150; e-mail até 150; empresa até 110; representante e
contato até 100; cargo da oportunidade até 80; perfil desejado até 255;
descrição de tarefa até 10.000. Senha: 12 a 128 caracteres, sem trim.
CNPJ é opcional, aceita a máscara padrão, é armazenado como 14 dígitos e deve
ser único se informado. Validação fiscal de dígitos verificadores não foi
definida no contrato. E-mail opcional de cliente deve ter formato válido.

## Candidatos, importação e dashboards

As regras e exemplos completos estão em [backend-camadas.md](backend-camadas.md).
O cadastro de candidato exige `nome` e `email`. `perfilIdeal` é booleano e começa
em false. Status: `inscrito` (padrão), `em_analise`, `aprovado`, `reprovado`, `erro`.
Status erro exige `motivoErro` não vazio, até 500 caracteres; sair desse status
limpa o motivo. E-mail é único por vaga, desconsiderando maiúsculas. Rotas de
candidato sempre verificam o vínculo com a vaga da URL.

CSV: até 2 MiB e 1000 vagas, vírgula ou ponto e vírgula, cabeçalho com os sete
campos de criação de vaga. `canais` separa IDs com `|`. Falha em qualquer registro
desfaz todo o lote. Chave repetida com conteúdo diferente retorna 409; o mesmo
conteúdo e chave retorna o lote existente. Uma chave nova representa lote novo.

Dashboards aceitam `dataInicial`, `dataFinal`, `responsavelId`, `projetoId`.
Padrão: últimos 30 dias UTC; máximo 367 dias inclusivos. Entrega é a transição
de uma tarefa para a última coluna do Kanban por ordem. Repetir o mesmo status
não conta de novo; reabrir e concluir gera novo evento. Não há backfill histórico.
Dias sem entregas não aparecem em `porDia`.

## Dependências externas

Publicação externa exige definir plataformas e configurar suas credenciais.
Selecionar um canal não publica a vaga. SMTP real exige configuração do provedor.
A integração das telas Flutter, que ainda usam demonstração local, é um trabalho
separado da reorganização e dos fluxos HTTP deste backend. Não há refresh porque
a estratégia de sessão não o exige.
