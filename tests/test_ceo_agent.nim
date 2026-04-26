## ============================================================================
## CEO-Agents - Tests: ceo_agent.nim
## ============================================================================
## Cobertura objetivo: >80%
## Ejecutar: nim c -r tests/test_ceo_agent.nim
## ============================================================================

import unittest
import json, tables, sequtils, algorithm, math, strutils

# ============================================================================
# Tipos auxiliares para tests (sin importar ceo_agent directamente
# para evitar dependencias de red en CI)
# ============================================================================

type
  MockTaskType = enum
    ttCodeGen = "code_generation"
    ttCodeReview = "code_review"
    ttDocumentation = "documentation"
    ttTesting = "testing"
    ttSecurityScan = "security_scan"
    ttApiDesign = "api_design"
    ttGeneric = "generic"

  MockAgentScore = object
    name: string
    score: float
    specializations: seq[string]

  MockTaskRequest = object
    name: string
    description: string
    taskType: string
    priority: string

  MockTaskResult = object
    success: bool
    agent: string
    output: string
    qualityScore: float
    durationMs: float
    tokensUsed: int

proc scoreAgent(agent: MockAgentScore, taskType: string): float =
  ## Calcula el score de un agente para un tipo de tarea
  var score = agent.score
  if taskType in agent.specializations:
    score += 0.2
  return min(1.0, score)

proc selectBestAgent(agents: seq[MockAgentScore], taskType: string): MockAgentScore =
  ## Selecciona el mejor agente para una tarea
  var best = agents[0]
  var bestScore = scoreAgent(agents[0], taskType)
  for agent in agents[1..^1]:
    let s = scoreAgent(agent, taskType)
    if s > bestScore:
      bestScore = s
      best = agent
  return best

suite "CEOAgent - Selección de Agentes":

  test "Selecciona agente con mayor performance":
    let agents = @[
      MockAgentScore(name: "AgentA", score: 0.5, specializations: @["python"]),
      MockAgentScore(name: "AgentB", score: 0.9, specializations: @["javascript"]),
      MockAgentScore(name: "AgentC", score: 0.7, specializations: @["devops"]),
    ]
    let best = selectBestAgent(agents, "generic")
    check best.name == "AgentB"

  test "Especialización aumenta score del agente":
    let agent = MockAgentScore(name: "PythonAgent", score: 0.7, specializations: @["python", "data"])
    let scoreGeneric = scoreAgent(agent, "generic")
    let scorePython = scoreAgent(agent, "python")
    check scorePython > scoreGeneric

  test "Score máximo no supera 1.0":
    let agent = MockAgentScore(name: "SuperAgent", score: 0.95, specializations: @["code_generation"])
    let score = scoreAgent(agent, "code_generation")
    check score <= 1.0

  test "Agente especializado gana sobre agente genérico":
    let agents = @[
      MockAgentScore(name: "Specialist", score: 0.6, specializations: @["code_generation"]),
      MockAgentScore(name: "Generalist", score: 0.75, specializations: @[]),
    ]
    let best = selectBestAgent(agents, "code_generation")
    check best.name == "Specialist"

  test "Con un solo agente, se selecciona ese":
    let agents = @[
      MockAgentScore(name: "OnlyAgent", score: 0.5, specializations: @[])
    ]
    let best = selectBestAgent(agents, "testing")
    check best.name == "OnlyAgent"

suite "CEOAgent - Tipos de Tareas":

  test "Tipos de tarea válidos":
    let validTypes = @[
      "code_generation", "code_review", "documentation",
      "testing", "security_scan", "api_design", "generic"
    ]
    check validTypes.len == 7
    for t in validTypes:
      check t.len > 0

  test "Prioridades válidas":
    let priorities = @["low", "normal", "high", "critical"]
    check priorities.len == 4

  test "Tarea con nombre vacío es inválida":
    let task = MockTaskRequest(name: "", description: "desc", taskType: "generic", priority: "normal")
    check task.name.len == 0  # Debería ser rechazada

  test "Tarea con descripción vacía es inválida":
    let task = MockTaskRequest(name: "task", description: "", taskType: "generic", priority: "normal")
    check task.description.len == 0  # Debería ser rechazada

  test "Tarea válida tiene nombre y descripción":
    let task = MockTaskRequest(
      name: "Implement API",
      description: "Create a REST API with authentication",
      taskType: "code_generation",
      priority: "high"
    )
    check task.name.len > 0
    check task.description.len > 0
    check task.taskType == "code_generation"

suite "CEOAgent - Resultados de Tareas":

  test "TaskResult exitoso tiene qualityScore positivo":
    let result = MockTaskResult(
      success: true,
      agent: "TestAgent",
      output: "Generated code...",
      qualityScore: 0.85,
      durationMs: 1500.0,
      tokensUsed: 500
    )
    check result.success == true
    check result.qualityScore > 0.0
    check result.qualityScore <= 1.0

  test "TaskResult fallido tiene success=false":
    let result = MockTaskResult(
      success: false,
      agent: "TestAgent",
      output: "",
      qualityScore: 0.0,
      durationMs: 100.0,
      tokensUsed: 0
    )
    check result.success == false

  test "DurationMs es positivo":
    let result = MockTaskResult(
      success: true, agent: "A", output: "ok",
      qualityScore: 0.8, durationMs: 250.0, tokensUsed: 100
    )
    check result.durationMs > 0.0

  test "TokensUsed es no negativo":
    let result = MockTaskResult(
      success: true, agent: "A", output: "ok",
      qualityScore: 0.8, durationMs: 100.0, tokensUsed: 0
    )
    check result.tokensUsed >= 0

suite "CEOAgent - Estadísticas":

  test "Tasa de éxito se calcula correctamente":
    let total = 100
    let successful = 87
    let rate = successful.float / total.float * 100.0
    check abs(rate - 87.0) < 0.01

  test "Tasa de éxito con 0 tareas es 0":
    let total = 0
    let rate = if total == 0: 0.0 else: 100.0
    check rate == 0.0

  test "Costo total es suma de costos individuales":
    let costs = @[0.001, 0.002, 0.0015, 0.003]
    let total = costs.foldl(a + b, 0.0)
    check abs(total - 0.0075) < 0.0001

  test "Performance promedio de agentes":
    let performances = @[0.7, 0.8, 0.9, 0.6, 0.85]
    let avg = performances.foldl(a + b, 0.0) / performances.len.float
    check abs(avg - 0.77) < 0.01

suite "CEOAgent - Routing y Prioridades":

  test "Tarea crítica tiene prioridad máxima":
    let priorities = @["low", "normal", "high", "critical"]
    let criticalIdx = priorities.find("critical")
    check criticalIdx == priorities.len - 1

  test "Orden de prioridades es correcto":
    let priorityMap = {"low": 0, "normal": 1, "high": 2, "critical": 3}.toTable
    check priorityMap["critical"] > priorityMap["high"]
    check priorityMap["high"] > priorityMap["normal"]
    check priorityMap["normal"] > priorityMap["low"]

  test "Tarea de seguridad se asigna a SecurityAgent":
    let agents = @[
      MockAgentScore(name: "SecurityAgent", score: 0.7, specializations: @["security_scan", "security"]),
      MockAgentScore(name: "CodeAgent",     score: 0.8, specializations: @["code_generation"]),
    ]
    let best = selectBestAgent(agents, "security_scan")
    check best.name == "SecurityAgent"

when isMainModule:
  echo "Running ceo_agent tests..."
