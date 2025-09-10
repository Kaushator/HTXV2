#!/usr/bin/env bash
set -euo pipefail

# Deny patterns: calls that can spend LLM tokens
PATTERNS=(
  "openai[[:space:][:punct:]]"
  "anthropic[[:space:][:punct:]]"
  "vertex[[:space:][:punct:]]ai"
  "aiplatform[[:space:][:punct:]]"
)

fail=0
for pat in "${PATTERNS[@]}"; do
  if rg -n -S -i --glob '!docs/**' --glob '!**/*.md' --glob '!**/*.json' "$pat" >/dev/null 2>&1; then
    echo "Found forbidden LLM usage pattern: $pat" >&2
    rg -n -S -i --glob '!docs/**' --glob '!**/*.md' --glob '!**/*.json' "$pat" || true
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "Blocking: potential LLM token usage detected. Remove or guard before pushing." >&2
  exit 1
fi

echo "OK: no LLM token usage patterns detected."

