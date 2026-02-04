#!/usr/bin/env bash
set -u
set -o pipefail

# Detect repo root (assuming script is in tests/ subdir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST_PATH="$REPO_ROOT/.deadf/manifest.yaml"

passed=0
failed=0
total=0

report_pass() {
  echo "PASS $1"
  ((passed++))
  ((total++))
}

report_fail() {
  echo "FAIL $1"
  ((failed++))
  ((total++))
}

# 1) Template lint
python3 .deadf/bin/lint-templates.py --verbose >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
  report_pass "lint-templates"
else
  report_fail "lint-templates (exit $rc)"
fi

# 2) Manifest count vs disk count
mapfile -t manifest_paths < <(
  python3 - "$MANIFEST_PATH" <<'PY'
import pathlib
import sys
import yaml

manifest_path = sys.argv[1] if len(sys.argv) > 1 else '.deadf/manifest.yaml'
p = pathlib.Path(manifest_path)
with p.open('r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

for item in data.get('files', []):
    print(item['path'])
PY
)

manifest_count=${#manifest_paths[@]}
actual_count=0
missing=0
for path in "${manifest_paths[@]}"; do
  if [[ -f "$path" ]]; then
    ((actual_count++))
  else
    ((missing++))
  fi
done

if [[ $missing -eq 0 && $manifest_count -eq $actual_count ]]; then
  report_pass "manifest-count"
else
  report_fail "manifest-count (manifest $manifest_count, actual $actual_count, missing $missing)"
fi

# 3) Spot-check 3 random hashes
mapfile -t manifest_hashes < <(
  python3 - "$MANIFEST_PATH" <<'PY'
import pathlib
import sys
import yaml

manifest_path = sys.argv[1] if len(sys.argv) > 1 else '.deadf/manifest.yaml'
p = pathlib.Path(manifest_path)
with p.open('r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

for item in data.get('files', []):
    print(f"{item['path']}\t{item['sha256']}")
PY
)

sample_count=3
if [[ ${#manifest_hashes[@]} -lt $sample_count ]]; then
  sample_count=${#manifest_hashes[@]}
fi

mapfile -t sample_hashes < <(printf '%s\n' "${manifest_hashes[@]}" | shuf -n "$sample_count")

for entry in "${sample_hashes[@]}"; do
  path=${entry%%$'\t'*}
  expected=${entry#*$'\t'}
  if [[ ! -f "$path" ]]; then
    report_fail "hash $path (missing file)"
    continue
  fi
  actual=$(sha256sum "$path" | awk '{print $1}')
  if [[ "$actual" == "$expected" ]]; then
    report_pass "hash $path"
  else
    report_fail "hash $path (mismatch)"
  fi
done

echo "Summary: $passed passed, $failed failed, $total total"
if [[ $failed -ne 0 ]]; then
  exit 1
fi
