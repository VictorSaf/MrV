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
# Lock to protect session access and prevent race conditions
sessions_lock = asyncio.Lock()

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

    # Get or create session (protected by lock to prevent race conditions)
    async with sessions_lock:
        if request.session_id not in sessions:
            sessions[request.session_id] = AgentState(
                current_node=StateNode.AMBIGUITY_SCANNER,
                user_input=request.input,
                conversation_history=[]
            )
        else:
            state = sessions[request.session_id]
            state.user_input = request.input

    # Run through graph
    graph = CognitiveGraph()
    memory = HybridMemory()
    await memory.initialize()

    try:
        # Process through nodes (read-only, safe outside lock)
        async with sessions_lock:
            state = sessions[request.session_id]

        # Run ambiguity scanner
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

        # Store updated state (protected by lock)
        async with sessions_lock:
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
