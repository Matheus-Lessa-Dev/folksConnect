# Backend: camadas e fluxos operacionais

Branch: `feature/backend-camadas-fluxos`, criada de `origin/develop`.
Dependência: implementação do backend existente em `main` (`0793cc0`), incorporada
por fast-forward porque ainda não estava em `develop`. Nenhuma alteração foi feita
em `main` ou `develop`. Não houve alteração nas telas do Flutter.

## Organização

```text
bin/server.dart                 inicialização e migrations
lib/src/application.dart        composição das dependências
lib/src/config/                 configuração da aplicação
lib/src/routes/                 caminhos HTTP e autenticação das rotas
lib/src/controllers/            HTTP, cabeçalhos, decodificação de upload e respostas
lib/src/dto/                    dados de entrada/saída, CSV, validação e serialização
lib/src/services/               regras, permissões e fronteiras de transação
lib/src/repositories/           SQL, consultas e persistência
lib/src/models/                 entidades originais preservadas
lib/src/exceptions/             ApiError
lib/src/middleware/             CORS e tradução de falhas para HTTP
lib/src/security/               identidade, senhas e tokens
```

Fluxo: rota → autenticação → controller → DTO/service → repository → PostgreSQL.
Services não recebem `Request`, não retornam `Response` e não contêm SQL.
Repositories compartilham a mesma conexão transacional fornecida pelo service.
`database.dart` mantém o pool, as transações e o executor de migrations.
`http.dart` concentra leitura limitada do corpo e resposta JSON; `security.dart`
reexporta as funções/identidade para manter os imports internos compatíveis.

## Primeira versão das regras operacionais

Os documentos anteriores deixavam estes critérios abertos. Esta entrega adota
explicitamente os critérios abaixo; mudanças futuras de produto devem atualizar
contrato, testes e migrations quando necessário.

### Vagas e candidatos

`GET /api/vagas/{id}` consulta detalhes. `PATCH` aceita os campos do cadastro e
`etapaId`; exige D. Datas e referências são validadas na mesma transação. Etapas
só avançam pela ordem configurada; manter a etapa é permitido. A lista de canais
substitui integralmente a anterior, inclusive com `[]`.

Candidatos são cadastros vinculados a uma vaga; o mesmo e-mail pode participar de
outra vaga. Nome/e-mail obrigatórios; telefone opcional (até 40 caracteres).
Cadastro exige C; edição/remoção exige D. Exemplo:

```http
POST /api/vagas/1/candidatos
Authorization: Bearer TOKEN
Content-Type: application/json

{"nome":"Pessoa candidata","email":"pessoa@example.com","perfilIdeal":true}
```

Status permitidos: inscrito, em_analise, aprovado, reprovado e erro. Qualquer
status pode ser atribuído manualmente; erro exige motivoErro. A saída do status
erro limpa o motivo. Um candidato com perfil ideal também pode ter outro status;
a marcação é manual e independente, sem fórmula automática de avaliação.

Indicadores: inscritos = quantidade de cadastros da vaga; candidatosIdeais =
quantidade com perfilIdeal; erros = quantidade com status erro. Remover candidato
recalcula as contagens. Vaga vazia retorna zeros com disponiveis=true.
Contadores legados não são convertidos em candidatos fictícios.

### Importação de vagas

`POST /api/importacoes` recebe CSV UTF-8 (com ou sem BOM), separado por vírgula ou
ponto e vírgula. Aceita aspas escapadas e campos entre aspas com quebras de linha.
Cabeçalhos obrigatórios, em qualquer ordem, sem extras/repetições:

```csv
cargo,perfilDesejado,clienteId,responsavelId,prazoInicial,prazoFinal,canais
Analista,Experiência em Dart,1,1,2026-11-01,2026-12-01,1|2
```

Os IDs precisam existir no banco; não são criados clientes, usuários ou canais
implicitamente. `canais` vazio é permitido. `.xlsx` não é aceito nesta versão:
exporte a planilha como CSV UTF-8. Máximo 2 MiB e 1000 vagas por lote.

Cabeçalhos HTTP: `Content-Type: text/csv; charset=utf-8`, Bearer e
`X-Idempotency-Key: identificador-do-lote`. Exige A e C. Erro de validação ou
referência desfaz o lote inteiro, incluindo o registro da importação. Registros
idênticos dentro do mesmo CSV são recusados. Chave e conteúdo idênticos retornam
o mesmo lote (200); chave reutilizada com outro conteúdo retorna 409. Chaves
distintas representam lotes distintos e podem criar vagas semelhantes.
Solicitações concorrentes da mesma chave são serializadas no PostgreSQL.

Resposta: `id`, `quantidade`, `criadoEm`, `vagas` (IDs). `GET /importacoes/{id}`
exige A e só permite consultar o próprio lote ou atuar como administrador.

### Dashboards e entregas

`GET /dashboard/atividades` conta tarefas pelo prazo inicial no período, com
agrupamentos por status de Kanban e etapa do funil (inclui grupos zerados).
Retorna `filtros`, `total`, `porStatus`, `porEtapa`.

`GET /dashboard/entregas` conta eventos de entrada na última coluna do Kanban,
determinada pela ordem configurada. Grava responsável, projeto e autor do momento
da conclusão. Repetir o status final não duplica o evento, inclusive com chamadas
concorrentes; reabrir e concluir novamente cria outro evento. Renomear colunas
não apaga as entregas já registradas. Retorna `filtros`, `total`, `porDia` e
`porResponsavel`; `porDia` contém apenas dias com eventos.

Ambos aceitam dataInicial/dataFinal (YYYY-MM-DD), responsavelId e projetoId.
Padrão: hoje e os 29 dias anteriores em UTC; no máximo 367 dias inclusivos.
Sem backfill de entregas porque o schema antigo não guardava a data de conclusão.

### Permissões de usuários

`PATCH /usuarios/{id}` agora também aceita `permissoes`: lista integral de IDs,
incluindo `[]` para revogar todas as permissões explícitas. Exige F; o operador
só pode conceder o que possui. Administradores só podem ser editados por um
contexto administrativo. Cargo e permissões são alterados atomicamente. Sessões
existentes consultam as permissões no servidor a cada requisição.

## Validação

```powershell
Push-Location backend
dart analyze
Pop-Location
docker compose --profile test run --build --rm backend-test
docker compose config --quiet
```

A suíte completa passou com **24 testes**, usando exclusivamente `folks_connect_test`,
incluindo upgrade do schema 001,
rotas antigas, autorização, SMTP local, anexos, edição de vaga, candidatos,
indicadores, importação com rollback/idempotência e dashboards. A sonda HTTP
também passou com `PREPARE OK`/`VERIFY OK` após reiniciar `backend-e2e`: sessão,
cadastros, anexos, vaga editada, candidato, indicadores, lote de importação,
repetição idempotente e eventos de entrega permaneceram iguais. A coleção
`docs/insomnia/folks-connect.json` contém as 46 operações do contrato atual.

## Dependências que exigem informação externa

Publicação real em LinkedIn/outros canais depende de plataformas escolhidas,
contas, permissões e credenciais; cadastrar canal não dispara publicação.
Recuperação por e-mail já usa SMTP, mas entrega pelo provedor real depende de
configuração. As telas Flutter mantêm sua demonstração local; integração com
estas APIs e novas telas de candidatos/dashboard/importação não foram incluídas
na alteração do backend.
