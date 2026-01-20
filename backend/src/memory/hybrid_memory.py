from typing import List, Dict, Any, Optional
from .vector_store import EpisodicMemory
from .graph_store import TemporalKnowledgeGraph

class HybridMemory:
    """
    Hybrid memory system combining:
    - Episodic memory (vector DB) for conversation/linguistic nuance
    - Semantic memory (knowledge graph) for structured relationships
    """

    def __init__(self):
        self.episodic = EpisodicMemory()
        self.semantic = TemporalKnowledgeGraph()

    async def initialize(self):
        """Initialize both memory systems"""
        await self.semantic.connect()

    # Episodic operations
    async def store_episodic(self, content: str, metadata: Optional[Dict] = None):
        """Store conversational memory"""
        await self.episodic.store(content, metadata)

    async def retrieve_episodic(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Retrieve similar conversations"""
        return await self.episodic.retrieve(query, k)

    # Semantic operations
    async def store_semantic_entity(self, entity_type: str, properties: Dict) -> Dict:
        """Store structured entity"""
        return await self.semantic.create_entity(entity_type, properties)

    async def store_semantic_relationship(
        self,
        from_entity: Dict,
        rel_type: str,
        to_entity: Dict,
        properties: Optional[Dict] = None
    ) -> Dict:
        """Store structured relationship"""
        return await self.semantic.create_relationship(
            from_entity, rel_type, to_entity, properties
        )

    async def get_causal_chain(self, entity_id: str) -> List[Dict]:
        """Get dependency chain for entity"""
        return await self.semantic.query_dependencies(entity_id)

    async def close(self):
        """Cleanup connections"""
        await self.semantic.close()
