---
managed-by: agents-bootstrap
source: shared/git.md
---

# Diretrizes de Uso do Git para Agentes de IA

## Objetivo

Estas instruções definem como um agente de IA deve utilizar Git em qualquer repositório.
O objetivo é garantir rastreabilidade, segurança, isolamento de mudanças, facilidade de revisão
e **trabalho em paralelo** de vários agentes no mesmo repositório.

---

## Regra Obrigatória

**Nenhuma alteração pode ser feita diretamente em `main`, `master` ou `develop`.**
Toda alteração deve ser feita em uma branch própria da tarefa, criada a partir da `develop`.

**Antes de iniciar qualquer alteração, o agente deve perguntar ao usuário** se o trabalho deve ser feito em:

1. **Branch** — criada no diretório principal com `git checkout -b`; ou
2. **Worktree** — criada com `agents.sh skill git-worktree`, isolada em `.worktrees/<branch>`.

O agente não escolhe o modo por conta própria: sempre pergunta e segue a resposta do usuário.

É proibido:

- Trabalhar diretamente em `main`, `master`, `develop` ou qualquer branch protegida.
- Criar branch/worktree de forma diferente da escolhida pelo usuário
  (ex.: `git worktree add` direto em vez de `agents.sh skill git-worktree`).
- Trocar de branch (`git checkout`, `git switch`) dentro de uma worktree.
- Reutilizar uma branch/worktree antiga para uma nova tarefa.
- Misturar alterações de tarefas diferentes na mesma branch.

---

## Fluxo Obrigatório

### 1. Criar a branch ou a worktree

Perguntar ao usuário qual modo usar e seguir a opção escolhida.

#### Opção A — Branch (`git checkout -b`)

```bash
git checkout develop
git pull --ff-only
git checkout -b tipo/descricao-curta
```

- A branch deve sempre partir da `develop` atualizada.
- Se houver alterações não commitadas no diretório principal, **não** prossiga: reporte ao usuário.
- Neste modo não há trabalho em paralelo no mesmo diretório; outro agente não deve usar o diretório principal ao mesmo tempo.

#### Opção B — Worktree (`agents.sh skill git-worktree`)

```bash
agents.sh skill git-worktree tipo/descricao-curta
```

O script:

- atualiza a `develop` local (`git pull --ff-only`) e **sempre** cria a worktree a partir dela
  (aborta se a `develop` local não existir ou não puder ser atualizada);
- cria a branch e a worktree em `<repo>/.worktrees/<branch>` (barras da branch viram `-`);
- cria links simbólicos para `.env` e `.env.e2e` quando existirem;
- informa no output a base, a branch, o caminho e os links criados.

Se o script abortar, **não contorne com comandos git manuais**: corrija a causa (ou reporte ao usuário) e rode novamente.

Em seguida, entre na worktree e trabalhe somente nela:

```bash
cd .worktrees/tipo-descricao-curta
```

Nunca versione os links `.env`/`.env.e2e` nem o diretório `.worktrees/`.

### 2. Realizar alterações

Modificar apenas os arquivos necessários para a tarefa, na branch (ou worktree) da tarefa.

### 3. Validar alterações

Executar quando disponível:

- Testes automatizados
- Verificações de qualidade
- Build do projeto quando aplicável

Exemplo:

```bash
npm test
```

ou

```bash
pytest
```

### 4. Criar commits claros

Exemplos:

```bash
git commit -m "feat: adiciona geração de relatório"
```

```bash
git commit -m "fix: corrige validação de e-mail"
```

```bash
git commit -m "docs: atualiza guia de instalação"
```

### 5. Publicar a branch

```bash
git push -u origin nome-da-branch
```

### 6. Abrir Pull Request

Toda alteração deve ser revisada através de Pull Request antes de ser incorporada,
com base na `develop`.

---

## Convenção de Nomes de Branch

Utilizar um dos prefixos abaixo (nome usado no `git checkout -b` ou passado como argumento ao `agents.sh skill git-worktree`):

| Tipo | Exemplo |
|--------|----------|
| feat | feat/nova-funcionalidade |
| fix | fix/corrigir-bug |
| hotfix | hotfix/correcao-urgente |
| refactor | refactor/reorganizar-servico |
| docs | docs/atualizar-readme |
| test | test/adicionar-cobertura |
| chore | chore/atualizar-dependencias |

---

## Regras de Segurança

O agente de IA deve:

- Perguntar ao usuário se deve usar branch ou worktree antes de iniciar a tarefa.
- Confirmar (`git branch --show-current`) que está fora de `main`, `master` e `develop` antes de modificar arquivos.
- No modo worktree, confirmar também (`pwd`) que está dentro de `.worktrees/<branch>`.
- Usar uma branch/worktree nova mesmo para alterações pequenas.
- Nunca ler, imprimir, copiar ou commitar o conteúdo de `.env` / `.env.e2e`.
- Evitar commits contendo arquivos temporários.
- Não forçar push (`--force`) sem autorização explícita.
- Não reescrever histórico compartilhado.
- Não excluir branches remotas sem autorização explícita.
- Não remover worktrees de outros agentes (`git worktree remove`/`prune`) sem autorização explícita.

---

## Checklist Obrigatório

Antes de finalizar qualquer tarefa:

- [ ] O usuário foi consultado sobre usar branch ou worktree.
- [ ] A branch foi criada com `git checkout -b` a partir da `develop` atualizada, ou a worktree com `agents.sh skill git-worktree`.
- [ ] No modo worktree, todo o trabalho foi feito dentro de `.worktrees/<branch>`.
- [ ] Nenhuma alteração foi feita diretamente em `main`, `master` ou `develop`.
- [ ] Os testes foram executados.
- [ ] Os commits possuem mensagens claras.
- [ ] A branch foi enviada para o remoto.
- [ ] Um Pull Request foi preparado ou aberto.
- [ ] A PR segue o `github.md` (incluindo o trailer `<agente>-session: <id>`).

---

## Resumo

> Nenhuma alteração pode ser realizada diretamente em `main`, `master` ou `develop`.
> Toda tarefa começa perguntando ao usuário se deve usar branch (`git checkout -b`) ou worktree (`agents.sh skill git-worktree`),
> é feita na branch/worktree criada a partir da `develop`, e a PR termina com a sessão do agente.
