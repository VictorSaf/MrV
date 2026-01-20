from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
import asyncio
from ...agents.graph import CognitiveGraph
from ...agents.state import AgentState, StateNode
from ...memory.hybrid_memory import HybridMemory

router = APIRouter()

# In-memory session storage (use Redis in production)
sessions: Dict[str, AgentState] = {}
# Per-session locks to serialize requests for same session while allowing concurrent sessions
session_locks: Dict[str, asyncio.Lock] = {}
# Global lock only for managing the session_locks dict
_locks_lock = asyncio.Lock()

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

    # Get or create a lock for this specific session
    async with _locks_lock:
        if request.session_id not in session_locks:
            session_locks[request.session_id] = asyncio.Lock()
        session_lock = session_locks[request.session_id]

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
        else:
            state = sessions[request.session_id]
            state.user_input = request.input

        # Run through graph
        graph = CognitiveGraph()
        memory = HybridMemory()
        await memory.initialize()

        try:
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
            await memory.close()
