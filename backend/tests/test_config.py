import pytest
from src.core.config import AppConfig

def test_config_loads_environment():
    config = AppConfig()
    assert config.langchain_api_key is not None
    assert config.claude_api_key is not None
    assert config.gemini_api_key is not None
