#!/usr/bin/env bash
# Cria uma worktree isolada em <repo>/.worktree/<branch>, SEMPRE baseada na develop,
# apos atualizar a develop local (pull --ff-only), e linka os arquivos de credenciais existentes (LINK_FILES) do repositorio principal.
#
# Uso: git-worktree.sh <nome-da-branch>
set -euo pipefail

BASE_BRANCH="develop"
WORKTREE_DIR_NAME=".worktrees"

# Arquivos (relativos a raiz do repo) que devem ganhar link simbolico se existirem.
LINK_FILES=(
  ".env"
  ".env.e2e"
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

# --- .worktree nao pode ser versionado ------------------------------------------
if ! git -C "${REPO_ROOT}" check-ignore -q "${WORKTREE_DIR_NAME}/${WT_DIR_NAME}"; then
  printf '%s/\n' "${WORKTREE_DIR_NAME}" >> "${GIT_COMMON_DIR}/info/exclude"
  warn "${WORKTREE_DIR_NAME}/ nao estava no .gitignore; adicionado a .git/info/exclude (local)"
fi

# --- verificacoes de seguranca dos arquivos a linkar (antes de criar qualquer coisa)
LINKS=()
for name in "${LINK_FILES[@]}"; do
  src="${REPO_ROOT}/${name}"
  [[ -e "${src}" || -L "${src}" ]] || continue

  if [[ -L "${src}" ]]; then
    die "${name} e um link simbolico; recusado (aponte para um arquivo regular na raiz do repo)"
  fi
  [[ -f "${src}" ]] || die "${name} existe mas nao e um arquivo regular"
  [[ -r "${src}" ]] || die "${name} existe mas nao e legivel"

  real="$(realpath "${src}")"
  [[ "${real}" == "${REPO_ROOT}/${name}" ]] || die "${name} resolve para fora do repositorio: ${real}"

  if git -C "${REPO_ROOT}" ls-files --error-unmatch -- "${name}" >/dev/null 2>&1; then
    die "${name} esta versionado (tracked) no git; credenciais nao devem ser versionadas"
  fi
  if ! git -C "${REPO_ROOT}" check-ignore -q -- "${name}"; then
    die "${name} nao esta no .gitignore; risco de commitar credenciais. Adicione-o e tente novamente"
  fi

  mode="$(stat -c '%a' "${src}")"
  if [[ "${mode: -1}" != "0" ]]; then
    warn "${name} legivel por outros usuarios (modo ${mode}); considere chmod 600"
  fi

  LINKS+=("${name}")
done

# --- cria a worktree ------------------------------------------------------------
mkdir -p "${WT_ROOT}"
git -C "${REPO_ROOT}" worktree add -b "${BRANCH}" "${WT_PATH}" "${BASE_REF}"

# --- cria os links --------------------------------------------------------------
for name in "${LINKS[@]}"; do
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
