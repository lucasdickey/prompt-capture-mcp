---
description: Display the captured prompt history from PROMPTS_INPUT_LOG.md
---

Please read and display the prompt capture log file for this repository. Check these locations in order:

1. `./PROMPTS_INPUT_LOG.md` (current repository directory - most common)
2. Search parent directories if in a subdirectory: `git rev-parse --show-toplevel 2>/dev/null` then check that directory
3. If not found, inform the user

Once you find the file, display its contents. If the file is very long (more than 100 entries), ask the user if they want to see:
- The entire file
- Just the most recent N entries
- Entries from a specific time period
- Filter by specific keywords or date ranges

If the file doesn't exist, let the user know that:
- No prompts have been captured yet in this repository
- They may need to run a command in this repository first
- The prompt-capture-mcp server may not be running (check with `curl http://127.0.0.1:8000/health`)
