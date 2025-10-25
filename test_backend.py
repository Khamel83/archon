#!/usr/bin/env python3
"""
Simple health check server for testing - bypasses database dependencies
"""
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Archon Test Server")

@app.get("/")
async def root():
    return {"status": "ok", "message": "Archon test server running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "test-backend"}

@app.get("/api/health")
async def api_health():
    return await health()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8181)