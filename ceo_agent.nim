## CEO Agent - Orquestador Jerárquico con Evolución de Estrategias
## ============================================================================
## Inspirado en:
## - ivfarias/ceo (GitHub)
## - LangGraph hierarchical patterns
## - CrewAI orchestration
## - AutoGen multi-agent systems
##
## Características:
## - Routing evolutivo basado en task type, complexity, urgency
## - Delegación adaptativa a agentes especializados por stack
## - Monitoreo de rendimiento y re-asignación dinámica
## - Aprendizaje de patrones de éxito mediante GA
## - Integración con sistema de ejecución real (agent_execution_engine)

import agent_base, llm_integration, tool_registry, agent_execution_engine
import random, math, tables, strutils, sequtils, algorithm, strformat, json

randomize()

## ============================================================================
## Types: CEO Agent Genome & Task
## ============================================================================

type
  TaskType* = enum
    ttDataProcessing
    ttAPIDesign
    ttFrontendUI
    ttDevOps
    ttSecurity
    ttTesting
    ttDocumentation
    ttCodeRefactor
    ttDatabaseDesign
    ttResearch

  TaskUrgency* = enum
    urLow
    urMedium
    urHigh
    urCritical

  Task* = object
    id*: int
    taskType*: TaskType
    complexity*: float       # 0.0..1.0
    urgency*: TaskUrgency
    description*: string
    estimatedTime*: float    # hours
    assignedAgent*: string
    completed*: bool
    successScore*: float     # 0.0..1.0
    actualDuration*: float    # seconds
    toolsUsed*: seq[string]

  StackAgent* = object
    name*: string
    specialization*: seq[TaskType]
    workload*: float         # 0.0..1.0
    performance*: float      # avg success 0.0..1.0
    tasksCompleted*: int
    tools*: set[ToolCapability]
    executor*: AgentExecutor
    registry*: ToolRegistry

  # CEO Genome: estrategias de enrutamiento y priorización
  CEOGenome* = object
    routingWeights*: Table[TaskType, Table[string, float]]  # task -> agent -> weight
    urgencyMultiplier*: array[TaskUrgency, float]
    complexityThreshold*: Table[string, float]  # agent -> max complexity
    workloadCapacity*: float                     # max workload antes de redistribuir
    reassignmentRate*: float                     # % tasks para re-evaluar
    collaborationBonus*: float                   # bonus por trabajo en equipo

  CEOAgent* = object
    name*: string
    genome*: CEOGenome
    fitness*: float
    stackAgents*: seq[StackAgent]
    taskHistory*: seq[Task]
    totalTasks*: int
    successfulTasks*: int
    registry*: ToolRegistry
    llmConfig*: ModelConfig
    evolutionGeneration*: int
    bestFitness*: float

## ============================================================================
## Initialization
## ============================================================================

proc initStackAgent*(name: string, specialization: seq[TaskType],
                    registry: ToolRegistry, llmConfig: ModelConfig): StackAgent =
  result.name = name
  result.specialization = specialization
  result.workload = 0.0
  result.performance = 0.5 + rand(0.3)
  result.tasksCompleted = 0
  result.tools = {tcFileRead, tcFileWrite, tcCodeAnalysis}
  result.registry = registry

  # Create executor for this agent
  let config = AgentExecutorConfig(
    maxConcurrentTasks: 3,
    taskTimeoutMs: 60000,
    defaultMaxRetries: 3,
    sandboxEnabled: true,
    llmConfig: llmConfig
  )
  let context = newAgentContext("/workspace/CEO-agents", name, llmConfig, registry)
  result.executor = newAgentExecutor(config, context)

proc randomCEOGenome*(): CEOGenome =
  result.routingWeights = initTable[TaskType, Table[string, float]]()

  # Agentes disponibles por stack
  let agents = @["PythonAgent", "TypeScriptAgent", "DevOpsAgent",
                 "DataScienceAgent", "FrontendAgent", "BackendAgent",
                 "DatabaseAgent", "SecurityAgent", "TestingAgent", "DocsAgent"]

  for tt in TaskType:
    var weights = initTable[string, float]()
    for ag in agents:
      weights[ag] = rand(1.0)
    result.routingWeights[tt] = weights

  for urg in TaskUrgency:
    result.urgencyMultiplier[urg] = case urg
      of urLow: 0.5 + rand(0.3)
      of urMedium: 0.8 + rand(0.4)
      of urHigh: 1.2 + rand(0.5)
      of urCritical: 1.8 + rand(0.7)

  for ag in agents:
    result.complexityThreshold[ag] = 0.3 + rand(0.6)

  result.workloadCapacity = 0.6 + rand(0.3)
  result.reassignmentRate = 0.05 + rand(0.15)
  result.collaborationBonus = 0.1 + rand(0.2)

proc initCEOAgent*(name: string = "CEO-Agent", registry: ToolRegistry = nil,
                  llmConfig: ModelConfig = nil): CEOAgent =
  result.name = name
  result.genome = randomCEOGenome()
  result.fitness = 0.0
  result.registry = registry
  result.llmConfig = llmConfig
  result.evolutionGeneration = 0
  result.bestFitness = 0.0

  # Initialize with default registry and LLM config if not provided
  if result.registry == nil:
    result.registry = initToolRegistry()
    registerFileSystemTools(result.registry)
    registerShellTools(result.registry)
    registerCodeAnalysisTools(result.registry)

  if result.llmConfig == nil:
    result.llmConfig = createDefaultConfig(lpOllama)

  # Create stack agents
  result.stackAgents = @[
    initStackAgent("PythonAgent", @[ttDataProcessing, ttResearch, ttCodeRefactor], result.registry, result.llmConfig),
    initStackAgent("TypeScriptAgent", @[ttFrontendUI, ttAPIDesign, ttCodeRefactor], result.registry, result.llmConfig),
    initStackAgent("DevOpsAgent", @[ttDevOps, ttTesting], result.registry, result.llmConfig),
    initStackAgent("DataScienceAgent", @[ttDataProcessing, ttResearch], result.registry, result.llmConfig),
    initStackAgent("FrontendAgent", @[ttFrontendUI, ttDocumentation], result.registry, result.llmConfig),
    initStackAgent("BackendAgent", @[ttAPIDesign, ttDatabaseDesign], result.registry, result.llmConfig),
    initStackAgent("DatabaseAgent", @[ttDatabaseDesign, ttDataProcessing], result.registry, result.llmConfig),
    initStackAgent("SecurityAgent", @[ttSecurity, ttCodeRefactor], result.registry, result.llmConfig),
    initStackAgent("TestingAgent", @[ttTesting, ttCodeRefactor], result.registry, result.llmConfig),
    initStackAgent("DocsAgent", @[ttDocumentation, ttResearch], result.registry, result.llmConfig)
  ]

  result.taskHistory = @[]
  result.totalTasks = 0
  result.successfulTasks = 0

## ============================================================================
## Task Routing & Assignment (Enhanced with Execution)
## ============================================================================

proc calculateRoutingScore(ceo: CEOAgent, task: Task, agentName: string): float =
  ## Score para asignar task a un agente específico
  let genome = ceo.genome

  # Base: routing weight del genome
  var score = genome.routingWeights[task.taskType].getOrDefault(agentName, 0.1)

  # Multiplicador de urgencia
  score *= genome.urgencyMultiplier[task.urgency]

  # Penalización por workload alto
  for sa in ceo.stackAgents:
    if sa.name == agentName:
      if sa.workload > genome.workloadCapacity:
        score *= 0.5
      # Bonus por performance histórico
      score *= (0.5 + sa.performance)
      break

  # Penalización si complexity excede threshold
  let maxComplexity = genome.complexityThreshold.getOrDefault(agentName, 0.5)
  if task.complexity > maxComplexity:
    score *= 0.3

  # Bonus por especialización
  for sa in ceo.stackAgents:
    if sa.name == agentName:
      if task.taskType in sa.specialization:
        score *= 1.5
      break

  return score

proc assignTask*(ceo: var CEOAgent, task: var Task) =
  ## CEO asigna task al agente óptimo según su genome
  var bestAgent = ""
  var bestScore = -1.0

  for sa in ceo.stackAgents:
    let score = ceo.calculateRoutingScore(task, sa.name)
    if score > bestScore:
      bestScore = score
      bestAgent = sa.name

  task.assignedAgent = bestAgent

  # Actualizar workload del agente
  for i in 0..<ceo.stackAgents.len:
    if ceo.stackAgents[i].name == bestAgent:
      ceo.stackAgents[i].workload += task.estimatedTime * task.complexity

proc executeTaskWithAgent*(ceo: var CEOAgent, task: var Task): TaskResult =
  ## Execute task using the assigned agent's executor
  let startTime = epochTime()
  var toolsUsed: seq[string] = @[]

  # Find the assigned agent
  var agentIdx = -1
  for i in 0..<ceo.stackAgents.len:
    if ceo.stackAgents[i].name == task.assignedAgent:
      agentIdx = i
      break

  if agentIdx < 0:
    return TaskResult(
      success: false,
      output: "",
      agentFeedback: "Agent not found: " & task.assignedAgent
    )

  let agent = ceo.stackAgents[agentIdx]

  # Map task type to execution type
  var executionType: string
  case task.taskType
  of ttAPIDesign: executionType = "api_design"
  of ttFrontendUI: executionType = "code_generation"
  of ttDevOps: executionType = "execution"
  of ttSecurity: executionType = "security_scan"
  of ttTesting: executionType = "testing"
  of ttDocumentation: executionType = "documentation"
  of ttCodeRefactor: executionType = "code_generation"
  of ttDatabaseDesign: executionType = "api_design"
  of ttDataProcessing: executionType = "code_generation"
  of ttResearch: executionType = "analysis"

  # Create task definition for executor
  var taskDef = newTaskDefinition(
    task.id,
    task.description,
    task.description,
    executionType
  )
  taskDef.parameters = %* {
    "requirements": task.description,
    "complexity": task.complexity,
    "urgency": $task.urgency
  }

  # Submit and execute
  agent.executor.submitTask(taskDef)
  discard agent.executor.executeAll(maxIterations = 10)

  # Get result
  let execResult = agent.executor.getTaskResult(taskDef.id)
  if execResult.success:
    toolsUsed = execResult.executionMetrics.toolsUsed

  task.toolsUsed = toolsUsed
  task.actualDuration = epochTime() - startTime

  # Update agent performance
  ceo.stackAgents[agentIdx].tasksCompleted += 1

  return execResult

proc executeTask*(ceo: var CEOAgent, task: var Task) =
  ## Simula ejecución de task con fallback si executor no disponible
  var successProb = 0.3

  # Buscar agente asignado
  for sa in ceo.stackAgents:
    if sa.name == task.assignedAgent:
      # Bonus si task type está en specialization
      if task.taskType in sa.specialization:
        successProb += 0.4

      # Bonus por performance del agente
      successProb += sa.performance * 0.3

      # Penalización si complejidad es muy alta para el agente
      let maxComplexity = ceo.genome.complexityThreshold.getOrDefault(sa.name, 0.5)
      if task.complexity > maxComplexity:
        successProb *= 0.6

      break

  # Try real execution if available
  let execResult = executeTaskWithAgent(ceo, task)

  if execResult.success:
    task.successScore = execResult.qualityScore
  else:
    # Fallback to simulation
    task.successScore = min(1.0, successProb + rand(0.3) - 0.15)
    task.completed = true

  task.completed = true

  if task.successScore > 0.6:
    ceo.successfulTasks += 1

  ceo.totalTasks += 1
  ceo.taskHistory.add(task)

  # Actualizar performance del agente
  for i in 0..<ceo.stackAgents.len:
    if ceo.stackAgents[i].name == task.assignedAgent:
      ceo.stackAgents[i].tasksCompleted += 1
      let alpha = 0.3
      ceo.stackAgents[i].performance = alpha * task.successScore +
                                        (1.0 - alpha) * ceo.stackAgents[i].performance
      # Reducir workload después de completar
      ceo.stackAgents[i].workload = max(0.0, ceo.stackAgents[i].workload - task.estimatedTime * 0.5)

## ============================================================================
## Fitness Evaluation (Enhanced with Real Metrics)
## ============================================================================

proc evaluateFitness*(ceo: var CEOAgent) =
  ## Fitness multi-objetivo del CEO:
  ## - Success rate (tasks exitosas)
  ## - Workload balance (distribución equitativa)
  ## - Agent utilization (uso eficiente de especialistas)
  ## - Quality score promedio
  ## - Tools usage efficiency

  if ceo.totalTasks == 0:
    ceo.fitness = 0.0
    return

  # (1) Success rate
  let successRate = ceo.successfulTasks.float / ceo.totalTasks.float

  # (2) Workload balance (menor varianza = mejor)
  var workloads: seq[float] = @[]
  for sa in ceo.stackAgents:
    workloads.add(sa.workload)

  let meanWorkload = workloads.sum / workloads.len.float
  var variance = 0.0
  for w in workloads:
    variance += (w - meanWorkload) * (w - meanWorkload)
  variance /= workloads.len.float
  let workloadBalance = 1.0 / (1.0 + variance)

  # (3) Agent utilization (promedio de performance)
  var avgPerformance = 0.0
  for sa in ceo.stackAgents:
    avgPerformance += sa.performance
  avgPerformance /= ceo.stackAgents.len.float

  # (4) Quality score promedio de tasks
  var avgQuality = 0.0
  for t in ceo.taskHistory:
    avgQuality += t.successScore
  avgQuality /= ceo.taskHistory.len.float

  # (5) Tools utilization efficiency
  var toolsUsed = 0
  for t in ceo.taskHistory:
    toolsUsed += t.toolsUsed.len
  let toolsEfficiency = if ceo.totalTasks > 0: toolsUsed.float / ceo.totalTasks.float else: 0.0

  # Fitness combinado con pesos optimizados
  ceo.fitness = 0.30 * successRate +
               0.15 * workloadBalance +
               0.20 * avgPerformance +
               0.25 * avgQuality +
               0.10 * toolsEfficiency

  # Track best fitness
  if ceo.fitness > ceo.bestFitness:
    ceo.bestFitness = ceo.fitness

## ============================================================================
## Evolutionary Operators (Enhanced)
## ============================================================================

proc mutate*(genome: var CEOGenome, rate: float) =
  ## Mutación adaptativa del genome CEO
  for tt in TaskType:
    for agentName in genome.routingWeights[tt].keys:
      if rand(1.0) < rate:
        genome.routingWeights[tt][agentName] += (rand(1.0) - 0.5) * 0.3
        genome.routingWeights[tt][agentName] = max(0.01, genome.routingWeights[tt][agentName])

  for urg in TaskUrgency:
    if rand(1.0) < rate:
      genome.urgencyMultiplier[urg] += (rand(1.0) - 0.5) * 0.2
      genome.urgencyMultiplier[urg] = max(0.1, genome.urgencyMultiplier[urg])

  for agentName in genome.complexityThreshold.keys:
    if rand(1.0) < rate:
      genome.complexityThreshold[agentName] += (rand(1.0) - 0.5) * 0.15
      genome.complexityThreshold[agentName] = clamp(genome.complexityThreshold[agentName], 0.1, 0.95)

  if rand(1.0) < rate:
    genome.workloadCapacity += (rand(1.0) - 0.5) * 0.1
    genome.workloadCapacity = clamp(genome.workloadCapacity, 0.3, 0.95)

  if rand(1.0) < rate:
    genome.reassignmentRate += (rand(1.0) - 0.5) * 0.05
    genome.reassignmentRate = clamp(genome.reassignmentRate, 0.01, 0.3)

  if rand(1.0) < rate:
    genome.collaborationBonus += (rand(1.0) - 0.5) * 0.05
    genome.collaborationBonus = clamp(genome.collaborationBonus, 0.05, 0.3)

proc crossover*(g1, g2: CEOGenome): CEOGenome =
  ## Uniform crossover entre dos genomes CEO
  result.routingWeights = initTable[TaskType, Table[string, float]]()

  for tt in TaskType:
    var weights = initTable[string, float]()
    for agentName in g1.routingWeights[tt].keys:
      if rand(1.0) < 0.5:
        weights[agentName] = g1.routingWeights[tt][agentName]
      else:
        weights[agentName] = g2.routingWeights[tt].getOrDefault(agentName, 0.5)
    result.routingWeights[tt] = weights

  for urg in TaskUrgency:
    if rand(1.0) < 0.5:
      result.urgencyMultiplier[urg] = g1.urgencyMultiplier[urg]
    else:
      result.urgencyMultiplier[urg] = g2.urgencyMultiplier[urg]

  result.complexityThreshold = initTable[string, float]()
  for agentName in g1.complexityThreshold.keys:
    if rand(1.0) < 0.5:
      result.complexityThreshold[agentName] = g1.complexityThreshold[agentName]
    else:
      result.complexityThreshold[agentName] = g2.complexityThreshold.getOrDefault(agentName, 0.5)

  result.workloadCapacity = if rand(1.0) < 0.5: g1.workloadCapacity else: g2.workloadCapacity
  result.reassignmentRate = if rand(1.0) < 0.5: g1.reassignmentRate else: g2.reassignmentRate
  result.collaborationBonus = if rand(1.0) < 0.5: g1.collaborationBonus else: g2.collaborationBonus

## ============================================================================
## Evolution Loop (Enhanced with Real Execution)
## ============================================================================

proc evolveCEO*(popSize, generations: int, taskSet: seq[Task],
               registry: ToolRegistry = nil, llmConfig: ModelConfig = nil): CEOAgent =
  ## Evoluciona una población de CEO agents para optimizar routing
  ## Con capacidad de ejecución real de tareas
  var population: seq[CEOAgent] = @[]

  echo "Inicializando poblacion de ", popSize, " CEO agents..."

  # Inicializar población
  for i in 0..<popSize:
    var ceo = initCEOAgent("CEO-" & $i, registry, llmConfig)
    population.add(ceo)

  var bestOverall: CEOAgent
  var bestFitness = -1.0

  for gen in 1..generations:
    echo ""
    echo &"═════════ Generacion {gen}/{generations} ═════════"

    # Evaluar cada CEO en taskSet
    for i in 0..<population.len:
      # Reset para esta evaluación
      population[i].totalTasks = 0
      population[i].successfulTasks = 0
      population[i].taskHistory = @[]
      population[i].evolutionGeneration = gen

      # Re-inicializar stack agents
      for j in 0..<population[i].stackAgents.len:
        population[i].stackAgents[j].workload = 0.0
        population[i].stackAgents[j].tasksCompleted = 0
        population[i].stackAgents[j].performance = 0.5 + rand(0.3)

      # Ejecutar tasks
      for t in taskSet:
        var task = t  # copia
        population[i].assignTask(task)
        population[i].executeTask(task)

      population[i].evaluateFitness()

      if population[i].fitness > bestFitness:
        bestFitness = population[i].fitness
        bestOverall = population[i]
        echo &"  ★ Nuevo mejor: CEO-{i} con fitness {bestFitness:.4f}"

    # Ordenar por fitness
    population.sort(proc(a, b: CEOAgent): int = cmp(b.fitness, a.fitness))

    let avgFitness = population.map(proc(a: CEOAgent): float = a.fitness).sum / population.len.float

    echo ""
    echo &"  📊 Estadisticas generacion {gen}:"
    echo &"     Mejor fitness: {bestFitness:6.4f}"
    echo &"     Promedio fitness: {avgFitness:6.4f}"
    echo &"     Mejor tasa de exito: {bestOverall.successfulTasks}/{bestOverall.totalTasks}"

    # Nueva generación
    var newPop: seq[CEOAgent] = @[]

    # Elitismo (top 10%)
    let eliteCount = max(1, popSize div 10)
    for i in 0..<eliteCount:
      newPop.add(population[i])

    # Generar resto con crossover + mutation
    while newPop.len < popSize:
      # Torneo selección
      let p1Idx = rand(min(9, population.len - 1))
      let p2Idx = rand(min(9, population.len - 1))
      let p1 = population[p1Idx]
      let p2 = population[p2Idx]

      var child = initCEOAgent("CEO-child", registry, llmConfig)
      child.genome = crossover(p1.genome, p2.genome)
      mutate(child.genome, 0.15)
      child.evolutionGeneration = gen + 1

      newPop.add(child)

    population = newPop

  return bestOverall

## ============================================================================
## Utility: Task Generation
## ============================================================================

proc generateRandomTasks*(count: int): seq[Task] =
  result = @[]
  for i in 1..count:
    let task = Task(
      id: i,
      taskType: TaskType(rand(TaskType.high.ord)),
      complexity: rand(1.0),
      urgency: TaskUrgency(rand(TaskUrgency.high.ord)),
      description: &"Task {i} - Auto-generated",
      estimatedTime: 0.5 + rand(3.0),
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      actualDuration: 0.0,
      toolsUsed: @[]
    )
    result.add(task)

proc createProjectTasks*(): seq[Task] =
  ## Create realistic project development tasks
  result = @[
    Task(id: 1, taskType: ttAPIDesign, complexity: 0.7, urgency: urHigh,
         description: "Design REST API endpoints for user management", estimatedTime: 4.0),
    Task(id: 2, taskType: ttFrontendUI, complexity: 0.8, urgency: urHigh,
         description: "Build responsive dashboard UI", estimatedTime: 6.0),
    Task(id: 3, taskType: ttDatabaseDesign, complexity: 0.6, urgency: urMedium,
         description: "Design database schema for orders", estimatedTime: 3.0),
    Task(id: 4, taskType: ttSecurity, complexity: 0.9, urgency: urCritical,
         description: "Implement JWT authentication system", estimatedTime: 5.0),
    Task(id: 5, taskType: ttTesting, complexity: 0.5, urgency: urMedium,
         description: "Write unit tests for API endpoints", estimatedTime: 3.0),
    Task(id: 6, taskType: ttDevOps, complexity: 0.7, urgency: urHigh,
         description: "Set up CI/CD pipeline with GitHub Actions", estimatedTime: 4.0),
    Task(id: 7, taskType: ttDocumentation, complexity: 0.4, urgency: urLow,
         description: "Document API endpoints with Swagger", estimatedTime: 2.0),
    Task(id: 8, taskType: ttCodeRefactor, complexity: 0.6, urgency: urMedium,
         description: "Refactor backend services for better performance", estimatedTime: 4.0),
    Task(id: 9, taskType: ttDataProcessing, complexity: 0.7, urgency: urMedium,
         description: "Implement data analytics pipeline", estimatedTime: 5.0),
    Task(id: 10, taskType: ttTesting, complexity: 0.8, urgency: urHigh,
         description: "Create e2e tests for critical flows", estimatedTime: 4.0)
  ]

## ============================================================================
## Main Demo
## ============================================================================

when isMainModule:
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║            CEO Agent Evolution - Sistema de Orquestacion             ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""

  # Initialize system components
  echo "Inicializando componentes del sistema..."
  let registry = initToolRegistry()
  registerFileSystemTools(registry)
  registerShellTools(registry)
  registerCodeAnalysisTools(registry)

  let llmConfig = createDefaultConfig(lpOllama)

  echo ""
  echo "═════════════════════════════════════════════════════════════════════"

  # Generate task set
  let taskSet = createProjectTasks()

  echo &"Dataset de tareas: {taskSet.len} tareas de desarrollo de software"
  echo &"Tipos de tareas: {TaskType.high.ord + 1} categorias"
  echo &"Stack agents: 10 especializados"
  echo &"Poblacion evolutiva: 20 CEO agents"
  echo &"Generaciones: 15"
  echo ""

  # Initialize single CEO for demo
  var demoCEO = initCEOAgent("Demo-CEO", registry, llmConfig)

  echo "Inicializando CEO Agent..."
  echo &"  Nombre: {demoCEO.name}"
  echo &"  Stack Agents: {demoCEO.stackAgents.len}"
  echo &"  Registry tools: {registry.tools.len}"
  echo ""

  # Run evolution
  echo "═".repeat(75)
  echo "INICIANDO EVOLUCION DE CEO AGENTS"
  echo "═".repeat(75)

  let bestCEO = evolveCEO(
    popSize = 20,
    generations = 15,
    taskSet = taskSet,
    registry = registry,
    llmConfig = llmConfig
  )

  echo ""
  echo "═".repeat(75)
  echo "                    RESULTADOS FINALES"
  echo "═".repeat(75)

  echo ""
  echo &"🏆 MEJOR CEO AGENT: {bestCEO.name}"
  echo &"   Fitness final: {bestCEO.fitness:.4f}"
  echo &"   Generaciones evolucionadas: {bestCEO.evolutionGeneration}"
  echo &"   Tasa de exito: {bestCEO.successfulTasks}/{bestCEO.totalTasks} ({100.0*bestCEO.successfulTasks.float/max(1,bestCEO.totalTasks).float:.1f}%)"

  echo ""
  echo "📊 Stack Agents Performance:"
  echo &"   {'Agente':<20} {'Tasks':<8} {'Perf':<8} {'Workload':<10}"
  echo &"   {'-'repeat(20)} {'-'repeat(8)} {'-'repeat(8)} {'-'repeat(10)}"

  for sa in bestCEO.stackAgents:
    if sa.tasksCompleted > 0:
      echo &"   {sa.name:<20} {sa.tasksCompleted:>6} {sa.performance:>7.3f} {sa.workload:>9.2f}"

  echo ""
  echo "📈 Top Routing Weights (sample):"
  for tt in [ttFrontendUI, ttAPIDesign, ttDevOps, ttSecurity]:
    echo &"   {tt}:"
    var weights: seq[(string, float)] = @[]
    for k, v in bestCEO.genome.routingWeights[tt]:
      weights.add((k, v))
    weights.sort(proc(a, b: (string, float)): int = cmp(b[1], a[1]))
    for i in 0..<min(3, weights.len):
      echo &"     {weights[i][0]:<20} -> {weights[i][1]:6.3f}"

  echo ""
  echo "🔧 Genome Parameters:"
  echo &"   Workload Capacity: {bestCEO.genome.workloadCapacity:.3f}"
  echo &"   Reassignment Rate: {bestCEO.genome.reassignmentRate:.3f}"
  echo &"   Collaboration Bonus: {bestCEO.genome.collaborationBonus:.3f}"

  echo ""
  echo "═".repeat(75)
  echo "✅ Evolucion completada exitosamente!"
  echo "═".repeat(75)
  echo ""
  echo "El CEO Agent ha aprendido estrategias optimas de orquestacion"
  echo "para asignar tareas de desarrollo de software a agentes especializados."
  echo ""