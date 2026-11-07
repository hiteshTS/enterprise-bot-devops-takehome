import os
import socket
from pathlib import Path
from fastapi import FastAPI

app = FastAPI()
CONFIG_DIR = Path("/etc/demo-config")
CONFIG_FILES = {"APP_NAME": "app_name", "VERSION": "version"}

def get_config(name: str, default: str) -> str:
    config_file = CONFIG_DIR / CONFIG_FILES.get(name, name)
    if config_file.is_file():
        return config_file.read_text().strip()
    return os.getenv(name, default)

@app.get("/")
def root():
    return {
        "app": get_config("APP_NAME", "enterprise-bot"),
        "version": get_config("VERSION", "1.0.0"),
        "pod": socket.gethostname()
    }

@app.get("/healthz")
def health():
    return {"status": "healthy"}