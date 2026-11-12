# Backend Folks Connect

Stack preservada: Dart, Shelf/Shelf Router e PostgreSQL 16. Os models originais
continuam em `backend/lib/src/models`; as consultas ficam em `repositories/`,
as regras em `services/`, a adaptação HTTP em `controllers/` e as rotas em
`routes/api_routes.dart`. A composição fica em `application.dart`.
Veja [arquitetura e novos fluxos](backend-camadas.md).
O schema 001 permanece intacto; 002 acrescenta os dados
operacionais e ajusta a nulabilidade necessária ao contrato. A migration 003
ordena checklists legados e garante ordens únicas nas três configurações.

## Execução local

Na raiz, copie `.env.example` para `.env` (não sobrescreva configuração existente):

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up --build -d
docker compose logs backend
```

API: `http://localhost:8081/api`. Frontend: `http://localhost:8080`.
`GET /api/health` consulta o banco, além de confirmar que o processo responde.
As telas Flutter existentes ainda usam dados de demonstração em memória;
os fluxos HTTP do backend são acessíveis diretamente pelo Insomnia.

O backend aplica migrations em transação, com trava de migração e checksums,
antes de aceitar requisições. Isso funciona tanto com volumes novos quanto com
o schema 001 já criado. Faça backup antes de atualizar bancos de uso.
Duplicidades de e-mail desconsiderando maiúsculas precisam ser corrigidas antes
da migration 002. Usuários legados sem senha permanecem sem login até receberem
uma senha pelo fluxo de recuperação com SMTP configurado.

Para parar mantendo banco, sessões e anexos: `docker compose down`.
Não utilize `down -v` se quiser preservar os dados. Os anexos são `BYTEA` no
PostgreSQL; não dependem do sistema de arquivos do container do backend.

## Acesso de desenvolvimento

Com `APP_ENV=development` e `DEV_SEED=true`, o primeiro início cria:

- E-mail: `admin@folks.local`.
- Senha: `FolksDev!2026`.
- Projeto: `Desenvolvimento`.

Esses valores podem ser alterados por `DEV_ADMIN_EMAIL`/`DEV_ADMIN_PASSWORD`.
O seed é idempotente e não troca senha nem promove uma conta já existente.
Não recria dados de demonstração. Cargos, prioridades e etapas iniciais são
catálogos configuráveis; tarefas, clientes e vagas começam vazios.
Para produção, use **`APP_ENV=production` e `DEV_SEED=false`**; habilitar o seed
fora de desenvolvimento impede a inicialização. A provisão de administradores
de produção não é exposta por rota HTTP. Ela exige procedimento operacional de
provisionamento pelo responsável pelo banco. O cargo Gerente não é equivalente
ao atributo interno de administrador.

## Insomnia e autenticação

Importe `docs/insomnia/folks-connect.json` pelo menu de importação de arquivo.
Selecione o ambiente local. Execute Login, copie `token` da resposta para a
variável `token` do ambiente. As requisições protegidas já utilizam
`Authorization: Bearer {{ _.token }}`.

```http
POST /api/auth/login
Content-Type: application/json

{"email":"admin@folks.local","senha":"FolksDev!2026"}
```

A sessão dura 12 horas, fica persistida e pode ser revogada por logout,
desativação ou redefinição de senha. Não há refresh token: após expirar, faça
login novamente. Senhas são armazenadas com PBKDF2-HMAC-SHA256, sal aleatório e
600.000 iterações; tokens aleatórios de 256 bits são armazenados apenas como
hash SHA-256. Use HTTPS ao hospedar fora da máquina local.

Consulte os catálogos antes de cadastrar; configure no ambiente os IDs
retornados (`cargoId`, `projetoId`, `prioridadeId`, `responsavelId`, `clienteId`,
`canalId`, `statusId`, `etapaId`). Salve também os IDs das criações de tarefa,
item e anexo. Os números de exemplo não substituem os IDs reais do seu banco.
Para salvar configurações, copie o JSON do GET, faça a alteração desejada e
utilize o objeto integral no corpo do PUT, preservando IDs de itens existentes.
A variável `configuracoes` da coleção deve conter esse JSON como string; você
também pode substituir diretamente o corpo do PUT pelo JSON recebido.

O cadastro de usuário exige uma senha inicial de 12 a 128 caracteres, informada
pelo operador. A entrega dessa senha ao usuário ocorre fora da API. Não há envio
de credencial ou convite automático. O usuário pode definir outra senha pelo
fluxo de recuperação. O perfil só aceita nome e e-mail; permissões são atribuídas
no cadastro e podem ser substituídas pelo PATCH de usuário com permissão F.
O operador só pode conceder permissões que possui; cargos não concedem acesso.

## Recuperação de senha

Configure `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM` e, se o servidor exigir,
`SMTP_USER`/`SMTP_PASSWORD`. `SMTP_SSL=true` usa TLS direto (normalmente porta
465); com `false`, o cliente negocia STARTTLS. Conexões sem TLS só são admitidas
com `APP_ENV=development` e `SMTP_ALLOW_INSECURE=true`.

```http
POST /api/auth/recuperar-senha
Content-Type: application/json

{"email":"admin@folks.local"}
```

O e-mail contém o token para `POST /api/auth/redefinir-senha`:

```json
{"token":"TOKEN_RECEBIDO_POR_EMAIL","senha":"MinhaNovaSenha!2026"}
```

O token expira em 30 minutos, é de uso único e uma nova solicitação invalida o
anterior. A resposta da solicitação é genérica (202) para e-mails cadastrados ou
não. Sem configuração ou com falha de envio, retorna 503, sem fingir entrega.
O corpo HTTP e os logs não expõem o token de recuperação.
Há limites persistidos de login (10 tentativas/15 minutos por e-mail) e
recuperação (3/15 minutos por e-mail), com resposta 429 ao exceder.

## Arquivos

No Insomnia, selecione um arquivo no campo multipart `arquivo` ou adicione até
10 campos `arquivos`. Cada arquivo aceita até 10 MiB (10.485.760 bytes).
O lote é atômico: um arquivo inválido impede todo o envio.
Também é possível enviar um arquivo como corpo binário com `X-File-Name`
(codificado como URL para caracteres fora de ASCII) e seu `Content-Type`.
O download exige autenticação e retorna `Content-Disposition: attachment`.

## Banco e configuração sem Docker

Exporte `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USER` e
`DATABASE_PASSWORD`. `DATABASE_SSL=require` exige TLS; o padrão local é sem TLS.
Na pasta `backend`, execute `dart pub get` e `dart run bin/server.dart`.
`PORT` é 8080 por padrão; para a mesma URL do Compose, use `PORT=8081`.
`MIGRATIONS_PATH` é relativo ao diretório de execução, padrão `database/migrations`.
O código não carrega `.env` automaticamente fora do Compose.

Projetos têm somente GET no contrato. Fora do seed de desenvolvimento, a
provisão de projetos deve ser feita pelo responsável pelo banco, por exemplo:
`INSERT INTO projetos (nome) VALUES ('Nome do projeto');`.

## Testes

O teste de integração limpa **somente** o banco dedicado `folks_connect_test`.
Nunca aponte os testes para um banco de uso. Crie o banco uma vez:

```powershell
docker compose up -d database
docker compose exec database psql -U folks_connect -d postgres -c "CREATE DATABASE folks_connect_test"
docker compose --profile test run --build --rm backend-test
docker compose --profile test run --rm backend-test dart analyze
docker compose config --quiet
```

Se alterou `POSTGRES_USER`, ajuste o argumento `-U`. Se o banco de testes já
existe, não repita o CREATE DATABASE. Os testes exercitam HTTP real e PostgreSQL,
incluindo transações, autorização, bytes de anexos e SMTP de teste. O servidor
SMTP local da suíte apenas captura os e-mails de teste; não envia a terceiros.
`dart test` sem `RUN_DB_TESTS=true` executa somente os testes unitários e sinaliza
explicitamente os testes de banco como ignorados.

O resultado e o procedimento de reinício estão em `relatorio-backend.md`.
