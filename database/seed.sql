-- ============================================================================
-- CEO-Agents - Seed Inicial de la Base de Datos
-- ============================================================================
-- Ejecutar después de las migraciones:
--   psql $DATABASE_URL -f database/seed.sql
-- ============================================================================

-- Configuración inicial del sistema
INSERT INTO system_config (key, value, "updatedAt") VALUES
  ('llm_provider',       'ollama',                        NOW()),
  ('llm_model',          'llama3',                        NOW()),
  ('max_tasks_per_hour', '100',                           NOW()),
  ('shell_sandbox',      'true',                          NOW()),
  ('version',            '2.0.0',                         NOW())
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, "updatedAt" = NOW();

-- Agentes iniciales del stack CEO
INSERT INTO agents (id, name, specializations, performance, "tasksCompleted", status, "createdAt", "updatedAt") VALUES
  ('agent_python',     'PythonAgent',     ARRAY['python','data','backend'],        0.75, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_typescript', 'TypeScriptAgent', ARRAY['typescript','frontend','react'],  0.72, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_devops',     'DevOpsAgent',     ARRAY['devops','ci/cd','containers'],    0.70, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_frontend',   'FrontendAgent',   ARRAY['ui','css','responsive'],          0.68, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_backend',    'BackendAgent',    ARRAY['api','database','microservices'], 0.73, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_security',   'SecurityAgent',   ARRAY['security','auth','encryption'],   0.80, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_testing',    'TestingAgent',    ARRAY['testing','qa','validation'],      0.77, 0, 'AVAILABLE', NOW(), NOW()),
  ('agent_docs',       'DocsAgent',       ARRAY['documentation','api-docs'],       0.65, 0, 'AVAILABLE', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- Snapshot inicial del sistema
INSERT INTO system_snapshots (
  "totalTasks", "successfulTasks", "successRate",
  "totalRequests", "totalTokens", "totalCost",
  "cacheHits", "uptimeSeconds", "recordedAt"
) VALUES (0, 0, 0.0, 0, 0, 0.0, 0, 0.0, NOW());
