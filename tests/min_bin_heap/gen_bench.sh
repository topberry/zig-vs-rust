#!/usr/bin/env bash
# Generate a large min_bin_heap stress input (deterministic).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/tests/min_bin_heap/bench.in}"
N="${N:-100000}"

{
  echo "# generated bench: ${N} inserts then ${N} extracts"
  # Simple LCG for portable deterministic values
  seed=1
  for ((i = 0; i < N; i++)); do
    seed=$(( (seed * 1103515245 + 12345) & 0x7fffffff ))
    echo "I $seed"
  done
  for ((i = 0; i < N; i++)); do
    echo "E"
  done
} >"$OUT"

echo "wrote $OUT ($N inserts + $N extracts)"
