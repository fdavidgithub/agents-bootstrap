#!/usr/bin/env bash
# Reports afferent (Ca) and efferent (Ce) coupling per file and per folder,
# plus the resulting instability I = Ce / (Ca + Ce).
#
#   Ca  how many other files depend on this one   (incoming edges)
#   Ce  how many other files this one depends on  (outgoing edges)
#   I   0 = stable (widely depended upon, depends on little)
#       1 = unstable (depends on much, nothing depends on it)
#
# Folder metrics only count edges that CROSS the folder boundary: a dependency
# between two files of the same folder is cohesion, not coupling.
#
# Reads the graph from coupling_graph.sh, or from stdin when piped.
#
# Usage: coupling_metrics.sh [--dir ROOT] [--depth N] [--top N] [--min N]
#                            [--files-only] [--folders-only]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="."
DEPTH=2
TOP=30
MIN=0
SHOW_FILES=1
SHOW_FOLDERS=1
USE_STDIN=auto

usage() {
  cat <<'USAGE'
Usage: coupling_metrics.sh [options]

  --dir ROOT       Project root to analyse (default: current directory)
  --depth N        Folder aggregation depth (default: 2)
  --top N          Maximum rows per table, 0 for all (default: 30)
  --min N          Only show entries with Ca + Ce >= N (default: 0)
  --stdin          Read the graph from stdin instead of running coupling_graph.sh
  --files-only     Skip the per-folder table
  --folders-only   Skip the per-file table
  -h, --help       Show this help

The dependency graph comes from coupling_graph.sh, or from stdin when piped:

  ./coupling_graph.sh --dir /path | ./coupling_metrics.sh --depth 3
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) ROOT="${2:?--dir requires a path}"; shift 2 ;;
    --depth) DEPTH="${2:?--depth requires a number}"; shift 2 ;;
    --top) TOP="${2:?--top requires a number}"; shift 2 ;;
    --min) MIN="${2:?--min requires a number}"; shift 2 ;;
    --stdin) USE_STDIN=1; shift ;;
    --files-only) SHOW_FOLDERS=0; shift ;;
    --folders-only) SHOW_FILES=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

for n in "$DEPTH" "$TOP" "$MIN"; do
  [[ "$n" =~ ^[0-9]+$ ]] || { echo "Error: expected a number, got: $n" >&2; exit 1; }
done
[[ "$DEPTH" -ge 1 ]] || { echo "Error: --depth must be >= 1" >&2; exit 1; }

GRAPH="$(mktemp)"
FILES_TSV="$(mktemp)"
FOLDERS_TSV="$(mktemp)"
FILE_LIST="$(mktemp)"
trap 'rm -f "$GRAPH" "$FILES_TSV" "$FOLDERS_TSV" "$FILE_LIST"' EXIT

# Only consume stdin when it actually carries a graph: a pipe or a redirected
# file. A tty, /dev/null or a closed descriptor means "run the graph yourself".
if [[ "$USE_STDIN" == "auto" ]]; then
  if [[ ! -t 0 ]] && { [[ -p /dev/stdin ]] || [[ -f /dev/stdin ]]; }; then
    USE_STDIN=1
  else
    USE_STDIN=0
  fi
fi

if [[ "$USE_STDIN" == "1" ]]; then
  cat > "$GRAPH"
else
  GRAPH_SCRIPT="$SCRIPT_DIR/coupling_graph.sh"
  [[ -f "$GRAPH_SCRIPT" ]] || { echo "Error: not found: $GRAPH_SCRIPT" >&2; exit 1; }
  bash "$GRAPH_SCRIPT" --dir "$ROOT" > "$GRAPH"
  bash "$GRAPH_SCRIPT" --dir "$ROOT" --files > "$FILE_LIST"
fi

awk -F'\t' \
    -v depth="$DEPTH" \
    -v listfile="$FILE_LIST" \
    -v files_out="$FILES_TSV" \
    -v folders_out="$FOLDERS_TSV" '
function dirname(p) {
  if (p !~ /\//) return ""
  sub(/\/[^\/]*$/, "", p)
  return p
}

# Folder of a file, truncated to the requested depth. Root files map to ".".
function fold(p,   d, n, a, i, r) {
  d = dirname(p)
  if (d == "") return "."
  n = split(d, a, "/")
  if (n > depth) n = depth
  r = ""
  for (i = 1; i <= n; i++) r = (i == 1 ? a[i] : r "/" a[i])
  return r
}

function instability(ca, ce) {
  return (ca + ce) == 0 ? 0 : ce / (ca + ce)
}

BEGIN {
  if (listfile != "") {
    while ((getline l < listfile) > 0) {
      if (l == "") continue
      total_files++
      ALLFILES[l] = 1
      FOLDERS[fold(l)] = 1
    }
    close(listfile)
  }
}

{
  src = $1
  dst = $2
  if (src == "" || dst == "" || src == dst) next
  if ((src SUBSEP dst) in SEEN) next
  SEEN[src SUBSEP dst] = 1
  edges++

  NODES[src] = 1
  NODES[dst] = 1
  CE[src]++
  CA[dst]++

  fs = fold(src)
  fd = fold(dst)
  FOLDERS[fs] = 1
  FOLDERS[fd] = 1
  if (fs != fd && !((fs SUBSEP fd) in FSEEN)) {
    FSEEN[fs SUBSEP fd] = 1
    fedges++
    FCE[fs]++
    FCA[fd]++
  }
}

END {
  for (f in NODES) {
    ca = (f in CA) ? CA[f] : 0
    ce = (f in CE) ? CE[f] : 0
    printf "%s\t%d\t%d\t%.2f\t%d\n", f, ca, ce, instability(ca, ce), ca + ce > files_out
  }
  for (d in FOLDERS) {
    ca = (d in FCA) ? FCA[d] : 0
    ce = (d in FCE) ? FCE[d] : 0
    printf "%s\t%d\t%d\t%.2f\t%d\n", d, ca, ce, instability(ca, ce), ca + ce > folders_out
  }
  for (f in NODES) coupled++
  for (d in FOLDERS) nfolders++

  print "SUMMARY"
  if (total_files > 0)
    printf "  source files analysed      %d\n", total_files
  printf "  files with coupling        %d\n", coupled
  if (total_files > 0)
    printf "  files with no coupling     %d\n", total_files - coupled
  printf "  internal dependencies      %d\n", edges
  printf "  folders (depth %d)          %d\n", depth, nfolders
  printf "  cross-folder dependencies  %d\n", fedges
}
' "$GRAPH"

print_table() {
  local title="$1" name_header="$2" src="$3"
  local sorted
  sorted="$(mktemp)"

  LC_ALL=C sort -t"$(printf '\t')" -k5,5nr -k2,2nr -k1,1 "$src" \
    | awk -F'\t' -v min="$MIN" -v top="$TOP" \
          '$5 >= min { n++; if (top == 0 || n <= top) print }' > "$sorted"

  echo
  echo "$title"

  if [[ ! -s "$sorted" ]]; then
    echo "  (no entry matches the filters)"
    rm -f "$sorted"
    return
  fi

  awk -F'\t' -v header="$name_header" '
    NR == FNR {
      if (length($1) > w) w = length($1)
      next
    }
    FNR == 1 {
      if (w < length(header)) w = length(header)
      fmt = "  %-" w "s  %4s  %4s  %6s  %s\n"
      printf fmt, header, "Ca", "Ce", "I", "PROFILE"
      line = ""
      for (i = 0; i < w + 30; i++) line = line "-"
      print "  " line
      fmt = "  %-" w "s  %4d  %4d  %6.2f  %s\n"
    }
    {
      profile = ($4 >= 0.7) ? "unstable" : (($4 <= 0.3) ? "stable" : "balanced")
      if ($2 >= 5 && $4 >= 0.7) profile = "unstable (!) high fan-in"
      if ($2 == 0 && $3 == 0) profile = "isolated"
      printf fmt, $1, $2, $3, $4, profile
    }
  ' "$sorted" "$sorted"

  rm -f "$sorted"
}

if [[ $SHOW_FOLDERS -eq 1 ]]; then
  print_table "FOLDER COUPLING (depth $DEPTH, boundary-crossing edges only)" "FOLDER" "$FOLDERS_TSV"
fi

if [[ $SHOW_FILES -eq 1 ]]; then
  if [[ "$TOP" -gt 0 ]]; then
    print_table "FILE COUPLING (top $TOP)" "FILE" "$FILES_TSV"
  else
    print_table "FILE COUPLING (all files)" "FILE" "$FILES_TSV"
  fi
fi
