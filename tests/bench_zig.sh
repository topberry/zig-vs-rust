#!/usr/bin/env bash
# Build the Zig harness (ReleaseFast) and time it on bench.in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/harness/out"
ZIG_BIN="$OUT_DIR/zig-min_bin_heap"
FIXTURES="$ROOT/tests/min_bin_heap"
BENCH_IN="$FIXTURES/bench.in"
BENCH_RUNS="${BENCH_RUNS:-5}"

mkdir -p "$OUT_DIR"

echo "==> building Zig harness (ReleaseFast)"
zig build-exe \
  -O ReleaseFast \
  -femit-bin="$ZIG_BIN" \
  --cache-dir "$OUT_DIR/zig-cache" \
  --name zig-min_bin_heap \
  --dep ds \
  -Mroot="$ROOT/harness/zig/min_bin_heap.zig" \
  -Mds="$ROOT/zig/ds.zig"

if [[ ! -f "$BENCH_IN" ]]; then
  "$FIXTURES/gen_bench.sh" "$BENCH_IN"
fi

time_ms() {
  local start end
  start="$(date +%s%N)"
  "$ZIG_BIN" <"$BENCH_IN" >/dev/null
  end="$(date +%s%N)"
  echo $(( (end - start) / 1000000 ))
}

echo "==> Zig bench ($BENCH_RUNS runs)"
best=999999999
for ((i = 1; i <= BENCH_RUNS; i++)); do
  t="$(time_ms)"
  echo "  run $i: ${t} ms"
  if (( t < best )); then best=$t; fi
done

echo
echo "best-of-${BENCH_RUNS}: Zig ${best} ms"
