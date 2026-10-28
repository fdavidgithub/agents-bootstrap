---
name: application-health
description: Use para analisar a saúde da aplicação — acoplamento aferente (Ca) e eferente (Ce) entre arquivos e pastas, fronteiras de módulo, dependências internas e pontos de risco — e escrever o relatório em docs/application/health.md.
managed-by: agents-bootstrap
source: shared/skills/application-health/SKILL.md
---

# application-health

Mede o acoplamento interno do projeto com os scripts em `scripts/` (caminhos
relativos a esta skill) e produz um relatório. Os números vêm dos scripts, não
de impressão.

## Pré-requisitos

-   `bash` e `awk`. Nada precisa ser instalado.
-   `git` é opcional: dentro de um repositório Git só os arquivos versionados e
    não ignorados são analisados; fora dele, todos os arquivos são varridos.

## Uso

Rode sempre **a partir da raiz do projeto a analisar** (os scripts ficam nesta
skill, não no projeto):

```bash
bash scripts/coupling_metrics.sh
```

Para analisar outro diretório sem sair da raiz, use `--dir`.

### `coupling_metrics.sh` (comando principal)

Imprime um resumo, o acoplamento por pasta e o acoplamento por arquivo.

| Opção            | Efeito                                                       |
| ---------------- | ------------------------------------------------------------ |
| `--dir RAIZ`     | Raiz do projeto a analisar (padrão: diretório atual)          |
| `--depth N`      | Profundidade de agregação das pastas (padrão: `2`)            |
| `--top N`        | Máximo de linhas por tabela; `0` mostra todas (padrão: `30`)  |
| `--min N`        | Só exibe entradas com `Ca + Ce >= N` (padrão: `0`)            |
| `--files-only`   | Omite a tabela por pasta                                      |
| `--folders-only` | Omite a tabela por arquivo                                    |
| `--stdin`        | Lê o grafo da entrada padrão em vez de gerá-lo                |

```bash
# visão macro: só as pastas de primeiro nível
bash scripts/coupling_metrics.sh --depth 1 --folders-only

# os 15 arquivos mais acoplados, ignorando os pouco conectados
bash scripts/coupling_metrics.sh --files-only --top 15 --min 3
```

### `coupling_graph.sh` (grafo bruto)

Imprime uma aresta por linha, `origem<TAB>destino`, com caminhos relativos à
raiz. Útil para responder "quem depende deste arquivo?":

```bash
bash scripts/coupling_graph.sh | grep -F 'src/core/db.ts'
```

Aceita `--dir RAIZ` e `--files` (lista os arquivos-fonte analisados, sem
calcular arestas). Os dois scripts se combinam por pipe, para filtrar o grafo
antes de medir:

```bash
bash scripts/coupling_graph.sh \
  | grep -v '/tests\?/' \
  | bash scripts/coupling_metrics.sh --stdin --depth 2
```

## Como ler as métricas

| Métrica | Significado                                                             |
| ------- | ----------------------------------------------------------------------- |
| `Ca`    | **Acoplamento aferente** — quantos outros arquivos dependem deste        |
| `Ce`    | **Acoplamento eferente** — de quantos outros arquivos este depende       |
| `I`     | **Instabilidade** — `I = Ce / (Ca + Ce)`, entre `0` e `1`                |

-   **`I` próximo de `0` (estável)** — muita gente depende e ele depende de
    pouco. Bom para contratos, tipos, utilitários e domínio; mudar é caro,
    pois propaga para todos os dependentes.
-   **`I` próximo de `1` (instável)** — depende de muita coisa e ninguém
    depende dele. Lugar natural de telas, controllers, comandos de CLI e pontos
    de entrada; mudar é barato.
-   **`I` intermediário (equilibrado)** — normal em camadas de serviço.

A coluna `PROFILE` traduz esses valores e marca com `(!)` o caso de risco
`Ca >= 5` com `I >= 0.7`: muitos dependem do arquivo e ele depende de muita
coisa, então qualquer mudança em suas dependências chega a todos os seus
dependentes. `isolated` indica ausência de dependência interna nos dois
sentidos.

### Sinais que merecem atenção

-   Arquivo com `Ca` alto **e** `I` alto → candidato a ser quebrado em partes.
-   Pasta com `Ca` alto e `Ce` alto → fronteira de módulo mal definida.
-   Arquivo com `Ca` muito alto (ordem de dezenas) → ponto único de falha.
-   Muitos arquivos `isolated` que não são pontos de entrada → possível código
    morto.
-   Pasta de domínio com `I` alto → o núcleo depende das bordas; normalmente
    falta inversão de dependência.

### Pasta conta só o que cruza a fronteira

Nas tabelas por pasta, uma dependência entre dois arquivos da **mesma** pasta é
coesão e não entra em `Ca` nem `Ce`. Por isso os totais por pasta são menores
que a soma dos totais por arquivo — é esperado. O nível de agregação vem de
`--depth`: com `--depth 1`, `src/core/db.ts` conta em `src`; com `--depth 2`,
em `src/core`.

## Limitações

A análise é heurística, baseada em texto, não um compilador:

-   **JavaScript, TypeScript, Python, PHP, Ruby e shell** — resolução por
    caminho; a mais precisa. Extensões e arquivos de índice (`index.*`,
    `__init__.py`) são resolvidos automaticamente.
-   **Go e C#** — pacote/namespace é um diretório; quando o alvo resolve para
    um diretório, é criada uma aresta para **cada** arquivo dele, o que infla
    um pouco o `Ca`.
-   **Java e Kotlin** — resolução por namespace; imports estáticos e curingas
    resolvem para o pacote, quando encontrado.
-   **Dependências externas são descartadas** (`react`, `os`, `fmt`, pacotes do
    Composer etc.): a medição é só de acoplamento **interno**.
-   **Aliases de bundler não são lidos de configuração.** `@/` e `~/` valem
    como raiz do projeto e `src`, `app`, `lib` e `source` são tentadas como
    raízes de código, mas `paths` do `tsconfig.json` e aliases de Webpack/Vite
    não são interpretados.
-   **Imports dinâmicos com variável** e **injeção de dependência em tempo de
    execução** (containers, service locators, reflexão) não aparecem no grafo.
-   São ignorados `.git`, `.agents-bootstrap`, `node_modules`, `vendor`,
    `dist`, `build`, `out`, `target`, `coverage`, `__pycache__`, `.venv`,
    `venv`, `bin` e `obj`.

Quando um número contrariar o que se sabe do código, confira a aresta no grafo
bruto antes de concluir; uma limitação acima costuma explicar a diferença.

## Relatório

Escreva o resultado em `docs/application/health.md`, em português brasileiro,
com:

1.  **Data da análise e comando executado**, para reprodução.
2.  **Resumo** — arquivos analisados, com acoplamento, sem acoplamento,
    dependências internas e dependências entre pastas.
3.  **Acoplamento por pasta** — a tabela do script, com leitura em prosa das
    fronteiras de módulo.
4.  **Arquivos mais acoplados** — os de maior `Ca + Ce`, com o motivo de cada
    um estar no topo.
5.  **Pontos de atenção** — cada item ligado ao arquivo ou pasta concreto e ao
    número que o sustenta.
6.  **Recomendações** — ações objetivas (extrair módulo, inverter dependência,
    quebrar arquivo), ordenadas por impacto.

Regras:

-   Use apenas números produzidos pelos scripts. Não estime, não arredonde para
    "cerca de" e não cite arquivos que não apareceram na saída.
-   Se uma conclusão depender de algo que os scripts não medem (por exemplo,
    acoplamento via container de injeção de dependência), diga isso
    explicitamente em vez de inferir.
-   Se `docs/application/health.md` já existir, sobrescreva-o por completo; não
    acumule análises anteriores.
