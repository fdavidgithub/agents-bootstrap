---
managed-by: agents-bootstrap
source: shared/application_health.md
---

# Saúde da Aplicação — Acoplamento Aferente e Eferente

Este documento descreve como medir o acoplamento entre arquivos e pastas do
projeto e o que fazer com o resultado.

---

## Objetivo

Identificar, com números e não por impressão:

- quais arquivos e pastas concentram dependências (mudá-los quebra muita coisa);
- quais dependem de tudo e não são reaproveitados;
- quais fronteiras de módulo estão sendo atravessadas com frequência.

---

## Pré-requisitos

- `bash` e `awk` (presentes em qualquer ambiente POSIX);
- `git` é opcional — quando o projeto é um repositório Git, apenas os arquivos
  versionados e os não ignorados são analisados; fora de um repositório, todos
  os arquivos são varridos.

Nenhuma dependência precisa ser instalada.

---

## Como usar

### Passo 1 — localizar os scripts

Os scripts vivem no repositório `agents-bootstrap`, não dentro do projeto. O
caminho desse repositório é o mesmo que o `agents.sh` usa, gravado em
`~/.config/agent-bootstrap/repo_path`:

```bash
BOOTSTRAP="$(cat ~/.config/agent-bootstrap/repo_path)"
ls "$BOOTSTRAP/scripts/"
# coupling_graph.sh  coupling_metrics.sh  ...
```

Se o arquivo não existir, rode `agents.sh conf` para apontar o caminho do
repositório. Os comandos a seguir assumem `BOOTSTRAP` definido como acima.

Como os scripts não são copiados para dentro do projeto, todos os projetos da
máquina executam o mesmo arquivo, e `agents.sh sync` não tem efeito sobre eles.
Para usar uma versão mais recente, atualize o clone do `agents-bootstrap`:

```bash
git -C "$BOOTSTRAP" pull
```

### Passo 2 — rodar a análise

Sempre **a partir da raiz do projeto**:

```bash
bash "$BOOTSTRAP/scripts/coupling_metrics.sh"
```

Para analisar outro diretório sem sair da raiz, use `--dir`:

```bash
bash "$BOOTSTRAP/scripts/coupling_metrics.sh" --dir ./packages/api
```

### Passo 3 — pedir o relatório ao agente

Basta pedir *"analise a saúde da aplicação"*. O `AGENTS.md` do projeto
direciona o agente para este arquivo, que traz os comandos, a interpretação dos
números e o formato do relatório a escrever em `docs/application/health.md`.

---

## Scripts a executar

Referência completa dos dois scripts e de suas opções.

### 1. Relatório de acoplamento (comando principal)

```bash
bash "$BOOTSTRAP/scripts/coupling_metrics.sh"
```

Imprime três blocos: um resumo, o acoplamento por pasta e o acoplamento por
arquivo.

Opções:

| Opção            | Efeito                                                       |
| ---------------- | ------------------------------------------------------------ |
| `--dir RAIZ`     | Raiz do projeto a analisar (padrão: diretório atual)          |
| `--depth N`      | Profundidade de agregação das pastas (padrão: `2`)            |
| `--top N`        | Máximo de linhas por tabela; `0` mostra todas (padrão: `30`)  |
| `--min N`        | Só exibe entradas com `Ca + Ce >= N` (padrão: `0`)            |
| `--files-only`   | Omite a tabela por pasta                                      |
| `--folders-only` | Omite a tabela por arquivo                                    |
| `--stdin`        | Lê o grafo da entrada padrão em vez de gerá-lo                |

Exemplos:

```bash
# visão macro: só as pastas de primeiro nível
bash "$BOOTSTRAP/scripts/coupling_metrics.sh" --depth 1 --folders-only

# os 15 arquivos mais acoplados, ignorando os pouco conectados
bash "$BOOTSTRAP/scripts/coupling_metrics.sh" --files-only --top 15 --min 3
```

### 2. Grafo bruto de dependências (para inspeção pontual)

```bash
bash "$BOOTSTRAP/scripts/coupling_graph.sh"
```

Imprime uma aresta por linha, no formato `origem<TAB>destino`, com caminhos
relativos à raiz. Útil para responder "quem exatamente depende deste arquivo?":

```bash
bash "$BOOTSTRAP/scripts/coupling_graph.sh" | grep -F 'src/core/db.ts'
```

Também aceita `--dir RAIZ` e `--files` (lista os arquivos-fonte analisados, sem
calcular arestas).

Os dois scripts se combinam por pipe, o que permite filtrar o grafo antes de
medir:

```bash
bash "$BOOTSTRAP/scripts/coupling_graph.sh" \
  | grep -v '/tests\?/' \
  | bash "$BOOTSTRAP/scripts/coupling_metrics.sh" --stdin --depth 2
```

---

## Como ler as métricas

Para cada arquivo e cada pasta o relatório traz três números:

| Métrica | Significado                                                             |
| ------- | ----------------------------------------------------------------------- |
| `Ca`    | **Acoplamento aferente** — quantos outros arquivos dependem deste        |
| `Ce`    | **Acoplamento eferente** — de quantos outros arquivos este depende       |
| `I`     | **Instabilidade** — `I = Ce / (Ca + Ce)`, entre `0` e `1`                |

Interpretação de `I`:

- **`I` próximo de `0` (estável)** — muita gente depende dele e ele depende de
  pouco. É bom para contratos, tipos, utilitários e domínio. Mudanças aqui são
  caras: propagam para todos os dependentes.
- **`I` próximo de `1` (instável)** — depende de muita coisa e ninguém depende
  dele. É o lugar natural de telas, controllers, comandos de CLI e pontos de
  entrada. Mudar é barato.
- **`I` intermediário (equilibrado)** — normal em camadas de serviço.

### Exemplo de saída

Saída de um projeto de exemplo, com as tabelas encurtadas para caber aqui:

```
SUMMARY
  source files analysed      19
  files with coupling        18
  files with no coupling     1
  internal dependencies      12
  folders (depth 2)          13
  cross-folder dependencies  7

FOLDER COUPLING (depth 2, boundary-crossing edges only)
  FOLDER      Ca    Ce       I  PROFILE
  --------------------------------------
  src/util     2     0    0.00  stable
  src/core     1     1    0.50  balanced
  src          0     2    1.00  unstable

FILE COUPLING (top 30)
  FILE               Ca    Ce       I  PROFILE
  ---------------------------------------------
  src/core/db.ts      2     1    0.33  balanced
  src/util/log.ts     2     0    0.00  stable
  src/app.ts          0     2    1.00  unstable
```

Lendo linha a linha:

- `src/util/log.ts` — dois arquivos dependem dele e ele não depende de ninguém
  (`I = 0.00`). É uma base estável: bom lugar para código compartilhado, mas
  mudanças aqui atingem todos os dependentes.
- `src/core/db.ts` — dois dependem dele e ele depende de um (`I = 0.33`).
  Comportamento normal de uma camada intermediária.
- `src/app.ts` — ninguém depende dele e ele depende de dois (`I = 1.00`). É um
  ponto de entrada; mudar é barato e não propaga.
- A pasta `src` tem `Ce = 2` porque `src/app.ts` alcança `src/core` e
  `src/util`; a dependência `src/core/index.ts → src/core/db.ts` não conta,
  porque não cruza fronteira de pasta.

A coluna `PROFILE` traduz esses valores e marca com `(!)` os casos de risco:
`Ca >= 5` combinado com `I >= 0.7`, ou seja, um arquivo do qual muitos dependem
e que, ao mesmo tempo, depende de muita coisa — qualquer alteração em suas
dependências chega a todos os seus dependentes. `isolated` indica um arquivo ou
pasta sem nenhuma dependência interna nos dois sentidos.

### Sinais que merecem atenção

- Arquivo com `Ca` alto **e** `I` alto → candidato a ser quebrado em partes.
- Pasta com `Ca` alto e `Ce` alto → fronteira de módulo mal definida; a pasta
  atua ao mesmo tempo como base e como consumidora.
- Arquivo com `Ca` muito alto (ordem de dezenas) → ponto único de falha; toda
  mudança exige regressão ampla.
- Muitos arquivos `isolated` que não são pontos de entrada → possível código
  morto.
- Pasta de domínio com `I` alto → o núcleo do sistema está dependendo das
  bordas; normalmente indica inversão de dependência ausente.

### Acoplamento de pasta conta apenas o que cruza a fronteira

Nas tabelas por pasta, uma dependência entre dois arquivos da **mesma** pasta é
coesão, não acoplamento, e por isso não entra em `Ca` nem `Ce`. Só as arestas
que atravessam a fronteira da pasta são contadas. Isso significa que os totais
por pasta são menores que a soma dos totais por arquivo — é esperado.

O nível de agregação vem de `--depth`. Com `--depth 1`, `src/core/db.ts` é
contabilizado em `src`; com `--depth 2`, em `src/core`.

---

## Limitações

A análise é uma heurística baseada em texto, não um compilador. Vale conhecer o
alcance de cada linguagem antes de tirar conclusões:

- **JavaScript, TypeScript, Python, PHP, Ruby e shell** — resolução por
  caminho; é a parte mais precisa. Extensões e arquivos de índice
  (`index.*`, `__init__.py`) são resolvidos automaticamente.
- **Go e C#** — um pacote/namespace é um diretório, não um arquivo. Quando o
  alvo resolve para um diretório, é criada uma aresta para **cada** arquivo
  daquele diretório. O `Ca` desses arquivos fica, portanto, um pouco inflado.
- **Java e Kotlin** — resolução por namespace; imports estáticos e curingas
  (`import a.b.*`) resolvem para o pacote, quando encontrado.
- **Dependências externas são descartadas.** O que não resolve para um arquivo
  do projeto (`react`, `os`, `fmt`, pacotes do Composer etc.) fica fora do
  grafo: a medição é de acoplamento **interno**.
- **Aliases de bundler não são lidos de configuração.** `@/` e `~/` são tratados
  como raiz do projeto e as pastas `src`, `app`, `lib` e `source` são tentadas
  como raízes de código, mas `paths` de `tsconfig.json` ou aliases de
  Webpack/Vite não são interpretados.
- **Imports dinâmicos com variável** (`require(caminhoVariavel)`) não resolvem.
- **Injeção de dependência em tempo de execução** (containers, service
  locators, reflexão) não aparece no grafo.
- Diretórios `.git`, `.agents-bootstrap`, `node_modules`, `vendor`, `dist`,
  `build`, `out`, `target`, `coverage`, `__pycache__`, `.venv`, `venv`, `bin` e
  `obj` são ignorados — os próprios scripts de análise não entram na medição.

Quando um número contrariar o que se sabe do código, verifique a aresta no grafo
bruto antes de concluir. Uma limitação acima costuma explicar a diferença.

---

## O que produzir

Depois de executar os scripts, escreva o resultado em
`docs/application/health.md`, em português brasileiro, contendo:

1. **Data da análise e comando executado** — para que o relatório possa ser
   reproduzido.
2. **Resumo** — arquivos analisados, arquivos com acoplamento, arquivos sem
   acoplamento, dependências internas e dependências entre pastas.
3. **Acoplamento por pasta** — a tabela do script, com uma leitura em prosa das
   fronteiras de módulo.
4. **Arquivos mais acoplados** — os de maior `Ca + Ce`, com o motivo de cada um
   aparecer no topo.
5. **Pontos de atenção** — cada item ligado ao arquivo ou pasta concreto e ao
   número que o sustenta.
6. **Recomendações** — ações objetivas (extrair módulo, inverter dependência,
   quebrar arquivo), ordenadas por impacto.

Regras para o relatório:

- Use apenas números produzidos pelos scripts. Não estime, não arredonde para
  "cerca de" e não invente arquivos que não apareceram na saída.
- Se uma conclusão depender de algo que os scripts não medem (por exemplo,
  acoplamento via container de injeção de dependência), diga isso
  explicitamente em vez de inferir.
- Relacione os achados com `docs/guidelines/architecture.md`. Quando o
  acoplamento medido contrariar a arquitetura documentada, aponte o conflito;
  não altere a arquitetura por conta própria.
- Se `docs/application/health.md` já existir, sobrescreva-o por completo com o
  novo relatório — não acumule análises anteriores.
