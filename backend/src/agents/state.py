from enum import Enum
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

class StateNode(str, Enum):
    AMBIGUITY_SCANNER = "ambiguity_scanner"
    SOCRATIC_INTERROGATOR = "socratic_interrogator"
    ONTOLOGY_ARCHITECT = "ontology_architect"
    STRATEGY_MOTOR = "strategy_motor"
    EXECUTOR = "executor"
    REFLECTOR = "reflector"

class AgentState(BaseModel):
    current_node: StateNode
    user_input: str
    conversation_history: List[Dict[str, str]] = Field(default_factory=list)
    ambiguity_score: float = 0.0
    domain_ontology: Optional[Dict[str, Any]] = None
    project_logic: Optional[Dict[str, Any]] = None
    kpis: Optional[List[Dict[str, Any]]] = None
    error_message: Optional[str] = None
