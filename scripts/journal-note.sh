#!/usr/bin/env bash
set -euo pipefail

MSG=${1:-}
if [[ -z "${MSG}" ]]; then
  echo "Usage: $0 \"message\"" >&2
  exit 1
fi

DATE=$(date +%F)
FILE="docs/journal/${DATE}.md"

mkdir -p docs/journal
if [[ ! -f "$FILE" ]]; then
  echo -e "## ${DATE}\n" > "$FILE"
fi

echo "- ${MSG}" >> "$FILE"
echo "Appended to $FILE"

