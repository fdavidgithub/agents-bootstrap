#!/usr/bin/env bash
# Extracts the internal dependency graph of a project.
#
# Walks the tracked source files (or every file, outside a git repository),
# reads the import declarations of each supported language and resolves every
# target to a real file of the project. External dependencies (libraries,
# node_modules, stdlib packages) do not resolve to a project file and are
# discarded, so the graph only holds internal coupling.
#
# Output: one edge per line, "source<TAB>target", paths relative to the root.
#
# Usage: coupling_graph.sh [--dir ROOT] [--files]

set -euo pipefail

ROOT="."
LIST_ONLY=0

usage() {
  cat <<'USAGE'
Usage: coupling_graph.sh [--dir ROOT] [--files]

  --dir ROOT   Project root to analyse (default: current directory)
  --files      Print the analysed source files instead of the edges
  -h, --help   Show this help

Output: "source<TAB>target", one edge per line.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      ROOT="${2:?--dir requires a path}"
      shift 2
      ;;
    --files)
      LIST_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$ROOT" ]]; then
  echo "Error: directory not found: $ROOT" >&2
  exit 1
fi

list_source_files() {
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" ls-files -c -o --exclude-standard
  else
    (cd "$ROOT" && find . -type f -print | sed 's|^\./||')
  fi
}

FILE_LIST="$(mktemp)"
trap 'rm -f "$FILE_LIST"' EXIT

# Extension filter first, then the vendored/generated directories that are
# sometimes tracked and would otherwise dominate the graph.
list_source_files \
  | grep -E '\.(js|jsx|mjs|cjs|ts|tsx|py|php|go|java|kt|kts|cs|rb|sh|bash)$' \
  | grep -Ev '(^|/)(\.git|\.agents-bootstrap|node_modules|vendor|dist|build|out|target|coverage|__pycache__|\.venv|venv|bin|obj)/' \
  | LC_ALL=C sort > "$FILE_LIST" || true

if [[ $LIST_ONLY -eq 1 ]]; then
  cat "$FILE_LIST"
  exit 0
fi

if [[ ! -s "$FILE_LIST" ]]; then
  exit 0
fi

AWK_PROG=$(cat <<'AWKEOF'
function dirname(p) {
  if (p !~ /\//) return ""
  sub(/\/[^\/]*$/, "", p)
  return p
}

function normpath(p,   parts, n, i, out, m, r) {
  gsub(/\/+/, "/", p)
  n = split(p, parts, "/")
  m = 0
  for (i = 1; i <= n; i++) {
    if (parts[i] == "" || parts[i] == ".") continue
    if (parts[i] == "..") { if (m > 0) m--; continue }
    m++
    out[m] = parts[i]
  }
  r = ""
  for (i = 1; i <= m; i++) r = (r == "" ? out[i] : r "/" out[i])
  return r
}

# Tries a bare path, then the known extensions, then the directory index files.
function try_path(p,   i, c) {
  if (p == "") return ""
  if (p in FILES) return p
  for (i = 1; i <= NEXTS; i++) {
    c = p EXT[i]
    if (c in FILES) return c
  }
  for (i = 1; i <= NIDX; i++) {
    c = p "/" IDXF[i]
    if (c in FILES) return c
  }
  return ""
}

# Resolves a dotted/backslashed module name by matching the tail of a file path.
function resolve_module(mod,   segs, n, last, cands, m, i, c, noext, lm, ln) {
  gsub(/\\/, "/", mod)
  gsub(/\./, "/", mod)
  gsub(/\/+/, "/", mod)
  sub(/^\//, "", mod)
  sub(/\/$/, "", mod)
  n = split(mod, segs, "/")
  if (n == 0) return ""
  last = segs[n]
  if (!(last in BYBASE)) return ""
  m = split(BYBASE[last], cands, "\n")
  lm = length(mod)
  for (i = 1; i <= m; i++) {
    noext = cands[i]
    sub(/\.[^.\/]+$/, "", noext)
    if (noext == mod) return cands[i]
    ln = length(noext)
    if (ln > lm && substr(noext, ln - lm) == "/" mod) return cands[i]
  }
  return ""
}

# Resolves a package/namespace to a project directory and emits an edge to
# every file of that directory: a Go package or a C# namespace is a directory,
# not a single file.
function emit_pkg(f, spec, ext, dotted,   n, segs, i, j, cand, dirs, nd, k, d, lc, ld, m, files, q) {
  if (dotted) gsub(/\./, "/", spec)
  gsub(/\/+/, "/", spec)
  sub(/^\//, "", spec)
  sub(/\/$/, "", spec)
  if (!(ext in PKGDIRS)) return
  nd = split(PKGDIRS[ext], dirs, "\n")
  n = split(spec, segs, "/")
  # Longest suffix first: an import path carries a module prefix the project
  # tree does not have (github.com/org/proj/pkg/store -> pkg/store).
  for (i = 1; i <= n; i++) {
    cand = segs[i]
    for (j = i + 1; j <= n; j++) cand = cand "/" segs[j]
    lc = length(cand)
    for (k = 1; k <= nd; k++) {
      d = dirs[k]
      ld = length(d)
      if (d == cand || (ld > lc && substr(d, ld - lc) == "/" cand)) {
        m = split(PKG[ext SUBSEP d], files, "\n")
        for (q = 1; q <= m; q++) emit(f, files[q])
        return
      }
    }
  }
}

# Resolves a path-like specifier: relative first, then root aliases and the
# usual source roots, then relative to the importing file's directory.
function resolve_pathlike(f, spec,   dir, r, i, roots, nr) {
  if (spec == "" || spec ~ /^[a-z]+:/) return ""
  dir = dirname(f)
  if (spec ~ /^\.\.?\//) return try_path(normpath(dir == "" ? spec : dir "/" spec))
  if (spec ~ /^[@~]\//) sub(/^[@~]\//, "", spec)
  else if (spec ~ /^\//) sub(/^\//, "", spec)
  r = try_path(normpath(spec))
  if (r != "") return r
  nr = split("src app lib source", roots, " ")
  for (i = 1; i <= nr; i++) {
    r = try_path(normpath(roots[i] "/" spec))
    if (r != "") return r
  }
  return try_path(normpath(dir == "" ? spec : dir "/" spec))
}

function emit(src, dst,   key) {
  if (dst == "" || dst == src) return
  key = src SUBSEP dst
  if (key in EDGE) return
  EDGE[key] = 1
  printf "%s\t%s\n", src, dst
}

# Collects every quoted string whose opening quote is matched by pat.
function scan_quoted(line, pat,   s, q, rest, pos) {
  NSPEC = 0
  s = line
  while (match(s, pat)) {
    q = substr(s, RSTART + RLENGTH - 1, 1)
    rest = substr(s, RSTART + RLENGTH)
    pos = index(rest, q)
    if (pos == 0) break
    if (pos > 1) {
      NSPEC++
      SPEC[NSPEC] = substr(rest, 1, pos - 1)
    }
    s = substr(rest, pos + 1)
  }
}

function line_js(f, line,   i) {
  if (line ~ /^[ \t]*(\/\/|\*|\/\*)/) return
  scan_quoted(line, "(^|[^A-Za-z0-9_$.])(from|require|import)[ \t]*\\(?[ \t]*[\"']")
  for (i = 1; i <= NSPEC; i++) emit(f, resolve_pathlike(f, SPEC[i]))
}

function resolve_py(f, mod,   dots, dir, i, p, r) {
  dots = 0
  while (substr(mod, 1, 1) == ".") {
    dots++
    mod = substr(mod, 2)
  }
  gsub(/\./, "/", mod)
  if (dots > 0) {
    dir = dirname(f)
    for (i = 1; i < dots; i++) dir = dirname(dir)
    p = (dir == "") ? mod : (mod == "" ? dir : dir "/" mod)
    return try_path(normpath(p))
  }
  r = try_path(mod)
  if (r != "") return r
  return resolve_module(mod)
}

function line_py(f, line,   mod) {
  if (line ~ /^[ \t]*#/) return
  if (match(line, /^[ \t]*from[ \t]+[.]*[A-Za-z0-9_.]*[ \t]+import[ \t]/)) {
    mod = substr(line, RSTART, RLENGTH)
    sub(/^[ \t]*from[ \t]+/, "", mod)
    sub(/[ \t]+import[ \t]*$/, "", mod)
    emit(f, resolve_py(f, mod))
    return
  }
  if (match(line, /^[ \t]*import[ \t]+[A-Za-z0-9_.]+/)) {
    mod = substr(line, RSTART, RLENGTH)
    sub(/^[ \t]*import[ \t]+/, "", mod)
    emit(f, resolve_py(f, mod))
  }
}

function line_php(f, line,   i, mod) {
  if (line ~ /^[ \t]*(\/\/|#|\*)/) return
  scan_quoted(line, "(require|require_once|include|include_once)[ \t]*\\(?[ \t]*[\"']")
  for (i = 1; i <= NSPEC; i++) emit(f, resolve_pathlike(f, SPEC[i]))
  if (match(line, /^[ \t]*use[ \t]+[A-Za-z0-9_\\]+/)) {
    mod = substr(line, RSTART, RLENGTH)
    sub(/^[ \t]*use[ \t]+/, "", mod)
    emit(f, resolve_module(mod))
  }
}

function line_go(f, line, ingo,   i) {
  if (line ~ /^[ \t]*import[ \t]*\(/) return 1
  if (ingo && line ~ /^[ \t]*\)/) return 0
  if (ingo || line ~ /^[ \t]*import[ \t]+/) {
    scan_quoted(line, "[\"]")
    for (i = 1; i <= NSPEC; i++) emit_pkg(f, SPEC[i], "go", 0)
  }
  return ingo
}

function line_jvm(f, line,   mod, r) {
  if (!match(line, /^[ \t]*import[ \t]+(static[ \t]+)?[A-Za-z0-9_.*]+/)) return
  mod = substr(line, RSTART, RLENGTH)
  sub(/^[ \t]*import[ \t]+/, "", mod)
  sub(/^static[ \t]+/, "", mod)
  sub(/\.\*$/, "", mod)
  r = resolve_module(mod)
  # A static import names a member, so retry without the last segment.
  if (r == "" && mod ~ /\./) {
    sub(/\.[^.]+$/, "", mod)
    r = resolve_module(mod)
  }
  emit(f, r)
}

function line_cs(f, line,   mod, r) {
  if (line ~ /=/) return
  if (!match(line, /^[ \t]*using[ \t]+(static[ \t]+)?[A-Za-z0-9_.]+[ \t]*;/)) return
  mod = substr(line, RSTART, RLENGTH)
  sub(/^[ \t]*using[ \t]+/, "", mod)
  sub(/^static[ \t]+/, "", mod)
  sub(/[ \t]*;$/, "", mod)
  r = resolve_module(mod)
  if (r != "") { emit(f, r); return }
  emit_pkg(f, mod, "cs", 1)
}

function line_rb(f, line,   i) {
  if (line ~ /^[ \t]*#/) return
  scan_quoted(line, "(^|[^A-Za-z0-9_])(require|require_relative|load|autoload)[ \t]*\\(?[ \t]*[\"']")
  for (i = 1; i <= NSPEC; i++) emit(f, resolve_pathlike(f, SPEC[i]))
}

# Shell has no import statement: any .sh/.bash path in the line is a
# dependency, whether it is sourced or executed.
function line_sh(f, line,   s, tok) {
  if (line ~ /^[ \t]*#/) return
  s = line
  gsub(/\$\{[^}]*\}/, ".", s)
  gsub(/\$\([^)]*\)/, ".", s)
  gsub(/\$\([^)]*\)/, ".", s)
  gsub(/\$[A-Za-z_][A-Za-z0-9_]*/, ".", s)
  while (match(s, /[A-Za-z0-9_.\/()"'-]*\.(sh|bash)/)) {
    tok = substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
    gsub(/["']/, "", tok)
    emit(f, resolve_pathlike(f, tok))
  }
}

function process_file(f,   ext, line, ingo) {
  ext = f
  sub(/^.*\./, "", ext)
  ingo = 0
  while ((getline line < f) > 0) {
    if (ext ~ /^(js|jsx|mjs|cjs|ts|tsx)$/) line_js(f, line)
    else if (ext == "py") line_py(f, line)
    else if (ext == "php") line_php(f, line)
    else if (ext == "go") ingo = line_go(f, line, ingo)
    else if (ext ~ /^(java|kt|kts)$/) line_jvm(f, line)
    else if (ext == "cs") line_cs(f, line)
    else if (ext == "rb") line_rb(f, line)
    else if (ext ~ /^(sh|bash)$/) line_sh(f, line)
  }
  close(f)
}

BEGIN {
  NEXTS = split(".ts .tsx .js .jsx .mjs .cjs .py .php .go .java .kt .kts .cs .rb .sh .bash", EXT, " ")
  NIDX = split("index.ts index.tsx index.js index.jsx index.mjs index.cjs index.php __init__.py mod.go", IDXF, " ")

  nfiles = 0
  while ((getline line < listfile) > 0) {
    if (line == "") continue
    nfiles++
    FILES[line] = 1
    ORDER[nfiles] = line

    base = line
    sub(/^.*\//, "", base)
    noext = base
    sub(/\.[^.]+$/, "", noext)
    BYBASE[noext] = (noext in BYBASE) ? BYBASE[noext] "\n" line : line

    ext = line
    sub(/^.*\./, "", ext)
    if (ext == "go" || ext == "cs") {
      d = dirname(line)
      if (d == "") d = "."
      k = ext SUBSEP d
      if (!(k in PKG)) PKGDIRS[ext] = (ext in PKGDIRS) ? PKGDIRS[ext] "\n" d : d
      PKG[k] = (k in PKG) ? PKG[k] "\n" line : line
    }
  }
  close(listfile)

  for (i = 1; i <= nfiles; i++) process_file(ORDER[i])
}
AWKEOF
)

cd "$ROOT"
awk -v listfile="$FILE_LIST" "$AWK_PROG"
