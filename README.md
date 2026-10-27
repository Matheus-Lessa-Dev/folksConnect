# Folks Connect

## Executar com Docker

Copie `.env.example` para `.env` e ajuste os valores quando necessário. Depois
execute:

```bash
docker compose up --build
```

Aplicacoes disponiveis:

- Frontend: http://localhost:8080
- Backend: http://localhost:8081/api/health
- PostgreSQL: localhost:5432

Rotas do frontend:

- `http://localhost:8080/login`: login.
- `http://localhost:8080/kanban`: quadro de tarefas.
- `http://localhost:8080/funil-vagas`: funil de vagas.
- `http://localhost:8080/configuracoes`: configurações.

As abas atualizam a URL e acompanham o histórico do navegador. Acessar uma aba
sem autenticação abre o login e, após entrar, retorna à aba solicitada. A sessão
atual é mantida apenas em memória; recarregar a página exige novo login.
O caminho `/` mantém a abertura com a marca antes do login.

A feature `feature/rotas-frontend` parte de `develop` e reutiliza as telas de
login, Kanban, funil de vagas e configurações já integradas nessa branch.

As migrations SQL colocadas em `backend/database/migrations` sao executadas
automaticamente na primeira inicializacao do volume do PostgreSQL.

Para parar os containers sem remover os dados:

```bash
docker compose down
```

Para remover tambem o banco persistido:

```bash
docker compose down -v
```
