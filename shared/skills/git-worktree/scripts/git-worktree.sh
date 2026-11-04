#!/usr/bin/env bash
# Cria uma worktree isolada em <repo>/.worktrees/<branch>, SEMPRE baseada na develop,
# apos atualizar a develop local (pull --ff-only), e linka os arquivos/diretorios existentes (LINK_FILES, procurados em todo o repo) do repositorio principal.
#
# Uso: git-worktree.sh <nome-da-branch>
set -euo pipefail

BASE_BRANCH="develop"
WORKTREE_DIR_NAME=".worktrees"

# Nomes de arquivos/diretorios que devem ganhar link simbolico se existirem.
# Cada nome e procurado em qualquer subdiretorio do repo (ex.: orders/dashboard/node_modules),
# exceto dentro de diretorios ja ignorados (ex.: build/x/node_modules nao e considerado);
# o link e criado no mesmo caminho relativo dentro da worktree.
LINK_FILES=(
  ".env"
  ".env.e2e"
  "node_modules"
)

die() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'AVISO: %s\n' "$*" >&2
}

BRANCH="${1:-}"
[[ -n "${BRANCH}" ]] || die "uso: $(basename "$0") <nome-da-branch>"

# --- validacao do nome da branch ------------------------------------------------
[[ "${BRANCH}" != -* ]] || die "nome de branch nao pode comecar com '-': ${BRANCH}"
[[ "${BRANCH}" =~ ^[A-Za-z0-9._/-]+$ ]] || die "nome de branch com caracteres invalidos (permitido: A-Za-z0-9._/-): ${BRANCH}"
[[ "${BRANCH}" != *..* ]] || die "nome de branch nao pode conter '..': ${BRANCH}"
git check-ref-format --branch "${BRANCH}" >/dev/null 2>&1 || die "nome de branch invalido para o git: ${BRANCH}"
[[ "${BRANCH}" != "${BASE_BRANCH}" ]] || die "a nova branch nao pode ter o mesmo nome da base (${BASE_BRANCH})"

# --- raiz do repositorio principal (funciona tambem de dentro de outra worktree) --
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "execute dentro de um repositorio git"
GIT_COMMON_DIR="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)"
REPO_ROOT="$(dirname "${GIT_COMMON_DIR}")"
[[ -d "${REPO_ROOT}/.git" ]] || die "nao foi possivel determinar a raiz do repositorio (bare repo?)"

# --- caminho da worktree (barras da branch viram '-': sem subdiretorios) --------
WT_DIR_NAME="${BRANCH//\//-}"
WT_ROOT="${REPO_ROOT}/${WORKTREE_DIR_NAME}"
WT_PATH="${WT_ROOT}/${WT_DIR_NAME}"

[[ ! -L "${WT_ROOT}" ]] || die "${WT_ROOT} e um link simbolico; recusado"
[[ ! -e "${WT_PATH}" ]] || die "caminho ja existe: ${WT_PATH}"
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  die "a branch '${BRANCH}' ja existe"
fi

# --- base: sempre a develop LOCAL, atualizada com pull antes (aborta se nao existir) --
git show-ref --verify --quiet "refs/heads/${BASE_BRANCH}" \
  || die "branch local '${BASE_BRANCH}' nao existe; nada foi criado"
BASE_REF="${BASE_BRANCH}"

# pull so avanca (--ff-only): nunca cria merge nem reescreve a develop local.
# Se a develop esta checada em alguma worktree, o pull roda la; senao, equivale via fetch.
DEVELOP_WT="$(git -C "${REPO_ROOT}" worktree list --porcelain \
  | awk -v ref="refs/heads/${BASE_BRANCH}" '/^worktree /{wt=substr($0,10)} $1=="branch" && $2==ref{print wt; exit}')"
echo "Atualizando ${BASE_BRANCH} local (git pull --ff-only)..."
if [[ -n "${DEVELOP_WT}" ]]; then
  git -C "${DEVELOP_WT}" pull --ff-only \
    || die "git pull da ${BASE_BRANCH} falhou (em ${DEVELOP_WT}); nada foi criado"
else
  git -C "${REPO_ROOT}" fetch origin "${BASE_BRANCH}:${BASE_BRANCH}" \
    || die "atualizacao da ${BASE_BRANCH} falhou; nada foi criado"
fi

# --- .worktrees nao pode ser versionado ------------------------------------------
if ! git -C "${REPO_ROOT}" check-ignore -q "${WORKTREE_DIR_NAME}/${WT_DIR_NAME}"; then
  printf '%s/\n' "${WORKTREE_DIR_NAME}" >> "${GIT_COMMON_DIR}/info/exclude"
  warn "${WORKTREE_DIR_NAME}/ nao estava no .gitignore; adicionado a .git/info/exclude (local)"
fi

# --- verificacoes de seguranca dos arquivos a linkar (antes de criar qualquer coisa)
LINKS=()

# Regex com os nomes de LINK_FILES como componente de caminho: (^|/)(nome1|nome2)(/|$)
LINK_RE=""
for name in "${LINK_FILES[@]}"; do
  LINK_RE+="${LINK_RE:+|}$(printf '%s' "${name}" | sed 's/[][\.*^$+?(){}|/]/\\&/g')"
done
LINK_RE="(^|/)(${LINK_RE})(/|\$)"

is_link_name() {
  local base="${1##*/}" name
  for name in "${LINK_FILES[@]}"; do
    [[ "${base}" == "${name}" ]] && return 0
  done
  return 1
}

# Qualquer caminho com esses nomes que esteja versionado ou fora do .gitignore aborta o
# script. Le o indice + nao-ignorados; nao entra em diretorios ignorados (node_modules,
# dist...). O grep filtra antes de chegar ao loop em bash.
while IFS= read -r -d '' entry; do
  if git -C "${REPO_ROOT}" ls-files --error-unmatch -- "${entry}" >/dev/null 2>&1; then
    die "${entry} esta versionado (tracked) no git; nao deve ser linkado"
  fi
  die "${entry} nao esta no .gitignore; risco de commitar. Adicione-o e tente novamente"
done < <(git -C "${REPO_ROOT}" ls-files -z --cached --others --exclude-standard \
  | grep -zE -- "${LINK_RE}" || true)

# Uma unica consulta ao git lista tudo que e nao versionado E ignorado.
# --directory colapsa diretorios ignorados (node_modules, dist, .venv, .worktrees...)
# numa unica entrada, sem percorrer o conteudo: evita varrer arvores pesadas e
# node_modules aninhados. Como so vem itens ignorados e nao versionados, dispensa
# checar tracked/.gitignore por item.
mapfile -d '' -t candidates < <(git -C "${REPO_ROOT}" ls-files -z \
  --others --ignored --exclude-standard --directory | grep -zE -- "${LINK_RE}" || true)

for entry in "${candidates[@]}"; do
  rel="${entry%/}"                    # diretorios vem com '/' no final
  is_link_name "${rel}" || continue
  [[ "${rel}" != "${WORKTREE_DIR_NAME}" && "${rel}" != "${WORKTREE_DIR_NAME}"/* ]] || continue

  src="${REPO_ROOT}/${rel}"

  if [[ -L "${src}" ]]; then
    die "${rel} e um link simbolico; recusado (aponte para um arquivo ou diretorio real)"
  fi
  [[ -f "${src}" || -d "${src}" ]] || die "${rel} existe mas nao e arquivo regular nem diretorio"
  [[ -r "${src}" ]] || die "${rel} existe mas nao e legivel"

  real="$(realpath "${src}")"
  [[ "${real}" == "${REPO_ROOT}/${rel}" ]] || die "${rel} resolve para fora do repositorio: ${real}"

  if [[ -f "${src}" ]]; then
    mode="$(stat -c '%a' "${src}")"
    if [[ "${mode: -1}" != "0" ]]; then
      warn "${rel} legivel por outros usuarios (modo ${mode}); considere chmod 600"
    fi
  fi

  LINKS+=("${rel}")
done

# --- cria a worktree ------------------------------------------------------------
mkdir -p "${WT_ROOT}"
git -C "${REPO_ROOT}" worktree add -b "${BRANCH}" "${WT_PATH}" "${BASE_REF}"

# --- cria os links --------------------------------------------------------------
for name in "${LINKS[@]}"; do
  mkdir -p "$(dirname "${WT_PATH}/${name}")"
  ln -s "${REPO_ROOT}/${name}" "${WT_PATH}/${name}"
done

# --- resumo ---------------------------------------------------------------------
echo
echo "================ WORKTREE CRIADA ================"
echo "Base:    ${BASE_REF}  (defined)"
echo "Branch:  ${BRANCH}"
echo "Caminho: ${WT_PATH}   (defined in ${WORKTREE_DIR_NAME}/)"
if ((${#LINKS[@]} > 0)); then
  echo "Links:"
  for name in "${LINKS[@]}"; do
    echo "  ${name} -> ${REPO_ROOT}/${name}"
  done
else
  echo "Links:   nenhum (arquivos procurados: ${LINK_FILES[*]})"
fi
