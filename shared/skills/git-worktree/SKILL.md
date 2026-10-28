---
name: git-worktree
description: Use para criar uma worktree git isolada, baseada na develop atualizada, com links para .env e node_modules do repositório principal.
managed-by: agents-bootstrap
source: shared/skills/git-worktree/SKILL.md
---

# git-worktree

Cria uma worktree isolada para uma nova branch com o script
`scripts/git-worktree.sh` (caminho relativo a esta skill).

## Uso

```bash
scripts/git-worktree.sh <nome-da-branch>
```

Rode de dentro do repositório; vale também de dentro de outra worktree.
Depois de criada, trabalhe dentro do caminho informado no resumo final
(`.worktrees/<branch>`).

## O que o script faz

-   Cria a worktree em `<repo>/.worktrees/<branch>`, sempre com base na
    branch local `develop`. As barras do nome da branch viram `-` no nome do
    diretório (`feat/x` → `.worktrees/feat-x`).
-   Atualiza a `develop` antes, com `git pull --ff-only` (na worktree em que
    ela estiver checada) ou `git fetch origin develop:develop`. Nunca cria
    merge nem reescreve a `develop`.
-   Se `.worktrees/` não estiver ignorado, adiciona-o a `.git/info/exclude`
    (local) e avisa.
-   Cria links simbólicos para `.env`, `.env.e2e` e `node_modules`
    encontrados em qualquer subdiretório do repositório principal, no mesmo
    caminho relativo dentro da worktree. Os nomes ficam na lista `LINK_FILES`
    do script.
-   Ao final, imprime um resumo: base, branch, caminho e links criados.

## Quando o script aborta (nada é criado)

-   nome de branch inválido: vazio, começando com `-`, com caracteres fora de
    `A-Za-z0-9._/-`, com `..`, rejeitado por `git check-ref-format` ou igual
    a `develop`;
-   a branch já existe ou o caminho da worktree já existe;
-   a branch local `develop` não existe;
-   o `git pull`/`fetch` da `develop` falha;
-   `.worktrees` é um link simbólico;
-   algum item de `LINK_FILES` é link simbólico, resolve para fora do repo,
    não é arquivo/diretório legível, está versionado (tracked) ou não está no
    `.gitignore`. Nesse último caso, adicione-o ao `.gitignore` e rode de
    novo.

Itens de `LINK_FILES` legíveis por outros usuários geram apenas um aviso
(considere `chmod 600`).
