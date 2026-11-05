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

As migrations SQL em `backend/database/migrations` são executadas pelo backend
em cada inicialização, incluindo bancos já existentes. A tabela
`schema_migrations` registra versão e checksum; migrations aplicadas não devem
ser editadas. Não é necessário apagar o volume para atualizar o schema.

Backend e testes no Insomnia: [guia de execução](docs/backend.md),
[contrato HTTP](docs/rotas-backend.md),
[coleção importável](docs/insomnia/folks-connect.json) e
[relatório de verificações](docs/relatorio-backend.md).

O usuário inicial é exclusivo de desenvolvimento e exige `APP_ENV=development`
e `DEV_SEED=true`. As credenciais estão em `.env.example`; veja o guia antes de
expor a aplicação fora do ambiente local.

Para parar os containers sem remover os dados:

```bash
docker compose down
```

Para remover tambem o banco persistido:

```bash
docker compose down -v
```
