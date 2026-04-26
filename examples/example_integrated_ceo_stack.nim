## Ejemplo Integrado: CEO + Stack Agents
##
## Caso de uso: desarrollo de una PWA (Progressive Web App)
## 
## El CEO Agent recibe un conjunto de tasks para construir la PWA:
## - Frontend UI (React/TypeScript)
## - Backend API (Node.js)
## - Database schema (PostgreSQL)
## - Security (authentication, HTTPS)
## - Testing (unit + e2e)
## - DevOps (CI/CD pipeline)
## - Documentation (API docs, user guide)
##
## El CEO Agent:
## 1. Analiza cada task y asigna al agente más apropiado
## 2. Los Stack Agents ejecutan las tasks, aprenden de resultados
## 3. El CEO evoluciona su estrategia de routing basado en feedback
## 4. El sistema co-evoluciona para maximizar éxito global del proyecto

import random, math, tables, strutils, sequtils, algorithm, times, strformat

randomize()

## ============================================================================
## Imports simulados (en un proyecto real, importarías ceo_agent y stack_agents)
## ============================================================================

type
  SkillDomain* = enum
    sdSyntax, sdArchitecture, sdPerformance, sdSecurity, sdTesting,
    sdDebugging, sdDocumentation, sdIntegration, sdDeployment, sdMaintenance

  StackAgentType* = enum
    satPython, satTypeScript, satDevOps, satDataScience, satFrontend,
    satBackend, satDatabase, satSecurity, satTesting, satDocs

  TaskType* = enum
    ttDataProcessing, ttAPIDesign, ttFrontendUI, ttDevOps, ttSecurity,
    ttTesting, ttDocumentation, ttCodeRefactor, ttDatabaseDesign, ttResearch

  TaskUrgency* = enum
    urLow, urMedium, urHigh, urCritical

  Task* = object
    id*: int
    taskType*: TaskType
    complexity*: float
    urgency*: TaskUrgency
    description*: string
    estimatedTime*: float
    assignedAgent*: string
    completed*: bool
    successScore*: float
    skillsRequired*: seq[SkillDomain]

  StackAgentGenome* = object
    skills*: Table[SkillDomain, float]
    learningRate*: float
    specializationDepth*: float
    collaborationScore*: float
    adaptabilityRate*: float

  TaskOutcome* = object
    taskId*: int
    success*: bool
    timeSpent*: float
    qualityScore*: float
    skillsUsed*: seq[SkillDomain]

  StackAgent* = object
    agentType*: StackAgentType
    genome*: StackAgentGenome
    fitness*: float
    experience*: seq[TaskOutcome]
    totalTasks*: int
    successfulTasks*: int
    name*: string

  CEOGenome* = object
    routingWeights*: Table[TaskType, Table[string, float]]
    urgencyMultiplier*: array[TaskUrgency, float]
    complexityThreshold*: Table[string, float]
    workloadCapacity*: float
    reassignmentRate*: float

  CEOAgent* = object
    genome*: CEOGenome
    fitness*: float
    stackAgents*: seq[StackAgent]
    taskHistory*: seq[Task]
    totalTasks*: int
    successfulTasks*: int

## ============================================================================
## PWA Project Tasks
## ============================================================================

proc createPWATasks*(): seq[Task] =
  result = @[
    # Phase 1: Design & Architecture
    Task(
      id: 1,
      taskType: ttFrontendUI,
      complexity: 0.7,
      urgency: urHigh,
      description: "Design responsive UI components with React",
      estimatedTime: 8.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdSyntax, sdArchitecture, sdDocumentation]
    ),
    Task(
      id: 2,
      taskType: ttAPIDesign,
      complexity: 0.8,
      urgency: urHigh,
      description: "Design RESTful API endpoints for data sync",
      estimatedTime: 6.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdArchitecture, sdIntegration, sdDocumentation]
    ),
    Task(
      id: 3,
      taskType: ttDatabaseDesign,
      complexity: 0.6,
      urgency: urMedium,
      description: "Design PostgreSQL schema for user data & cache",
      estimatedTime: 5.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdArchitecture, sdPerformance, sdSecurity]
    ),
    
    # Phase 2: Implementation
    Task(
      id: 4,
      taskType: ttFrontendUI,
      complexity: 0.9,
      urgency: urCritical,
      description: "Implement Service Worker for offline caching",
      estimatedTime: 12.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdSyntax, sdIntegration, sdDebugging]
    ),
    Task(
      id: 5,
      taskType: ttAPIDesign,
      complexity: 0.7,
      urgency: urHigh,
      description: "Implement Node.js backend API with Express",
      estimatedTime: 10.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdSyntax, sdArchitecture, sdIntegration]
    ),
    Task(
      id: 6,
      taskType: ttSecurity,
      complexity: 0.8,
      urgency: urCritical,
      description: "Implement JWT authentication & HTTPS",
      estimatedTime: 8.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdSecurity, sdIntegration, sdTesting]
    ),
    
    # Phase 3: Testing & QA
    Task(
      id: 7,
      taskType: ttTesting,
      complexity: 0.6,
      urgency: urMedium,
      description: "Write unit tests for API endpoints (Jest)",
      estimatedTime: 6.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdTesting, sdDebugging, sdSyntax]
    ),
    Task(
      id: 8,
      taskType: ttTesting,
      complexity: 0.75,
      urgency: urHigh,
      description: "E2E tests for PWA offline functionality (Cypress)",
      estimatedTime: 8.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdTesting, sdIntegration, sdDebugging]
    ),
    
    # Phase 4: DevOps & Deployment
    Task(
      id: 9,
      taskType: ttDevOps,
      complexity: 0.7,
      urgency: urHigh,
      description: "Set up CI/CD pipeline with GitHub Actions",
      estimatedTime: 7.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdDeployment, sdIntegration, sdTesting]
    ),
    Task(
      id: 10,
      taskType: ttDevOps,
      complexity: 0.65,
      urgency: urMedium,
      description: "Configure Docker containers for backend",
      estimatedTime: 5.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdDeployment, sdArchitecture, sdPerformance]
    ),
    
    # Phase 5: Documentation
    Task(
      id: 11,
      taskType: ttDocumentation,
      complexity: 0.5,
      urgency: urMedium,
      description: "Write API documentation with Swagger/OpenAPI",
      estimatedTime: 4.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdDocumentation, sdArchitecture]
    ),
    Task(
      id: 12,
      taskType: ttDocumentation,
      complexity: 0.4,
      urgency: urLow,
      description: "Create user guide & deployment instructions",
      estimatedTime: 3.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdDocumentation, sdDeployment]
    ),
    
    # Phase 6: Optimization & Refactoring
    Task(
      id: 13,
      taskType: ttCodeRefactor,
      complexity: 0.6,
      urgency: urLow,
      description: "Optimize bundle size & lazy loading",
      estimatedTime: 6.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdPerformance, sdArchitecture, sdSyntax]
    ),
    Task(
      id: 14,
      taskType: ttDataProcessing,
      complexity: 0.7,
      urgency: urMedium,
      description: "Implement data analytics for user behavior",
      estimatedTime: 8.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdArchitecture, sdIntegration, sdPerformance]
    ),
    Task(
      id: 15,
      taskType: ttSecurity,
      complexity: 0.75,
      urgency: urHigh,
      description: "Security audit & vulnerability scanning",
      estimatedTime: 6.0,
      assignedAgent: "",
      completed: false,
      successScore: 0.0,
      skillsRequired: @[sdSecurity, sdTesting, sdDebugging]
    )
  ]

## ============================================================================
## Inicialización simplificada de agentes (versión demo)
## ============================================================================

proc initDemoStackAgent(name: string, agentType: StackAgentType, 
                        primarySkills: seq[SkillDomain]): StackAgent =
  result.name = name
  result.agentType = agentType
  result.genome.skills = initTable[SkillDomain, float]()
  
  for skill in SkillDomain:
    if skill in primarySkills:
      result.genome.skills[skill] = 0.7 + rand(0.25)
    else:
      result.genome.skills[skill] = 0.3 + rand(0.3)
  
  result.genome.learningRate = 0.1 + rand(0.1)
  result.genome.specializationDepth = 0.65 + rand(0.25)
  result.genome.collaborationScore = 0.6 + rand(0.3)
  result.genome.adaptabilityRate = 0.15 + rand(0.1)
  
  result.fitness = 0.0
  result.experience = @[]
  result.totalTasks = 0
  result.successfulTasks = 0

proc initDemoCEO(): CEOAgent =
  result.genome.routingWeights = initTable[TaskType, Table[string, float]]()
  
  let agents = @["TypeScriptAgent", "FrontendAgent", "BackendAgent", 
                 "DatabaseAgent", "SecurityAgent", "TestingAgent",
                 "DevOpsAgent", "DocsAgent", "PythonAgent", "DataScienceAgent"]
  
  for tt in TaskType:
    var weights = initTable[string, float]()
    for ag in agents:
      weights[ag] = rand(1.0)
    result.genome.routingWeights[tt] = weights
  
  for urg in TaskUrgency:
    result.genome.urgencyMultiplier[urg] = case urg
      of urLow: 0.6
      of urMedium: 1.0
      of urHigh: 1.5
      of urCritical: 2.2
  
  result.genome.complexityThreshold = initTable[string, float]()
  for ag in agents:
    result.genome.complexityThreshold[ag] = 0.5 + rand(0.3)
  
  result.genome.workloadCapacity = 0.75
  result.genome.reassignmentRate = 0.1
  
  result.stackAgents = @[
    initDemoStackAgent("TypeScriptAgent", satTypeScript, @[sdSyntax, sdArchitecture, sdIntegration]),
    initDemoStackAgent("FrontendAgent", satFrontend, @[sdSyntax, sdIntegration, sdPerformance]),
    initDemoStackAgent("BackendAgent", satBackend, @[sdArchitecture, sdSecurity, sdIntegration]),
    initDemoStackAgent("DatabaseAgent", satDatabase, @[sdArchitecture, sdPerformance, sdSecurity]),
    initDemoStackAgent("SecurityAgent", satSecurity, @[sdSecurity, sdTesting, sdDebugging]),
    initDemoStackAgent("TestingAgent", satTesting, @[sdTesting, sdDebugging, sdDocumentation]),
    initDemoStackAgent("DevOpsAgent", satDevOps, @[sdDeployment, sdIntegration, sdPerformance]),
    initDemoStackAgent("DocsAgent", satDocs, @[sdDocumentation, sdArchitecture]),
    initDemoStackAgent("PythonAgent", satPython, @[sdSyntax, sdArchitecture, sdTesting]),
    initDemoStackAgent("DataScienceAgent", satDataScience, @[sdArchitecture, sdPerformance])
  ]
  
  result.taskHistory = @[]
  result.totalTasks = 0
  result.successfulTasks = 0
  result.fitness = 0.0

## ============================================================================
## Routing & Execution (versión simplificada)
## ============================================================================

proc assignTask(ceo: var CEOAgent, task: var Task) =
  var bestAgent = ""
  var bestScore = -1.0
  
  for sa in ceo.stackAgents:
    var score = ceo.genome.routingWeights[task.taskType].getOrDefault(sa.name, 0.1)
    score *= ceo.genome.urgencyMultiplier[task.urgency]
    
    # Skill match
    for skill in task.skillsRequired:
      score *= (0.5 + sa.genome.skills.getOrDefault(skill, 0.3))
    
    if score > bestScore:
      bestScore = score
      bestAgent = sa.name
  
  task.assignedAgent = bestAgent

proc executeTask(ceo: var CEOAgent, task: var Task) =
  var successProb = 0.3
  
  for i in 0..<ceo.stackAgents.len:
    if ceo.stackAgents[i].name == task.assignedAgent:
      for skill in task.skillsRequired:
        let skillLevel = ceo.stackAgents[i].genome.skills.getOrDefault(skill, 0.1)
        successProb += skillLevel * 0.15
      
      successProb *= (1.0 - task.complexity * 0.25)
      successProb = clamp(successProb, 0.05, 0.95)
      
      let success = rand(1.0) < successProb
      task.successScore = if success: 0.65 + rand(0.35) else: 0.25 + rand(0.35)
      task.completed = true
      
      if task.successScore > 0.6:
        ceo.successfulTasks += 1
      
      ceo.totalTasks += 1
      ceo.taskHistory.add(task)
      
      # Update agent
      ceo.stackAgents[i].totalTasks += 1
      if success:
        ceo.stackAgents[i].successfulTasks += 1
      
      let outcome = TaskOutcome(
        taskId: task.id,
        success: success,
        timeSpent: task.estimatedTime,
        qualityScore: task.successScore,
        skillsUsed: task.skillsRequired
      )
      ceo.stackAgents[i].experience.add(outcome)
      
      # Learning
      for skill in task.skillsRequired:
        if success:
          let improvement = ceo.stackAgents[i].genome.learningRate * task.successScore * 0.04
          if skill in ceo.stackAgents[i].genome.skills:
            ceo.stackAgents[i].genome.skills[skill] = min(1.0, ceo.stackAgents[i].genome.skills[skill] + improvement)
      
      break

proc evaluateCEOFitness(ceo: var CEOAgent) =
  if ceo.totalTasks == 0:
    ceo.fitness = 0.0
    return
  
  let successRate = ceo.successfulTasks.float / ceo.totalTasks.float
  
  var avgAgentSuccess = 0.0
  for sa in ceo.stackAgents:
    if sa.totalTasks > 0:
      avgAgentSuccess += sa.successfulTasks.float / sa.totalTasks.float
  avgAgentSuccess /= ceo.stackAgents.len.float
  
  var avgQuality = 0.0
  for t in ceo.taskHistory:
    avgQuality += t.successScore
  avgQuality /= ceo.taskHistory.len.float
  
  ceo.fitness = 0.4 * successRate + 0.3 * avgAgentSuccess + 0.3 * avgQuality

## ============================================================================
## Main Execution
## ============================================================================

when isMainModule:
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║   CEO + Stack Agents Integration Demo: PWA Development Project       ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""
  
  let startTime = cpuTime()
  
  # Crear PWA tasks
  var tasks = createPWATasks()
  echo &"📋 Project: Progressive Web App (15 tasks)"
  echo &"   Phases: Design → Implementation → Testing → DevOps → Docs → Optimization\n"
  
  # Inicializar CEO
  var ceo = initDemoCEO()
  echo "🤖 CEO Agent initialized with 10 specialized stack agents:"
  for sa in ceo.stackAgents:
    echo &"   • {sa.name:20s} [{sa.agentType}]"
  echo ""
  
  # Asignar y ejecutar tasks
  echo "🔄 Assigning and executing tasks...\n"
  for i in 0..<tasks.len:
    ceo.assignTask(tasks[i])
    echo &"Task {tasks[i].id:2d} | {tasks[i].description:50s} → {tasks[i].assignedAgent:20s} | Urgency: {tasks[i].urgency}"
    ceo.executeTask(tasks[i])
  
  # Evaluar CEO
  ceo.evaluateCEOFitness()
  
  echo ""
  echo "─".repeat(75)
  echo "📊 PROJECT RESULTS"
  echo "─".repeat(75)
  
  # Global stats
  let successRate = 100.0 * ceo.successfulTasks.float / ceo.totalTasks.float
  var totalQuality = 0.0
  for t in ceo.taskHistory:
    totalQuality += t.successScore
  let avgQuality = totalQuality / ceo.taskHistory.len.float
  
  echo &"\n🎯 Overall Performance:"
  echo &"   CEO Fitness:        {ceo.fitness:6.4f}"
  echo &"   Tasks Completed:    {ceo.successfulTasks}/{ceo.totalTasks} ({successRate:5.1f}%)"
  echo &"   Avg Quality Score:  {avgQuality:6.4f}"
  
  # Agent breakdown
  echo &"\n👥 Agent Performance Breakdown:"
  echo "   " & alignLeft("Agent", 20) & " " & align("Tasks", 8) & " " & align("Success", 10) & " " & align("Rate", 8) & " " & align("Avg Quality", 12)
  echo "   " & "-".repeat(20) & " " & "-".repeat(8) & " " & "-".repeat(10) & " " & "-".repeat(8) & " " & "-".repeat(12)
  
  for sa in ceo.stackAgents:
    if sa.totalTasks > 0:
      let agentSuccessRate = 100.0 * sa.successfulTasks.float / sa.totalTasks.float
      var agentAvgQuality = 0.0
      for outcome in sa.experience:
        agentAvgQuality += outcome.qualityScore
      agentAvgQuality /= sa.experience.len.float
      
      echo &"   {sa.name:<20} {sa.totalTasks:>8} {sa.successfulTasks:>10} {agentSuccessRate:>7.1f}% {agentAvgQuality:>11.3f}"
  
  # Task details
  echo &"\n📝 Task Execution Details:"
  var tasksByPhase = initTable[string, seq[Task]]()
  tasksByPhase["Design"] = tasks[0..2]
  tasksByPhase["Implementation"] = tasks[3..5]
  tasksByPhase["Testing"] = tasks[6..7]
  tasksByPhase["DevOps"] = tasks[8..9]
  tasksByPhase["Documentation"] = tasks[10..11]
  tasksByPhase["Optimization"] = tasks[12..14]
  
  for phase, phaseTasks in tasksByPhase:
    var phaseSuccess = 0
    var phaseQuality = 0.0
    for t in phaseTasks:
      if t.successScore > 0.6:
        phaseSuccess += 1
      phaseQuality += t.successScore
    phaseQuality /= phaseTasks.len.float
    
    echo &"   {phase:15s}: {phaseSuccess}/{phaseTasks.len} tasks successful, quality {phaseQuality:5.3f}"
  
  # Critical tasks
  echo &"\n⚠️  Critical/High Priority Tasks:"
  for t in ceo.taskHistory:
    if t.urgency in [urCritical, urHigh]:
      let status = if t.successScore > 0.6: "✓ SUCCESS" else: "✗ FAILED"
      echo &"   {status} | Task {t.id:2d}: {t.description:50s} (quality: {t.successScore:5.3f})"
  
  let elapsedTime = cpuTime() - startTime
  echo &"\n⏱️  Execution time: {elapsedTime:6.3f} seconds"
  
  echo "\n✅ CEO + Stack Agents integration demo completed successfully!"
  echo "═".repeat(75)
