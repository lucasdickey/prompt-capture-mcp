from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import os

app = FastAPI(title="Prompt Capture MCP")

LOG_FILE = "PROMPTS_INPUT_LOG.md"


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
    os.makedirs(os.path.dirname(LOG_FILE) or ".", exist_ok=True)
    entry = (
        f"---\n"
        f"timestamp: {datetime.utcnow().isoformat()}Z\n"
        f"project: {getattr(data.context, 'project', '')}\n"
        f"workspace: {getattr(data.context, 'workspace', '')}\n"
        f"file: {getattr(data.context, 'file', '')}\n"
        f"model: {getattr(data.context, 'model', '')}\n"
        f"---\n"
        f"**Prompt:**\n{data.prompt}\n\n"
    )
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(entry)
    return {"status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy"}
