# RPD Ganis GIU Backend

Emergent Cognitive Architecture for tabula rasa project management.

## Architecture Overview

### Core Components

1. **Cognitive Graph** (`src/agents/`)
   - LangGraph cyclic state machine
   - 6 node types: Ambiguity Scanner → Socratic Interrogator → Ontology Architect → Strategy Motor → Executor → Reflector

2. **Memory Systems** (`src/memory/`)
   - **Episodic Memory**: Vector-based conversation storage
   - **Semantic Memory**: Neo4j temporal knowledge graph
   - Hybrid retrieval for linguistic nuance + causal reasoning

3. **AI Nodes** (`src/agents/nodes/`, `src/agents/council/`)
   - **Ambiguity Scanner**: Entropy analysis of user input
   - **Socratic Interrogator**: Clarifying question generation
   - **Ontology Architect**: Dynamic schema induction
   - **KPI Fabricator**: Qualitative → quantitative metric mapping
   - **Council System**: Multi-agent deliberation (Optimist, Pessimist, Historian, Synthesizer)

4. **Model Router** (`src/routing/`)
   - Intelligent LLM selection per task
   - Cost-based optimization
   - Complexity-aware routing

5. **API** (`src/api/`)
   - FastAPI RESTful service
   - Session management
   - CORS-enabled for Swift frontend

## Setup

### Prerequisites
- Python 3.10+
- Docker (for Neo4j)

### Installation

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys
```

### Environment Variables

```bash
LANGCHAIN_API_KEY=your_key
CLAUDE_API_KEY=your_key
GEMINI_API_KEY=your_key
OPENAI_API_KEY=your_key
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_password
```

## Running Services

### Start Neo4j (Optional - uses in-memory fallback if unavailable)

```bash
docker-compose up -d
```

### Start Backend Server

```bash
python run.py
```

Server starts on `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## Testing

Run all tests:
```bash
PYTHONPATH=. pytest tests/ -v
```

Run specific test:
```bash
PYTHONPATH=. pytest tests/test_ambiguity_scanner.py -v
```

## API Endpoints

### POST `/api/agent/process`

Process user input through cognitive graph.

**Request:**
```json
{
  "input": "Help me optimize my supply chain",
  "session_id": "unique-session-id"
}
```

**Response:**
```json
{
  "session_id": "unique-session-id",
  "ambiguity_score": 0.85,
  "questions": [
    "What is your primary objective - cost, speed, or quality?",
    "What are your budget and timeline constraints?"
  ],
  "ontology": null,
  "kpis": null,
  "message": "Input processed successfully"
}
```

### GET `/health`

Health check endpoint.

## Test Results

✅ **14/14 tests passing**
- 2 Ambiguity Scanner tests
- 1 API endpoint test
- 1 Config test
- 1 Council deliberation test
- 1 Graph state test
- 1 Graph store test
- 2 Hybrid memory tests
- 1 KPI fabrication test
- 2 Model router tests
- 1 Ontology architect test
- 1 Socratic interrogator test

## Architecture Patterns

### Schema-Last Ontology
Domain schemas emerge from conversation, not predefined templates.

### Multi-Agent Council
Optimist proposes → Pessimist critiques → Historian verifies → Synthesizer combines.

### Intelligent Routing
Tasks automatically route to optimal LLM based on complexity and cost.

### Temporal Knowledge
Relationships track validity windows for time-aware reasoning.

## Development

### Adding a New Node

1. Create node in `src/agents/nodes/`
2. Add to state machine in `src/agents/graph.py`
3. Write test in `tests/`
4. Update router if needed

### Modifying Memory

- Episodic: `src/memory/vector_store.py`
- Semantic: `src/memory/graph_store.py`
- Combined: `src/memory/hybrid_memory.py`

## Production Deployment

1. Use proper vector database (Chroma/Pinecone) instead of in-memory
2. Setup Redis for session storage
3. Configure Neo4j cluster
4. Add authentication middleware
5. Setup monitoring (Prometheus/Grafana)
6. Use gunicorn/uvicorn workers for scaling

## License

MIT
