from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import agent

app = FastAPI(title="Rpd Ganis GIU API")

# CORS for Swift app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(agent.router, prefix="/api/agent", tags=["agent"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "environment": "development"}
