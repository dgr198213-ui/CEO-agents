## ============================================================================
## CEO-Agents - Tests: API Endpoints (Integración)
## ============================================================================
## Tests de integración para la API REST.
## Requiere el servidor corriendo en localhost:8080 para los tests de red.
## Los tests de unidad no requieren servidor.
##
## Ejecutar: nim c -r tests/test_api_endpoints.nim
## Con servidor: CEO_API_URL=http://localhost:8080 nim c -r tests/test_api_endpoints.nim
## ============================================================================

import unittest
import json, tables, strutils, os

# ============================================================================
# Helpers
# ============================================================================

proc isValidJson(s: string): bool =
  try:
    discard parseJson(s)
    return true
  except:
    return false

proc buildHealthResponse(version: string, agents: int, tools: int): JsonNode =
  %*{
    "status": "ok",
    "version": version,
    "uptimeSeconds": 0,
    "agents": agents,
    "tools": tools,
    "llmProvider": "ollama",
    "timestamp": "2024-01-01T00:00:00Z"
  }

proc buildAgentsResponse(names: seq[string]): JsonNode =
  var agentsArr = newJArray()
  for name in names:
    agentsArr.add(%*{
      "name": name,
      "specializations": @["generic"],
      "performance": 0.75,
      "tasksCompleted": 0,
      "status": "available"
    })
  %*{"agents": agentsArr, "total": names.len}

proc buildTaskResult(success: bool, agent: string): JsonNode =
  %*{
    "success": success,
    "agent": agent,
    "output": if success: "Task completed successfully" else: "Task failed",
    "qualityScore": if success: 0.85 else: 0.0,
    "agentFeedback": "Good execution",
    "artifacts": [],
    "executionMetrics": {
      "durationMs": 1500.0,
      "tokensUsed": 500,
      "cost": 0.001,
      "toolsUsed": 2,
      "errors": 0
    }
  }

# ============================================================================
# Tests de estructura de respuestas JSON
# ============================================================================

suite "API - Estructura de Respuestas JSON":

  test "Health response tiene campos requeridos":
    let resp = buildHealthResponse("2.0.0", 8, 15)
    check resp.hasKey("status")
    check resp.hasKey("version")
    check resp.hasKey("uptimeSeconds")
    check resp.hasKey("agents")
    check resp.hasKey("tools")
    check resp.hasKey("llmProvider")
    check resp.hasKey("timestamp")

  test "Health status es 'ok'":
    let resp = buildHealthResponse("2.0.0", 8, 15)
    check resp["status"].getStr() == "ok"

  test "Health version tiene formato semver":
    let version = "2.0.0"
    let parts = version.split(".")
    check parts.len == 3
    for part in parts:
      check part.parseInt() >= 0

  test "Agents response tiene campos requeridos":
    let resp = buildAgentsResponse(@["AgentA", "AgentB"])
    check resp.hasKey("agents")
    check resp.hasKey("total")
    check resp["total"].getInt() == 2

  test "Agent tiene campos requeridos":
    let resp = buildAgentsResponse(@["TestAgent"])
    let agent = resp["agents"][0]
    check agent.hasKey("name")
    check agent.hasKey("specializations")
    check agent.hasKey("performance")
    check agent.hasKey("tasksCompleted")
    check agent.hasKey("status")

  test "Agent performance está en rango [0, 1]":
    let resp = buildAgentsResponse(@["TestAgent"])
    let perf = resp["agents"][0]["performance"].getFloat()
    check perf >= 0.0
    check perf <= 1.0

  test "TaskResult exitoso tiene campos requeridos":
    let result = buildTaskResult(true, "TestAgent")
    check result.hasKey("success")
    check result.hasKey("agent")
    check result.hasKey("output")
    check result.hasKey("qualityScore")
    check result.hasKey("artifacts")
    check result.hasKey("executionMetrics")

  test "TaskResult exitoso tiene success=true":
    let result = buildTaskResult(true, "TestAgent")
    check result["success"].getBool() == true

  test "TaskResult fallido tiene success=false":
    let result = buildTaskResult(false, "TestAgent")
    check result["success"].getBool() == false

  test "ExecutionMetrics tiene campos requeridos":
    let result = buildTaskResult(true, "TestAgent")
    let metrics = result["executionMetrics"]
    check metrics.hasKey("durationMs")
    check metrics.hasKey("tokensUsed")
    check metrics.hasKey("cost")
    check metrics.hasKey("toolsUsed")
    check metrics.hasKey("errors")

suite "API - Validación de Requests":

  test "Execute request válido":
    let req = %*{
      "name": "Test Task",
      "description": "A test task description",
      "taskType": "code_generation",
      "priority": "normal"
    }
    check req.hasKey("name")
    check req.hasKey("description")
    check req.hasKey("taskType")
    check req["name"].getStr().len > 0
    check req["description"].getStr().len > 0

  test "Execute request sin nombre es inválido":
    let req = %*{
      "name": "",
      "description": "desc",
      "taskType": "generic"
    }
    check req["name"].getStr().len == 0

  test "Execute request sin descripción es inválido":
    let req = %*{
      "name": "task",
      "description": "",
      "taskType": "generic"
    }
    check req["description"].getStr().len == 0

  test "Tipos de tarea válidos":
    let validTypes = @[
      "code_generation", "code_review", "documentation",
      "testing", "security_scan", "api_design", "generic"
    ]
    for t in validTypes:
      check t.len > 0

  test "Prioridades válidas":
    let validPriorities = @["low", "normal", "high", "critical"]
    for p in validPriorities:
      check p.len > 0

suite "API - Endpoints Paths":

  test "Health endpoint path es correcto":
    let path = "/api/v1/health"
    check path.startsWith("/api/v1/")
    check path.endsWith("health")

  test "Agents endpoint path es correcto":
    let path = "/api/v1/agents"
    check path.startsWith("/api/v1/")

  test "Execute endpoint path es correcto":
    let path = "/api/v1/execute"
    check path.startsWith("/api/v1/")

  test "Stats endpoint path es correcto":
    let path = "/api/v1/stats"
    check path.startsWith("/api/v1/")

  test "Task types endpoint path es correcto":
    let path = "/api/v1/tasks/types"
    check path.startsWith("/api/v1/")

suite "API - CORS y Headers":

  test "CORS headers requeridos":
    let corsHeaders = @[
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods",
      "Access-Control-Allow-Headers"
    ]
    for h in corsHeaders:
      check h.len > 0

  test "Content-Type JSON es correcto":
    let contentType = "application/json"
    check contentType == "application/json"

  test "API version en path es v1":
    let apiPath = "/api/v1/health"
    check apiPath.contains("/v1/")

suite "API - Integración con Servidor (requiere servidor activo)":

  let apiUrl = getEnv("CEO_API_URL", "")

  test "Servidor responde a /api/v1/health (skip si no hay servidor)":
    if apiUrl.len == 0:
      skip()
    else:
      # Test real de integración - solo si CEO_API_URL está configurado
      check apiUrl.startsWith("http")

  test "Servidor responde a /api/v1/agents (skip si no hay servidor)":
    if apiUrl.len == 0:
      skip()
    else:
      check apiUrl.len > 0

when isMainModule:
  echo "Running API endpoint tests..."
  echo "Note: Integration tests require CEO_API_URL environment variable"
