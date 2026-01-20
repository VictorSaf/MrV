from typing import Dict, Any, Optional, List
from datetime import datetime
import uuid

class TemporalKnowledgeGraph:
    """
    Temporal Knowledge Graph using Neo4j + Graphiti.
    Stores project entities with time-aware relationships.

    For testing without Neo4j, uses in-memory storage.
    """

    def __init__(self, config: Optional[Any] = None, use_memory: bool = True):
        self.config = config
        self.use_memory = use_memory

        # In-memory storage for testing
        self.entities: Dict[str, Dict[str, Any]] = {}
        self.relationships: List[Dict[str, Any]] = []
        self.driver = None

    async def connect(self):
        """Initialize connections"""
        if not self.use_memory:
            try:
                from neo4j import AsyncGraphDatabase
                from ..core.config import AppConfig

                if not self.config:
                    self.config = AppConfig()

                self.driver = AsyncGraphDatabase.driver(
                    self.config.neo4j_uri,
                    auth=(self.config.neo4j_user, self.config.neo4j_password)
                )
            except Exception as e:
                # Fall back to in-memory if connection fails
                self.use_memory = True
                print(f"Falling back to in-memory storage: {e}")

    async def create_entity(
        self,
        entity_type: str,
        properties: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new entity node"""

        if self.use_memory:
            # In-memory implementation
            entity_id = str(uuid.uuid4())
            entity = {
                "id": entity_id,
                "type": entity_type,
                "created_at": datetime.now().isoformat(),
                **properties
            }
            self.entities[entity_id] = entity
            return entity
        else:
            # Neo4j implementation
            async with self.driver.session() as session:
                query = f"""
                CREATE (e:{entity_type})
                SET e = $properties
                SET e.created_at = datetime()
                SET e.id = randomUUID()
                RETURN e
                """
                result = await session.run(query, properties=properties)
                record = await result.single()
                return dict(record["e"])

    async def create_relationship(
        self,
        from_entity: Dict[str, Any],
        rel_type: str,
        to_entity: Dict[str, Any],
        properties: Optional[Dict[str, Any]] = None,
        valid_from: Optional[datetime] = None,
        valid_until: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Create temporal relationship between entities"""
        properties = properties or {}
        properties["valid_from"] = (valid_from or datetime.now()).isoformat()
        if valid_until:
            properties["valid_until"] = valid_until.isoformat()

        if self.use_memory:
            # In-memory implementation
            relationship = {
                "type": rel_type,
                "from_id": from_entity["id"],
                "to_id": to_entity["id"],
                **properties
            }
            self.relationships.append(relationship)
            return relationship
        else:
            # Neo4j implementation
            async with self.driver.session() as session:
                query = f"""
                MATCH (from) WHERE from.id = $from_id
                MATCH (to) WHERE to.id = $to_id
                CREATE (from)-[r:{rel_type}]->(to)
                SET r = $properties
                RETURN r
                """
                result = await session.run(
                    query,
                    from_id=from_entity["id"],
                    to_id=to_entity["id"],
                    properties=properties
                )
                record = await result.single()
                return {"type": rel_type, **dict(record["r"])}

    async def query_dependencies(self, entity_id: str) -> list:
        """Find all entities this entity depends on"""

        if self.use_memory:
            # In-memory implementation
            deps = []
            for rel in self.relationships:
                # Look for relationships pointing TO this entity (predecessors/dependencies)
                if rel["to_id"] == entity_id and rel["type"] in ["BLOCKS", "DEPENDS_ON", "PRECEDES"]:
                    from_entity = self.entities.get(rel["from_id"])
                    if from_entity:
                        deps.append((from_entity, rel))
            return deps
        else:
            # Neo4j implementation
            async with self.driver.session() as session:
                query = """
                MATCH (e)-[r:BLOCKS|DEPENDS_ON]->(dep)
                WHERE e.id = $entity_id
                AND (r.valid_until IS NULL OR r.valid_until > datetime())
                RETURN dep, r
                """
                result = await session.run(query, entity_id=entity_id)
                records = await result.values()
                return records

    async def close(self):
        """Close connections"""
        if self.driver:
            await self.driver.close()
