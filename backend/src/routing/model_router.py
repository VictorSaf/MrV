from enum import Enum
from typing import Dict, Optional

class TaskType(str, Enum):
    AMBIGUITY_SCAN = "ambiguity_scan"
    SOCRATIC_INTERROGATION = "socratic_interrogation"
    ONTOLOGY_GENERATION = "ontology_generation"
    KPI_FABRICATION = "kpi_fabrication"
    COUNCIL_DELIBERATION = "council_deliberation"
    STRATEGY_PLANNING = "strategy_planning"

class ModelRouter:
    """
    Intelligent model router that selects optimal LLM for each task.

    Selection criteria:
    - Task complexity
    - Cost constraints
    - Latency requirements
    - Model capabilities
    """

    # Model costs per 1M tokens (input/output average)
    MODEL_COSTS = {
        "claude-3-5-sonnet-20241022": 0.015,  # $15/1M tokens
        "claude-3-haiku-20240307": 0.001,      # $1/1M tokens
        "gpt-4o": 0.025,                        # $25/1M tokens
        "gpt-4o-mini": 0.0015,                  # $1.5/1M tokens
        "gemini-2.0-flash-exp": 0.0,            # Free tier
    }

    # Model capabilities by task type
    TASK_MODELS = {
        TaskType.AMBIGUITY_SCAN: {
            "preferred": ["claude-3-haiku-20240307", "gpt-4o-mini"],
            "fallback": ["claude-3-5-sonnet-20241022"]
        },
        TaskType.SOCRATIC_INTERROGATION: {
            "preferred": ["claude-3-5-sonnet-20241022", "gpt-4o"],
            "fallback": ["gpt-4o-mini"]
        },
        TaskType.ONTOLOGY_GENERATION: {
            "preferred": ["claude-3-5-sonnet-20241022", "gemini-2.0-flash-exp"],
            "fallback": ["gpt-4o"]
        },
        TaskType.KPI_FABRICATION: {
            "preferred": ["claude-3-5-sonnet-20241022"],
            "fallback": ["gpt-4o"]
        },
        TaskType.COUNCIL_DELIBERATION: {
            "preferred": ["claude-3-5-sonnet-20241022", "gpt-4o"],
            "fallback": ["claude-3-haiku-20240307"]
        },
        TaskType.STRATEGY_PLANNING: {
            "preferred": ["claude-3-5-sonnet-20241022", "gpt-4o"],
            "fallback": ["gemini-2.0-flash-exp"]
        }
    }

    def __init__(self, cost_threshold: Optional[float] = None):
        """
        Initialize router with optional cost threshold.

        Args:
            cost_threshold: Max acceptable cost per 1M tokens
        """
        self.cost_threshold = cost_threshold

    def select_model(
        self,
        task_type: TaskType,
        complexity_score: float = 0.5,
        latency_sensitive: bool = False
    ) -> str:
        """
        Select optimal model for task.

        Args:
            task_type: Type of task to perform
            complexity_score: 0-1 score indicating task complexity
            latency_sensitive: Whether task requires fast response

        Returns:
            Model identifier string
        """
        candidates = self.TASK_MODELS.get(task_type, {})
        preferred = candidates.get("preferred", [])
        fallback = candidates.get("fallback", [])

        # Filter by cost if threshold set
        if self.cost_threshold:
            preferred = [m for m in preferred if self.MODEL_COSTS.get(m, 0) <= self.cost_threshold]

        # Select based on complexity
        if complexity_score > 0.8:
            # High complexity - use powerful model
            model = preferred[0] if preferred else fallback[0]
        elif complexity_score < 0.3:
            # Low complexity - use cheaper/faster model
            # Prefer cheaper models in preferred list
            cheap_models = sorted(preferred, key=lambda m: self.MODEL_COSTS.get(m, 0))
            model = cheap_models[0] if cheap_models else fallback[0]
        else:
            # Medium complexity - balanced choice
            model = preferred[0] if preferred else fallback[0]

        return model

    def estimate_cost(
        self,
        model: str,
        input_tokens: int,
        output_tokens: int
    ) -> float:
        """
        Estimate cost for model usage.

        Args:
            model: Model identifier
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens

        Returns:
            Estimated cost in dollars
        """
        cost_per_million = self.MODEL_COSTS.get(model, 0.01)
        total_tokens = input_tokens + output_tokens
        return (total_tokens / 1_000_000) * cost_per_million
