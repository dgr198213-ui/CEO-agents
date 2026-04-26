// ============================================================================
// CEO-Agents Frontend - Tipos TypeScript
// ============================================================================

export interface Agent {
  name: string;
  specializations: string[];
  performance: number;
  tasksCompleted: number;
  status: "available" | "busy" | "offline";
}

export interface ExecutionMetrics {
  durationMs: number;
  tokensUsed: number;
  cost: number;
  toolsUsed: number;
  errors: number;
}

export interface Artifact {
  name: string;
  path: string;
  artifactType: string;
  size: number;
  checksum: string;
}

export interface TaskResult {
  success: boolean;
  agent: string;
  output: string;
  qualityScore: number;
  agentFeedback: string;
  artifacts: Artifact[];
  executionMetrics: ExecutionMetrics;
}

export interface TaskRequest {
  name: string;
  description: string;
  taskType: string;
  priority?: "low" | "normal" | "high" | "critical";
}

export type TaskType =
  | "code_generation"
  | "code_review"
  | "documentation"
  | "testing"
  | "security_scan"
  | "api_design"
  | "generic";

export interface TaskTypeInfo {
  type: TaskType;
  description: string;
}

export interface HealthStatus {
  status: "ok" | "degraded" | "down";
  version: string;
  uptimeSeconds: number;
  agents: number;
  tools: number;
  llmProvider: string;
  timestamp: string;
}

export interface AgentStat {
  name: string;
  tasksCompleted: number;
  performance: number;
}

export interface LLMStats {
  totalRequests: number;
  totalTokens: number;
  totalCost: number;
  cacheHits: number;
}

export interface CEOStats {
  totalTasks: number;
  successfulTasks: number;
  successRate: number;
}

export interface ServerStats {
  uptimeSeconds: number;
  totalRequests: number;
  totalTasksExecuted: number;
}

export interface SystemStats {
  server: ServerStats;
  ceo: CEOStats;
  llm: LLMStats;
  agents: AgentStat[];
}
