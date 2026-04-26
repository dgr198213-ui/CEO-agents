// ============================================================================
// CEO-Agents Frontend - Cliente API
// ============================================================================

import axios from "axios";
import type {
  Agent,
  TaskRequest,
  TaskResult,
  TaskTypeInfo,
  HealthStatus,
  SystemStats,
} from "@/types";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

const client = axios.create({
  baseURL: API_BASE,
  timeout: 30_000,
  headers: { "Content-Type": "application/json" },
});

// ── Health ────────────────────────────────────────────────────────────────────

export async function fetchHealth(): Promise<HealthStatus> {
  const { data } = await client.get<HealthStatus>("/api/v1/health");
  return data;
}

// ── Agents ────────────────────────────────────────────────────────────────────

export async function fetchAgents(): Promise<Agent[]> {
  const { data } = await client.get<{ agents: Agent[]; total: number }>(
    "/api/v1/agents"
  );
  return data.agents;
}

export async function fetchAgentByName(name: string): Promise<Agent> {
  const { data } = await client.get<Agent>(`/api/v1/agents/${name}`);
  return data;
}

// ── Task Types ────────────────────────────────────────────────────────────────

export async function fetchTaskTypes(): Promise<TaskTypeInfo[]> {
  const { data } = await client.get<{ taskTypes: TaskTypeInfo[] }>(
    "/api/v1/tasks/types"
  );
  return data.taskTypes;
}

// ── Stats ─────────────────────────────────────────────────────────────────────

export async function fetchStats(): Promise<SystemStats> {
  const { data } = await client.get<SystemStats>("/api/v1/stats");
  return data;
}

// ── Execute Task ──────────────────────────────────────────────────────────────

export async function executeTask(task: TaskRequest): Promise<TaskResult> {
  const { data } = await client.post<TaskResult>("/api/v1/execute", task);
  return data;
}
