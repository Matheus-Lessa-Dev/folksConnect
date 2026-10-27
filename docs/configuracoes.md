# Configurações — Folks Mobile

Feature Gitflow: `feature/configuracoes`, a partir de `develop`.
Depende da navegação autenticada e dos controllers de sessão integrados com o funil de vagas em `develop` (`fe3bff5`).

## Referências conferidas no Chrome já autenticado

- [Configurações, 402 × 874](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-29).
- [Configurações Gerais, 402 × 1008](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=164-272).
- [Usuários e papéis, 402 × 874](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=175-80).
- [Novo Usuário, 402 × 1086](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=176-260).

O título foi confirmado no painel: Inria Serif Bold, 30 px, branco. A implementação reutiliza os gradientes, fontes locais, navegação e marca original existentes. O rótulo “Kanban, funil e Checklis” preserva o texto do quadro. Barras de status e gestos pertencem ao sistema e não são reproduzidas no Flutter.

Ainda há diferenças de densidade nos painéis com controles editáveis e áreas de toque ampliadas. O avatar usa temporariamente o ícone de pessoa do Flutter; a exportação da imagem original do Figma não foi concluída. Esta etapa não está certificada como idêntica pixel a pixel.

## Primeira etapa implementada

- Aba `/configuracoes` acessível pelo Kanban e funil, com estado mantido enquanto a sessão estiver aberta.
- Perfil com nome, e-mail e cargo, editáveis em memória.
- Configurações gerais com edição, adição e remoção de itens de cada seção. Exige ao menos um item por seção, sem nomes vazios ou repetidos. Fechar descarta o rascunho; salvar valida todas as seções antes de aplicar.
- Lista de usuários com cargo editável e remoção confirmada.
- Cadastro com nome, e-mail único, cargo e as doze permissões do quadro. Cancelar não cadastra.
- Painéis roláveis com espaço para teclado, safe areas e adaptação para texto ampliado.

## Limites de integração

Os dados são exclusivamente de demonstração e ficam em memória no `SettingsController` da sessão autenticada. Sair ou recarregar descarta as alterações. E-mails dos exemplos usam `example.com`.

O cadastro não cria contas Google nem credenciais de acesso. Cargos e permissões ainda não concedem autorização real. Perfil e usuários não são enviados ao backend.

As listas de etapas e checklist salvas são o estado da interface de configurações. Ainda não alteram os enums, tarefas, vagas ou checklists dos controllers de Kanban/funil. Essa integração precisa definir identificadores estáveis e tratamento de etapas já em uso antes de permitir renomear/excluir etapas reais. Não há migration nem schema novo nesta feature.

## Validação

`flutter analyze --no-pub`, `flutter test --no-pub --concurrency=1` (35 testes aprovados) e `flutter build web --release --no-pub`.

Os testes de configurações cobrem gravação atômica, cancelamento de rascunho, duplicidade de e-mail, permissões, remoção e celular/paisagem/tablet com fontes ampliadas e teclado.

O teste de navegação também verifica a preservação do perfil ao alternar entre as três abas. Foram corrigidos dois problemas nos testes recebidos de `develop`: expectativa de cartão em um controller vazio e clique no botão de login fora da área visível.

`frontend/tool/capture_settings.dart` renderiza os quatro estados para revisão visual. Execute com `flutter test tool/capture_settings.dart --no-pub --dart-define=CAPTURE_DIR=<pasta>`.
