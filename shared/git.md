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

**Toda alteração deve ser realizada em uma worktree isolada, criada exclusivamente com `scripts/git-worktree.sh`.**

É proibido:

- Trabalhar diretamente em `main`, `master`, `develop` ou qualquer branch protegida.
- Trabalhar no diretório principal do repositório (a raiz); todo o trabalho acontece em `.worktree/<branch>`.
- **Criar branch por conta própria** (`git branch`, `git checkout -b`, `git switch -c`, `git worktree add` direto etc.).
  Trocar de branch no diretório principal impede o trabalho em paralelo. A única forma permitida de
  criar uma branch é o `git-worktree.sh`, que cria branch e worktree juntas.
- Trocar de branch (`git checkout`, `git switch`) dentro de uma worktree.
- Reutilizar uma branch/worktree antiga para uma nova tarefa.
- Misturar alterações de tarefas diferentes na mesma branch.

---

## Fluxo Obrigatório

### 1. Criar a worktree

```bash
scripts/git-worktree.sh tipo/descricao-curta
```

O script:

- atualiza a `develop` local (`git pull --ff-only`) e **sempre** cria a worktree a partir dela
  (aborta se a `develop` local não existir ou não puder ser atualizada);
- cria a branch e a worktree em `<repo>/.worktree/<branch>` (barras da branch viram `-`);
- cria links simbólicos para `.env` e `.env.e2e` quando existirem;
- informa no output a base, a branch, o caminho e os links criados.

Se o script abortar, **não contorne com comandos git manuais**: corrija a causa (ou reporte ao usuário) e rode novamente.

Em seguida, entre na worktree e trabalhe somente nela:

```bash
cd .worktree/tipo-descricao-curta
```

Nunca versione os links `.env`/`.env.e2e` nem o diretório `.worktree/`.

### 2. Realizar alterações

Modificar apenas os arquivos necessários para a tarefa, dentro da worktree.

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

Utilizar um dos prefixos abaixo (nome passado como argumento ao `git-worktree.sh`):

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

- Confirmar (`pwd` e `git branch --show-current`) que está dentro de `.worktree/<branch>` antes de modificar arquivos.
- Verificar se está fora de `main`, `master` e `develop`.
- Usar uma worktree nova mesmo para alterações pequenas.
- Nunca ler, imprimir, copiar ou commitar o conteúdo de `.env` / `.env.e2e`.
- Evitar commits contendo arquivos temporários.
- Não forçar push (`--force`) sem autorização explícita.
- Não reescrever histórico compartilhado.
- Não excluir branches remotas sem autorização explícita.
- Não remover worktrees de outros agentes (`git worktree remove`/`prune`) sem autorização explícita.

---

## Checklist Obrigatório

Antes de finalizar qualquer tarefa:

- [ ] A worktree foi criada com `scripts/git-worktree.sh` (nenhuma branch criada manualmente).
- [ ] Todo o trabalho foi feito dentro de `.worktree/<branch>`.
- [ ] Nenhuma alteração foi feita diretamente em `main`, `master` ou `develop`.
- [ ] Os testes foram executados.
- [ ] Os commits possuem mensagens claras.
- [ ] A branch foi enviada para o remoto.
- [ ] Um Pull Request foi preparado ou aberto.
- [ ] A PR segue o `github.md` (incluindo o trailer `<agente>-session: <id>`).

---

## Resumo

> Nenhuma alteração pode ser realizada na branch principal nem no diretório principal do repositório.
> Toda tarefa começa com `scripts/git-worktree.sh`, é feita na worktree criada por ele, e a PR termina com a sessão do agente.
> O agente nunca cria branches por conta própria.
