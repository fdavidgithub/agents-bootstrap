---
managed-by: agents-bootstrap
source: shared/git.md
---

# Diretrizes de Uso do Git para Agentes de IA

## Objetivo

Estas instruções definem como um agente de IA deve utilizar Git em qualquer repositório. 
O objetivo é garantir rastreabilidade, segurança, isolamento de mudanças e facilidade de revisão.

---

## Regra Obrigatória

**Toda alteração deve ser realizada em uma nova branch.**

É proibido:

- Trabalhar diretamente em `main`, `master`, `develop` ou qualquer branch protegida.
- Reutilizar uma branch antiga para uma nova tarefa.
- Misturar alterações de tarefas diferentes na mesma branch.

Para cada solicitação, correção, melhoria ou experimento:

1. Atualizar as referências remotas.
2. Criar uma nova branch.
3. Realizar as alterações nessa branch.
4. Registrar commits descritivos.
5. Abrir um Pull Request (ou equivalente) para revisão.

---

## Fluxo Obrigatório

### 1. Atualizar o repositório

```bash
git fetch --all --prune
```

### 2. Branch base

develop

### 3. Criar uma nova branch

Formato recomendado:

```text
tipo/descricao-curta
```

Exemplos:

```bash
git checkout develop
git pull origin develop

git checkout -b feat/adicionar-relatorio
```

```bash
git checkout -b fix/corrigir-validacao
```

```bash
git checkout -b docs/atualizar-instrucoes
```

### 4. Realizar alterações

Modificar apenas os arquivos necessários para a tarefa.

### 5. Validar alterações

Executar quando disponivel:

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

### 6. Criar commits claros

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

### 7. Publicar a branch

```bash
git push -u origin nome-da-branch
```

### 8. Abrir Pull Request

Toda alteração deve ser revisada através de Pull Request antes de ser incorporada à branch principal.

---

## Convenção de Nomes de Branch

Utilizar um dos prefixos abaixo:

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

- Confirmar a branch atual antes de modificar arquivos.
- Verificar se está fora de `main` e `master`.
- Criar uma nova branch mesmo para alterações pequenas.
- Evitar commits contendo arquivos temporários.
- Não forçar push (`--force`) sem autorização explícita.
- Não reescrever histórico compartilhado.
- Não excluir branches remotas sem autorização explícita.

---

## Checklist Obrigatório

Antes de finalizar qualquer tarefa:

- [ ] Foi criada uma nova branch.
- [ ] Nenhuma alteração foi feita diretamente em `main`, `master` ou `develop`.
- [ ] Os testes foram executados.
- [ ] Os commits possuem mensagens claras.
- [ ] A branch foi enviada para o remoto.
- [ ] Um Pull Request foi preparado ou aberto.

---

## Resumo

A regra principal é simples:

> Nenhuma alteração pode ser realizada diretamente na branch principal. Toda tarefa, independentemente do tamanho, deve começar com a criação de uma nova branch exclusiva.

