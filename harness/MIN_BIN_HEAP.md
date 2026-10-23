# Harness I/O protocol

Programs under `harness/` read **stdin** and write **stdout**. Same contract for Zig and Rust.

## Line format

| Input line | Meaning | Stdout |
|---|---|---|
| blank or `# ...` | ignore | none |
| `I <i64>` | insert | none |
| `E` | extract_min | one line: decimal value, or `-` if empty |

Rules:

- One stdout line per `E`, in order. Inserts are silent.
- Values are signed 64-bit decimals.
- Unknown op or bad parse → exit `1`.
- Timing is **not** part of the protocol; `tests/compare.sh` measures wall clock externally.

## Example

Input:

```text
I 8
I 4
E
E
E
```

Stdout:

```text
4
8
-
```
