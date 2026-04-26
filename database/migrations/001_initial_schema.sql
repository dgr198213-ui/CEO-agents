-- ============================================================================
-- CEO-Agents - Migración 001: Schema Inicial
-- ============================================================================
-- Aplica: CREATE TABLE para todos los modelos del sistema
-- ============================================================================

-- Enums
CREATE TYPE agent_status AS ENUM ('AVAILABLE', 'BUSY', 'OFFLINE');
CREATE TYPE task_priority AS ENUM ('LOW', 'NORMAL', 'HIGH', 'CRITICAL');
CREATE TYPE task_status AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED');

-- Tabla: agents
CREATE TABLE IF NOT EXISTS agents (
  id               VARCHAR(30)  PRIMARY KEY,
  name             VARCHAR(100) UNIQUE NOT NULL,
  specializations  TEXT[]       NOT NULL DEFAULT '{}',
  performance      DOUBLE PRECISION NOT NULL DEFAULT 0.5,
  "tasksCompleted" INTEGER      NOT NULL DEFAULT 0,
  status           agent_status NOT NULL DEFAULT 'AVAILABLE',
  "createdAt"      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  "updatedAt"      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Tabla: tasks
CREATE TABLE IF NOT EXISTS tasks (
  id             VARCHAR(30)   PRIMARY KEY,
  name           VARCHAR(255)  NOT NULL,
  description    TEXT          NOT NULL,
  "taskType"     VARCHAR(50)   NOT NULL,
  priority       task_priority NOT NULL DEFAULT 'NORMAL',
  status         task_status   NOT NULL DEFAULT 'PENDING',
  success        BOOLEAN,
  output         TEXT,
  "qualityScore" DOUBLE PRECISION,
  "agentFeedback" TEXT,
  "durationMs"   DOUBLE PRECISION,
  "tokensUsed"   INTEGER,
  cost           DOUBLE PRECISION,
  "agentId"      VARCHAR(30)   REFERENCES agents(id) ON DELETE SET NULL,
  "createdAt"    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  "updatedAt"    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  "completedAt"  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_tasks_agent_id   ON tasks("agentId");
CREATE INDEX IF NOT EXISTS idx_tasks_task_type  ON tasks("taskType");
CREATE INDEX IF NOT EXISTS idx_tasks_status     ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks("createdAt");

-- Tabla: artifacts
CREATE TABLE IF NOT EXISTS artifacts (
  id             VARCHAR(30)  PRIMARY KEY,
  name           VARCHAR(255) NOT NULL,
  path           VARCHAR(500) NOT NULL,
  "artifactType" VARCHAR(50)  NOT NULL,
  size           INTEGER      NOT NULL DEFAULT 0,
  checksum       VARCHAR(64)  NOT NULL DEFAULT '',
  "taskId"       VARCHAR(30)  NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  "createdAt"    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_artifacts_task_id ON artifacts("taskId");

-- Tabla: agent_metrics
CREATE TABLE IF NOT EXISTS agent_metrics (
  id              VARCHAR(30)      PRIMARY KEY,
  "agentId"       VARCHAR(30)      NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  performance     DOUBLE PRECISION NOT NULL,
  "tasksCount"    INTEGER          NOT NULL,
  "successRate"   DOUBLE PRECISION NOT NULL,
  "avgDurationMs" DOUBLE PRECISION NOT NULL,
  "recordedAt"    TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_metrics_agent_id    ON agent_metrics("agentId");
CREATE INDEX IF NOT EXISTS idx_agent_metrics_recorded_at ON agent_metrics("recordedAt");

-- Tabla: system_snapshots
CREATE TABLE IF NOT EXISTS system_snapshots (
  id               VARCHAR(30)      PRIMARY KEY,
  "totalTasks"     INTEGER          NOT NULL DEFAULT 0,
  "successfulTasks" INTEGER         NOT NULL DEFAULT 0,
  "successRate"    DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  "totalRequests"  INTEGER          NOT NULL DEFAULT 0,
  "totalTokens"    INTEGER          NOT NULL DEFAULT 0,
  "totalCost"      DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  "cacheHits"      INTEGER          NOT NULL DEFAULT 0,
  "uptimeSeconds"  DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  "recordedAt"     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_snapshots_recorded_at ON system_snapshots("recordedAt");

-- Tabla: system_config
CREATE TABLE IF NOT EXISTS system_config (
  key        VARCHAR(100) PRIMARY KEY,
  value      TEXT         NOT NULL,
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
