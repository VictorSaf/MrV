from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

class HistorianAgent:
    """Ensures consistency with past decisions"""

    def __init__(self, memory, use_llm: bool = True):
        self.llm_enabled = use_llm
        self.memory = memory
        if use_llm:
            self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.2)
            self.prompt = ChatPromptTemplate.from_messages([
                ("system", "You verify consistency with past decisions and documentation. Check for contradictions."),
                ("user", "{input}\n\nPast decisions: {history}")
            ])
        else:
            self.llm = None
            self.prompt = None

    async def verify(self, state: dict) -> str:
        if self.llm_enabled and self.llm:
            # Retrieve relevant history
            history = await self.memory.retrieve_episodic(str(state), k=3)
            history_text = "\n".join([h["content"] for h in history])

            chain = self.prompt | self.llm
            response = await chain.ainvoke({
                "input": str(state),
                "history": history_text
            })
            return response.content
        else:
            return "Historian view: No significant conflicts with past decisions. Timeline aligns with previous project estimates."
