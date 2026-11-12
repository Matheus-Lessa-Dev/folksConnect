# Pendências do backend — Folks Connect

Análise realizada em 12/11/2026, na branch `feature/backend-camadas-fluxos`.
Escopo: backend, infraestrutura e banco de dados. Nenhuma alteração no frontend.
Este documento registra o estado observado nessa data; as pendências não foram
corrigidas durante a análise.

## Diagnóstico

O backend está bem avançado: o escopo funcional atual está implementado, mas
ainda há correções e preparação operacional antes de considerá-lo concluído
para produção. A maior parte do trabalho restante está em confiabilidade,
administração e infraestrutura.

Autenticação, recuperação de senha, usuários, permissões, configurações,
tarefas, checklists, anexos, vagas, candidatos, indicadores, importação CSV e
dashboards já existem. Os relatórios antigos que apontam vários desses módulos
como pendentes não representam o código atual.

## Validações realizadas

- `dart analyze`: sem problemas.
- Suíte completa: **24 testes aprovados**, com PostgreSQL e HTTP.
- Testes unitários de validação e CSV: seis testes aprovados em execução separada.
- Build do executável e configuração do Compose aprovados.
- Persistência após reiniciar o backend: sessão, cadastros, candidatos,
  importações, entregas e arquivos preservados. A sonda retornou `PREPARE OK`
  e `VERIFY OK`; o SHA-256 do download permaneceu idêntico e o anexo removido
  continuou ausente.
- Três verificações adicionais reproduziram os problemas descritos abaixo.

As verificações com gravação usaram exclusivamente `folks_connect_test`.
Nenhum arquivo do projeto foi alterado durante a análise. Os testes adicionais
foram temporários e não foram incorporados à suíte do repositório. O backend
temporário de testes foi parado ao final da verificação.

## 1. Correções funcionais prioritárias

### 1.1. Configurações podem perder alterações de outro usuário

**Reprodução:** duas pessoas partem da mesma configuração. A primeira altera o
Kanban; a segunda altera o checklist usando a versão antiga. Ambos os
salvamentos retornam `200`, mas o segundo desfaz a alteração do Kanban
silenciosamente.

A transação protege a gravação, mas não identifica um formulário desatualizado.
Falta versionamento da configuração, com rejeição do salvamento antigo por
`409` ou `412`.

Referência: [settings_service.dart](lib/src/services/settings_service.dart),
método `SettingsService.put`.

### 1.2. Edição de permissões sem consulta administrativa correspondente

O `PATCH /api/usuarios/{id}` substitui as permissões, mas a listagem não retorna
as permissões atuais e não existe `GET /api/usuarios/{id}`. A consulta de
detalhes retornou `404` na verificação adicional.

Isso impede carregar com segurança o estado atual para uma edição posterior.
Falta uma consulta de detalhes protegida pela autorização adequada.

Referências:

- [users_repository.dart](lib/src/repositories/users_repository.dart), método
  `UserRepository.list`.
- [api_routes.dart](lib/src/routes/api_routes.dart), rotas de usuários.

### 1.3. Recuperação de senha revela existência da conta quando SMTP falha

**Reprodução:** com o SMTP indisponível, a recuperação respondeu `503` para um
e-mail cadastrado e `202` para um e-mail inexistente. A resposta pública deixa
de ser genérica nesse cenário.

Falta uniformizar esse comportamento e registrar a falha de entrega
internamente. Uma fila de envio também permitiria controlar tentativas.
A solução deve atualizar o contrato e os testes conforme a estratégia adotada.

Referência: [auth_service.dart](lib/src/services/auth_service.dart), método
`AuthService.recover`.

## 2. Pendências para produção

| Prioridade | O que falta | Evidência e encaminhamento |
|---|---|---|
| Alta | Separar usuários do banco | A conta usada pelo Compose foi confirmada como superusuária, com poderes de criar bancos e papéis. Criar uma conta restrita para a aplicação e outra para migrations. |
| Alta | Provisionar o primeiro administrador | O bootstrap disponível é exclusivo de desenvolvimento. Falta um comando ou procedimento completo, reproduzível e testado para criar o administrador de produção. |
| Alta | Preparar a implantação de produção | O Compose atual oferece credenciais e seed de desenvolvimento por padrão e publica o PostgreSQL em todas as interfaces. Falta configuração própria de produção, rede restrita, segredos e HTTPS na entrada da API. |
| Alta | Automatizar backup e testar restauração | Não foi encontrada essa automação no repositório. O volume preserva os dados entre reinícios, mas não substitui backup. Como os anexos estão no PostgreSQL, entram nesse planejamento. |
| Alta | Homologar SMTP real | O fluxo passou com servidor SMTP local. Validar autenticação, TLS, remetente e recebimento pelo provedor escolhido. |
| Média | Automatizar validações e implantação | Não foi encontrado pipeline no repositório. Automatizar análise, testes com PostgreSQL isolado, build e verificações das migrations. |

Essas observações descrevem o repositório e o ambiente local inspecionado;
não comprovam a ausência de infraestrutura externa mantida separadamente.

Referências:

- [docker-compose.yml](../docker-compose.yml).
- [Guia do backend](../docs/backend.md), incluindo a limitação do bootstrap
  administrativo ao ambiente de desenvolvimento.

## 3. Operação, segurança e desempenho

- **Monitoramento:** acrescentar logs de requisições com duração, status e
  identificador, além de alertas para falhas de banco e SMTP. Existe
  `/api/health`, mas o serviço backend não tem healthcheck configurado no
  Compose.
- **Auditoria administrativa:** registrar autor e alterações de permissões,
  desativações e configurações. Atualmente há histórico específico de avanços
  e entregas.
- **Limites de recursos:** complementar o limite de autenticação por e-mail
  com controle por origem e concorrência; definir cotas de anexos. O multipart
  pode carregar aproximadamente 100 MiB por requisição em memória.
- **Build reproduzível:** fixar a versão da imagem Dart e executar o container
  com usuário sem privilégios. O Dockerfile usa `dart:stable` e mantém o SDK
  na imagem final.
- **Validação de desempenho:** medir importação no limite de 1.000 registros,
  consultas com volume e uploads simultâneos antes de escolher novos índices
  ou capacidade. Os testes funcionais executados não comprovam desempenho
  sob carga.

Referências:

- [api_middleware.dart](lib/src/middleware/api_middleware.dart).
- [auth_service.dart](lib/src/services/auth_service.dart).
- [upload_decoder.dart](lib/src/controllers/upload_decoder.dart).
- [http.dart](lib/src/http.dart).
- [Dockerfile](Dockerfile).

## 4. Decisões de negócio que precisam de aceite

Esses pontos não são necessariamente defeitos nem exigem automaticamente novas
funcionalidades. Precisam ser confirmados com os responsáveis pelo produto.

- **Visibilidade dos dados:** atualmente qualquer usuário autenticado pode
  consultar dados de todos os projetos, incluindo candidatos e anexos. Isso
  está explícito no contrato; confirmar se atende à operação.
- **Indicadores:** perfil ideal é uma marcação manual. Entregas contam entradas
  na última coluna, e uma reconclusão gera outro evento. Confirmar essas
  definições e o uso de UTC.
- **Histórico legado:** os contadores antigos de candidatos são preservados no
  banco, mas os indicadores atuais contam os candidatos cadastrados. Se houver
  dados históricos importantes, decidir como apresentá-los.
- **Publicação externa:** cadastrar canais não publica vagas. Integrações
  dependem das plataformas escolhidas e só entram como pendência se fizerem
  parte da entrega.

Referências:

- [Contrato atual](../docs/rotas-backend.md).
- [Camadas e fluxos operacionais](../docs/backend-camadas.md).
- [Migration 004](database/migrations/004_fluxos_operacionais.sql).

## 5. Documentação

- Corrigir o [README](../README.md): ele descreve as migrations como executadas
  na primeira inicialização do volume PostgreSQL. Atualmente o backend verifica
  e aplica as migrations pendentes durante sua inicialização, antes de aceitar
  requisições.
- Atualizar ou identificar claramente como histórico o
  [documento original de rotas](../rotas-backend-folks.md), que ainda afirma que
  somente dois endpoints existem.
- Manter o [contrato implementado](../docs/rotas-backend.md) e o documento de
  [camadas e fluxos](../docs/backend-camadas.md) como referências do estado atual,
  distinguindo-os dos relatórios históricos.

## 6. Ordem sugerida para fechar o backend

1. Corrigir os três problemas reproduzidos e incorporar testes de regressão.
2. Fechar o provisionamento administrativo de produção.
3. Preparar banco, infraestrutura e backup com restauração testada.
4. Homologar SMTP e obter aceite das regras de negócio.
5. Automatizar validações e implantação; completar monitoramento e validação
   de desempenho conforme a carga esperada.
6. Atualizar a documentação e homologar a entrega pelos contratos HTTP.

Não há necessidade identificada de reescrever a arquitetura ou alterar o
frontend para executar esse trabalho. As implementações futuras devem seguir
Gitflow, com features a partir de `develop` ou continuação da feature
correspondente, preservando alterações existentes e documentando dependências.
