# Prompt Capture MCP

A lightweight system that automatically captures and logs all prompts you send from Claude Code to a local markdown file. Uses Claude Code's UserPromptSubmit hook for seamless, automatic capture. Perfect for tracking your interactions, building a prompt library, or analyzing your workflow.

## Features

- **Automatic Prompt Logging**: Captures every prompt using Claude Code hooks
- **Non-Intrusive**: Runs in background without affecting your workflow
- **Context Tracking**: Records project, workspace, session ID, and model information
- **Timestamped Entries**: Each prompt is logged with an ISO 8601 timestamp
- **Markdown Format**: Easy-to-read log file that's perfect for documentation
- **Auto-start Integration**: Server launches automatically when Claude Code starts
- **Minimal Overhead**: Lightweight FastAPI server with low resource usage

## Quick Start

### Automated Installation (Recommended)

```bash
git clone <your-repo-url> prompt-capture-mcp
cd prompt-capture-mcp
./install.sh
```

The install script will:
1. Ask for your preferred installation directory (default: `~/Tools/prompt-capture-mcp`)
2. Copy all necessary files
3. Install Python dependencies
4. Configure Claude Code to auto-start the server
5. Optionally set up macOS LaunchAgent for system-wide auto-start
6. Test the installation

Then restart Claude Code and you're ready to go!

### Manual Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url> prompt-capture-mcp
   cd prompt-capture-mcp
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Choose installation directory**
   ```bash
   mkdir -p ~/Tools/prompt-capture-mcp
   cp main.py manifest.json config/start.sh ~/Tools/prompt-capture-mcp/
   chmod +x ~/Tools/prompt-capture-mcp/start.sh
   ```

4. **Configure Claude Code**

   Create or edit `~/.anthropic/config/mcp.json`:
   ```json
   {
     "tools": {
       "prompt-capture": {
         "type": "local",
         "path": "/Users/YOUR_USERNAME/Tools/prompt-capture-mcp/manifest.json"
       }
     },
     "onLaunch": [
       {
         "command": "./start.sh",
         "cwd": "/Users/YOUR_USERNAME/Tools/prompt-capture-mcp"
       }
     ]
   }
   ```

   Replace `YOUR_USERNAME` with your actual username.

5. **Restart Claude Code**

## Usage

Once installed, the MCP server runs automatically in the background. Every prompt you send through Claude Code will be logged to:

```
~/Tools/prompt-capture-mcp/PROMPTS_INPUT_LOG.md
```

### Log Format

Each entry includes:
```markdown
---
timestamp: 2025-10-29T21:59:47.219086Z
project: my-project
workspace: /path/to/workspace
file: src/app.py
model: claude-sonnet-4-5
---
**Prompt:**
Your prompt text here
```

### Manual Server Control

Start the server manually:
```bash
cd ~/Tools/prompt-capture-mcp
./start.sh
```

Or run directly:
```bash
cd ~/Tools/prompt-capture-mcp
python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Stop the server:
```bash
# Find the process
ps aux | grep uvicorn

# Kill it
kill <PID>
```

### Health Check

Test if the server is running:
```bash
curl http://127.0.0.1:8000/health
```

Expected response: `{"status":"healthy"}`

## Optional: System-Wide Auto-Start (macOS)

To have the server start automatically at system boot (not just when Claude Code launches):

1. **Update the plist file** with your installation path in `config/com.promptcapture.mcp.plist`

2. **Install the LaunchAgent**
   ```bash
   cp config/com.promptcapture.mcp.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/com.promptcapture.mcp.plist
   ```

3. **Verify it's running**
   ```bash
   launchctl list | grep promptcapture
   ```

To unload:
```bash
launchctl unload ~/Library/LaunchAgents/com.promptcapture.mcp.plist
```

## Project Structure

```
prompt-capture-mcp/
├── main.py                          # FastAPI server with capture endpoint
├── capture_hook.py                  # UserPromptSubmit hook script
├── manifest.json                    # MCP tool manifest (optional)
├── requirements.txt                 # Python dependencies
├── install.sh                       # Automated installation script
├── config/
│   ├── start.sh                     # Server startup script
│   ├── mcp.json.example             # Claude Code config example
│   └── com.promptcapture.mcp.plist  # macOS LaunchAgent template
└── README.md                        # This file

After installation:
~/.anthropic/config/
├── mcp.json                         # MCP server auto-start config
└── settings.json                    # Hook configuration
```

## How It Works

1. **FastAPI Server**: A FastAPI server runs locally on `http://127.0.0.1:8000`
2. **Auto-start**: The `onLaunch` hook in `mcp.json` starts the server when Claude Code launches
3. **UserPromptSubmit Hook**: Claude Code hook fires every time you submit a prompt
4. **Hook Script**: The `capture_hook.py` script receives prompt data and sends it to the server
5. **API Endpoint**: The server's `/capture_prompt` endpoint receives and logs the prompt
6. **Logging**: Each captured prompt is appended to `PROMPTS_INPUT_LOG.md` with metadata

## API Endpoints

### `POST /capture_prompt`

Captures a prompt and appends it to the log file.

**Request:**
```json
{
  "prompt": "Your prompt text",
  "context": {
    "project": "my-project",
    "workspace": "/path/to/workspace",
    "file": "src/app.py",
    "model": "claude-sonnet-4-5"
  }
}
```

**Response:**
```json
{
  "status": "ok"
}
```

### `GET /health`

Health check endpoint.

**Response:**
```json
{
  "status": "healthy"
}
```

## Troubleshooting

### Server won't start

1. Check if Python 3 is installed: `python3 --version`
2. Verify dependencies: `pip list | grep -E "(fastapi|uvicorn|pydantic)"`
3. Check for port conflicts: `lsof -i :8000`
4. Review logs in the terminal or system console

### Prompts not being logged

1. Verify server is running: `curl http://127.0.0.1:8000/health`
2. Check `~/.anthropic/config/mcp.json` for correct paths
3. Check `~/.anthropic/config/settings.json` has the UserPromptSubmit hook configured
4. Ensure scripts are executable:
   ```bash
   chmod +x ~/Tools/prompt-capture-mcp/start.sh
   chmod +x ~/Tools/prompt-capture-mcp/capture_hook.py
   ```
5. Test the hook manually:
   ```bash
   echo '{"prompt":"test","session_id":"test"}' | ~/Tools/prompt-capture-mcp/capture_hook.py
   ```
6. Restart Claude Code

### Permission errors

```bash
chmod +x ~/Tools/prompt-capture-mcp/start.sh
```

## Requirements

- Python 3.8+
- FastAPI 0.110.0+
- Uvicorn 0.29.0+
- Pydantic 2.0.0+
- Requests 2.31.0+
- Claude Code with hooks support

## Security & Privacy

- **Local Only**: The server only listens on `127.0.0.1` (localhost)
- **No External Connections**: No data is sent outside your machine
- **Plain Text Storage**: Logs are stored as plain markdown files
- **User Control**: You can view, edit, or delete log files anytime

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

Built for use with [Claude Code](https://claude.com/claude-code) by Anthropic.
