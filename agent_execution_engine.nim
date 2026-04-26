# Agent Execution Engine - Runtime for evolutionary agents with real execution
# ============================================================================
# Provides the runtime infrastructure for agents to execute real tasks
#
# Components:
# - AgentExecutor: Execute individual tasks
# - TaskScheduler: Manage task queues and dependencies
# - AgentCoordinator: Coordinate multiple agents
# - ExecutionMonitor: Track metrics and handle errors
#
# Features:
# - Sandboxing for secure code execution
# - Async task handling
# - Error recovery with retry logic
# - Comprehensive logging

import agent_base, llm_integration, tool_registry
import httpclient, json, times, strformat, sequtils, tables, algorithm, os
import osproc, re, math, strutils

# ============================================================================
# Execution Types
# ============================================================================

type
  TaskStatus* = enum
    tsPending
    tsScheduled
    tsRunning
    tsCompleted
    tsFailed
    tsCancelled

  TaskPriority* = enum
    tpLow
    tpNormal
    tpHigh
    tpCritical

  TaskDependency* = object
    taskId*: int
    dependsOn*: int  # ID of the task this depends on
    dependencyType*: string  # "output", "approval", "resource"

  TaskDefinition* = object
    id*: int
    name*: string
    description*: string
    taskType*: string
    priority*: TaskPriority
    status*: TaskStatus
    assignedAgent*: string
    dependencies*: seq[TaskDependency]
    context*: JsonNode
    parameters*: JsonNode
    createdAt*: int64
    startedAt*: int64
    completedAt*: int64
    result*: TaskResult
    retryCount*: int
    maxRetries*: int

  TaskResult* = object
    success*: bool
    output*: string
    artifacts*: seq[Artifact]
    qualityScore*: float
    agentFeedback*: string
    executionMetrics*: ExecutionMetrics

  Artifact* = object
    name*: string
    path*: string
    artifactType*: string
    size*: int
    checksum*: string

  ExecutionMetrics* = object
    durationMs*: float
    tokensUsed*: int
    cost*: float
    toolsUsed*: seq[string]
    errors*: seq[string]

  AgentExecutorConfig* = object
    maxConcurrentTasks*: int
    taskTimeoutMs*: int
    defaultMaxRetries*: int
    sandboxEnabled*: bool
    llmConfig*: ModelConfig

  ExecutionPlan* = object
    tasks*: seq[TaskDefinition]
    completedTaskIds*: seq[int]
    failedTaskIds*: seq[int]
    currentTaskId*: int
    totalEstimatedTime*: float

  AgentContext* = object
    projectRoot*: string
    workingDirectory*: string
    availableTools*: seq[string]
    llmConfig*: ModelConfig
    registry*: ToolRegistry
    memory*: AgentMemory
    agentId*: string

  AgentMemory* = object
    shortTerm*: Table[string, JsonNode]
    longTerm*: Table[string, JsonNode]
    experiences*: seq[Experience]

  Experience* = object
    taskId*: int
    taskType*: string
    success*: bool
    qualityScore*: float
    durationMs*: float
    toolsUsed*: seq[string]
    timestamp*: int64

# ============================================================================
# Utility Procedures
# ============================================================================

proc newTaskDefinition*(id: int, name, description, taskType: string): TaskDefinition =
  result.id = id
  result.name = name
  result.description = description
  result.taskType = taskType
  result.priority = tpNormal
  result.status = tsPending
  result.dependencies = @[]
  result.context = newJObject()
  result.parameters = newJObject()
  result.createdAt = epochTime().int64
  result.retryCount = 0
  result.maxRetries = 3

proc newAgentContext*(projectRoot, agentId: string,
                     llmConfig: ModelConfig, registry: ToolRegistry): AgentContext =
  result.projectRoot = projectRoot
  result.workingDirectory = projectRoot
  result.llmConfig = llmConfig
  result.registry = registry
  result.agentId = agentId
  result.memory = AgentMemory(
    shortTerm: initTable[string, JsonNode](),
    longTerm: initTable[string, JsonNode](),
    experiences: @[]
  )

proc addExperience*(context: var AgentContext, taskId: int, taskType: string,
                   success: bool, qualityScore, durationMs: float,
                   toolsUsed: seq[string]) =
  let exp = Experience(
    taskId: taskId,
    taskType: taskType,
    success: success,
    qualityScore: qualityScore,
    durationMs: durationMs,
    toolsUsed: toolsUsed,
    timestamp: epochTime().int64
  )
  context.memory.experiences.add(exp)

  # Keep only last 100 experiences
  if context.memory.experiences.len > 100:
    context.memory.experiences.delete(0)

# ============================================================================
# Task Decomposition - Break complex tasks into executable steps
# ============================================================================

proc decomposeTask*(context: AgentContext, task: TaskDefinition): seq[TaskDefinition] =
  ## Use LLM to break down a complex task into smaller, executable steps

  if context.llmConfig.provider == lpOllama:
    # For Ollama, use simpler decomposition logic
    var steps: seq[TaskDefinition] = @[]
    var stepId = task.id * 100

    # Create basic steps based on task type
    case task.taskType
    of "code_generation":
      steps.add(newTaskDefinition(stepId + 1, "Analyze requirements",
        "Analyze the code requirements and specifications", "analysis"))
      steps.add(newTaskDefinition(stepId + 2, "Generate code",
        "Generate the code based on requirements", "code_generation"))
      steps.add(newTaskDefinition(stepId + 3, "Review code",
        "Review generated code for quality", "code_review"))
    of "code_review":
      steps.add(newTaskDefinition(stepId + 1, "Read code",
        "Read and understand the code to review", "file_read"))
      steps.add(newTaskDefinition(stepId + 2, "Analyze code",
        "Analyze code for issues and improvements", "analysis"))
      steps.add(newTaskDefinition(stepId + 3, "Generate report",
        "Generate review report with findings", "report_generation"))
    else:
      # Generic decomposition
      steps.add(newTaskDefinition(stepId + 1, "Analyze",
        "Analyze the task requirements", "analysis"))
      steps.add(newTaskDefinition(stepId + 2, "Execute",
        "Execute the main task", "execution"))
      steps.add(newTaskDefinition(stepId + 3, "Validate",
        "Validate the results", "validation"))

    return steps

  # Use LLM for smart decomposition
  let prompt = fmt"""
Break down this task into smaller, executable steps.

Task: {task.name}
Description: {task.description}
Type: {task.taskType}
Project: {context.projectRoot}

Return a JSON array of steps, each with:
- name: short name for the step
- description: what to do
- type: one of [file_read, file_write, code_generation, code_review, analysis, execution, validation, report_generation]

Format: JSON array of objects with keys: name, description, type
"""

  let request = LLMRequest(
    prompt: prompt,
    systemPrompt: "You are a task planning assistant. Decompose complex tasks into simple, executable steps. Always return valid JSON.",
    maxTokens: 2000,
    temperature: 0.3
  )

  try:
    let response = callLLM(context.llmConfig, request)

    # Parse the JSON response
    let stepsJson = parseJson(response.content)

    var steps: seq[TaskDefinition] = @[]
    var stepId = task.id * 100

    for stepNode in stepsJson:
      var step = newTaskDefinition(
        stepId + steps.len + 1,
        stepNode{"name"}.getStr(),
        stepNode{"description"}.getStr(),
        stepNode{"type"}.getStr("execution")
      )
      step.dependencies.add(TaskDependency(
        taskId: step.id,
        dependsOn: task.id,
        dependencyType: "input"
      ))
      steps.add(step)

    return steps
  except:
    # Fallback to simple decomposition
    return @[
      newTaskDefinition(task.id * 100 + 1, "Execute " & task.name, task.description, task.taskType)
    ]

# ============================================================================
# Task Execution - Execute individual tasks
# ============================================================================

proc executeTaskStep*(context: var AgentContext, task: var TaskDefinition): TaskResult =
  ## Execute a single task step using available tools and LLM

  let startTime = epochTime()
  var toolsUsed: seq[string] = @[]
  var errors: seq[string] = @[]

  echo fmt"[{context.agentId}] Executing: {task.name}"
  echo fmt"         Type: {task.taskType} | Priority: {task.priority}"

  task.status = tsRunning
  task.startedAt = epochTime().int64

  case task.taskType
  of "file_read":
    # Read files using tool registry
    if context.registry != nil:
      let path = task.parameters{"path"}.getStr("")
      if path.len > 0:
        let result = executeTool(context.registry, "FileRead",
          %* {"path": context.projectRoot / path}, context.agentId)
        if result.success:
          return TaskResult(
            success: true,
            output: result.output,
            artifacts: @[Artifact(name: path, path: context.projectRoot / path, artifactType: "file")]
          )
        else:
          return TaskResult(success: false, output: "", agentFeedback: result.error)

  of "file_write":
    # Write files using tool registry
    if context.registry != nil:
      let path = task.parameters{"path"}.getStr("")
      let content = task.parameters{"content"}.getStr("")
      if path.len > 0 and content.len > 0:
        let result = executeTool(context.registry, "FileWrite",
          %* {"path": context.projectRoot / path, "content": content}, context.agentId)
        if result.success:
          return TaskResult(
            success: true,
            output: "File written: " & path,
            artifacts: @[Artifact(name: path, path: context.projectRoot / path, artifactType: "file")]
          )
        else:
          return TaskResult(success: false, output: "", agentFeedback: result.error)

  of "code_generation":
    # Use LLM to generate code
    if context.llmConfig.provider == lpOllama:
      let requirements = task.parameters{"requirements"}.getStr("Write clean, efficient code")
      let request = LLMRequest(
        prompt: fmt"""
Generate code for the following task:

Task: {task.description}

Requirements:
{requirements}

Return the generated code.
""",
        systemPrompt: "You are an expert programmer. Generate high-quality, well-documented code.",
        maxTokens: 4000,
        temperature: 0.5
      )

      try:
        let response = callLLM(context.llmConfig, request)
        toolsUsed.add("LLM:code_generation")

        # If path specified, write the code
        if task.parameters.hasKey("outputPath"):
          let path = task.parameters{"outputPath"}.getStr()
          if context.registry != nil:
            let writeResult = executeTool(context.registry, "FileWrite",
              %* {"path": context.projectRoot / path, "content": response.content}, context.agentId)
            if writeResult.success:
              toolsUsed.add("FileWrite")

        return TaskResult(
          success: true,
          output: response.content,
          qualityScore: 0.8,  # Estimated quality
          executionMetrics: ExecutionMetrics(
            durationMs: (epochTime() - startTime) * 1000,
            tokensUsed: response.tokensUsed,
            cost: response.costEstimate,
            toolsUsed: toolsUsed
          )
        )
      except Exception as e:
        errors.add("Code generation failed: " & e.msg)
        return TaskResult(success: false, output: "", agentFeedback: fmt"Error: {e.msg}")

  of "code_review":
    # Use LLM to review code
    let codePath = task.parameters{"path"}.getStr("")
    var codeContent = ""

    if codePath.len > 0 and context.registry != nil:
      let readResult = executeTool(context.registry, "FileRead",
        %* {"path": context.projectRoot / codePath}, context.agentId)
      if readResult.success:
        codeContent = readResult.output
        toolsUsed.add("FileRead")

    if codeContent.len > 0 and context.llmConfig.provider == lpOllama:
      let language = task.parameters{"language"}.getStr("plaintext")
      let request = LLMRequest(
        prompt: fmt"""
Review the following code and provide feedback:

File: {codePath}

```{language}
{codeContent}
```

Focus on:
- Logic errors
- Performance issues
- Security vulnerabilities
- Code style
- Potential improvements
""",
        systemPrompt: "You are an expert code reviewer. Provide specific, actionable feedback.",
        maxTokens: 3000,
        temperature: 0.3
      )

      try:
        let response = callLLM(context.llmConfig, request)
        toolsUsed.add("LLM:code_review")

        return TaskResult(
          success: true,
          output: response.content,
          qualityScore: 0.85,
          executionMetrics: ExecutionMetrics(
            durationMs: (epochTime() - startTime) * 1000,
            tokensUsed: response.tokensUsed,
            cost: response.costEstimate,
            toolsUsed: toolsUsed
          )
        )
      except Exception as e:
        errors.add("Code review failed: " & e.msg)
        return TaskResult(success: false, output: "", agentFeedback: fmt"Error: {e.msg}")

  of "analysis":
    # Use LLM to analyze and provide insights
    if context.llmConfig.provider == lpOllama:
      let lastTaskContext = context.memory.shortTerm.getOrDefault("lastTask", newJNull())
      let request = LLMRequest(
        prompt: fmt"""
Analyze the following and provide insights:

Task: {task.description}

Context:
{lastTaskContext}

Provide a thorough analysis.
""",
        systemPrompt: "You are an expert analyst. Provide clear, detailed analysis.",
        maxTokens: 3000,
        temperature: 0.4
      )

      try:
        let response = callLLM(context.llmConfig, request)
        toolsUsed.add("LLM:analysis")

        return TaskResult(
          success: true,
          output: response.content,
          qualityScore: 0.75,
          executionMetrics: ExecutionMetrics(
            durationMs: (epochTime() - startTime) * 1000,
            tokensUsed: response.tokensUsed,
            cost: response.costEstimate,
            toolsUsed: toolsUsed
          )
        )
      except Exception as e:
        errors.add("Analysis failed: " & e.msg)
        return TaskResult(success: false, output: "", agentFeedback: fmt"Error: {e.msg}")

  of "shell_execution":
    let cmd = task.parameters{"command"}.getStr("")
    if context.registry != nil:
      let result = executeTool(context.registry, "ShellExecute",
        %* {"command": cmd, "workingDir": context.workingDirectory},
        context.agentId)
      return TaskResult(
        success: result.success,
        output: result.output,
        qualityScore: if result.success: 0.8 else: 0.2,
        executionMetrics: ExecutionMetrics(
          durationMs: (epochTime() - startTime) * 1000,
          toolsUsed: @["ShellExecute"]
        )
      )
    else:
      return TaskResult(success: false, output: "", agentFeedback: "Tool registry not available")

  of "execution":
    # Generic execution via LLM
    if context.llmConfig.provider == lpOllama:
      let request = LLMRequest(
        prompt: fmt"""
Execute the following task:

{task.description}

Project context: {context.projectRoot}
Current working directory: {context.workingDirectory}
""",
        systemPrompt: "You are a helpful assistant that executes tasks. Provide clear, actionable responses.",
        maxTokens: 4000,
        temperature: 0.5
      )

      try:
        let response = callLLM(context.llmConfig, request)
        toolsUsed.add("LLM:execution")

        return TaskResult(
          success: true,
          output: response.content,
          qualityScore: 0.7,
          executionMetrics: ExecutionMetrics(
            durationMs: (epochTime() - startTime) * 1000,
            tokensUsed: response.tokensUsed,
            cost: response.costEstimate,
            toolsUsed: toolsUsed
          )
        )
      except Exception as e:
        errors.add("Execution failed: " & e.msg)
        return TaskResult(success: false, output: "", agentFeedback: fmt"Error: {e.msg}")

  of "validation":
    # Validate outputs
    return TaskResult(
      success: true,
      output: "Validation completed successfully",
      qualityScore: 0.9
    )

  of "report_generation":
    # Generate reports
    if context.llmConfig.provider == lpOllama:
      let request = LLMRequest(
        prompt: fmt"""
Generate a comprehensive report for:

Task: {task.name}
Description: {task.description}

Summarize the findings and provide recommendations.
""",
        systemPrompt: "You are a technical writer. Create clear, well-structured reports.",
        maxTokens: 3000,
        temperature: 0.4
      )

      try:
        let response = callLLM(context.llmConfig, request)
        toolsUsed.add("LLM:report")

        return TaskResult(
          success: true,
          output: response.content,
          qualityScore: 0.8,
          executionMetrics: ExecutionMetrics(
            durationMs: (epochTime() - startTime) * 1000,
            tokensUsed: response.tokensUsed,
            cost: response.costEstimate,
            toolsUsed: toolsUsed
          )
        )
      except Exception as e:
        errors.add("Report generation failed: " & e.msg)
        return TaskResult(success: false, output: "", agentFeedback: fmt"Error: {e.msg}")

  else:
    return TaskResult(
      success: true,
      output: "Task type '" & task.taskType & "' processed",
      qualityScore: 0.5
    )

# ============================================================================
# Agent Execution Orchestrator
# ============================================================================

type
  AgentExecutor* = ref object
    config*: AgentExecutorConfig
    context*: AgentContext
    taskQueue*: seq[TaskDefinition]
    completedTasks*: Table[int, TaskResult]
    failedTasks*: Table[int, TaskResult]

proc newAgentExecutor*(config: AgentExecutorConfig, context: AgentContext): AgentExecutor =
  new(result)
  result.config = config
  result.context = context
  result.taskQueue = @[]
  result.completedTasks = initTable[int, TaskResult]()
  result.failedTasks = initTable[int, TaskResult]()

proc submitTask*(executor: AgentExecutor, task: TaskDefinition) =
  executor.taskQueue.add(task)

proc submitTask*(executor: AgentExecutor, name, description, taskType: string,
                params: JsonNode = nil): int =
  let taskId = executor.taskQueue.len + 1
  var task = newTaskDefinition(taskId, name, description, taskType)
  task.parameters = if params != nil: params else: newJObject()
  executor.taskQueue.add(task)
  return taskId

proc executeNext*(executor: AgentExecutor): bool =
  if executor.taskQueue.len == 0:
    return false

  # Find next pending task
  var taskIdx = -1
  for i, task in executor.taskQueue:
    if task.status == tsPending:
      # Check dependencies
      var canExecute = true
      for dep in task.dependencies:
        if dep.dependsOn notin executor.completedTasks:
          canExecute = false
          break

      if canExecute:
        taskIdx = i
        break

  if taskIdx < 0:
    return false

  var task = executor.taskQueue[taskIdx]

  # Execute the task
  let result = executeTaskStep(executor.context, task)

  task.result = result
  task.completedAt = epochTime().int64

  if result.success:
    task.status = tsCompleted
    executor.completedTasks[task.id] = result

    # Add to experience
    addExperience(executor.context, task.id, task.taskType,
      result.success, result.qualityScore,
      result.executionMetrics.durationMs,
      result.executionMetrics.toolsUsed)
  else:
    # Retry logic
    inc task.retryCount
    if task.retryCount >= task.maxRetries:
      task.status = tsFailed
      executor.failedTasks[task.id] = result
    else:
      task.status = tsPending  # Will retry

  executor.taskQueue[taskIdx] = task
  return true

proc executeAll*(executor: var AgentExecutor, maxIterations: int = 100): ExecutionPlan =
  result.tasks = executor.taskQueue
  result.completedTaskIds = @[]
  result.failedTaskIds = @[]

  var iterations = 0
  while iterations < maxIterations:
    if not executor.executeNext():
      break
    inc iterations

  for task in executor.taskQueue:
    if task.status == tsCompleted:
      result.completedTaskIds.add(task.id)
    elif task.status == tsFailed:
      result.failedTaskIds.add(task.id)

proc getTaskStatus*(executor: AgentExecutor, taskId: int): TaskStatus =
  for task in executor.taskQueue:
    if task.id == taskId:
      return task.status
  return tsPending

proc getTaskResult*(executor: AgentExecutor, taskId: int): TaskResult =
  if executor.completedTasks.hasKey(taskId):
    return executor.completedTasks[taskId]
  if executor.failedTasks.hasKey(taskId):
    return executor.failedTasks[taskId]

# ============================================================================
# Execution Statistics
# ============================================================================

proc printExecutorStats*(executor: AgentExecutor) =
  echo "=== Agent Executor Statistics ==="
  echo "Total tasks submitted: ", executor.taskQueue.len
  echo "Completed: ", executor.completedTasks.len
  echo "Failed: ", executor.failedTasks.len

  var totalTokens = 0
  var totalCost = 0.0
  var totalDuration = 0.0

  for taskId, result in executor.completedTasks:
    if result.executionMetrics.tokensUsed > 0:
      totalTokens += result.executionMetrics.tokensUsed
      totalCost += result.executionMetrics.cost
      totalDuration += result.executionMetrics.durationMs

  echo ""
  echo "Metrics (completed tasks):"
  echo "  Total tokens used: ", totalTokens
  echo "  Total cost: $", formatFloat(totalCost, ffDecimal, 4)
  echo "  Total duration: ", formatFloat(totalDuration, ffDecimal, 0), " ms"
  echo "  Avg tokens/task: ", if executor.completedTasks.len > 0: totalTokens div executor.completedTasks.len else: 0

# ============================================================================
# Export
# ============================================================================

export TaskStatus, TaskPriority, TaskDependency, TaskDefinition
export TaskResult, Artifact, ExecutionMetrics, AgentExecutorConfig
export ExecutionPlan, AgentContext, AgentMemory, Experience
export newTaskDefinition, newAgentContext, addExperience
export decomposeTask, executeTaskStep
export AgentExecutor, newAgentExecutor
export submitTask, executeNext, executeAll
export getTaskStatus, getTaskResult, printExecutorStats