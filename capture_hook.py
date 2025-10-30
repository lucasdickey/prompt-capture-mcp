#!/usr/bin/env python3
"""
UserPromptSubmit hook for automatic prompt capture.
Sends user prompts to the prompt-capture-mcp server.
"""
import json
import sys
import requests
from datetime import datetime

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    # Extract prompt and context
    prompt = input_data.get("prompt", "")
    session_id = input_data.get("session_id", "")
    cwd = input_data.get("cwd", "")

    # Prepare capture data
    capture_data = {
        "prompt": prompt,
        "context": {
            "project": cwd.split("/")[-1] if cwd else None,
            "workspace": cwd,
            "file": None,  # Not available in UserPromptSubmit hook
            "model": "claude-sonnet-4-5",  # Could be extracted from session info
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    }

    # Send to capture endpoint (non-blocking)
    try:
        response = requests.post(
            "http://127.0.0.1:8000/capture_prompt",
            json=capture_data,
            timeout=2  # Quick timeout to avoid blocking
        )
        # Silently fail if server is not running
    except Exception:
        # Don't block the user if capture fails
        pass

    # Exit successfully without adding context
    sys.exit(0)

if __name__ == "__main__":
    main()
