from typing import Dict, Any, List
from pydantic import BaseModel, Field

class EntitySchema(BaseModel):
    type: str
    properties: Dict[str, Any]
    description: str

class RelationshipSchema(BaseModel):
    from_entity: str
    to_entity: str
    type: str
    properties: Dict[str, Any] = Field(default_factory=dict)

class DomainOntology(BaseModel):
    domain: str
    entities: List[EntitySchema]
    relationships: List[RelationshipSchema]
    logic_rules: List[str] = Field(default_factory=list)
