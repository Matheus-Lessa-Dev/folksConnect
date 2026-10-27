# Folks Connect

## Projeto

- Projeto dividido em `frontend/` e `backend/`.
- Execucao completa via `docker-compose.yml`.
- Servicos Docker: `frontend` (Flutter Web + Nginx), `backend` (Dart + Shelf) e `database` (PostgreSQL 16).
- Frontend: `http://localhost:8080`.
- Backend: `http://localhost:8081`.
- Banco: `localhost:5432`.

## Estrutura

- Flutter: `frontend/lib/`.
- Entrada Flutter: `frontend/lib/main.dart`.
- Entrada Dart: `backend/bin/server.dart`.
- Backend interno: `backend/lib/src/`.
- Modelos: `backend/lib/src/models/`.
- Migrations SQL: `backend/database/migrations/`.
- Schema inicial: `backend/database/migrations/001_initial_schema.sql`.

## Comandos

```powershell
docker compose up --build
Push-Location frontend; flutter analyze; flutter build web --release; Pop-Location
Push-Location backend; dart analyze; Pop-Location
docker compose config
```

## Convencoes

- Responder em portugues, salvo pedido contrario.
- Fazer mudancas pequenas e focadas; preservar alteracoes existentes.
- Ler apenas o contexto necessario antes de editar.
- Validar sempre o trecho alterado com o comando mais especifico disponivel.
- Usar `apply_patch` para editar arquivos existentes e manter formatacao original.
- Nao editar `pubspec.lock` manualmente.
- Migrations devem ser SQL compativel com PostgreSQL e versionadas em `backend/database/migrations/`.
- Nao afirmar que colunas do banco sao definitivas quando nao estiverem confirmadas pelo SQL ou diagrama completo.
- Usar modelo de gerenciamento gitflow

## Regras permanentes de interface e Gitflow

- O Figma Folks Mobile e a fonte de verdade para telas, cores, tipografia, assets e espacamentos: https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile.
- Reutilizar os assets originais e conferir a tela implementada com o respectivo quadro. Nao redesenhar a marca ou substituir a paleta por um tema generico.
- Iniciar cada tela ou solicitacao nova em `feature/<nome-da-funcionalidade>`, a partir de `develop`. Se ja existir uma feature correspondente, continuar nela.
- Manter `main` para versoes estaveis e `develop` para integracao. Documentar dependencias entre features; nao misturar funcionalidades sem relacao.
- Verificar as alteracoes existentes antes de trocar de branch e preservar o trabalho do usuario.
