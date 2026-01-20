from typing import List, Set, Optional
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from ..state import AgentState

class AmbiguityScanner:
    """
    Analyzes user input for ambiguity and entropy.
    Calculates ambiguity score based on:
    - Vague terms (e.g., "fix", "improve", "optimize")
    - Missing context (domain, constraints, objectives)
    - Undefined metrics
    """

    VAGUE_TERMS: Set[str] = {
        "fix", "improve", "optimize", "better", "help", "manage",
        "handle", "deal with", "work on", "something", "stuff", "business"
    }

    def __init__(self, model: str = "claude-3-5-sonnet-20241022", use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model=model, temperature=0.3)
            self.prompt = ChatPromptTemplate.from_messages([
                ("system", """You are an ambiguity detection system. Analyze user input and identify:
1. Vague terms lacking specificity
2. Missing domain context
3. Undefined objectives or constraints
4. Unclear success metrics

Return a JSON with:
- ambiguity_factors: list of identified ambiguities
- missing_context: list of missing information
- clarity_score: 0-1 (0=totally ambiguous, 1=crystal clear)
"""),
                ("user", "{input}")
            ])
        else:
            self.llm = None
            self.prompt = None

    async def analyze(self, state: AgentState) -> AgentState:
        """Analyze input and calculate ambiguity score"""

        # Lexical analysis
        lexical_score = self._calculate_lexical_ambiguity(state.user_input)

        # LLM-based semantic analysis (if enabled)
        if self.use_llm and self.llm:
            chain = self.prompt | self.llm
            response = await chain.ainvoke({"input": state.user_input})
            content = response.content
        else:
            content = "Lexical analysis only"

        # Use only lexical score if LLM is disabled
        ambiguity_score = lexical_score

        # Update state
        state.ambiguity_score = ambiguity_score
        state.conversation_history.append({
            "role": "system",
            "analysis": f"Ambiguity detected: {ambiguity_score:.2f}",
            "content": content
        })

        return state

    def _calculate_lexical_ambiguity(self, text: str) -> float:
        """Calculate ambiguity based on word analysis"""
        words = text.lower().split()
        vague_count = sum(1 for word in words if word in self.VAGUE_TERMS)

        # High vagueness = high ambiguity
        if len(words) == 0:
            return 1.0

        vague_ratio = vague_count / len(words)

        # Short input = higher ambiguity
        length_penalty = max(0, 1 - len(words) / 20)

        return min(1.0, vague_ratio * 2 + length_penalty * 0.5)
