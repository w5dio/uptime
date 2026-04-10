#!/bin/bash
set -euo pipefail

CONSTITUTION_URL="https://raw.githubusercontent.com/w5dio/constitution/refs/heads/main/CONSTITUTION.md"

content=$(curl -fsSL "$CONSTITUTION_URL" 2>/dev/null) || {
  echo "Warning: Could not fetch constitution principles from w5dio/constitution." >&2
  exit 0
}

echo "=== PLATFORM CONSTITUTION (START) ==="
echo "Source: $CONSTITUTION_URL"
echo "Injected by: SessionStart hook (.claude/hooks/fetch-constitution.sh)"
echo ""
echo "$content"
echo ""
echo "=== PLATFORM CONSTITUTION (END) ==="
