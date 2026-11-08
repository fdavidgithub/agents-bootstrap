---
managed-by: agents-bootstrap
source: shared/AGENTS.md
---

# Agentes de IA — Instruções do Projeto

## Papel

Você está modificando código neste repositório.
Todas as alterações devem seguir a arquitetura, os padrões de código e a stack
definidos na documentação.

Antes de escrever ou modificar código, consulte a documentação em `/docs`.

------------------------------------------------------------------------

## Documentação Fonte de Verdade

A pasta `/docs` contém a documentação oficial do projeto.

Consulte os seguintes documentos quando relevante:

-   docs/guidelines/architecture.md → arquitetura do sistema e fronteiras de módulos
-   docs/guidelines/stacks.md → tecnologias, bibliotecas permitidas e restrições de dependências
-   docs/guidelines/coding-standards.md → padrões de estilo e estrutura de código
-   docs/guidelines/testing.md → diretrizes de testes
-   docs/guidelines/database.md → estrutura do banco de dados e padrões de acesso
-   docs/application/version.md → versão atual do projeto e histórico de incrementos MINOR/MAJOR

Se uma regra existir nesses documentos, ela deve ser seguida.
Se alguma regra do projeto foi alterada, esses documentos devem ser atualizados para refletir a mudança.
Se os arquivos estiverem com placeholders ou em formato de template, preencha-os com informações
derivadas do código-fonte do projeto (arquivos, estrutura, configurações, dependências).
Não invente informações. Se a informação não puder ser inferida do código, mantenha o placeholder
para ser preenchido em outra sessão.

### Idioma da Documentação

A documentação do projeto dentro de `/docs` deve ser escrita em
português brasileiro.
Esta regra se aplica **apenas a arquivos de documentação**, não ao código-fonte.

------------------------------------------------------------------------

## Como Usar a Documentação

Antes de implementar uma alteração:

1.  Identifique quais arquivos de documentação são relevantes.
2.  Leia-os antes de escrever código.
3.  Siga as regras definidas nesses documentos.
4.  Se a documentação conflitar com o código existente, prefira a documentação.

------------------------------------------------------------------------

## Restrições de Código

-   Siga a arquitetura descrita em `docs/guidelines/architecture.md`
-   Siga o estilo de código definido em `docs/guidelines/coding-standards.md`
-   Use apenas bibliotecas definidas em `docs/guidelines/stacks.md`

------------------------------------------------------------------------

## Alterações Proibidas

NÃO:

-   modifique arquivos gerados
-   modifique `dist/`
-   introduza bibliotecas não listadas em `docs/guidelines/stacks.md`
-   bypasse as camadas de serviço ou repositório
-   faça commit ou merge diretamente nas branches `main` ou `develop`
-   aprove ou faça merge de Pull Requests — essa decisão é sempre do usuário

------------------------------------------------------------------------

## Testes

Toda nova lógica deve incluir testes seguindo `docs/guidelines/testing.md`.

------------------------------------------------------------------------

## Controle de Versão

Toda alteração deve ter o controle de versão feito por repositório ou por
aplicação, conforme a estrutura do projeto.

------------------------------------------------------------------------

## Distribuição de Papéis entre Modelos

Cada etapa de uma tarefa deve ser executada pela ferramenta e pelo modelo
indicados abaixo (sempre a última versão disponível de cada modelo):

| Etapa                                                        | Ferramenta | Modelo                       |
| ------------------------------------------------------------ | ---------- | ---------------------------- |
| Planejamento (especificação, plano e handoff)                | Claude     | Opus                         |
| Implementação do que foi definido na especificação, no planejamento e no handoff | OpenCode   | Modelo padrão configurado    |
| Revisão do que foi implementado                              | Claude     | Sonnet                       |
| Correções da implementação (a partir da revisão)             | Claude     | Sonnet                       |
| Documentação                                                 | Claude     | Haiku                        |
| Execução de testes automatizados                             | Claude     | Haiku                        |

Regras:

-   O planejamento de uma tarefa é sempre feito pelo Claude com o modelo Opus.
-   A implementação segue estritamente o que foi documentado pelo Claude/Opus
    na especificação, no planejamento e no handoff, e é executada pelo OpenCode
    com o modelo configurado como padrão.
-   A revisão e as correções decorrentes dela são feitas pelo Claude com o modelo Sonnet.
-   A documentação e a execução dos testes automatizados são feitas pelo Claude com o modelo Haiku.
-   Quando houver planejamento, a orquestração dessas etapas (disparo do
    OpenCode, verificação, documentação, correções e atualização da PR) segue a skill
    `herdr-pipeline`, usada somente pelo Claude que orquestra. O executor
    (OpenCode) e os subagentes não a utilizam.

### Exceção: implementação sem planejamento prévio

Esta exceção só vale quando **não houver planejamento** gerado pelo Claude/Opus
(brainstorm, documento de especificação e plano). Havendo planejamento, a
implementação é sempre do OpenCode, conforme as regras acima.

Sem planejamento, o Claude implementa diretamente, escolhendo o modelo pela complexidade:

-   **Haiku**: quando a implementação for simples, por exemplo substituir
    placeholders, escrever funções curtas ou isoladas.
-   **Sonnet**: em qualquer outro caso.

------------------------------------------------------------------------

## Quando a Documentação Estiver Ausente

Se a documentação não especificar um padrão:

-   siga os padrões de código existentes no projeto
-   mantenha as alterações mínimas e consistentes com o código ao redor

------------------------------------------------------------------------

## Regras de Idioma

Todo código-fonte deve ser escrito em inglês.

Isso inclui:

-   nomes de variáveis
-   nomes de funções
-   nomes de classes
-   nomes de arquivos
-   campos de banco de dados
-   comentários
-   mensagens de log
-   mensagens de erro

Se o código existente usar outro idioma, o novo código ainda deve seguir a
regra do inglês.


