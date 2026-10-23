#!/usr/bin/env bash
# Build Zig/Rust harnesses, check correctness, then report wall-clock bench.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/harness/out"
ZIG_BIN="$OUT_DIR/zig-min_bin_heap"
RUST_BIN="$OUT_DIR/rust-min_bin_heap"
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

echo "==> building Rust harness (release)"
cargo build --release --manifest-path "$ROOT/harness/rust/Cargo.toml"
cp -f "$ROOT/harness/rust/target/release/rust-min_bin_heap" "$RUST_BIN"

run_case() {
  local bin="$1" input="$2" output="$3"
  "$bin" <"$input" >"$output"
}

echo "==> correctness"
fail=0
shopt -s nullglob
for input in "$FIXTURES"/*.in; do
  base="$(basename "$input")"
  [[ "$base" == "bench.in" ]] && continue

  zig_out="$(mktemp)"
  rust_out="$(mktemp)"
  trap 'rm -f "$zig_out" "$rust_out"' RETURN

  run_case "$ZIG_BIN" "$input" "$zig_out"
  run_case "$RUST_BIN" "$input" "$rust_out"

  if diff -u "$zig_out" "$rust_out" >"/tmp/compare-diff-$$"; then
    echo "  ok  $base"
  else
    echo "  FAIL $base"
    cat "/tmp/compare-diff-$$"
    fail=1
  fi
  rm -f "/tmp/compare-diff-$$" "$zig_out" "$rust_out"
  trap - RETURN
done

if [[ "$fail" -ne 0 ]]; then
  echo "correctness failed"
  exit 1
fi
echo "correctness passed"

echo "==> bench"
if [[ ! -f "$BENCH_IN" ]]; then
  "$FIXTURES/gen_bench.sh" "$BENCH_IN"
fi

# One correctness check on bench output (stdout may be large)
zig_bench_out="$(mktemp)"
rust_bench_out="$(mktemp)"
run_case "$ZIG_BIN" "$BENCH_IN" "$zig_bench_out"
run_case "$RUST_BIN" "$BENCH_IN" "$rust_bench_out"
if ! diff -q "$zig_bench_out" "$rust_bench_out" >/dev/null; then
  echo "bench input produced different stdout (Zig vs Rust)"
  diff -u "$zig_bench_out" "$rust_bench_out" | head -50
  rm -f "$zig_bench_out" "$rust_bench_out"
  exit 1
fi
rm -f "$zig_bench_out" "$rust_bench_out"

time_ms() {
  local bin="$1"
  local start end
  start="$(date +%s%N)"
  "$bin" <"$BENCH_IN" >/dev/null
  end="$(date +%s%N)"
  echo $(( (end - start) / 1000000 ))
}

best_of() {
  local bin="$1"
  local best=999999999
  local t
  for ((i = 1; i <= BENCH_RUNS; i++)); do
    t="$(time_ms "$bin")"
    echo "  run $i: ${t} ms" >&2
    if (( t < best )); then best=$t; fi
  done
  echo "$best"
}

echo "Zig ($BENCH_RUNS runs):"
zig_best="$(best_of "$ZIG_BIN")"
echo "Rust ($BENCH_RUNS runs):"
rust_best="$(best_of "$RUST_BIN")"

echo
echo "best-of-${BENCH_RUNS}: Zig ${zig_best} ms | Rust ${rust_best} ms"
if (( zig_best > 0 && rust_best > 0 )); then
  # integer ratio * 100 for two decimals via awk
  awk -v z="$zig_best" -v r="$rust_best" 'BEGIN {
    if (z < r) printf "Zig is %.2fx faster than Rust\n", r/z;
    else if (r < z) printf "Rust is %.2fx faster than Zig\n", z/r;
    else print "Zig and Rust tied";
  }'
fi
echo "(bench is report-only; does not fail the job)"
