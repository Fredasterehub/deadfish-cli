#!/bin/bash
# Updates the Recent Changes section in README.md with latest feat/fix commits
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Generate changelog table from git log (feat/fix only)
CHANGELOG=$(git log --oneline --format="%h %s" \
  | grep -E "^[a-f0-9]+ (feat|fix)" \
  | head -10 \
  | while IFS= read -r line; do
      hash=$(echo "$line" | cut -d' ' -f1)
      msg=$(echo "$line" | cut -d' ' -f2-)
      # Bold the type prefix
      msg=$(echo "$msg" | sed 's/^\(feat[^:]*:\)/**\1**/' | sed 's/^\(fix[^:]*:\)/**\1**/')
      echo "| \`$hash\` | $msg |"
    done)

# Replace between markers
awk '
  /<!-- AUTO-GENERATED:/ { print; found=1; next }
  /<!-- END AUTO-GENERATED -->/ { 
    print ""
    print "| Commit | Change |"
    print "|--------|--------|"
    while ((getline line < "/dev/stdin") > 0) print line
    print ""
    found=0
  }
  !found { print }
' README.md <<< "$CHANGELOG" > README.tmp

mv README.tmp README.md
echo "✅ README.md changelog updated"
