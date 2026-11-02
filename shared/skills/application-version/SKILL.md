---
name: application-version
description: Use ao concluir qualquer alteração (antes do último commit/Pull Request) e sempre que precisar incrementar ou consultar a versão do projeto — define o Semantic Versioning (MAJOR.MINOR.PATCH), quando subir cada componente e como manter docs/application/version.md.
managed-by: agents-bootstrap
source: shared/skills/application-version/SKILL.md
---

# application-version

Define como o agente controla a versão do projeto. O projeto segue o padrão
Semantic Versioning (`MAJOR.MINOR.PATCH`). A versão atual e o histórico ficam
em `docs/application/version.md` — nunca no `AGENTS.md`, que é compartilhado
entre projetos e sobrescrito a cada sincronização.

## Versão única ou por app

Um projeto pode ter uma versão única ou uma versão por app (quando o repositório
reúne mais de uma aplicação). `docs/application/version.md` declara qual é o
caso: se ele tiver uma tabela de versões por app, cada app tem a sua versão e o
seu histórico, e as regras abaixo valem para cada app separadamente, conforme a
seção "Versão por app" desse arquivo.

## Regras de incremento

-   Todo merge de Pull Request ou commit direto incrementa o `PATCH`. Com versão
    por app, incrementa o `PATCH` de cada app afetado pela alteração; o próprio
    `docs/application/version.md` define quais caminhos afetam cada app e quais
    alterações não sobem versão nenhuma.
-   `MINOR` é incrementado quando há nova funcionalidade compatível com versões
    anteriores; zera o `PATCH`.
-   `MAJOR` é incrementado quando há mudança incompatível com versões
    anteriores; zera `MINOR` e `PATCH`.
-   Cada alteração incrementa apenas um componente (por app, com versão por
    app): se couber `MINOR` ou `MAJOR`, ele substitui o incremento do `PATCH`.

## Fluxo

1.  Leia `docs/application/version.md` e identifique se a versão é única ou por
    app e quais apps a alteração afeta.
2.  Decida o componente a incrementar (`PATCH`, `MINOR` ou `MAJOR`).
3.  Atualize a versão em `docs/application/version.md` como parte da própria
    alteração: no último commit da branch antes de abrir o Pull Request, ou no
    próprio commit quando for um commit direto. Assim o merge já leva a nova
    versão.
4.  Ao incrementar `MINOR` ou `MAJOR`, registre a nova versão, a data e a
    justificativa no histórico de `docs/application/version.md` (no histórico
    do app correspondente, com versão por app). `PATCH` não é registrado no
    histórico.

### Arquivo ausente

Se `docs/application/version.md` não existir, crie-o a partir do template do
agents-bootstrap com a versão `0.0.1`, que já corresponde à alteração atual (não
aplicar outro incremento sobre ela). Não reprocesse o histórico do repositório
para deduzir uma versão: a contagem começa a partir da criação do arquivo.

## O que o agente NÃO faz

-   Criar tags git, releases ou publicar a versão em qualquer outro lugar.
    `docs/application/version.md` é apenas o registro da versão; criar a tag ou
    a release correspondente é uma operação manual, sempre feita pelo usuário.
-   Alterar a versão em outros arquivos do projeto (ex.: `package.json`,
    `pyproject.toml`) sem pedido explícito do usuário.

## Checklist antes de finalizar

-   [ ] `docs/application/version.md` foi lido (versão única ou por app).
-   [ ] Exatamente um componente foi incrementado (por app afetado).
-   [ ] `MINOR`/`MAJOR` foram registrados no histórico com data e justificativa.
-   [ ] O incremento está no último commit da branch (ou no commit direto).
-   [ ] Nenhuma tag, release ou outro arquivo de versão foi alterado.
