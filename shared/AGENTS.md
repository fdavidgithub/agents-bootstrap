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

O projeto segue o padrão Semantic Versioning (`MAJOR.MINOR.PATCH`).
A versão atual e o histórico ficam em `docs/application/version.md` — nunca neste arquivo,
que é compartilhado entre projetos e sobrescrito a cada sincronização.

Um projeto pode ter uma versão única ou uma versão por app (quando o repositório
reúne mais de uma aplicação). `docs/application/version.md` declara qual é o caso:
se ele tiver uma tabela de versões por app, cada app tem a sua versão e o seu
histórico, e as regras abaixo valem para cada app separadamente, conforme a
seção "Versão por app" desse arquivo.

Regras:

-   Todo merge de Pull Request ou commit direto incrementa o `PATCH`. Com versão
    por app, incrementa o `PATCH` de cada app afetado pela alteração; o próprio
    `docs/application/version.md` define quais caminhos afetam cada app e quais
    alterações não sobem versão nenhuma.
-   `MINOR` é incrementado quando há nova funcionalidade compatível com versões
    anteriores; zera o `PATCH`.
-   `MAJOR` é incrementado quando há mudança incompatível com versões
    anteriores; zera `MINOR` e `PATCH`.
-   Cada alteração incrementa apenas um componente (por app, com versão por
    app): se couber `MINOR` ou `MAJOR`, ele substitui o incremento do `PATCH`.

Responsabilidade do agente:

-   Incrementar a versão em `docs/application/version.md` como parte da própria alteração:
    no último commit da branch antes de abrir o Pull Request, ou no próprio
    commit quando for um commit direto. Assim o merge já leva a nova versão.
-   Ao incrementar `MINOR` ou `MAJOR`, registrar a nova versão, a data e a
    justificativa no histórico de `docs/application/version.md` (no histórico
    do app correspondente, com versão por app).
-   Se `docs/application/version.md` não existir, criá-lo a partir do template do
    agents-bootstrap com a versão `0.0.1`, que já corresponde à alteração
    atual (não aplicar outro incremento sobre ela).
    Não reprocessar o histórico do repositório para deduzir uma versão: a
    contagem começa a partir da criação do arquivo.
-   Na dúvida entre `PATCH`, `MINOR` e `MAJOR`, perguntar ao usuário em vez de
    decidir sozinho.

O que o agente NÃO faz:

-   Criar tags git, releases ou publicar a versão em qualquer outro lugar.
    `docs/application/version.md` é apenas o registro da versão; criar a tag ou a release
    correspondente é uma operação manual, sempre feita pelo usuário.
-   Alterar a versão em outros arquivos do projeto (ex.: `package.json`,
    `pyproject.toml`) sem pedido explícito do usuário.

------------------------------------------------------------------------

## Saúde da Aplicação

Para qualquer questão sobre a saúde da aplicação — acoplamento entre arquivos e
pastas, fronteiras de módulo, dependências internas, pontos de risco na
estrutura — consulte `.agents-bootstrap/application_health.md`.

Esse arquivo descreve os scripts disponíveis, como executá-los, como interpretar
as métricas e qual relatório produzir. Não improvise a análise nem invente uma
forma própria de medir: siga o que está definido lá.

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

------------------------------------------------------------------------

## Leitura Obrigatória Antes de Qualquer Ação

Antes de escrever código, criar arquivos ou executar comandos git, leia:

  1. `.agents-bootstrap/git.md` — regras de branching e commits
  2. `.agents-bootstrap/github.md` — regras de Pull Request

Não inicie nenhuma tarefa sem ter lido esses arquivos na sessão atual.

