# Custo estimado da sessão

**Sessão:** `b4d031ba-11a2-4469-ac9b-e75451f82dcb`
**Modelo detectado:** `claude-sonnet-5` (Claude Sonnet 5)
**Data:** 2026-08-17
**Gerado por:** `session_cost.sh` (deduplicado por `message.id`)

> ⚠️ Estimativa calculada a partir dos tokens registrados no arquivo de transcript local (`~/.claude/projects/-tmp-teste/...jsonl`) e da tabela de preços oficial da Anthropic. **Não é o valor exato do `/cost`** — para o número oficial, rode `/cost` na conversa. Assume cache write com TTL de 5 min (padrão do Claude Code).

## Tokens consumidos (deduplicados por mensagem)

| Modelo | Mensagens únicas | Input | Output | Cache write | Cache read |
|---|---:|---:|---:|---:|---:|
| claude-sonnet-5 | 26 | 52 | 17.585 | 384.595 | 6.757.036 |
| **TOTAL** | **26** | **52** | **17.585** | **384.595** | **6.757.036** |

## Preços aplicados (Claude Sonnet 5, tabela promocional até 2026-08-31)

| Item | Preço / 1M tokens |
|---|---:|
| Input | $2,00 |
| Output | $10,00 |
| Cache write (5 min, 1,25×) | $2,50 |
| Cache read (0,1×) | $0,20 |

*(Após 31/08/2026 os preços normais são $3,00 input / $15,00 output — cache escala na mesma proporção.)*

## Custo estimado

| Item | Cálculo | Custo (USD) |
|---|---|---:|
| Input | 52 × $2,00/1M | $0,0001 |
| Output | 17.585 × $10,00/1M | $0,1759 |
| Cache write | 384.595 × $2,50/1M | $0,9615 |
| Cache read | 6.757.036 × $0,20/1M | $1,3514 |
| **Total** | | **≈ $2,49** |

## Nota sobre a correção aplicada

Uma versão anterior deste script somava o campo `usage` de **toda linha** do `.jsonl`, mas cada resposta da API com múltiplos blocos de conteúdo (ex: `thinking` + `tool_use`) é gravada em várias linhas repetindo o mesmo `usage`. Isso inflava a contagem em ~40-60%. A versão atual deduplica por `message.id` antes de somar, e também identifica o(s) modelo(s) usado(s) na sessão.

## Script usado

```bash
#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?Uso: $0 /caminho/para/sessao.jsonl}"

awk '
  {
    id = ""
    if (match($0, /"id":"msg_[A-Za-z0-9]+"/)) {
      id = substr($0, RSTART, RLENGTH)
    }
    if (id == "" || (id in seen) || $0 !~ /"usage":\{/) next
    seen[id] = 1

    model = "desconhecido"
    if (match($0, /"model":"[^"]+"/)) {
      m = substr($0, RSTART, RLENGTH)
      split(m, mp, "\""); model = mp[4]
    }

    in_t = 0; out_t = 0; cc_t = 0; cr_t = 0
    if (match($0, /"input_tokens":[0-9]+/)) {
      split(substr($0, RSTART, RLENGTH), a, ":"); in_t = a[2]
    }
    if (match($0, /"output_tokens":[0-9]+/)) {
      split(substr($0, RSTART, RLENGTH), a, ":"); out_t = a[2]
    }
    if (match($0, /"cache_creation_input_tokens":[0-9]+/)) {
      split(substr($0, RSTART, RLENGTH), a, ":"); cc_t = a[2]
    }
    if (match($0, /"cache_read_input_tokens":[0-9]+/)) {
      split(substr($0, RSTART, RLENGTH), a, ":"); cr_t = a[2]
    }

    sum_in[model]  += in_t
    sum_out[model] += out_t
    sum_cc[model]  += cc_t
    sum_cr[model]  += cr_t
    msgs[model]++

    total_in  += in_t
    total_out += out_t
    total_cc  += cc_t
    total_cr  += cr_t
    total_msgs++

    models[model] = 1
  }
  END {
    for (m in models) {
      printf "model=%s\n", m
      printf "  mensagens_unicas=%d\n", msgs[m]
      printf "  input=%d\n", sum_in[m]
      printf "  output=%d\n", sum_out[m]
      printf "  cache_creation=%d\n", sum_cc[m]
      printf "  cache_read=%d\n", sum_cr[m]
    }
    printf "TOTAL\n"
    printf "  mensagens_unicas=%d\n", total_msgs
    printf "  input=%d\n", total_in
    printf "  output=%d\n", total_out
    printf "  cache_creation=%d\n", total_cc
    printf "  cache_read=%d\n", total_cr
  }
' "$FILE"
```

Uso: `./session_cost.sh /caminho/para/sessao.jsonl`
