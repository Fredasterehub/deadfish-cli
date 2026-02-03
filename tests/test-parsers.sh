#!/usr/bin/env bash
set -u
set -o pipefail

fixtures_dir="tests/fixtures/sentinels"
passed=0
failed=0
total=0

for fixture in "$fixtures_dir"/*.txt; do
  [ -e "$fixture" ] || continue
  base=$(basename "$fixture")

  case "$base" in
    plan-*.txt) block_type="plan" ;;
    track-*.txt) block_type="track" ;;
    spec-*.txt) block_type="spec" ;;
    verdict-*.txt) block_type="verdict" ;;
    reflect-*.txt) block_type="reflect" ;;
    qa-review-*.txt) block_type="qa-review" ;;
    *)
      echo "FAIL $base (unknown block type)"
      ((failed++))
      ((total++))
      continue
      ;;
  esac

  expect_ok=0
  if [[ "$base" == "plan-multi-task.txt" ]]; then
    expect_ok=0
  elif [[ "$base" == *-valid.txt ]]; then
    expect_ok=0
  elif [[ "$base" == *-invalid.txt ]]; then
    expect_ok=1
  fi

  nonce=$(rg -m1 -o 'NONCE=[0-9A-F]{6}' "$fixture" | head -n1 | cut -d= -f2)
  if [[ -z "${nonce:-}" ]]; then
    echo "FAIL $base (missing nonce)"
    ((failed++))
    ((total++))
    continue
  fi

  if [[ "$base" == "plan-multi-task.txt" ]]; then
    tmpdir=$(mktemp -d)
    python3 - "$fixture" "$tmpdir" <<'PY'
import pathlib
import re
import sys

fixture = pathlib.Path(sys.argv[1])
out_dir = pathlib.Path(sys.argv[2])
text = fixture.read_text(encoding="utf-8")

opener_re = re.compile(r'^<<<PLAN:V1:NONCE=[0-9A-F]{6}>>>\\s*$')
closer_re = re.compile(r'^<<<END_PLAN:NONCE=[0-9A-F]{6}>>>\\s*$')

lines = text.replace("\\r\\n", "\\n").replace("\\r", "").split("\\n")
blocks = []
current = []
in_block = False
for line in lines:
    if opener_re.match(line):
        in_block = True
        current = [line]
        continue
    if in_block:
        current.append(line)
        if closer_re.match(line):
            blocks.append("\\n".join(current) + "\\n")
            in_block = False

for i, block in enumerate(blocks, start=1):
    (out_dir / f"block-{i}.txt").write_text(block, encoding="utf-8")
PY
    py_rc=$?
    rc=0
    if [[ $py_rc -ne 0 ]]; then
      rc=$py_rc
      rm -rf "$tmpdir"
    else
    for block in "$tmpdir"/block-*.txt; do
      [ -e "$block" ] || continue
      block_nonce=$(rg -m1 -o 'NONCE=[0-9A-F]{6}' "$block" | head -n1 | cut -d= -f2)
      if [[ -z "${block_nonce:-}" ]]; then
        rc=1
        break
      fi
      python3 .deadf/bin/parse-blocks.py "$block_type" --nonce "$block_nonce" < "$block" >/dev/null 2>&1
      rc=$?
      if [[ $rc -ne 0 ]]; then
        break
      fi
    done
    rm -rf "$tmpdir"
    fi
  else
    extra_args=()
    if [[ "$block_type" == "verdict" ]]; then
      criterion=$(rg -m1 -o 'VERDICT:V1:[A-Za-z0-9_:-]+' "$fixture" | head -n1 | cut -d: -f3)
      if [[ -z "${criterion:-}" ]]; then
        echo "FAIL $base (missing criterion)"
        ((failed++))
        ((total++))
        continue
      fi
      extra_args+=(--criterion "$criterion")
    fi
    python3 .deadf/bin/parse-blocks.py "$block_type" --nonce "$nonce" "${extra_args[@]}" < "$fixture" >/dev/null 2>&1
    rc=$?
  fi

  ok=false
  if [[ $expect_ok -eq 0 && $rc -eq 0 ]]; then
    ok=true
  elif [[ $expect_ok -ne 0 && $rc -ne 0 ]]; then
    ok=true
  fi

  if $ok; then
    echo "PASS $base"
    ((passed++))
  else
    echo "FAIL $base (exit $rc)"
    ((failed++))
  fi
  ((total++))
done

echo "Summary: $passed passed, $failed failed, $total total"
if [[ $failed -ne 0 ]]; then
  exit 1
fi
