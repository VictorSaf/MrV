from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

class SynthesizerAgent:
    """Combines perspectives into balanced plan"""

    def __init__(self, use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.5)
            self.prompt = ChatPromptTemplate.from_messages([
                ("system", "You synthesize diverse viewpoints into a balanced, executable plan. Balance ambition with pragmatism."),
                ("user", """Optimist view: {optimist}

Pessimist view: {pessimist}

Historian view: {historian}

Create synthesis:""")
            ])
        else:
            self.llm = None
            self.prompt = None

    async def synthesize(self, optimist: str, pessimist: str, historian: str) -> str:
        if self.use_llm and self.llm:
            chain = self.prompt | self.llm
            response = await chain.ainvoke({
                "optimist": optimist,
                "pessimist": pessimist,
                "historian": historian
            })
            return response.content
        else:
            return "Synthesis: Launch in 2 months with phased rollout. MVP with core features first, then iterate. Build in buffer time for quality assurance."
