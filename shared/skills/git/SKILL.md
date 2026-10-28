---
name: git
description: Use antes de qualquer alteração em um repositório e em toda operação git (branch, commit, push, Pull Request) — define o fluxo obrigatório, a pergunta entre branch e worktree, a convenção de nomes e as regras de segurança.
managed-by: agents-bootstrap
source: shared/skills/git/SKILL.md
---

# git

Define como o agente usa Git: rastreabilidade, segurança, isolamento das
mudanças, facilidade de revisão e trabalho em paralelo de vários agentes no
mesmo repositório.

## Regra obrigatória

**Nenhuma alteração pode ser feita diretamente em `main`, `master` ou
`develop`.** Toda alteração é feita em uma branch própria da tarefa, criada a
partir da `develop`.

**Antes de iniciar qualquer alteração, pergunte ao usuário** (informando a
branch atual, de `git branch --show-current`) se o trabalho deve ser feito em:

1.  **Branch** — criada no diretório principal com `git checkout -b`; ou
2.  **Worktree** — criada com a skill `git-worktree`, isolada em
    `.worktrees/<branch>`.

Não escolha o modo por conta própria: pergunte e siga a resposta. Não edite
nenhum arquivo antes de recebê-la.

É proibido:

-   trabalhar diretamente em `main`, `master`, `develop` ou qualquer branch
    protegida;
-   criar branch/worktree de forma diferente da escolhida pelo usuário (por
    exemplo, `git worktree add` direto em vez da skill `git-worktree`);
-   trocar de branch (`git checkout`, `git switch`) dentro de uma worktree;
-   reutilizar uma branch/worktree antiga para uma nova tarefa;
-   misturar alterações de tarefas diferentes na mesma branch.

## Fluxo

### 1. Criar a branch ou a worktree

#### Opção A — Branch

```bash
git checkout develop
git pull --ff-only
git checkout -b tipo/descricao-curta
```

-   A branch sempre parte da `develop` atualizada.
-   Se houver alterações não commitadas no diretório principal, **não**
    prossiga: reporte ao usuário.
-   Neste modo não há trabalho em paralelo no mesmo diretório; outro agente não
    deve usar o diretório principal ao mesmo tempo.

#### Opção B — Worktree

Use a skill `git-worktree` com o nome da branch (`tipo/descricao-curta`). Ela
cria a worktree em `.worktrees/<branch>` a partir da `develop` atualizada.
Se ela abortar, **não contorne com comandos git manuais**: corrija a causa (ou
reporte ao usuário) e rode de novo.

Em seguida, entre na worktree e trabalhe somente nela:

```bash
cd .worktrees/tipo-descricao-curta
```

Nunca versione links de `.env`/`.env.e2e` nem o diretório `.worktrees/`.

### 2. Realizar alterações

Modifique apenas os arquivos necessários para a tarefa, na branch (ou
worktree) da tarefa.

### 3. Validar

Execute, quando disponíveis: testes automatizados, verificações de qualidade e
build do projeto.

### 4. Commits claros

```bash
git commit -m "feat: adiciona geração de relatório"
git commit -m "fix: corrige validação de e-mail"
git commit -m "docs: atualiza guia de instalação"
```

### 5. Publicar a branch

```bash
git push -u origin nome-da-branch
```

### 6. Pull Request

Toda alteração é revisada por Pull Request, com base na `develop`, antes de ser
incorporada.

## Convenção de nomes de branch

| Tipo     | Exemplo                       |
| -------- | ----------------------------- |
| feat     | feat/nova-funcionalidade      |
| fix      | fix/corrigir-bug              |
| hotfix   | hotfix/correcao-urgente       |
| refactor | refactor/reorganizar-servico  |
| docs     | docs/atualizar-readme         |
| test     | test/adicionar-cobertura      |
| chore    | chore/atualizar-dependencias  |

## Regras de segurança

-   Pergunte se deve usar branch ou worktree antes de iniciar a tarefa.
-   Confirme (`git branch --show-current`) que está fora de `main`, `master` e
    `develop` antes de modificar arquivos.
-   No modo worktree, confirme também (`pwd`) que está dentro de
    `.worktrees/<branch>`.
-   Use uma branch/worktree nova mesmo para alterações pequenas.
-   Nunca leia, imprima, copie ou commite o conteúdo de `.env` / `.env.e2e`.
-   Evite commits com arquivos temporários.
-   Não force push (`--force`) sem autorização explícita.
-   Não reescreva histórico compartilhado.
-   Não exclua branches remotas sem autorização explícita.
-   Não remova worktrees de outros agentes (`git worktree remove`/`prune`) sem
    autorização explícita.

## Checklist antes de finalizar

-   [ ] O usuário foi consultado sobre usar branch ou worktree.
-   [ ] A branch saiu da `develop` atualizada (ou a worktree foi criada pela
        skill `git-worktree`).
-   [ ] No modo worktree, todo o trabalho foi feito em `.worktrees/<branch>`.
-   [ ] Nada foi alterado diretamente em `main`, `master` ou `develop`.
-   [ ] Os testes foram executados.
-   [ ] Os commits têm mensagens claras.
-   [ ] A branch foi enviada ao remoto.
-   [ ] Um Pull Request foi preparado ou aberto.
