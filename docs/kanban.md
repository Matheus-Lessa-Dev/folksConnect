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

`KanbanScreen` pode receber um `KanbanController` e o callback `onSignOut`. O fluxo de abertura e login existente foi preservado: o quadro completo aparece apos a autenticacao e Sair retorna ao login. O tema `FolksTheme.kanban` fica restrito ao quadro, preservando o tema e as cores das telas de abertura e login.

O backend existente apenas expoe health check e apresentacao da API. Os dados, alteracoes e bytes dos anexos ficam **somente em memoria durante a sessao**; recarregar restaura os dados de demonstracao. Nao ha upload ou gravacao em banco. Empresas, cargos, projetos e responsaveis sao catalogos de demonstracao, a substituir pelos endpoints reais quando implementados.

As demais abas ficam desabilitadas ate suas respectivas features existirem. Importacao de planilha nao foi implementada: o Figma nao apresenta seu fluxo.

## Referencia visual

O quadro e os tres estados sobrepostos seguem a composicao observada no Figma: fundo roxo, cartoes roxos, formularios azul-escuro, navegacao azul, acento laranja e botao adicionar dourado. Os tokens estao centralizados em `frontend/lib/core/theme/folks_theme.dart`.

As propriedades das camadas confirmaram Inria Serif Bold nos titulos (30 px no quadro e 18 px nos cartoes), Inter nas colunas, categorias e metadados, e Inria Sans no sinal de adicionar. As familias foram incorporadas como assets locais com licencas OFL. A renderizacao nao depende de fontes instaladas no computador nem de download em tempo de execucao.

Foram conferidos no painel do Figma os fundos radiais (`#2F1F59`, `#250D63`, `#241250`, `#160C30`), cartoes (`#666666` com 20% de opacidade), folhas (`#12182A`), navegacao (`#1B224E`), adicionar (`#D9A441`) e circulo da marca (`#FF671D`). O botao principal usa as cores do estilo radial `centro`, incluindo `#190D36`.

A marca branca original foi baixada da camada `LOGO-BRANCA.png` e preservada em `frontend/assets/brand/folks-white.png`. `FolksMark` faz o recorte do simbolo no layout, como na navegacao do Figma, sem alterar o arquivo original.

Os gradientes usam os centros, proporcoes elipticas e paradas do CSS copiado pelo painel do Figma: fundo `116.25% 78.95% at 88.91% 39.74%` (paradas 0, 16.28%, 28.82%, 58.85%) e centro `133.71% 6229.23% at 46.68% 57.14%` (0, 51.21%, 67.88%, 90.12%, 100%). O proprio Figma alerta que esse CSS nao preserva uma rotacao interna do gradiente. Ainda precisam de conferencia alguns controles e cores auxiliares de status. A implementacao segue a referencia inspecionada, mas ainda nao foi certificada como identica pixel a pixel.

## Validacao

```powershell
cd frontend
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub
```

Testes cobrem criacao, validacao, filtros, lista, movimento entre colunas, checklist, cancelamento/confirmacao do avanco e layouts de celular, paisagem e tablet com texto ampliado.
