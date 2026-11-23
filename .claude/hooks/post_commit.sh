#!/bin/bash
# Hook: runs after every Bash tool call.
# If the command was a git commit or git merge, reminds Claude to update docs.

input=$(cat)

command=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

if echo "$command" | grep -qE "git merge"; then
    echo "HOOK — git merge detectado."
    echo "Actualiza progress.txt y CLAUDE.md con los cambios del branch mergeado."
fi
