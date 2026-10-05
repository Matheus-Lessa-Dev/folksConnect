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
