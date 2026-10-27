# Funil de Vagas — Folks Mobile

Branch `feature/funil-vagas`, criada a partir de `develop`. A feature incorpora
`feature/kanban` (até `48086a4`) para reutilizar o tema, as fontes, a marca e os
componentes já implementados. A integração futura em `develop` deve considerar
essa dependência.

## Referências consultadas

O Figma foi consultado pelo MCP do Playwright:

- [Tela principal, 402 × 874](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=68-2).
- [Cadastrar Vaga](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-595).
- [Seleção de cliente](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-828).
- [Novo cliente dentro do cadastro](https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile?node-id=158-1056).

## Escopo

- Rota autenticada `/funil-vagas`, acessível pelo ícone do funil na navegação inferior.
- Cartões com cargo, cliente, tempo desde a abertura, prazo, etapas e indicadores.
- Cadastro de cargo, cliente, perfil desejado, responsável, período e canais.
- Novo cliente com empresa, CNPJ, representante, contato e e-mail. A empresa é
  obrigatória; o e-mail, quando informado, deve ter formato válido.
- Inclusão e seleção de canais, validação de campos obrigatórios e período.
- Navegação compartilhada com o Kanban, mantendo os controllers durante a sessão.
- Funil e Kanban acessíveis depois do login; sair encerra os controllers em memória.
- Conteúdo rolável, safe areas e formulários adaptados para teclado e texto maior.

As cores, fontes e gradientes reutilizam `FolksTheme`. As etapas reutilizam o
componente `Pipeline` já existente no Kanban. Os controles de formulário usam
alvos de toque maiores que os elementos compactos do desenho.

## Limites desta primeira versão

Os dados são demonstrativos e ficam **somente em memória**. Recarregar restaura
os exemplos. Não há integração com API, banco, divulgação real ou candidatos.
Os indicadores de uma nova vaga começam zerados na etapa Triagem. Os cartões
são informativos: não foi inventado um fluxo de edição ou movimentação.

Como regra provisória de apresentação, o prazo é atrasado depois do dia final;
até três dias antes do vencimento, inclusive o dia final, aparece “Perto de
Fechar”. Essa janela de três dias precisa ser confirmada como regra de negócio.
Vagas futuras mostram “início em …”, sem apresentar dias negativos.

Salvar um novo cliente mantém esse cliente na sessão, mesmo se o usuário fechar
o cadastro da vaga depois. Campos adicionais do cliente são dados locais de
apresentação; não definem o schema do banco. CNPJ não tem validação cadastral.
O diálogo para adicionar canal é uma adaptação funcional: o Figma mostra o
botão, mas não detalha esse diálogo.

## Validação

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub
flutter test tool/capture_vacancy_funnel.dart --no-pub --dart-define=CAPTURE_DIR=<pasta>
```

Os testes cobrem limites de prazo, criação e validação, novo cliente, canais,
cancelamento, navegação e manutenção do estado do Kanban, além de celular,
paisagem e tablet com texto ampliado e animações reduzidas.
