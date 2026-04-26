import asynchttpserver, asyncdispatch, json, strformat, strutils, times, tables
import agent_base, llm_integration, tool_registry, agent_execution_engine
import example_ceo_functional

proc respondJson(req: Request, status: HttpCode, data: JsonNode) {.async.} =
  let headers = newHttpHeaders([("Content-Type", "application/json")])
  await req.respond(status, $data, headers)

proc artifactToJson(artifact: Artifact): JsonNode =
  return %* {
    "name": artifact.name,
    "path": artifact.path,
    "artifactType": artifact.artifactType,
    "size": artifact.size,
    "checksum": artifact.checksum
  }

proc taskResultToJson(agentName: string, taskResult: TaskResult): JsonNode =
  var artifacts = newJArray()
  for artifact in taskResult.artifacts:
    artifacts.add(artifactToJson(artifact))

  return %* {
    "success": taskResult.success,
    "agent": agentName,
    "output": taskResult.output,
    "qualityScore": taskResult.qualityScore,
    "agentFeedback": taskResult.agentFeedback,
    "artifacts": artifacts,
    "executionMetrics": {
      "durationMs": taskResult.executionMetrics.durationMs,
      "tokensUsed": taskResult.executionMetrics.tokensUsed,
      "cost": taskResult.executionMetrics.cost,
      "toolsUsed": taskResult.executionMetrics.toolsUsed,
      "errors": taskResult.executionMetrics.errors
    }
  }

proc processRequest(req: Request) {.async, gcsafe.} =
  if req.reqMethod == HttpPost and req.url.path == "/api/v1/execute":
    try:
      let bodyStr = req.body
      if bodyStr == "":
        await req.respondJson(Http400, %*{"error": "Empty body"})
        return
        
      let body = parseJson(bodyStr)
      if not body.hasKey("description") or not body.hasKey("name"):
        await req.respondJson(Http400, %*{"error": "Missing 'name' or 'description'"})
        return
        
      let taskName = body["name"].getStr()
      let taskDesc = body["description"].getStr()
      let taskType = if body.hasKey("taskType"): body["taskType"].getStr() else: "generic"
      
      let llmConfig = example_ceo_functional.initLLMConfig()
      let registry = example_ceo_functional.initToolRegistry()
      var stackAgents = initStackAgents(registry, llmConfig)
      
      var ceo = CEOOrchestrator(
        name: "CEO-Agent",
        stackAgents: stackAgents,
        llmConfig: llmConfig,
        registry: registry,
        totalTasks: 0,
        successfulTasks: 0
      )
      
      # Using a pseudo-random ID
      let taskId = int(now().toTime().toUnix() mod 1000000)
      
      let newTask = ProjectTask(
        id: taskId,
        name: taskName,
        description: taskDesc,
        taskType: taskType,
        priority: tpNormal,
        context: newJObject()
      )
      
      let assignedAgent = assignTaskToAgent(ceo, newTask)
      var targetAgent = assignedAgent # need mutable
      let taskExecutionResult = executeTask(targetAgent, newTask, registry)
      
      if taskExecutionResult.success:
        ceo.successfulTasks += 1
        
      ceo.totalTasks += 1
      
      # Serialize output
      let resJson = taskResultToJson(targetAgent.name, taskExecutionResult)
      
      await req.respondJson(Http200, resJson)
    except JsonParsingError:
      await req.respondJson(Http400, %*{"error": "Invalid JSON format"})
    except Exception as e:
      await req.respondJson(Http500, %*{"error": "Internal server error", "message": e.msg})
  else:
    await req.respondJson(Http404, %*{"error": "Endpoint not found. Use POST /api/v1/execute"})

proc main() {.async.} =
  let server = newAsyncHttpServer()
  echo "🚀 Iniciando CEO-Agents API Server en http://0.0.0.0:8080"
  await server.serve(Port(8080), processRequest)

waitFor main()
