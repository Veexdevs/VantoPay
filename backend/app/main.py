"""FastAPI application entrypoint for the VantoPay backend."""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config import settings
from .db import init_db
from .routers import (
    accounts,
    admin,
    auth,
    integrations,
    pix,
    sessions,
    transfers,
)
from .security import enforce_rate_limit


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.database_url.startswith("sqlite"):
        init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="API de serviços financeiros do VantoPay.",
    lifespan=lifespan,
)

# Origin allowlist for the deployed web app (Vercel) and local dev.
_origins = [
    o.strip()
    for o in (settings.public_origin or "").split(",")
    if o.strip()
]
if not _origins:
    _origins = ["http://localhost:8000", "http://localhost:3000", "http://localhost:5500"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_origin_regex=r"https://[a-z0-9-]+\.vercel\.app",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    try:
        enforce_rate_limit(request)
    except HTTPException as exc:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return await call_next(request)


@app.get("/health", tags=["system"])
def health() -> dict:
    return {
        "status": "ok",
        "env": settings.env,
        "integrations": settings.integrations_configured(),
    }


app.include_router(auth.router)
app.include_router(accounts.router)
app.include_router(transfers.router)
app.include_router(pix.router)
app.include_router(sessions.router)
app.include_router(admin.router)
app.include_router(integrations.router)
