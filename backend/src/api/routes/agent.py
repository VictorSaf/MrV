from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
import asyncio
from datetime import datetime, timedelta
from ...agents.graph import CognitiveGraph
from ...agents.state import AgentState, StateNode
from ...memory.hybrid_memory import HybridMemory

router = APIRouter()

# In-memory session storage (use Redis in production)
sessions: Dict[str, AgentState] = {}
# Session metadata for TTL management
session_metadata: Dict[str, Dict[str, Any]] = {}
# Per-session locks to serialize requests for same session while allowing concurrent sessions
session_locks: Dict[str, asyncio.Lock] = {}
# Global lock for managing session_locks dict
_locks_lock = asyncio.Lock()
# Session TTL (30 minutes)
SESSION_TTL = timedelta(minutes=30)


async def get_or_create_session_lock(session_id: str) -> asyncio.Lock:
    """Get or create a lock for a session, ensuring atomicity."""
    # Keep the lock reference while protected by _locks_lock
    # This prevents the TOCTOU race condition
    async with _locks_lock:
        if session_id not in session_locks:
            session_locks[session_id] = asyncio.Lock()
        # Return the lock while still holding _locks_lock
        # The lock object itself is thread-safe to acquire after this
        return session_locks[session_id]


async def cleanup_expired_sessions():
    """Remove expired sessions and their locks."""
    async with _locks_lock:
        now = datetime.now()
        expired = [
            sid for sid, meta in session_metadata.items()
            if now - meta["last_access"] > SESSION_TTL
        ]
        for sid in expired:
            sessions.pop(sid, None)
            session_locks.pop(sid, None)
            session_metadata.pop(sid, None)

        if expired:
            print(f"🧹 Cleaned up {len(expired)} expired sessions")


class ProcessRequest(BaseModel):
    input: str
    session_id: str


class ProcessResponse(BaseModel):
    session_id: str
    ambiguity_score: Optional[float] = None
    questions: Optional[list] = None
    ontology: Optional[Dict[str, Any]] = None
    kpis: Optional[list] = None
    message: str


@router.post("/process", response_model=ProcessResponse)
async def process_input(request: ProcessRequest):
    """Process user input through cognitive graph"""

    # Periodically cleanup expired sessions (every ~100 requests)
    import random
    if random.random() < 0.01:
        await cleanup_expired_sessions()

    # Get session lock atomically (fixes TOCTOU race condition)
    session_lock = await get_or_create_session_lock(request.session_id)

    # Hold the session-specific lock for the entire operation
    # This serializes requests for the same session while allowing different sessions concurrently
    async with session_lock:
        # Get or create session
        if request.session_id not in sessions:
            state = AgentState(
                current_node=StateNode.AMBIGUITY_SCANNER,
                user_input=request.input,
                conversation_history=[]
            )
            sessions[request.session_id] = state
            session_metadata[request.session_id] = {
                "created": datetime.now(),
                "last_access": datetime.now()
            }
        else:
            state = sessions[request.session_id]
            state.user_input = request.input
            # Update last access time
            session_metadata[request.session_id]["last_access"] = datetime.now()

        # Run through graph
        graph = CognitiveGraph()
        memory = HybridMemory()

        try:
            # Initialize memory inside try block (fixes resource leak)
            await memory.initialize()

            # Run ambiguity scanner (all state mutations protected by session lock)
            from ...agents.nodes.ambiguity_scanner import AmbiguityScanner
            scanner = AmbiguityScanner(use_llm=False)
            state = await scanner.analyze(state)

            # If high ambiguity, run interrogator
            questions = None
            if state.ambiguity_score > 0.7:
                from ...agents.nodes.socratic_interrogator import SocraticInterrogator
                interrogator = SocraticInterrogator(use_llm=False)
                state = await interrogator.generate_questions(state)
                questions = state.conversation_history[-1].get("questions", [])

            # Store updated state
            sessions[request.session_id] = state

            return ProcessResponse(
                session_id=request.session_id,
                ambiguity_score=state.ambiguity_score,
                questions=questions,
                message="Input processed successfully"
            )

        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
        finally:
            # Always close memory connections, even if initialization fails
            await memory.close()
