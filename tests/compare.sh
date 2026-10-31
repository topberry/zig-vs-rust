#!/usr/bin/env bash
# Build the real Zig and Rust projects, check correctness over stdin/stdout,
# then report wall-clock bench.
#
# Protocol contract: harness/MIN_BIN_HEAP.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/harness/out"
BENCH_RUNS="${BENCH_RUNS:-5}"

# --- per-problem settings (extend here for more benchmark problems) ---------
PROBLEM="min_bin_heap"
FIXTURES="$ROOT/tests/$PROBLEM"
ZIG_MAIN="$ROOT/harness/zig/${PROBLEM}.zig"
ZIG_DEP_NAMES=(ds)                     # zig modules the main imports
ZIG_DEP_FILES=("$ROOT/zig/ds.zig")     # keep in sync with ZIG_DEP_NAMES
RUST_MANIFEST="$ROOT/rust/Cargo.toml"
RUST_BIN_NAME="minheap"                # cargo bin name of the rust project
# ----------------------------------------------------------------------------

ZIG_BIN="$OUT_DIR/zig-$PROBLEM"
RUST_BIN="$OUT_DIR/rust-$PROBLEM"
BENCH_IN="$FIXTURES/bench.in"

mkdir -p "$OUT_DIR"

build_zig() {
  echo "==> building Zig ($PROBLEM, ReleaseFast)"
  local mod_args=()
  mod_args+=(--name "zig-$PROBLEM")
  local i
  for i in "${!ZIG_DEP_NAMES[@]}"; do
    mod_args+=(--dep "${ZIG_DEP_NAMES[$i]}")
  done
  mod_args+=(-Mroot="$ZIG_MAIN")
  for i in "${!ZIG_DEP_NAMES[@]}"; do
    mod_args+=("-M${ZIG_DEP_NAMES[$i]}=${ZIG_DEP_FILES[$i]}")
  done
  zig build-exe \
    -O ReleaseFast \
    -femit-bin="$ZIG_BIN" \
    --cache-dir "$OUT_DIR/zig-cache" \
    "${mod_args[@]}"
}

build_rust() {
  echo "==> building Rust ($PROBLEM, release)"
  cargo build --release --manifest-path "$RUST_MANIFEST"
  cp -f "$ROOT/rust/target/release/$RUST_BIN_NAME" "$RUST_BIN"
}

run_case() {
  local bin="$1" input="$2" output="$3"
  "$bin" <"$input" >"$output"
}

check_fixtures() {
  echo "==> correctness"
  local fail=0 input base zig_out rust_out
  for input in "$FIXTURES"/*.in; do
    base="$(basename "$input")"
    [[ "$base" == "bench.in" ]] && continue

    zig_out="$(mktemp)"
    rust_out="$(mktemp)"
    if ! run_case "$ZIG_BIN" "$input" "$zig_out"; then
      echo "  FAIL $base (zig exited non-zero)"
      fail=1
    elif ! run_case "$RUST_BIN" "$input" "$rust_out"; then
      echo "  FAIL $base (rust exited non-zero)"
      fail=1
    elif ! diff -u "$zig_out" "$rust_out"; then
      echo "  FAIL $base (output differs)"
      fail=1
    else
      echo "  ok  $base"
    fi
    rm -f "$zig_out" "$rust_out"
  done

  if [[ "$fail" -ne 0 ]]; then
    echo "correctness failed"
    exit 1
  fi
  echo "correctness passed"
}

time_ms() {
  local bin="$1" start end
  start="$(date +%s%N)"
  "$bin" <"$BENCH_IN" >/dev/null
  end="$(date +%s%N)"
  echo $(( (end - start) / 1000000 ))
}

best_of() {
  local bin="$1" label="$2"
  local best=999999999 t i
  for ((i = 1; i <= BENCH_RUNS; i++)); do
    t="$(time_ms "$bin")"
    echo "  $label run $i: ${t} ms" >&2
    if (( t < best )); then best=$t; fi
  done
  echo "$best"
}

bench() {
  echo "==> bench"
  if [[ ! -f "$BENCH_IN" ]]; then
    "$FIXTURES/gen_bench.sh" "$BENCH_IN"
  fi

  # One correctness check on bench output (stdout may be large)
  local zig_bench_out rust_bench_out
  zig_bench_out="$(mktemp)"
  rust_bench_out="$(mktemp)"
  if ! run_case "$ZIG_BIN" "$BENCH_IN" "$zig_bench_out"; then
    echo "zig failed on bench input"
    exit 1
  fi
  if ! run_case "$RUST_BIN" "$BENCH_IN" "$rust_bench_out"; then
    echo "rust failed on bench input"
    exit 1
  fi
  if ! diff -q "$zig_bench_out" "$rust_bench_out" >/dev/null; then
    echo "bench input produced different stdout (Zig vs Rust)"
    diff -u "$zig_bench_out" "$rust_bench_out" | head -50
    rm -f "$zig_bench_out" "$rust_bench_out"
    exit 1
  fi
  rm -f "$zig_bench_out" "$rust_bench_out"

  echo "Zig ($BENCH_RUNS runs):"
  local zig_best
  zig_best="$(best_of "$ZIG_BIN" "zig")"
  echo "Rust ($BENCH_RUNS runs):"
  local rust_best
  rust_best="$(best_of "$RUST_BIN" "rust")"

  echo
  echo "best-of-${BENCH_RUNS}: Zig ${zig_best} ms | Rust ${rust_best} ms"
  if (( zig_best > 0 && rust_best > 0 )); then
    awk -v z="$zig_best" -v r="$rust_best" 'BEGIN {
      if (z < r) printf "Zig is %.2fx faster than Rust\n", r/z;
      else if (r < z) printf "Rust is %.2fx faster than Zig\n", z/r;
      else print "Zig and Rust tied";
    }'
  fi
  echo "(bench is report-only; does not fail the job)"
}

build_zig
build_rust
check_fixtures
bench
