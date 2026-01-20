from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

class PessimistAgent:
    """Identifies risks and failure modes"""

    def __init__(self, use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.3)
            self.prompt = ChatPromptTemplate.from_messages([
                ("system", "You are a risk analyst. Identify all possible failure modes, resource gaps, and worst-case scenarios. Be thorough and skeptical."),
                ("user", "{input}")
            ])
        else:
            self.llm = None
            self.prompt = None

    async def critique(self, state: dict, optimist_plan: str) -> str:
        if self.use_llm and self.llm:
            chain = self.prompt | self.llm
            response = await chain.ainvoke({
                "input": f"State: {state}\n\nProposed Plan: {optimist_plan}"
            })
            return response.content
        else:
            return "Pessimist view: 2 months is very aggressive. Risk of technical debt, quality issues, and team burnout. Need contingency planning."
