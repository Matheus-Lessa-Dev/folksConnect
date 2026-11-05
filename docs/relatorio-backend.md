# Relatório de entrega do backend

Data: 03/11/2026. Branch: `feature/backend-api`.

O contrato analisado foi `rotas-backend-folks.md` na raiz. O caminho solicitado
`docs/rotas-backend.md` não existia; agora contém o contrato HTTP implementado.
O documento original e as alterações preexistentes foram preservados.

## Funcionalidades concluídas

| Módulo | Entrega |
|---|---|
| Persistência | Pool PostgreSQL, transações e migrations automáticas com checksum e trava. Schema 001 preservado; migrations 002/003 incrementais. |
| Autenticação | Sessões opacas persistidas de 12 horas, login/logout, recuperação SMTP, redefinição com expiração/uso único e revogação das sessões. |
| Perfil | Consulta com cargo/permissões e edição de nome/e-mail, recusando campos de acesso. |
| Usuários | Cadastro com credenciais e permissões, listagem, alteração de cargo e desativação preservando vínculos. |
| Autorização | Verificação no servidor; cargo não concede administração; operador não concede permissões que não possui. Seed administrativo somente em desenvolvimento. |
| Catálogos | Cadastro/pesquisa de clientes e canais; consulta de cargos, permissões, projetos e prioridades. |
| Configurações | Três seções salvas atomicamente, IDs estáveis, ordenação, validação de duplicados e bloqueio de remoção de etapas em uso. |
| Tarefas | Cadastro, detalhes, edição prevista, filtros/paginação, movimentação independente do recrutamento e avanço transacional com responsável. |
| Checklist | Snapshot do padrão por tarefa, inclusão e marcação/desmarcação de itens da tarefa. |
| Anexos | Upload binário/multipart, limite de 10 MiB por arquivo, download autenticado, remoção e conteúdo BYTEA no PostgreSQL. |
| Vagas | Cadastro/listagem com cliente, responsável, datas, etapa e múltiplos canais. Indicadores indefinidos retornam nulos. |
| Entrega | Guia de execução, contrato com exemplos, coleção Insomnia com 35 operações, usuário inicial e ferramentas de teste/reinício. |

A stack e as classes dos models existentes foram mantidas. Cliente, usuário,
tarefa e vaga receberam ajustes pontuais de nulabilidade coerentes com os campos
opcionais e a distinção entre cargo interno e cargo da oportunidade. Os módulos
usam os models nos campos originais e enriquecem a serialização com o contrato.

## Funcionalidades verificadas

**Suíte final: 16 testes aprovados**, incluindo HTTP real e PostgreSQL 16 no
Docker. Nenhum teste de banco foi ignorado na execução completa:

```powershell
docker compose --profile test run --build --rm backend-test
```

| Verificação | Resultado |
|---|---|
| Migrations em banco novo e reaplicação | Três versões registradas; reaplicação idempotente. |
| Upgrade com registros do schema 001 | Usuários, tarefas, cliente, checklist, vaga/canal e contadores legados preservados em schema isolado. |
| Migration alterada após aplicação | Alteração de uma cópia de teste recusada pelo checksum. |
| Login/perfil/logout | Credencial errada recusada; sessão persistida; logout revogado. |
| Autorização | Perfil recusa elevação; usuário sem permissão recebe 403; concessão de acesso não possuído recusada sem criar conta. |
| Todas as rotas protegidas | As 30 operações protegidas responderam 401 sem Bearer. |
| Usuários/catálogos | Cadastro, pesquisa, alteração, validação de e-mail, duplicidade de canal, desativação e revogação de conta inativa aprovados. |
| Configurações | IDs preservados, troca de nomes, adição e rollback por corpo inválido/etapa em uso aprovados. |
| Tarefas | Relações reais, filtros/paginação, edição e independência entre status e etapa aprovados. |
| Avanços concorrentes | Duas solicitações para a mesma etapa: uma 201, outra 409, um único avanço. Referência inválida não altera a tarefa. |
| Checklist | Marcar/desmarcar, recusar item de outra tarefa e preservar snapshot após alteração do padrão aprovados. |
| Anexos | Bytes e nomes UTF-8 preservados, multipart com dois arquivos, limite exato de 10 MiB aceito, excesso com 413, lote inválido sem gravação parcial, multipart truncado com 400 e remoção aprovados. |
| Vagas | Múltiplos canais, filtros, rollback por canal inexistente e vínculo preservado após alterar cargo interno do responsável. |
| Recuperação | E-mail recebido por SMTP local; token anterior invalidado, novo de uso único, expirado recusado, senha antiga recusada e sessões revogadas. |
| Seed de desenvolvimento | Habilitação em produção recusada. |
| Análise estática | `dart analyze`: sem problemas. |
| Build/Compose | Compilação AOT, imagens de execução/teste e `docker compose config --quiet` aprovados. |
| URL para Insomnia | Health, login, perfil autenticado e logout em `http://localhost:8081/api` testados a partir do host. |

A coleção usa o [JSON v4 aceito pelo Insomnia](https://developer.konghq.com/insomnia/import-export/).
Sua estrutura, IDs/ambiente e cobertura das 35 operações foram conferidos.
A importação pela interface gráfica do Insomnia não foi executada nesta sessão;
os fluxos HTTP equivalentes foram executados pela suíte e pela sonda.

### Persistência após reiniciar o backend

A sonda `backend/tool/persistence_probe.dart` usa HTTP contra o executável
compilado de `backend-e2e`, com banco dedicado de testes. Grava usuário, cliente,
canal, configurações, tarefa, descrição editada, status, avanço/responsável,
checklist concluído, anexos e vaga/canal. Após reiniciar o processo, utiliza o
mesmo token anterior ao reinício e compara os dados.

Procedimento executado e reproduzível, após a suíte:

```powershell
docker compose --profile test up --build -d backend-e2e
docker compose --profile test run --rm backend-test dart run tool/persistence_probe.dart prepare
docker compose --profile test restart backend-e2e
docker compose --profile test run --rm backend-test dart run tool/persistence_probe.dart verify
docker compose --profile test stop backend-e2e
```

Resultado: **PREPARE OK e VERIFY OK**. Sessão/perfil e dados permaneceram iguais.
O SHA-256 do download permaneceu idêntico; um anexo removido antes do reinício
continuou retornando 404. A sonda espera o backend ficar pronto após o reinício.

O volume `test_state` contém somente estado e token da sonda de teste. Não execute
a suíte que limpa o banco simultaneamente à sonda. Os registros de verificação
não são seeds de demonstração e não foram criados no banco principal.

## Pendências e limites conhecidos

| Item | Definição ou configuração faltante |
|---|---|
| Dashboard de atividades | Registros contados, agrupamentos e filtros. Sem endpoint implementado. |
| Dashboard de entregas | Conceito de entrega, séries e período. Sem endpoint implementado. |
| Importação | Formato da planilha, mapeamento/destino e regras de erros/duplicidades. Sem endpoint implementado. |
| Indicadores | Fonte/vínculo das inscrições, fórmula de candidatos ideais e significado de erros. Retornam null e disponiveis=false. |
| Edição de vaga | Campos editáveis, transições e fluxo ainda pendentes no contrato. Permissão D existe; PATCH não foi criado. |
| Candidatos/publicação | CRUD de candidatos e integração externa não definidos. Relacionar canais não publica vagas fora do sistema. |
| “Perto de Fechar” | Janela de três dias é provisória no documento original; não virou regra definitiva da API. |
| SMTP principal | Host/remetente não configurados no `.env` atual. Recuperação responde 503 até configurar. Fluxo testado com SMTP local; entrega por provedor externo não testada. |
| Produção | Exige DEV_SEED=false, banco/administrador provisionados pelo operador e credenciais próprias. O seed é exclusivo de desenvolvimento. |
| Frontend | Este checkout tem apenas a tela inicial Flutter. Integração das telas com a API não faz parte desta entrega de backend. |

Regras operacionais adotadas constam no contrato: somente empresa obrigatória
no cliente; CNPJ informado com 14 dígitos, sem regra fiscal de dígito verificador;
senha inicial entregue pelo operador; B cobre o ciclo de tarefas e C os cadastros
auxiliares de vagas. Não foram criados fluxos extras para alteração posterior de
permissões ou isolamento por projeto.

A conexão nativa Dart → PostgreSQL pela porta do host Windows apresentou erro
de autenticação/protocolo na verificação inicial. As verificações completas
usaram a rede interna do Docker e passaram. A API HTTP em 8081 foi verificada
no host; prefira os comandos Docker documentados para reproduzir os testes.
