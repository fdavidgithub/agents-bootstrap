# agents-bootstrap

Repositório de prompts, instruções e templates utilizados por agentes de IA. Distribui arquivos compartilhados e de configuração para outros repositórios Git via o comando `agents.sh`.

## O que é instalado

Ao inicializar um repositório com este bootstrap, são criados:

- `.agents-bootstrap/` — arquivos gerenciados (não versionados): `AGENTS.md`, `git.md`, `github.md`, `application_health.md`
- `AGENTS.md` — symlink para `.agents-bootstrap/AGENTS.md` (não versionado)
- Pastas ocultas de configuração (ex.: `.claude/`), copiadas de `config/<tool>/` — não versionadas
- `opencode.json` — copiado de `config/opencode/` para a **raiz** do projeto (não em `.opencode/`), pois é onde o opencode lê a config do projeto — não versionado
- `docs/guidelines/` — templates de documentação do projeto (versionados)
- Hook `post-merge` — executa `agents.sh sync` automaticamente após `git pull`

## Instalação do comando `agents.sh`

Torne o script executável e disponível no PATH:

```bash
chmod +x /caminho/para/agents-bootstrap/agents.sh
ln -s /caminho/para/agents-bootstrap/agents.sh ~/.local/bin/agents.sh
```

## Configuração

Antes de usar, aponte o `agents.sh` para o diretório deste repositório:

```bash
agents.sh conf
```

O comando solicita o caminho absoluto do repositório `agents-bootstrap` e salva em `~/.config/agent-bootstrap/repo_path`.

## Uso

### Inicializar um novo repositório

Execute dentro do repositório Git que deseja configurar:

```bash
agents.sh init
```

Isso adiciona o remote `agents-bootstrap`, copia os arquivos compartilhados, cria o symlink `AGENTS.md` e instala o hook `post-merge`.

### Sincronizar atualizações

Para trazer as versões mais recentes dos arquivos compartilhados:

```bash
agents.sh sync
```

Os arquivos em `docs/guidelines/` só são copiados se ainda não existirem (não sobrescreve personalizações).

As pastas de config (`config/<tool>/`) são copiadas para a raiz como pasta oculta (`.<tool>/`) — com a exceção de `config/opencode/`, cujos arquivos vão direto para a raiz do projeto (ex.: `opencode.json`), pois é ali que o opencode espera encontrar a config do projeto. Se o destino já existir e houver terminal, o sync pergunta antes de sobrescrever (`O` sobrescrever / `S` pular / `A` abortar). Em execuções não interativas (ex.: hook `post-merge`), pastas/arquivos existentes são sobrescritos sem perguntar.

### Verificar configuração atual

```bash
agents.sh conf
```

Exibe o repositório configurado e permite alterar o caminho.

## Saúde da aplicação (acoplamento)

Este repositório traz scripts que medem o acoplamento aferente (`Ca`) e eferente
(`Ce`) dos arquivos e pastas de um projeto, sem nenhuma dependência além de
`bash` e `awk`. Eles não são copiados para dentro do projeto: rodam a partir
daqui, sobre o diretório atual. A partir da raiz do projeto a analisar:

```bash
BOOTSTRAP="$(cat ~/.config/agent-bootstrap/repo_path)"
bash "$BOOTSTRAP/scripts/coupling_metrics.sh"
```

O grafo bruto de dependências, uma aresta por linha, sai de:

```bash
bash "$BOOTSTRAP/scripts/coupling_graph.sh"
```

As instruções completas — opções, como ler `Ca`, `Ce` e a instabilidade
`I = Ce / (Ca + Ce)`, limitações por linguagem e o relatório a produzir em
`docs/application/health.md` — estão em `shared/application_health.md`, que é
distribuído como `.agents-bootstrap/application_health.md` nos projetos.

## Estrutura do repositório

| Pasta            | Papel                                                                        |
| ---------------- | ---------------------------------------------------------------------------- |
| `shared/`        | Arquivos distribuídos para `.agents-bootstrap/` nos projetos inicializados    |
| `scripts/`       | Scripts executados a partir deste repositório, não distribuídos               |
| `config/`        | Configurações por ferramenta, copiadas para a raiz do projeto                 |
| `templates/`     | Templates de `docs/`, copiados apenas se ainda não existirem                  |

## Fluxo recomendado

### Novo repositório

```bash
# 1. Configurar (uma única vez por máquina)
agents.sh conf

# 2. Inicializar o repositório alvo
cd /caminho/do/seu/projeto
agents.sh init
```

### Atualizações futuras

```bash
agents.sh sync
```

Após `git pull` em repositórios inicializados, o sync ocorre automaticamente via hook.

## Resumo dos comandos

| Comando          | Ação                                           |
| ---------------- | ---------------------------------------------- |
| `agents.sh conf` | Configura (ou exibe) o caminho do repositório  |
| `agents.sh init` | Inicializa um repositório Git com o bootstrap  |
| `agents.sh sync` | Sincroniza os arquivos compartilhados          |
