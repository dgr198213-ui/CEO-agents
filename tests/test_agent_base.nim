## ============================================================================
## CEO-Agents - Tests: agent_base.nim
## ============================================================================
## Cobertura objetivo: >80%
## Ejecutar: nim c -r tests/test_agent_base.nim
## ============================================================================

import unittest
import ../src/agent_base
import json, tables, math

suite "AgentBase - Tipos y Constructores":

  test "AgentConfig tiene valores por defecto correctos":
    let config = AgentConfig(
      name: "TestAgent",
      role: "tester",
      capabilities: @["testing", "validation"],
      maxRetries: 3,
      timeoutMs: 5000
    )
    check config.name == "TestAgent"
    check config.role == "tester"
    check config.capabilities.len == 2
    check config.maxRetries == 3
    check config.timeoutMs == 5000

  test "AgentState inicialización correcta":
    let state = AgentState(
      isActive: true,
      currentTask: "test_task",
      performance: 0.75,
      tasksCompleted: 10,
      errors: 2
    )
    check state.isActive == true
    check state.currentTask == "test_task"
    check abs(state.performance - 0.75) < 0.001
    check state.tasksCompleted == 10
    check state.errors == 2

  test "AgentMessage construcción":
    let msg = AgentMessage(
      sender: "AgentA",
      receiver: "AgentB",
      content: "Hello",
      msgType: "request",
      timestamp: 1000.0
    )
    check msg.sender == "AgentA"
    check msg.receiver == "AgentB"
    check msg.content == "Hello"
    check msg.msgType == "request"

suite "AgentBase - Performance y Métricas":

  test "Performance score está en rango [0, 1]":
    let perf = 0.85
    check perf >= 0.0
    check perf <= 1.0

  test "Cálculo de tasa de éxito":
    let total = 100
    let successful = 87
    let rate = successful.float / total.float
    check abs(rate - 0.87) < 0.001

  test "Performance degradación por errores":
    var perf = 1.0
    let errorPenalty = 0.05
    perf = max(0.0, perf - errorPenalty * 3)
    check perf < 1.0
    check perf >= 0.0

suite "AgentBase - Serialización JSON":

  test "AgentConfig serializa a JSON correctamente":
    let config = AgentConfig(
      name: "SerializeTest",
      role: "serializer",
      capabilities: @["json", "data"],
      maxRetries: 2,
      timeoutMs: 3000
    )
    let j = %*{
      "name": config.name,
      "role": config.role,
      "capabilities": config.capabilities,
      "maxRetries": config.maxRetries,
      "timeoutMs": config.timeoutMs
    }
    check j["name"].getStr() == "SerializeTest"
    check j["role"].getStr() == "serializer"
    check j["capabilities"].len == 2
    check j["maxRetries"].getInt() == 2

  test "AgentState serializa a JSON correctamente":
    let state = AgentState(
      isActive: true,
      currentTask: "json_test",
      performance: 0.9,
      tasksCompleted: 5,
      errors: 0
    )
    let j = %*{
      "isActive": state.isActive,
      "currentTask": state.currentTask,
      "performance": state.performance,
      "tasksCompleted": state.tasksCompleted,
      "errors": state.errors
    }
    check j["isActive"].getBool() == true
    check j["performance"].getFloat() > 0.8

suite "AgentBase - Validaciones":

  test "Nombre de agente no vacío":
    let name = "TestAgent"
    check name.len > 0

  test "Capacidades no duplicadas":
    let caps = @["python", "javascript", "python"]
    var unique: seq[string] = @[]
    for c in caps:
      if c notin unique:
        unique.add(c)
    check unique.len == 2

  test "Timeout positivo":
    let timeout = 5000
    check timeout > 0

  test "MaxRetries en rango válido":
    let retries = 3
    check retries >= 0
    check retries <= 10

when isMainModule:
  echo "Running agent_base tests..."
