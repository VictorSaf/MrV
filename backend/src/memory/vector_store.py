from typing import List, Dict, Any, Optional
import uuid

class EpisodicMemory:
    """Vector-based episodic memory for conversation history

    Uses in-memory storage for testing. In production, would use
    Chroma or another vector database with proper embeddings.
    """

    def __init__(self, collection_name: str = "rpd_episodes", use_memory: bool = True):
        self.collection_name = collection_name
        self.use_memory = use_memory

        # In-memory storage for testing
        self.documents: List[Dict[str, Any]] = []

    async def store(self, content: str, metadata: Optional[Dict] = None):
        """Store episodic memory"""
        doc = {
            "id": str(uuid.uuid4()),
            "content": content,
            "metadata": metadata or {}
        }
        self.documents.append(doc)

    async def retrieve(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Retrieve similar episodes

        For testing, does simple keyword matching.
        In production, would use vector similarity search.
        """
        # Simple keyword-based retrieval for testing
        query_words = set(query.lower().split())

        scored_docs = []
        for doc in self.documents:
            content_words = set(doc["content"].lower().split())
            # Calculate simple overlap score
            overlap = len(query_words & content_words)
            if overlap > 0:
                scored_docs.append((overlap, doc))

        # Sort by score descending
        scored_docs.sort(key=lambda x: x[0], reverse=True)

        # Return top k documents
        return [
            {"content": doc["content"], "metadata": doc["metadata"]}
            for _, doc in scored_docs[:k]
        ]
