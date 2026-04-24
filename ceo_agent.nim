## CEO Agent - Orquestador Jerárquico con Evolución de Estrategias
## 
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

import random, math, tables, strutils, sequtils, algorithm, strformat

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

  StackAgent* = object
    name*: string
    specialization*: seq[TaskType]
    workload*: float         # 0.0..1.0
    performance*: float      # avg success 0.0..1.0
    tasksCompleted*: int

  # CEO Genome: estrategias de enrutamiento y priorización
  CEOGenome* = object
    routingWeights*: Table[TaskType, Table[string, float]]  # task -> agent -> weight
    urgencyMultiplier*: array[TaskUrgency, float]
    complexityThreshold*: Table[string, float]  # agent -> max complexity
    workloadCapacity*: float                     # max workload antes de redistribuir
    reassignmentRate*: float                     # % tasks para re-evaluar

  CEOAgent* = object
    genome*: CEOGenome
    fitness*: float
    stackAgents*: seq[StackAgent]
    taskHistory*: seq[Task]
    totalTasks*: int
    successfulTasks*: int

## ============================================================================
## Initialization
## ============================================================================

proc initStackAgent*(name: string, specialization: seq[TaskType]): StackAgent =
  result.name = name
  result.specialization = specialization
  result.workload = 0.0
  result.performance = 0.5
  result.tasksCompleted = 0

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

proc initCEOAgent*(): CEOAgent =
  result.genome = randomCEOGenome()
  result.fitness = 0.0
  result.stackAgents = @[
    initStackAgent("PythonAgent", @[ttDataProcessing, ttResearch, ttCodeRefactor]),
    initStackAgent("TypeScriptAgent", @[ttFrontendUI, ttAPIDesign, ttCodeRefactor]),
    initStackAgent("DevOpsAgent", @[ttDevOps, ttTesting]),
    initStackAgent("DataScienceAgent", @[ttDataProcessing, ttResearch]),
    initStackAgent("FrontendAgent", @[ttFrontendUI, ttDocumentation]),
    initStackAgent("BackendAgent", @[ttAPIDesign, ttDatabaseDesign]),
    initStackAgent("DatabaseAgent", @[ttDatabaseDesign, ttDataProcessing]),
    initStackAgent("SecurityAgent", @[ttSecurity, ttCodeRefactor]),
    initStackAgent("TestingAgent", @[ttTesting, ttCodeRefactor]),
    initStackAgent("DocsAgent", @[ttDocumentation, ttResearch])
  ]
  result.taskHistory = @[]
  result.totalTasks = 0
  result.successfulTasks = 0

## ============================================================================
## Task Routing & Assignment
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

proc executeTask*(ceo: var CEOAgent, task: var Task) =
  ## Simula ejecución de task (éxito basado en match agente-task)
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
  
  # Ejecución
  task.successScore = min(1.0, successProb + rand(0.3) - 0.15)
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
## Fitness Evaluation
## ============================================================================

proc evaluateFitness*(ceo: var CEOAgent) =
  ## Fitness multi-objetivo del CEO:
  ## - Success rate (tasks exitosas)
  ## - Workload balance (distribución equitativa)
  ## - Agent utilization (uso eficiente de especialistas)
  
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
  
  # Fitness combinado
  ceo.fitness = 0.5 * successRate + 0.3 * workloadBalance + 0.2 * avgPerformance

## ============================================================================
## Evolutionary Operators
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

## ============================================================================
## Evolution Loop
## ============================================================================

proc evolveCEO*(popSize, generations: int, taskSet: seq[Task]): CEOAgent =
  ## Evoluciona una población de CEO agents para optimizar routing
  var population: seq[CEOAgent] = @[]
  
  # Inicializar población
  for _ in 0..<popSize:
    population.add(initCEOAgent())
  
  var bestOverall: CEOAgent
  var bestFitness = -1.0
  
  for gen in 1..generations:
    # Evaluar cada CEO en taskSet
    for i in 0..<population.len:
      # Reset para esta evaluación
      population[i].totalTasks = 0
      population[i].successfulTasks = 0
      population[i].taskHistory = @[]
      
      # Re-inicializar stack agents
      for j in 0..<population[i].stackAgents.len:
        population[i].stackAgents[j].workload = 0.0
        population[i].stackAgents[j].tasksCompleted = 0
      
      # Ejecutar tasks
      for t in taskSet:
        var task = t  # copia
        population[i].assignTask(task)
        population[i].executeTask(task)
      
      population[i].evaluateFitness()
      
      if population[i].fitness > bestFitness:
        bestFitness = population[i].fitness
        bestOverall = population[i]
    
    # Ordenar por fitness
    population.sort(proc(a, b: CEOAgent): int = cmp(b.fitness, a.fitness))
    
    echo &"Gen {gen:3d} | Best Fitness: {bestFitness:6.4f} | Success: {bestOverall.successfulTasks}/{bestOverall.totalTasks}"
    
    # Nueva generación
    var newPop: seq[CEOAgent] = @[]
    
    # Elitismo (top 10%)
    let eliteCount = max(1, popSize div 10)
    for i in 0..<eliteCount:
      newPop.add(population[i])
    
    # Generar resto con crossover + mutation
    while newPop.len < popSize:
      # Torneo selección
      let p1 = population[rand(min(9, population.len - 1))]
      let p2 = population[rand(min(9, population.len - 1))]
      
      var child = initCEOAgent()
      child.genome = crossover(p1.genome, p2.genome)
      mutate(child.genome, 0.15)
      
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
      description: &"Task {i}",
      estimatedTime: 0.5 + rand(3.0),
      assignedAgent: "",
      completed: false,
      successScore: 0.0
    )
    result.add(task)

## ============================================================================
## Main Demo
## ============================================================================

when isMainModule:
  echo "=== CEO Agent Evolution Demo ==="
  echo "Evolucionando estrategias de orquestación jerárquica\n"
  
  # Generar conjunto de tasks
  let taskSet = generateRandomTasks(50)
  
  echo &"Dataset: {taskSet.len} tasks"
  echo &"Task types: {TaskType.high.ord + 1} categorías"
  echo &"Stack agents: 10 especializados\n"
  
  # Evolucionar CEO
  let bestCEO = evolveCEO(popSize=20, generations=30, taskSet=taskSet)
  
  echo "\n=== Best CEO Agent ==="
  echo &"Fitness: {bestCEO.fitness:.4f}"
  echo &"Success Rate: {bestCEO.successfulTasks}/{bestCEO.totalTasks} ({100.0*bestCEO.successfulTasks.float/bestCEO.totalTasks.float:.1f}%)"
  echo &"\nStack Agents Performance:"
  for sa in bestCEO.stackAgents:
    echo &"  {sa.name:20s} | Perf: {sa.performance:5.3f} | Tasks: {sa.tasksCompleted:3d} | Workload: {sa.workload:5.2f}"
  
  echo &"\nTop Routing Weights (sample):"
  for tt in [ttFrontendUI, ttAPIDesign, ttDevOps, ttSecurity]:
    echo &"  {tt}:"
    var weights: seq[(string, float)] = @[]
    for k, v in bestCEO.genome.routingWeights[tt]:
      weights.add((k, v))
    weights.sort(proc(a, b: (string, float)): int = cmp(b[1], a[1]))
    for i in 0..<min(3, weights.len):
      echo &"    {weights[i][0]:20s} -> {weights[i][1]:6.3f}"
  
  echo "\n✓ CEO Agent evolution completed"
