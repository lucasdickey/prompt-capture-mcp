#!/bin/bash

# Prompt Capture MCP - Installation Script
# This script automates the installation of the Prompt Capture MCP server for Claude Code

set -e  # Exit on error

echo "==================================="
echo "Prompt Capture MCP - Installation"
echo "==================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default installation directory
INSTALL_DIR="$HOME/Tools/prompt-capture-mcp"

# Ask user for installation directory
echo "Where would you like to install the MCP server?"
echo "Default: $INSTALL_DIR"
read -p "Press Enter to use default, or type a custom path: " custom_dir

if [ -n "$custom_dir" ]; then
    INSTALL_DIR="${custom_dir/#\~/$HOME}"
fi

echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""

# Create installation directory
echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy files
echo "Copying server files..."
cp "$SCRIPT_DIR/main.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/capture_hook.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/manifest.json" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/config/start.sh" "$INSTALL_DIR/"

# Copy .claude directory with slash commands
if [ -d "$SCRIPT_DIR/.claude" ]; then
    echo "Installing slash commands..."
    cp -r "$SCRIPT_DIR/.claude" "$INSTALL_DIR/"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/start.sh"
chmod +x "$INSTALL_DIR/capture_hook.py"

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install -r "$SCRIPT_DIR/requirements.txt"
elif command -v pip &> /dev/null; then
    pip install -r "$SCRIPT_DIR/requirements.txt"
else
    echo "Warning: pip not found. Please install dependencies manually:"
    echo "  pip install -r requirements.txt"
fi

# Configure Claude Code MCP
echo ""
echo "Configuring Claude Code..."
CLAUDE_CONFIG_DIR="$HOME/.anthropic/config"
CLAUDE_MCP_CONFIG="$CLAUDE_CONFIG_DIR/mcp.json"

mkdir -p "$CLAUDE_CONFIG_DIR"

# Check if mcp.json exists
if [ -f "$CLAUDE_MCP_CONFIG" ]; then
    echo "Warning: $CLAUDE_MCP_CONFIG already exists."
    echo "Please manually merge the following configuration:"
    echo ""
    cat <<EOF
{
  "tools": {
    "prompt-capture": {
      "type": "local",
      "path": "$INSTALL_DIR/manifest.json"
    }
  },
  "onLaunch": [
    {
      "command": "./start.sh",
      "cwd": "$INSTALL_DIR"
    }
  ]
}
EOF
else
    # Create new mcp.json
    cat > "$CLAUDE_MCP_CONFIG" <<EOF
{
  "tools": {
    "prompt-capture": {
      "type": "local",
      "path": "$INSTALL_DIR/manifest.json"
    }
  },
  "onLaunch": [
    {
      "command": "./start.sh",
      "cwd": "$INSTALL_DIR"
    }
  ]
}
EOF
    echo "Created $CLAUDE_MCP_CONFIG"
fi

# Configure Claude Code hooks
echo ""
echo "Configuring UserPromptSubmit hook..."
CLAUDE_SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
    echo "Warning: $CLAUDE_SETTINGS already exists."
    echo "Please manually add the following to your hooks configuration:"
    echo ""
    cat <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/capture_hook.py",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF
else
    # Create new settings.json
    cat > "$CLAUDE_SETTINGS" <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/capture_hook.py",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF
    echo "Created $CLAUDE_SETTINGS"
fi

# Optional: macOS LaunchAgent setup
echo ""
read -p "Would you like to set up auto-start at system boot (macOS only)? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    PLIST_FILE="$HOME/Library/LaunchAgents/com.promptcapture.mcp.plist"

    # Update plist with actual installation path
    sed "s|/Users/YOURNAME/Tools/prompt-capture-mcp|$INSTALL_DIR|g" "$SCRIPT_DIR/config/com.promptcapture.mcp.plist" > "$PLIST_FILE"

    launchctl load "$PLIST_FILE"
    echo "LaunchAgent installed and loaded."
fi

# Test the installation
echo ""
echo "Testing installation..."
cd "$INSTALL_DIR"
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000 &
SERVER_PID=$!

sleep 2

if curl -s http://127.0.0.1:8000/health | grep -q "healthy"; then
    echo "✅ Server is healthy!"
else
    echo "❌ Server health check failed"
fi

kill $SERVER_PID 2>/dev/null || true

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code"
echo "2. The MCP server will start automatically"
echo "3. Your prompts will be logged to PROMPTS_INPUT_LOG.md in each repository"
echo "4. Use '/prompt-history' in Claude Code to view your captured prompts"
echo "5. Add 'PROMPTS_INPUT_LOG.md' to your .gitignore files"
echo ""
echo "To manually start the server:"
echo "  cd $INSTALL_DIR && ./start.sh"
echo ""
