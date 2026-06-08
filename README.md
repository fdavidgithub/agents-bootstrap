# Prompt Repository

Este repositório contém os prompts, instruções e arquivos utilizados pelos agentes de IA.

## Instalação em um Novo Repositório

Para instalar e configurar os prompts em um novo repositório, execute:

```bash
./init.sh
```

O script `init.sh` realiza a configuração inicial necessária, copiando os arquivos e estruturas necessárias para o funcionamento dos agentes.

## Mantendo os Prompts Atualizados

Após a instalação inicial, utilize o comando abaixo sempre que desejar sincronizar as atualizações mais recentes deste repositório:

```bash
./sync.sh
```

O script `sync.sh` atualiza os prompts e demais arquivos gerenciados sem a necessidade de executar novamente a instalação completa.

## Fluxo Recomendado

### Novo Repositório

```bash
git clone <repositorio>
cd <repositorio>

./init.sh
```

### Atualizações Futuras

```bash
./sync.sh
```

## Boas Práticas

* Execute `init.sh` apenas durante a configuração inicial.
* Utilize `sync.sh` regularmente para receber correções e melhorias.
* Revise as alterações sincronizadas antes de realizar commits.
* Siga as diretrizes definidas nos documentos de governança e uso de Git presentes neste repositório.

## Resumo

| Ação                    | Comando          |
| ----------------------- | ---------------- |
| Instalação inicial      | `./init.sh` |
| Atualização dos prompts | `./sync.sh`      |

Sempre utilize `init.sh` para configurar um novo repositório e `sync.sh` para manter os arquivos sincronizados com a versão mais recente.

