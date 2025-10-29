#!/bin/bash
# Simple startup script for Prompt Capture MCP
cd "$(dirname "$0")"
# Optionally activate a virtual environment
if [ -d "venv" ]; then
  source venv/bin/activate
fi
# Launch the FastAPI MCP server
exec python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
