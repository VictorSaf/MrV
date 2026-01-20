from typing import Dict
from ..state import AgentState
from .optimist import OptimistAgent
from .pessimist import PessimistAgent
from .historian import HistorianAgent
from .synthesizer import SynthesizerAgent
from ...memory.hybrid_memory import HybridMemory

class CouncilManager:
    """Orchestrates multi-agent deliberation"""

    def __init__(self, use_llm: bool = True):
        self.memory = HybridMemory()
        self.optimist = OptimistAgent(use_llm=use_llm)
        self.pessimist = PessimistAgent(use_llm=use_llm)
        self.historian = HistorianAgent(self.memory, use_llm=use_llm)
        self.synthesizer = SynthesizerAgent(use_llm=use_llm)

    async def deliberate(self, state: AgentState) -> AgentState:
        """Run council deliberation process"""

        # Initialize memory if not already done
        await self.memory.initialize()

        # 1. Optimist proposes
        optimist_view = await self.optimist.plan(state.dict())

        # 2. Pessimist critiques
        pessimist_view = await self.pessimist.critique(state.dict(), optimist_view)

        # 3. Historian verifies
        historian_view = await self.historian.verify(state.dict())

        # 4. Synthesizer combines
        synthesis = await self.synthesizer.synthesize(
            optimist_view,
            pessimist_view,
            historian_view
        )

        # Store in state
        state.project_logic = {
            "optimist_view": optimist_view,
            "pessimist_view": pessimist_view,
            "historian_view": historian_view,
            "synthesis": synthesis
        }

        return state
