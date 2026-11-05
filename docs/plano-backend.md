# Plano de implementação

Contrato de referência: `../rotas-backend-folks.md` (o caminho solicitado
`docs/rotas-backend.md` não existia na cópia inicial). A implementação preserva
Dart/Shelf, PostgreSQL, os models e o schema 001. Branch: `feature/backend-api`.

1. Infraestrutura: pool PostgreSQL, migrations 002 incrementais e versionadas,
   transações, validação de entrada e respostas de erro consistentes.
2. Identidade: senhas com PBKDF2, sessões opacas revogáveis persistidas,
   perfil, recuperação por SMTP e bootstrap restrito a desenvolvimento.
3. Usuários e catálogos: permissões consultadas no servidor, desativação
   preservando vínculos, clientes e canais; projetos/prioridades somente leitura.
4. Configurações: atualização integral atômica, IDs estáveis, ordem,
   proteção de etapas referenciadas e snapshots do checklist por tarefa.
5. Tarefas: filtros/paginação, detalhes, edição, movimentação independente
   do recrutamento, avanço transacional, checklist e anexos no PostgreSQL.
6. Vagas: cadastro transacional e múltiplos canais. Indicadores não definidos
   são nulos, sem simulação de números.
7. Entrega: coleção Insomnia, exemplos, configuração, testes negativos e
   fluxos integrados, reinício e conferência da persistência.

Cada módulo deve passar análise estática e verificações específicas antes de
avançar. Testes de integração usam banco isolado e nunca apagam banco de uso.
Dashboard, edição de vaga e importação permanecem pendentes conforme o contrato.
