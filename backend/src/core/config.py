from pydantic_settings import BaseSettings
from typing import Optional

class AppConfig(BaseSettings):
    langchain_api_key: str
    claude_api_key: str
    gemini_api_key: str
    openai_api_key: Optional[str] = None
    neo4j_uri: str = "bolt://localhost:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: str

    class Config:
        env_file = ".env"
        case_sensitive = False
