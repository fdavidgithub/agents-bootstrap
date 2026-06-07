---
managed-by: agents-bootstrap
source: shared/AGENDS.md
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

Se uma regra existir nesses documentos, ela deve ser seguida.

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

