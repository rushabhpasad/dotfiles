#!/usr/bin/env bash
# Injects matching stack-rule files into the session as additionalContext.
# Files live at ~/.claude/stack-rules/<name>.md
# Override auto-detect by creating $CLAUDE_PROJECT_DIR/.claude/stacks
# (comma- or newline-separated stack names, '#' for comments).

set -euo pipefail

STACK_DIR="$HOME/.claude/stack-rules"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OVERRIDE_FILE="$PROJECT_DIR/.claude/stacks"

declare -A STACKS=()
add() { STACKS["$1"]=1; }

if [[ -f "$OVERRIDE_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//,/ }"
    for name in $line; do
      name="$(echo "$name" | xargs)"
      [[ -n "$name" ]] && add "$name"
    done
  done < "$OVERRIDE_FILE"
else
  pkg="$PROJECT_DIR/package.json"
  if [[ -f "$pkg" ]]; then
    add "nodejs"
    grep -qE '"next"[[:space:]]*:' "$pkg" 2>/dev/null && add "nextjs-react" || true
    grep -qE '"(vue|nuxt|@nuxt/kit)"[[:space:]]*:' "$pkg" 2>/dev/null && add "vuejs" || true
    grep -qE '"(mongoose|mongodb)"[[:space:]]*:' "$pkg" 2>/dev/null && add "mongodb" || true
  fi

  for f in pyproject.toml requirements.txt setup.py Pipfile; do
    if [[ -f "$PROJECT_DIR/$f" ]]; then
      add "python"
      grep -qiE "pymongo|motor|beanie" "$PROJECT_DIR/$f" 2>/dev/null && add "mongodb" || true
    fi
  done

  for f in pom.xml build.gradle build.gradle.kts settings.gradle settings.gradle.kts; do
    if [[ -f "$PROJECT_DIR/$f" ]]; then
      add "java"
      grep -qiE "spring-data-mongodb|mongo-java-driver|mongodb-driver" "$PROJECT_DIR/$f" 2>/dev/null && add "mongodb" || true
    fi
  done
fi

context=""
loaded=()
for name in "${!STACKS[@]}"; do
  file="$STACK_DIR/$name.md"
  if [[ -f "$file" ]]; then
    loaded+=("$name")
    context+="Contents of $file (stack-specific rules, auto-loaded by detect-stack hook):"$'\n\n'
    context+="$(cat "$file")"$'\n\n---\n\n'
  fi
done

if [[ -z "$context" ]]; then
  printf '{"continue":true,"suppressOutput":true}\n'
  exit 0
fi

header="Stack rules loaded: ${loaded[*]}"$'\n\n'
context="$header$context"

printf '%s' "$context" | python3 -c '
import json, sys
ctx = sys.stdin.read()
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ctx
  },
  "suppressOutput": True
}))
'
