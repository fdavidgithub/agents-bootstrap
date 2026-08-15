# agents-bootstrap

Repositório de prompts, instruções e templates utilizados por agentes de IA. Distribui arquivos compartilhados e de configuração para outros repositórios Git via o comando `agents.sh`.

## O que é instalado

Ao inicializar um repositório com este bootstrap, são criados:

- `.agents-bootstrap/` — arquivos gerenciados (não versionados): `AGENTS.md`, `git.md`, `github.md`
- `AGENTS.md` — symlink para `.agents-bootstrap/AGENTS.md` (não versionado)
- Pastas ocultas de configuração (ex.: `.opencode/`), copiadas de `config/<tool>/` — não versionadas
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

As pastas de config (`config/<tool>/`) são copiadas para a raiz como pasta oculta (`.<tool>/`). Se o destino já existir e houver terminal, o sync pergunta antes de sobrescrever (`O` sobrescrever / `S` pular / `A` abortar). Em execuções não interativas (ex.: hook `post-merge`), pastas existentes são sobrescritas sem perguntar.

### Verificar configuração atual

```bash
agents.sh conf
```

Exibe o repositório configurado e permite alterar o caminho.

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
