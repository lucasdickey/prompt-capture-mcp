from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import os

app = FastAPI(title="Prompt Capture MCP")

LOG_FILENAME = "PROMPTS_INPUT_LOG.md"


class Context(BaseModel):
    project: str | None = None
    workspace: str | None = None
    file: str | None = None
    model: str | None = None


class PromptData(BaseModel):
    prompt: str
    context: Context | None = None


@app.post("/capture_prompt")
async def capture_prompt(data: PromptData):
    # Determine log file location based on workspace
    workspace = getattr(data.context, 'workspace', None) if data.context else None

    if workspace and os.path.isdir(workspace):
        # Write to the workspace directory (project-specific)
        log_file = os.path.join(workspace, LOG_FILENAME)
    else:
        # Fallback to current directory if no workspace provided
        log_file = LOG_FILENAME

    entry = (
        f"---\n"
        f"timestamp: {datetime.utcnow().isoformat()}Z\n"
        f"project: {getattr(data.context, 'project', '')}\n"
        f"workspace: {workspace or ''}\n"
        f"file: {getattr(data.context, 'file', '')}\n"
        f"model: {getattr(data.context, 'model', '')}\n"
        f"---\n"
        f"**Prompt:**\n{data.prompt}\n\n"
    )

    with open(log_file, "a", encoding="utf-8") as f:
        f.write(entry)
    return {"status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy"}
