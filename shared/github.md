---
managed-by: agents-bootstrap
source: shared/github.md
---

## GitHub CLI

Use sempre o GitHub CLI (`gh`) para interações com o GitHub. Nunca acesse
a API diretamente ou construa URLs manualmente.

### Criar issue

```bash
gh issue create --title "título" --body "descrição"
```

### Implementar uma issue

Antes de iniciar a implementação, consulte os detalhes da issue via CLI:

```bash
gh issue view <número>
```

Use o título, a descrição e os comentários da issue para guiar a implementação.

### Criar Pull Request

```bash
gh pr create --title "título" --body "$(cat <<'EOF'
## Resumo
- ...

## Plano de testes
- [ ] ...

EOF
)"
```
