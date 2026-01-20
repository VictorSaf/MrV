from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

class OptimistAgent:
    """Generates ambitious, creative plans"""

    def __init__(self, use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.8)
            self.prompt = ChatPromptTemplate.from_messages([
                ("system", "You are an optimistic strategist. Propose ambitious plans that maximize opportunity and innovation. Ignore constraints temporarily."),
                ("user", "{input}")
            ])
        else:
            self.llm = None
            self.prompt = None

    async def plan(self, state: dict) -> str:
        if self.use_llm and self.llm:
            chain = self.prompt | self.llm
            response = await chain.ainvoke({"input": str(state)})
            return response.content
        else:
            return "Optimist view: Launch boldly with maximum features and market impact. Focus on innovation and first-mover advantage."
