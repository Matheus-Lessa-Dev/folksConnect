# Referencia visual — Folks Mobile

- Arquivo: https://www.figma.com/design/H2ATifgEvdrl05TyUbcQdr/Folks-Mobile
- Login: node `9:1164`, frame 402 × 874.
- `login-reference.png`: exportacao original do quadro Login.
- Fundo amostrado da exportacao: `#3D3D3D`.
- Acao primaria e linhas dos campos: `#FF671D`.
- Marca e textos: branco.
- `frontend/assets/branding/folks-white.png`: recorte da marca original, com fundo convertido em transparencia, sem redesenho.
- O quadro Iniciando apresenta a mesma marca branca centralizada sobre o fundo cinza.
- Barras de status e indicador de gestos da referencia pertencem ao sistema operacional; nao sao controles desenhados dentro do Flutter.

## Gitflow

Cada tela ou solicitacao nova parte de `develop` em `feature/<funcionalidade>`.
Se a feature correspondente existir, continuar nela. `main` fica reservada a versoes estaveis.

1. `feature/tela-abertura`: tema, marca compartilhada e tela de abertura.
2. `feature/tela-login`: formulario e transicao da abertura ao login; depende da primeira feature.

As regras permanentes do projeto estao em `AGENTS.md`.
