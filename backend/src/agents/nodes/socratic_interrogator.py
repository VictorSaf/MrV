from typing import List
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field
from ..state import AgentState

class ClarifyingQuestions(BaseModel):
    questions: List[str] = Field(description="List of clarifying questions")
    reasoning: str = Field(description="Why these questions matter")

class SocraticInterrogator:
    """
    Generates clarifying questions using Socratic method to reduce ambiguity.
    Focuses on:
    - Domain identification
    - Objective clarification
    - Constraint discovery
    - Success criteria definition
    """

    def __init__(self, model: str = "claude-3-5-sonnet-20241022", use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model=model, temperature=0.7)
            self.parser = JsonOutputParser(pydantic_object=ClarifyingQuestions)

            self.prompt = ChatPromptTemplate.from_messages([
                ("system", """You are a Socratic questioner helping users clarify vague project goals.

Generate 2-4 essential questions that will:
1. Identify the specific domain/industry
2. Clarify the primary objective (cost, speed, quality, resilience?)
3. Discover constraints (budget, time, resources)
4. Define success metrics

Use open-ended questions. Avoid yes/no questions.
Be concise and focused.

{format_instructions}
"""),
                ("user", "User input: {input}\n\nAmbiguity score: {ambiguity_score}")
            ])
        else:
            self.llm = None
            self.parser = None
            self.prompt = None

    async def generate_questions(self, state: AgentState) -> AgentState:
        """Generate clarifying questions based on ambiguous input"""

        if self.use_llm and self.llm:
            chain = self.prompt | self.llm | self.parser

            result = await chain.ainvoke({
                "input": state.user_input,
                "ambiguity_score": state.ambiguity_score,
                "format_instructions": self.parser.get_format_instructions()
            })

            questions = result["questions"]
            reasoning = result["reasoning"]
        else:
            # Generate simple hardcoded questions for testing
            questions = [
                "What is the primary objective - reducing cost, improving speed, or enhancing quality?",
                "What are your key constraints in terms of budget, timeline, and resources?",
                "How will you measure success for this project?"
            ]
            reasoning = "These questions help clarify goals, constraints, and success criteria"

        # Add to conversation history
        state.conversation_history.append({
            "role": "assistant",
            "type": "clarification",
            "questions": questions,
            "reasoning": reasoning
        })

        return state
