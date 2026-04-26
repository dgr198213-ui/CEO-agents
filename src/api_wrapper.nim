## CEO-Agents REST API Server
## ============================================================================
## Servidor HTTP asíncrono que expone los agentes CEO como endpoints REST.
##
## Endpoints disponibles:
##   GET  /api/v1/health           - Estado del servidor
##   GET  /api/v1/agents           - Lista de agentes disponibles
##   GET  /api/v1/agents/:name     - Detalle de un agente específico
##   POST /api/v1/execute          - Ejecutar una tarea
##   GET  /api/v1/tasks/types      - Tipos de tarea soportados
##   GET  /api/v1/stats            - Estadísticas globales del sistema
##
## Versión 2.0 - Añadidos CORS, nuevos endpoints, manejo de errores mejorado.

import asynchttpserver, asyncdispatch, json, strformat, strutils, times, tables, os
import agent_base, llm_integration, tool_registry, agent_execution_engine
import ../examples/example_ceo_functional

# ============================================================================
# Estado Global del Servidor (thread-safe via single-threaded async)
# ============================================================================

var
  globalRegistry: ToolRegistry
  globalLLMConfig: ModelConfig
  globalCEO: CEOOrchestrator
  serverStartTime: float
  totalRequestsServed: int
  totalTasksExecuted: int
  serverInitialized: bool = false
  globalCredentials: seq[JsonNode] = @[] # Cache simple de credenciales

proc initGlobalState() =
  ## Inicializa el estado global del servidor una sola vez.
  if serverInitialized:
    return
  globalLLMConfig = example_ceo_functional.initLLMConfig()
  globalRegistry = example_ceo_functional.initToolRegistry()
  let agents = initStackAgents(globalRegistry, globalLLMConfig)
  globalCEO = CEOOrchestrator(
    name: "CEO-Agent",
    stackAgents: agents,
    llmConfig: globalLLMConfig,
    registry: globalRegistry,
    totalTasks: 0,
    successfulTasks: 0
  )
  serverStartTime = epochTime()
  serverInitialized = true
  echo "  ✓ Estado global del servidor inicializado"

# ============================================================================
# Helpers de Respuesta HTTP con CORS
# ============================================================================

proc corsHeaders(): HttpHeaders =
  result = newHttpHeaders([
    ("Content-Type",                "application/json"),
    ("Access-Control-Allow-Origin", "*"),
    ("Access-Control-Allow-Methods","GET, POST, OPTIONS"),
    ("Access-Control-Allow-Headers","Content-Type, Authorization, X-Requested-With"),
    ("Access-Control-Max-Age",      "86400")
  ])

proc respondJson(req: Request, status: HttpCode, data: JsonNode) {.async.} =
  await req.respond(status, $data, corsHeaders())

proc respondError(req: Request, status: HttpCode, message: string, detail: string = "") {.async.} =
  var body = %* {"error": message, "status": status.int}
  if detail.len > 0:
    body["detail"] = %detail
  await req.respond(status, $body, corsHeaders())

# ============================================================================
# Serializadores
# ============================================================================

proc artifactToJson(artifact: Artifact): JsonNode =
  %* {
    "name":         artifact.name,
    "path":         artifact.path,
    "artifactType": artifact.artifactType,
    "size":         artifact.size,
    "checksum":     artifact.checksum
  }

proc taskResultToJson(agentName: string, taskResult: TaskResult): JsonNode =
  var artifacts = newJArray()
  for artifact in taskResult.artifacts:
    artifacts.add(artifactToJson(artifact))

  %* {
    "success":      taskResult.success,
    "agent":        agentName,
    "output":       taskResult.output,
    "qualityScore": taskResult.qualityScore,
    "agentFeedback":taskResult.agentFeedback,
    "artifacts":    artifacts,
    "executionMetrics": {
      "durationMs":  taskResult.executionMetrics.durationMs,
      "tokensUsed":  taskResult.executionMetrics.tokensUsed,
      "cost":        taskResult.executionMetrics.cost,
      "toolsUsed":   taskResult.executionMetrics.toolsUsed,
      "errors":      taskResult.executionMetrics.errors
    }
  }

proc agentToJson(agent: StackAgent): JsonNode =
  var specs = newJArray()
  for s in agent.specializations:
    specs.add(%s)

  %* {
    "name":            agent.name,
    "specializations": specs,
    "performance":     agent.performance,
    "tasksCompleted":  agent.tasksCompleted,
    "status":          "available"
  }

# ============================================================================
# Handlers de Endpoints
# ============================================================================

proc handleHealth(req: Request) {.async.} =
  let uptime = epochTime() - serverStartTime
  await req.respondJson(Http200, %* {
    "status":        "ok",
    "version":       "2.0.0",
    "uptimeSeconds": uptime,
    "agents":        globalCEO.stackAgents.len,
    "tools":         globalRegistry.tools.len,
    "llmProvider":   $globalLLMConfig.provider,
    "timestamp":     now().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
  })

proc handleGetAgents(req: Request) {.async.} =
  var agentsArray = newJArray()
  for agent in globalCEO.stackAgents:
    agentsArray.add(agentToJson(agent))

  await req.respondJson(Http200, %* {
    "agents": agentsArray,
    "total":  globalCEO.stackAgents.len
  })

proc handleGetAgentByName(req: Request, agentName: string) {.async.} =
  for agent in globalCEO.stackAgents:
    if agent.name.toLower() == agentName.toLower():
      await req.respondJson(Http200, agentToJson(agent))
      return
  await req.respondError(Http404, &"Agente '{agentName}' no encontrado")

proc handleGetTaskTypes(req: Request) {.async.} =
  let taskTypes = @[
    %* {"type": "code_generation",  "description": "Genera código fuente en el lenguaje apropiado"},
    %* {"type": "code_review",      "description": "Revisa y analiza código existente"},
    %* {"type": "documentation",    "description": "Genera documentación Markdown"},
    %* {"type": "testing",          "description": "Genera suites de tests unitarios"},
    %* {"type": "security_scan",    "description": "Analiza vulnerabilidades de seguridad"},
    %* {"type": "api_design",       "description": "Genera especificaciones OpenAPI"},
    %* {"type": "generic",          "description": "Tarea genérica de propósito general"}
  ]
  var arr = newJArray()
  for t in taskTypes:
    arr.add(t)
  await req.respondJson(Http200, %* {"taskTypes": arr})

proc handleGetStats(req: Request) {.async.} =
  let usage = getUsageStats()
  var agentStats = newJArray()
  for agent in globalCEO.stackAgents:
    agentStats.add(%* {
      "name":           agent.name,
      "tasksCompleted": agent.tasksCompleted,
      "performance":    agent.performance
    })

  await req.respondJson(Http200, %* {
    "server": {
      "uptimeSeconds":     epochTime() - serverStartTime,
      "totalRequests":     totalRequestsServed,
      "totalTasksExecuted":totalTasksExecuted
    },
    "ceo": {
      "totalTasks":      globalCEO.totalTasks,
      "successfulTasks": globalCEO.successfulTasks,
      "successRate":     if globalCEO.totalTasks > 0:
                           globalCEO.successfulTasks.float / globalCEO.totalTasks.float * 100.0
                         else: 0.0
    },
    "llm": {
      "totalRequests": usage.totalRequests,
      "totalTokens":   usage.totalTokens,
      "totalCost":     usage.totalCost,
      "cacheHits":     usage.cacheHits
    },
    "agents": agentStats
  })

proc handleExecuteTask(req: Request) {.async.} =
  let bodyStr = req.body
  if bodyStr == "":
    await req.respondError(Http400, "Cuerpo de la petición vacío")
    return

  var body: JsonNode
  try:
    body = parseJson(bodyStr)
  except JsonParsingError as e:
    await req.respondError(Http400, "JSON inválido", e.msg)
    return

  if not body.hasKey("name") or not body.hasKey("description"):
    await req.respondError(Http400, "Campos requeridos: 'name' y 'description'")
    return

  let taskName = body["name"].getStr()
  let taskDesc = body["description"].getStr()
  let taskType = body{"taskType"}.getStr("generic")
  let priorityStr = body{"priority"}.getStr("normal")

  if taskName.len == 0 or taskDesc.len == 0:
    await req.respondError(Http400, "Los campos 'name' y 'description' no pueden estar vacíos")
    return

  let priority = case priorityStr.toLower()
    of "low":      tpLow
    of "high":     tpHigh
    of "critical": tpCritical
    else:          tpNormal

  let taskId = int(now().toTime().toUnix() mod 1_000_000)

  let newTask = ProjectTask(
    id:          taskId,
    name:        taskName,
    description: taskDesc,
    taskType:    taskType,
    priority:    priority,
    context:     newJObject()
  )

  var assignedAgent = assignTaskToAgent(globalCEO, newTask)
  let taskResult = executeTask(assignedAgent, newTask, globalRegistry)

  inc globalCEO.totalTasks
  inc totalTasksExecuted
  if taskResult.success:
    inc globalCEO.successfulTasks
    inc assignedAgent.tasksCompleted

  # Actualizar agente en el estado global
  for i in 0..<globalCEO.stackAgents.len:
    if globalCEO.stackAgents[i].name == assignedAgent.name:
      globalCEO.stackAgents[i] = assignedAgent
      break

  let resJson = taskResultToJson(assignedAgent.name, taskResult)
  await req.respondJson(Http200, resJson)

# ============================================================================
# Router Principal
# ============================================================================

proc processRequest(req: Request) {.async, gcsafe.} =
  inc totalRequestsServed

  let path = req.url.path
  let meth = req.reqMethod

  # Preflight CORS
  if meth == HttpOptions:
    await req.respond(Http204, "", corsHeaders())
    return

  try:
    # GET /api/v1/health
    if meth == HttpGet and path == "/api/v1/health":
      await handleHealth(req)

    # GET /api/v1/agents
    elif meth == HttpGet and path == "/api/v1/agents":
      await handleGetAgents(req)

    # GET /api/v1/agents/:name
    elif meth == HttpGet and path.startsWith("/api/v1/agents/"):
      let agentName = path["/api/v1/agents/".len..^1]
      await handleGetAgentByName(req, agentName)

    # GET /api/v1/tasks/types
    elif meth == HttpGet and path == "/api/v1/tasks/types":
      await handleGetTaskTypes(req)

    # GET /api/v1/stats
    elif meth == HttpGet and path == "/api/v1/stats":
      await handleGetStats(req)

    # POST /api/v1/execute
    elif meth == HttpPost and path == "/api/v1/execute":
      await handleExecuteTask(req)

    # --- Credential Management Endpoints ---
    
    # GET /api/v1/credentials
    elif meth == HttpGet and path == "/api/v1/credentials":
      await req.respondJson(Http200, %* {"credentials": globalCredentials})

    # POST /api/v1/credentials
    elif meth == HttpPost and path == "/api/v1/credentials":
      try:
        let cred = parseJson(req.body)
        var newCred = cred
        newCred["id"] = %($int(epochTime()))
        newCred["createdAt"] = %(now().format("yyyy-MM-dd'T'HH:mm:ss'Z'"))
        newCred["updatedAt"] = newCred["createdAt"]
        newCred["isActive"] = %false
        globalCredentials.add(newCred)
        await req.respondJson(Http201, newCred)
      except:
        await req.respondError(Http400, "Error al procesar credencial")

    # POST /api/v1/credentials/:id/activate
    elif meth == HttpPost and path.startsWith("/api/v1/credentials/") and path.endsWith("/activate"):
      let id = path["/api/v1/credentials/".len .. ^("/activate".len + 1)]
      var activated: JsonNode
      for i in 0 ..< globalCredentials.len:
        if globalCredentials[i]["id"].getStr() == id:
          globalCredentials[i]["isActive"] = %true
          activated = globalCredentials[i]
          # Actualizar configuración global del LLM
          let providerStr = activated["provider"].getStr()
          let provider = case providerStr
            of "openai": lpOpenAI
            of "anthropic": lpAnthropic
            of "openrouter": lpOpenRouter
            of "groq": lpGroq
            of "deepseek": lpDeepSeek
            of "mistral": lpMistral
            else: lpOllama
          
          let defaultBaseUrl = case provider
            of lpOpenRouter: "https://openrouter.ai"
            of lpGroq: "https://api.groq.com/openai"
            of lpDeepSeek: "https://api.deepseek.com"
            of lpMistral: "https://api.mistral.ai"
            of lpOpenAI: "https://api.openai.com"
            of lpAnthropic: "https://api.anthropic.com"
            else: "http://localhost:11434"

          globalLLMConfig = ModelConfig(
            provider: provider,
            model: activated{"model"}.getStr(if provider == lpGroq: "mixtral-8x7b-32768" else: "gpt-3.5-turbo"),
            apiKey: activated{"apiKey"}.getStr(""),
            baseUrl: activated{"apiUrl"}.getStr(defaultBaseUrl),
            maxTokens: 4096,
            temperature: 0.7
          )
        else:
          globalCredentials[i]["isActive"] = %false
      
      if activated != nil:
        await req.respondJson(Http200, activated)
      else:
        await req.respondError(Http404, "Credencial no encontrada")

    # DELETE /api/v1/credentials/:id
    elif meth == HttpDelete and path.startsWith("/api/v1/credentials/"):
      let id = path["/api/v1/credentials/".len .. ^1]
      let oldLen = globalCredentials.len
      globalCredentials.keepIf(proc(x: JsonNode): bool = x["id"].getStr() != id)
      if globalCredentials.len < oldLen:
        await req.respond(Http204, "", corsHeaders())
      else:
        await req.respondError(Http404, "Credencial no encontrada")

    # GET / - Página de bienvenida
    elif meth == HttpGet and (path == "/" or path == ""):
      await req.respondJson(Http200, %* {
        "name":    "CEO-Agents API",
        "version": "2.0.0",
        "docs":    "https://github.com/dgr198213-ui/CEO-agents",
        "endpoints": [
          "GET  /api/v1/health",
          "GET  /api/v1/agents",
          "GET  /api/v1/agents/:name",
          "GET  /api/v1/tasks/types",
          "GET  /api/v1/stats",
          "POST /api/v1/execute"
        ]
      })

    else:
      await req.respondError(Http404, &"Endpoint no encontrado: {meth} {path}")

  except Exception as e:
    echo &"[ERROR] {meth} {path}: {e.msg}"
    await req.respondError(Http500, "Error interno del servidor", e.msg)

# ============================================================================
# Entry Point
# ============================================================================

proc main() {.async.} =
  let port = getEnv("PORT", "8080").parseInt()
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║              CEO-Agents REST API Server v2.0                          ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Inicializando sistema..."
  initGlobalState()
  echo ""
  echo &"🚀 Servidor iniciado en http://0.0.0.0:{port}"
  echo ""
  echo "Endpoints disponibles:"
  echo "  GET  /api/v1/health"
  echo "  GET  /api/v1/agents"
  echo "  GET  /api/v1/agents/:name"
  echo "  GET  /api/v1/tasks/types"
  echo "  GET  /api/v1/stats"
  echo "  POST /api/v1/execute"
  echo ""

  let server = newAsyncHttpServer()
  await server.serve(Port(port), processRequest)

waitFor main()
