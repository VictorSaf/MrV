-- Mr.V Agent Memory System Database Schema
-- Phase 2: MEMORY - Persistence Layer
-- Date: 2026-01-15

-- Projects Table
-- Stores project metadata and configuration
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT CHECK(status IN ('active', 'archived', 'completed')) DEFAULT 'active',
    metadata TEXT,  -- JSON string for extensibility
    color TEXT,     -- Project-specific color theme
    universe_config TEXT  -- JSON for Phase 4 universe settings
);

-- Conversations Table
-- Stores all conversation messages with project context
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_input TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    model_used TEXT NOT NULL,
    response_time REAL,  -- Response time in seconds
    metadata TEXT,  -- JSON: mood, intent, provider stats, etc.
    embedding BLOB  -- Vector embedding for semantic search (future)
);

-- Create index for fast conversation retrieval by project
CREATE INDEX IF NOT EXISTS idx_conversations_project
ON conversations(project_id, timestamp DESC);

-- Create index for semantic search by timestamp
CREATE INDEX IF NOT EXISTS idx_conversations_timestamp
ON conversations(timestamp DESC);

-- Decisions Table
-- Tracks important decisions made during conversations
CREATE TABLE IF NOT EXISTS decisions (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    decision_text TEXT NOT NULL,
    rationale TEXT,
    alternatives TEXT,  -- JSON array of alternative options considered
    outcome TEXT,       -- What happened after this decision
    owner TEXT,         -- 'user', 'ai', or 'collaborative'
    tags TEXT,          -- JSON array of tags for categorization
    metadata TEXT       -- JSON for additional context
);

-- Create index for decision retrieval by project
CREATE INDEX IF NOT EXISTS idx_decisions_project
ON decisions(project_id, timestamp DESC);

-- Knowledge Nodes Table
-- Core knowledge graph nodes (concepts, tools, people, artifacts)
CREATE TABLE IF NOT EXISTS knowledge_nodes (
    id TEXT PRIMARY KEY,
    type TEXT CHECK(type IN ('concept', 'tool', 'person', 'artifact', 'task', 'file', 'api', 'pattern')) NOT NULL,
    name TEXT NOT NULL,
    content TEXT,  -- JSON with type-specific fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    project_id TEXT REFERENCES projects(id) ON DELETE SET NULL,  -- NULL for global knowledge
    confidence REAL DEFAULT 1.0,  -- Confidence score 0.0-1.0
    usage_count INTEGER DEFAULT 0,  -- How often referenced
    last_used TIMESTAMP,
    embedding BLOB,  -- Vector embedding for semantic search
    metadata TEXT    -- JSON for extensibility
);

-- Create index for node search
CREATE INDEX IF NOT EXISTS idx_knowledge_nodes_type
ON knowledge_nodes(type, name);

CREATE INDEX IF NOT EXISTS idx_knowledge_nodes_project
ON knowledge_nodes(project_id);

-- Knowledge Edges Table
-- Relationships between knowledge nodes
CREATE TABLE IF NOT EXISTS knowledge_edges (
    id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    target_id TEXT NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    relationship TEXT NOT NULL,  -- 'depends_on', 'relates_to', 'uses', 'implements', etc.
    weight REAL DEFAULT 1.0,     -- Relationship strength 0.0-1.0
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bidirectional INTEGER DEFAULT 0,  -- 1 if relationship works both ways
    metadata TEXT,  -- JSON for additional relationship data

    -- Ensure no duplicate edges
    UNIQUE(source_id, target_id, relationship)
);

-- Create index for graph traversal
CREATE INDEX IF NOT EXISTS idx_knowledge_edges_source
ON knowledge_edges(source_id, relationship);

CREATE INDEX IF NOT EXISTS idx_knowledge_edges_target
ON knowledge_edges(target_id, relationship);

-- User Profile Table
-- Stores user preferences and learned behaviors (key-value store)
CREATE TABLE IF NOT EXISTS user_profile (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,  -- JSON value
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT  -- JSON for additional context
);

-- Session Summary Table
-- Compressed summaries of long conversation sessions
CREATE TABLE IF NOT EXISTS session_summaries (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    summary TEXT NOT NULL,
    message_count INTEGER NOT NULL,
    key_decisions TEXT,  -- JSON array of decision IDs
    key_topics TEXT,     -- JSON array of main topics discussed
    mood_progression TEXT,  -- JSON array of mood states over time
    metadata TEXT
);

-- Create index for summary retrieval
CREATE INDEX IF NOT EXISTS idx_session_summaries_project
ON session_summaries(project_id, start_time DESC);

-- Context Snippets Table
-- Pre-computed relevant context for fast retrieval
CREATE TABLE IF NOT EXISTS context_snippets (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
    snippet_type TEXT CHECK(snippet_type IN ('conversation', 'decision', 'code', 'reference')) NOT NULL,
    content TEXT NOT NULL,
    relevance_score REAL DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,  -- NULL for permanent snippets
    source_ids TEXT,  -- JSON array of source conversation/decision IDs
    embedding BLOB,  -- Vector embedding for semantic matching
    metadata TEXT
);

-- Create index for context retrieval
CREATE INDEX IF NOT EXISTS idx_context_snippets_project
ON context_snippets(project_id, relevance_score DESC);

CREATE INDEX IF NOT EXISTS idx_context_snippets_expiry
ON context_snippets(expires_at);

-- Database Metadata Table
-- Tracks schema version and migrations
CREATE TABLE IF NOT EXISTS db_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial schema version
INSERT OR IGNORE INTO db_metadata (key, value)
VALUES ('schema_version', '1.0.0');

INSERT OR IGNORE INTO db_metadata (key, value)
VALUES ('created_at', datetime('now'));

-- Triggers for updated_at timestamps
CREATE TRIGGER IF NOT EXISTS update_projects_timestamp
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_knowledge_nodes_timestamp
AFTER UPDATE ON knowledge_nodes
FOR EACH ROW
BEGIN
    UPDATE knowledge_nodes SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger to update node usage statistics
CREATE TRIGGER IF NOT EXISTS update_knowledge_node_usage
AFTER INSERT ON knowledge_edges
FOR EACH ROW
BEGIN
    UPDATE knowledge_nodes
    SET usage_count = usage_count + 1, last_used = CURRENT_TIMESTAMP
    WHERE id = NEW.source_id OR id = NEW.target_id;
END;

-- View: Recent Activity
-- Combined view of recent conversations, decisions, and knowledge updates
CREATE VIEW IF NOT EXISTS recent_activity AS
SELECT
    'conversation' as activity_type,
    c.id,
    c.project_id,
    c.timestamp,
    c.user_input as content,
    c.model_used as metadata
FROM conversations c
UNION ALL
SELECT
    'decision' as activity_type,
    d.id,
    d.project_id,
    d.timestamp,
    d.decision_text as content,
    d.owner as metadata
FROM decisions d
UNION ALL
SELECT
    'knowledge' as activity_type,
    k.id,
    k.project_id,
    k.updated_at as timestamp,
    k.name as content,
    k.type as metadata
FROM knowledge_nodes k
ORDER BY timestamp DESC;

-- View: Project Statistics
CREATE VIEW IF NOT EXISTS project_statistics AS
SELECT
    p.id,
    p.name,
    p.status,
    COUNT(DISTINCT c.id) as conversation_count,
    COUNT(DISTINCT d.id) as decision_count,
    COUNT(DISTINCT k.id) as knowledge_node_count,
    MAX(c.timestamp) as last_activity,
    p.created_at,
    p.updated_at
FROM projects p
LEFT JOIN conversations c ON p.id = c.project_id
LEFT JOIN decisions d ON p.id = d.project_id
LEFT JOIN knowledge_nodes k ON p.id = k.project_id
GROUP BY p.id;
