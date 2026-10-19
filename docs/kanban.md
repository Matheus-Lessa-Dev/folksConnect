# Kanban — Folks Mobile

Feature Gitflow: `feature/kanban`, criada a partir de `develop`.

Referencia: [Folks Mobile no Figma](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile).

## Escopo implementado

- Quadro com A fazer, Em andamento, Aguardando e Concluido, rolagem horizontal e contagem por coluna.
- Filtros de projeto e alternancia Kanban/Lista. O Figma apresenta o seletor Lista, mas nao uma tela separada para esse estado; a lista reutiliza os mesmos cartoes.
- Nova tarefa com titulo, projeto, empresa, cargo, responsavel, datas e prioridade. Campos obrigatorios e ordem dos prazos sao validados antes da criacao.
- Detalhes com etapa de recrutamento, responsavel, prioridade, descricao, checklist e anexos de ate 10 MB por arquivo.
- Avanco de etapa com escolha de responsavel e confirmacao. Cancelar preserva a etapa anterior; etapas anteriores e atual nao podem ser selecionadas.
- Status do quadro e etapa de recrutamento sao independentes: mover um cartao nao altera o funil. O menu do cartao permite mover sem depender de gestos.
- Modais rolaveis com espaco para teclado, safe areas e controles acessiveis.

## Integracao

`KanbanScreen` pode receber um `KanbanController`. A tela pode ser acessada pela rota `/kanban`; temporariamente tambem e a tela inicial porque o frontend anterior estava vazio.

O backend existente apenas expoe health check e apresentacao da API. Os dados, alteracoes e bytes dos anexos ficam **somente em memoria durante a sessao**; recarregar restaura os dados de demonstracao. Nao ha upload ou gravacao em banco. Empresas, cargos, projetos e responsaveis sao catalogos de demonstracao, a substituir pelos endpoints reais quando implementados.

As demais abas ficam desabilitadas ate suas respectivas features existirem. Importacao de planilha nao foi implementada: o Figma nao apresenta seu fluxo.

## Referencia visual

O quadro e os tres estados sobrepostos seguem a composicao observada no Figma: fundo roxo, cartoes roxos, formularios azul-escuro, navegacao azul, acento laranja e botao adicionar dourado. Os tokens estao centralizados em `frontend/lib/core/theme/folks_theme.dart`.

Os valores de cor foram aproximados a partir da referencia visual; a conexao do Figma nao permitiu extrair todas as propriedades nesta sessao. A tipografia usa a familia Times New Roman nos titulos e Arial no corpo, com fallback; fontes nao foram incorporadas. O simbolo central usa provisoriamente `Icons.hub_outlined` e deve ser substituido pelo asset original exportado do Figma. Portanto, esta entrega ainda precisa de uma passada de fidelidade com tokens, fontes e marca exportados antes de ser considerada identica ao layout.

## Validacao

```powershell
cd frontend
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub
```

Testes cobrem criacao, validacao, filtros, lista, movimento entre colunas, checklist, cancelamento/confirmacao do avanco e layouts de celular, paisagem e tablet com texto ampliado.
