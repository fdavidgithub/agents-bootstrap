---
name: herdr-pipeline
description: Use ao implementar uma issue que passa por planejamento — orquestra o pipeline da seção "Distribuição de Papéis entre Modelos" do AGENTS.md: Claude/Opus planeja na worktree, o OpenCode implementa disparado pelo herdr, Claude/Haiku verifica os testes, Claude/Sonnet revisa e corrige, e a PR é atualizada sem merge.
managed-by: agents-bootstrap
source: shared/skills/herdr-pipeline/SKILL.md
---

# herdr-pipeline

Orquestra uma issue de ponta a ponta. O Claude que roda esta skill é o
**orquestrador**: a sessão principal com o modelo Opus. Ele planeja, dispara o
OpenCode pelo herdr, delega verificação, revisão e correções a subagentes com o
modelo de cada etapa e entrega a PR pronta para o usuário decidir o merge.

Esta skill implementa a tabela "Distribuição de Papéis entre Modelos" do
`AGENTS.md`. Se as duas divergirem, vale o `AGENTS.md`.

## Pré-requisitos

-   O CLI do herdr é `~/.local/bin/herdr-core` (`herdr`/`hc` podem não estar no
    PATH). O serviço precisa estar no ar: `herdr-core server status`.
-   O comando `opencode` precisa estar no PATH.
-   O OpenCode precisa poder editar arquivos e rodar comandos sem aprovação
    interativa, porque `opencode run` não tem tela para aprovar. Se a
    configuração do OpenCode tiver um bloco `permission` com `ask`, o executor
    trava ou recusa.
-   Os subagentes de modelo fixo são abertos pela ferramenta de agente do
    Claude, com o parâmetro de modelo (`sonnet`, `haiku`). Não é preciso
    arquivo de agente.

## Etapas

| # | Etapa | Quem | Modelo |
| - | ----- | ---- | ------ |
| 1 | Planejamento: worktree, spec, plano, handoff, PR de docs | orquestrador | Opus |
| 2 | Aprovação do plano | usuário | — |
| 3 | Implementação | OpenCode via herdr | padrão configurado |
| 4 | Conferência da entrega | orquestrador | Opus |
| 5 | Verificação final dos testes | subagente | Haiku |
| 6 | Revisão | subagente | Sonnet |
| 7 | Correções da revisão | subagente | Sonnet |
| 8 | Documentação e versão | subagente | Haiku |
| 9 | Push, atualização da PR e relatório | orquestrador | Opus |

### 1. Planejamento (Opus)

1.  Siga a skill `git`: a pergunta entre branch e worktree vale aqui. Neste
    pipeline o modo é sempre **worktree**, criada pela skill `git-worktree`.
    O executor, os subagentes e o orquestrador usam **a mesma worktree e a
    mesma branch** do começo ao fim.
2.  Leia a issue (`gh issue view <n>`) e escreva spec, plano e handoff na
    worktree, onde o projeto guarda esses documentos.
3.  Commit (sem trailer de sessão), push e abertura da PR com a skill
    `github`. **Quem planeja escreve o trailer:** a última linha do corpo da
    PR é `claude-session: <id-da-sessão-do-orquestrador>`. O handoff informa
    esse ID e diz que ele deve ser mantido.
4.  O handoff termina com uma seção **"Para o executor"**, contendo:
    -   caminho absoluto da worktree, branch e número da PR;
    -   o trailer da PR, que deve ser mantido sem alteração;
    -   as regras do executor (abaixo) e o formato da entrega.

### 2. Aprovação (usuário)

Apresente o plano em linguagem simples e **espere a aprovação explícita**.

-   A aprovação autoriza o orquestrador a seguir as etapas 3 a 9 sem perguntar
    de novo.
-   Sem aprovação, pare depois da etapa 1. Spec, plano e handoff são o
    entregável.
-   O merge nunca faz parte do pipeline: é sempre do usuário.

### 3. Implementação (OpenCode via herdr)

Dispare o OpenCode sem tela interativa, dentro da worktree:

```bash
herdr-core run --bg --name impl-<issue> --cwd <worktree-absoluta> \
  opencode run --title "issue <issue>" "<prompt do executor>"
```

-   `--name` precisa ser único entre os terminais vivos (`herdr-core ls`).
-   Use `--outlive-parent` só se o usuário quiser poder fechar o Claude
    durante a implementação. Sem ele, o OpenCode morre junto com o
    orquestrador.
-   O usuário pode acompanhar com `herdr-core attach impl-<issue>` e sair com
    ctrl+\ sem interromper.

**Prompt do executor** (adapte só os campos entre `< >`):

```text
Você é o executor da issue <issue>. Trabalhe somente em <worktree-absoluta>,
na branch <branch>, que já está checada.

Leia e siga estritamente <caminho-do-handoff>, <caminho-do-spec> e
<caminho-do-plano>. Não implemente nada fora deles. Se algo impedir seguir o
plano, pare e registre na entrega em vez de improvisar.

Regras:
- siga o AGENTS.md e as skills git (commits) e de testes do projeto;
- escreva os testes junto com o código e rode-os durante o trabalho;
- faça commits na branch atual, sem trailer de sessão;
- não faça push, não abra nem edite PR, não troque de branch, não faça merge;
- não altere o trailer da PR (claude-session: <id>): ele pertence a quem planejou.

Ao terminar, imprima exatamente este bloco como sua última saída:

=== ENTREGA OPENCODE ===
Status: concluido | parcial | bloqueado
Commits: <hash curto — mensagem, um por linha>
Testes: <comando exato> -> <resultado: N passaram, M falharam>
Desvios do plano: <nenhum | lista>
Pendências: <nenhuma | lista>
=== FIM ENTREGA ===
```

**Esperar o fim:**

```bash
herdr-core wait impl-<issue> --timeout 600
```

-   `"reason": "exit"` significa que terminou: siga para a etapa 4 com o
    `exit_code`.
-   `"reason": "timeout"` significa que ainda está trabalhando. Leia a tela
    (`herdr-core read impl-<issue> | tail -40`) para checar se não está parado
    numa pergunta, e espere de novo. Se estiver parado numa pergunta ou
    pedindo permissão, **não responda por ele**: relate ao usuário.
-   Não use `sleep`. O próprio `wait` faz a espera.

### 4. Conferência da entrega (orquestrador)

1.  `herdr-core read impl-<issue>` e extraia o bloco entre
    `=== ENTREGA OPENCODE ===` e `=== FIM ENTREGA ===`.
2.  Confira **na fonte**, não só no relato:
    -   `git -C <worktree> branch --show-current` é a branch da tarefa;
    -   `git -C <worktree> status --short` está limpo;
    -   `git -C <worktree> log --oneline develop..HEAD` bate com os commits
        relatados;
    -   nenhum commit caiu em `develop` ou no diretório principal.
3.  Se o bloco estiver ausente, `exit_code` ≠ 0, o status for `parcial` ou
    `bloqueado`, ou se a conferência divergir, **pare e relate ao usuário**
    com a saída. Não corrija a implementação por conta própria.
4.  Limpe o terminal: `herdr-core rm impl-<issue>`.

### 5. Verificação final dos testes (Haiku)

Subagente com modelo `haiku`, na worktree:

-   rode a suíte que `docs/guidelines/testing.md` manda rodar **antes de abrir
    PR**. O comando, o escopo e o que fica de fora (e2e, infra etc.) vêm desse
    documento, não desta skill. Camadas que exigem ambiente real só rodam se o
    plano pedir;
-   se o `testing.md` não definir o comando, pare e relate ao usuário em vez
    de adivinhar;
-   devolva o comando, a contagem e a saída das falhas **sem interpretar nem
    corrigir**.

Falhas novas em relação à `develop` vão para a revisão como achados.

### 6. Revisão (Sonnet)

Subagente com modelo `sonnet`, na worktree. Entregue a ele os caminhos de spec,
plano e handoff, o diff `develop...HEAD` e o resultado da etapa 5. Peça:

-   conformidade com spec, plano e `AGENTS.md`, incluindo arquitetura, testes
    e idioma do código;
-   bugs de correção com cenário concreto de falha;
-   achados ordenados por severidade, com `arquivo:linha`;
-   nenhuma edição: só o relatório.

### 7. Correções (Sonnet)

Se houver achados confirmados, abra um subagente com modelo `sonnet` na mesma
worktree e mesma branch:

-   corrigir cada achado com teste que falha antes e passa depois;
-   commits na branch, sem trailer e sem push;
-   devolver o que foi corrigido, o que não foi e por quê.

Depois repita a etapa 5 (Haiku). Faça no máximo **2 rodadas** de revisão e
correção. Se restar achado grave, pare e relate ao usuário.

### 8. Documentação e versão (Haiku)

Subagente com modelo `haiku`: atualizar o que o plano manda documentar em
`/docs` e aplicar a skill `application-version` antes do último commit.

### 9. Push, PR e relatório (orquestrador)

1.  `git -C <worktree> push`.
2.  Atualize o corpo da PR (`gh pr edit`) com o resumo da implementação e o
    plano de testes executado. **O trailer `claude-session: <id>` de quem
    planejou continua como a última linha, sem alteração.**
3.  Relate ao usuário:
    -   o link da PR;
    -   os commits;
    -   os testes com os números reais;
    -   os achados corrigidos e os pendentes;
    -   os desvios do plano.

    Não declare concluído sem a verificação da etapa 5 ter passado. Não faça
    merge.

## Regras gerais

-   Uma issue, uma worktree, uma branch, uma PR, do planejamento ao fim.
-   O orquestrador não escreve código de produção. A implementação é do
    OpenCode e as correções são do subagente Sonnet.
-   Saídas do OpenCode e dos subagentes são relatos a conferir, não fatos.
    Confira no git e nos testes antes de repassar.
-   Qualquer bloqueio (permissão, falha de teste persistente, desvio do plano
    sem saída): pare e relate. Não improvise uma etapa fora da tabela.
