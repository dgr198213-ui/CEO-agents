## Stack‑Specialized Agents
## 
## Implementa 10 agentes especializados por tecnología/dominio:
## 1. PythonAgent: data processing, ML, backend
## 2. TypeScriptAgent: frontend, Node.js, type‑safe APIs
## 3. DevOpsAgent: CI/CD, containers, infra‑as‑code
## 4. DataScienceAgent: analytics, modeling, viz
## 5. FrontendAgent: UI/UX, responsive, a11y
## 6. BackendAgent: REST/GraphQL APIs, microservices
## 7. DatabaseAgent: schema design, query optimization
## 8. SecurityAgent: vuln scanning, encryption, auth
## 9. TestingAgent: unit/integration/e2e testing
## 10. DocsAgent: technical writing, API docs, tutorials
##
## Cada agente tiene:
## - Genome con skills/conocimientos evolucionables
## - Mecanismo de aprendizaje por experiencia
## - Evaluación de fitness por tareas completadas

import random, math, tables, strutils, sequtils, algorithm

randomize()

## ============================================================================
## Base Types
## ============================================================================

type
  SkillDomain* = enum
    sdSyntax          # Language syntax & semantics
    sdArchitecture    # Design patterns & system architecture
    sdPerformance     # Optimization & profiling
    sdSecurity        # Secure coding practices
    sdTesting         # Testing methodologies
    sdDebugging       # Error diagnosis & fixing
    sdDocumentation   # Technical writing
    sdIntegration     # External APIs & services
    sdDeployment      # CI/CD & production
    sdMaintenance     # Refactoring & legacy code

  StackAgentGenome* = object
    skills*: Table[SkillDomain, float]  # 0.0..1.0 skill level
    learningRate*: float                # adaptive learning 0.01..0.3
    specializationDepth*: float         # generalist vs specialist
    collaborationScore*: float          # team‑work ability
    adaptabilityRate*: float            # how fast to adapt to new tasks

  StackAgentType* = enum
    satPython
    satTypeScript
    satDevOps
    satDataScience
    satFrontend
    satBackend
    satDatabase
    satSecurity
    satTesting
    satDocs

  TaskOutcome* = object
    taskId*: int
    success*: bool
    timeSpent*: float
    qualityScore*: float    # 0.0..1.0
    skillsUsed*: seq[SkillDomain]

  StackAgent* = object
    agentType*: StackAgentType
    genome*: StackAgentGenome
    fitness*: float
    experience*: seq[TaskOutcome]
    totalTasks*: int
    successfulTasks*: int

## ============================================================================
## Genome Initialization
## ============================================================================

proc initPythonGenome*(): StackAgentGenome =
  ## Python: strong in syntax, architecture, testing, debugging
  result.skills = {
    sdSyntax: 0.8 + rand(0.15),
    sdArchitecture: 0.7 + rand(0.2),
    sdPerformance: 0.6 + rand(0.2),
    sdSecurity: 0.5 + rand(0.2),
    sdTesting: 0.75 + rand(0.2),
    sdDebugging: 0.7 + rand(0.2),
    sdDocumentation: 0.6 + rand(0.15),
    sdIntegration: 0.65 + rand(0.2),
    sdDeployment: 0.5 + rand(0.2),
    sdMaintenance: 0.7 + rand(0.15)
  }.toTable
  result.learningRate = 0.1 + rand(0.1)
  result.specializationDepth = 0.6 + rand(0.3)
  result.collaborationScore = 0.6 + rand(0.3)
  result.adaptabilityRate = 0.15 + rand(0.1)

proc initTypeScriptGenome*(): StackAgentGenome =
  ## TypeScript: strong in syntax, architecture, frontend integration
  result.skills = {
    sdSyntax: 0.85 + rand(0.1),
    sdArchitecture: 0.75 + rand(0.15),
    sdPerformance: 0.65 + rand(0.2),
    sdSecurity: 0.6 + rand(0.15),
    sdTesting: 0.7 + rand(0.15),
    sdDebugging: 0.7 + rand(0.15),
    sdDocumentation: 0.65 + rand(0.2),
    sdIntegration: 0.75 + rand(0.15),
    sdDeployment: 0.55 + rand(0.2),
    sdMaintenance: 0.65 + rand(0.2)
  }.toTable
  result.learningRate = 0.12 + rand(0.08)
  result.specializationDepth = 0.65 + rand(0.25)
  result.collaborationScore = 0.7 + rand(0.2)
  result.adaptabilityRate = 0.18 + rand(0.1)

proc initDevOpsGenome*(): StackAgentGenome =
  ## DevOps: deployment, integration, performance, security
  result.skills = {
    sdSyntax: 0.5 + rand(0.2),
    sdArchitecture: 0.65 + rand(0.2),
    sdPerformance: 0.75 + rand(0.15),
    sdSecurity: 0.75 + rand(0.15),
    sdTesting: 0.65 + rand(0.2),
    sdDebugging: 0.6 + rand(0.2),
    sdDocumentation: 0.6 + rand(0.15),
    sdIntegration: 0.7 + rand(0.2),
    sdDeployment: 0.9 + rand(0.1),
    sdMaintenance: 0.65 + rand(0.2)
  }.toTable
  result.learningRate = 0.08 + rand(0.1)
  result.specializationDepth = 0.75 + rand(0.2)
  result.collaborationScore = 0.65 + rand(0.25)
  result.adaptabilityRate = 0.12 + rand(0.08)

proc initDataScienceGenome*(): StackAgentGenome =
  ## DataScience: architecture (pipelines), performance, testing (validation)
  result.skills = {
    sdSyntax: 0.7 + rand(0.2),
    sdArchitecture: 0.75 + rand(0.15),
    sdPerformance: 0.8 + rand(0.15),
    sdSecurity: 0.5 + rand(0.2),
    sdTesting: 0.7 + rand(0.15),
    sdDebugging: 0.65 + rand(0.2),
    sdDocumentation: 0.7 + rand(0.15),
    sdIntegration: 0.6 + rand(0.2),
    sdDeployment: 0.5 + rand(0.2),
    sdMaintenance: 0.6 + rand(0.2)
  }.toTable
  result.learningRate = 0.15 + rand(0.1)
  result.specializationDepth = 0.8 + rand(0.15)
  result.collaborationScore = 0.55 + rand(0.25)
  result.adaptabilityRate = 0.2 + rand(0.1)

proc initFrontendGenome*(): StackAgentGenome =
  ## Frontend: syntax (HTML/CSS/JS), integration (APIs), performance (UX)
  result.skills = {
    sdSyntax: 0.8 + rand(0.15),
    sdArchitecture: 0.65 + rand(0.2),
    sdPerformance: 0.7 + rand(0.2),
    sdSecurity: 0.55 + rand(0.2),
    sdTesting: 0.65 + rand(0.2),
    sdDebugging: 0.7 + rand(0.15),
    sdDocumentation: 0.6 + rand(0.2),
    sdIntegration: 0.75 + rand(0.15),
    sdDeployment: 0.5 + rand(0.2),
    sdMaintenance: 0.6 + rand(0.2)
  }.toTable
  result.learningRate = 0.12 + rand(0.1)
  result.specializationDepth = 0.65 + rand(0.25)
  result.collaborationScore = 0.7 + rand(0.2)
  result.adaptabilityRate = 0.16 + rand(0.1)

proc initBackendGenome*(): StackAgentGenome =
  ## Backend: architecture (APIs), security, integration, deployment
  result.skills = {
    sdSyntax: 0.75 + rand(0.15),
    sdArchitecture: 0.85 + rand(0.1),
    sdPerformance: 0.7 + rand(0.2),
    sdSecurity: 0.8 + rand(0.15),
    sdTesting: 0.7 + rand(0.15),
    sdDebugging: 0.7 + rand(0.15),
    sdDocumentation: 0.65 + rand(0.2),
    sdIntegration: 0.8 + rand(0.15),
    sdDeployment: 0.65 + rand(0.2),
    sdMaintenance: 0.7 + rand(0.15)
  }.toTable
  result.learningRate = 0.1 + rand(0.08)
  result.specializationDepth = 0.7 + rand(0.2)
  result.collaborationScore = 0.65 + rand(0.25)
  result.adaptabilityRate = 0.14 + rand(0.1)

proc initDatabaseGenome*(): StackAgentGenome =
  ## Database: architecture (schema), performance (query opt), security
  result.skills = {
    sdSyntax: 0.75 + rand(0.15),
    sdArchitecture: 0.85 + rand(0.1),
    sdPerformance: 0.85 + rand(0.1),
    sdSecurity: 0.75 + rand(0.15),
    sdTesting: 0.65 + rand(0.2),
    sdDebugging: 0.7 + rand(0.15),
    sdDocumentation: 0.65 + rand(0.2),
    sdIntegration: 0.6 + rand(0.2),
    sdDeployment: 0.55 + rand(0.2),
    sdMaintenance: 0.75 + rand(0.15)
  }.toTable
  result.learningRate = 0.08 + rand(0.1)
  result.specializationDepth = 0.8 + rand(0.15)
  result.collaborationScore = 0.6 + rand(0.25)
  result.adaptabilityRate = 0.1 + rand(0.08)

proc initSecurityGenome*(): StackAgentGenome =
  ## Security: security (obviously), debugging (vuln analysis), architecture
  result.skills = {
    sdSyntax: 0.7 + rand(0.2),
    sdArchitecture: 0.75 + rand(0.15),
    sdPerformance: 0.6 + rand(0.2),
    sdSecurity: 0.95 + rand(0.05),
    sdTesting: 0.75 + rand(0.15),
    sdDebugging: 0.8 + rand(0.15),
    sdDocumentation: 0.7 + rand(0.15),
    sdIntegration: 0.65 + rand(0.2),
    sdDeployment: 0.6 + rand(0.2),
    sdMaintenance: 0.7 + rand(0.15)
  }.toTable
  result.learningRate = 0.08 + rand(0.08)
  result.specializationDepth = 0.85 + rand(0.1)
  result.collaborationScore = 0.6 + rand(0.25)
  result.adaptabilityRate = 0.1 + rand(0.08)

proc initTestingGenome*(): StackAgentGenome =
  ## Testing: testing (main), debugging, architecture (test design)
  result.skills = {
    sdSyntax: 0.75 + rand(0.15),
    sdArchitecture: 0.7 + rand(0.2),
    sdPerformance: 0.65 + rand(0.2),
    sdSecurity: 0.65 + rand(0.2),
    sdTesting: 0.9 + rand(0.1),
    sdDebugging: 0.85 + rand(0.1),
    sdDocumentation: 0.7 + rand(0.15),
    sdIntegration: 0.65 + rand(0.2),
    sdDeployment: 0.55 + rand(0.2),
    sdMaintenance: 0.7 + rand(0.15)
  }.toTable
  result.learningRate = 0.1 + rand(0.1)
  result.specializationDepth = 0.75 + rand(0.2)
  result.collaborationScore = 0.7 + rand(0.2)
  result.adaptabilityRate = 0.14 + rand(0.1)

proc initDocsGenome*(): StackAgentGenome =
  ## Docs: documentation (main), syntax (technical accuracy), architecture
  result.skills = {
    sdSyntax: 0.7 + rand(0.2),
    sdArchitecture: 0.7 + rand(0.2),
    sdPerformance: 0.5 + rand(0.2),
    sdSecurity: 0.55 + rand(0.2),
    sdTesting: 0.6 + rand(0.2),
    sdDebugging: 0.6 + rand(0.2),
    sdDocumentation: 0.95 + rand(0.05),
    sdIntegration: 0.6 + rand(0.2),
    sdDeployment: 0.5 + rand(0.2),
    sdMaintenance: 0.65 + rand(0.2)
  }.toTable
  result.learningRate = 0.12 + rand(0.1)
  result.specializationDepth = 0.75 + rand(0.2)
  result.collaborationScore = 0.75 + rand(0.2)
  result.adaptabilityRate = 0.15 + rand(0.1)

## ============================================================================
## Agent Initialization
## ============================================================================

proc initStackAgent*(agentType: StackAgentType): StackAgent =
  result.agentType = agentType
  result.genome = case agentType
    of satPython: initPythonGenome()
    of satTypeScript: initTypeScriptGenome()
    of satDevOps: initDevOpsGenome()
    of satDataScience: initDataScienceGenome()
    of satFrontend: initFrontendGenome()
    of satBackend: initBackendGenome()
    of satDatabase: initDatabaseGenome()
    of satSecurity: initSecurityGenome()
    of satTesting: initTestingGenome()
    of satDocs: initDocsGenome()
  
  result.fitness = 0.0
  result.experience = @[]
  result.totalTasks = 0
  result.successfulTasks = 0

## ============================================================================
## Task Execution
## ============================================================================

proc executeTask*(agent: var StackAgent, skillsRequired: seq[SkillDomain], 
                  complexity: float): TaskOutcome =
  ## Simula ejecución de una task que requiere ciertos skills
  var successProb = 0.3
  
  # Evaluar match entre skills requeridos y skills del agente
  for skill in skillsRequired:
    let agentSkillLevel = agent.genome.skills.getOrDefault(skill, 0.1)
    successProb += agentSkillLevel * 0.2
  
  # Penalización por complejidad
  successProb *= (1.0 - complexity * 0.3)
  
  # Bonus por adaptabilidad
  successProb += agent.genome.adaptabilityRate * 0.15
  
  # Clamp
  successProb = clamp(successProb, 0.05, 0.95)
  
  # Simular éxito
  let success = rand(1.0) < successProb
  let qualityScore = if success: 0.6 + rand(0.4) else: 0.2 + rand(0.3)
  let timeSpent = complexity * (1.0 + rand(1.0))
  
  result = TaskOutcome(
    taskId: agent.totalTasks + 1,
    success: success,
    timeSpent: timeSpent,
    qualityScore: qualityScore,
    skillsUsed: skillsRequired
  )
  
  agent.experience.add(result)
  agent.totalTasks += 1
  if success:
    agent.successfulTasks += 1
  
  # Aprendizaje: mejorar skills usados
  for skill in skillsRequired:
    if success:
      let improvement = agent.genome.learningRate * qualityScore * 0.05
      if skill in agent.genome.skills:
        agent.genome.skills[skill] = min(1.0, agent.genome.skills[skill] + improvement)

proc evaluateFitness*(agent: var StackAgent) =
  ## Fitness: success rate + avg quality + skill balance
  if agent.totalTasks == 0:
    agent.fitness = 0.0
    return
  
  let successRate = agent.successfulTasks.float / agent.totalTasks.float
  
  var avgQuality = 0.0
  for outcome in agent.experience:
    avgQuality += outcome.qualityScore
  avgQuality /= agent.experience.len.float
  
  # Skill balance (evitar sobre‑especialización extrema)
  var skillValues: seq[float] = @[]
  for skill in SkillDomain:
    skillValues.add(agent.genome.skills.getOrDefault(skill, 0.0))
  let meanSkill = skillValues.sum / skillValues.len.float
  var variance = 0.0
  for v in skillValues:
    variance += (v - meanSkill) * (v - meanSkill)
  variance /= skillValues.len.float
  let balanceScore = 1.0 / (1.0 + variance)
  
  agent.fitness = 0.5 * successRate + 0.3 * avgQuality + 0.2 * balanceScore

## ============================================================================
## Evolutionary Operators
## ============================================================================

proc mutate*(genome: var StackAgentGenome, rate: float) =
  for skill in SkillDomain:
    if rand(1.0) < rate:
      let delta = (rand(1.0) - 0.5) * 0.1
      if skill in genome.skills:
        genome.skills[skill] = clamp(genome.skills[skill] + delta, 0.0, 1.0)
  
  if rand(1.0) < rate:
    genome.learningRate = clamp(genome.learningRate + (rand(1.0) - 0.5) * 0.05, 0.01, 0.3)
  
  if rand(1.0) < rate:
    genome.specializationDepth = clamp(genome.specializationDepth + (rand(1.0) - 0.5) * 0.1, 0.1, 0.95)
  
  if rand(1.0) < rate:
    genome.collaborationScore = clamp(genome.collaborationScore + (rand(1.0) - 0.5) * 0.1, 0.1, 1.0)
  
  if rand(1.0) < rate:
    genome.adaptabilityRate = clamp(genome.adaptabilityRate + (rand(1.0) - 0.5) * 0.05, 0.05, 0.35)

proc crossover*(g1, g2: StackAgentGenome): StackAgentGenome =
  result.skills = initTable[SkillDomain, float]()
  for skill in SkillDomain:
    if rand(1.0) < 0.5:
      result.skills[skill] = g1.skills.getOrDefault(skill, 0.5)
    else:
      result.skills[skill] = g2.skills.getOrDefault(skill, 0.5)
  
  result.learningRate = if rand(1.0) < 0.5: g1.learningRate else: g2.learningRate
  result.specializationDepth = if rand(1.0) < 0.5: g1.specializationDepth else: g2.specializationDepth
  result.collaborationScore = if rand(1.0) < 0.5: g1.collaborationScore else: g2.collaborationScore
  result.adaptabilityRate = if rand(1.0) < 0.5: g1.adaptabilityRate else: g2.adaptabilityRate

## ============================================================================
## Main Demo
## ============================================================================

when isMainModule:
  echo "=== Stack Specialized Agents Demo ==="
  echo "Entrenando 10 agentes especializados por stack\n"
  
  var agents: seq[StackAgent] = @[]
  for agentType in StackAgentType:
    agents.add(initStackAgent(agentType))
  
  # Generar tareas aleatorias
  type TaskDef = object
    skills: seq[SkillDomain]
    complexity: float
  
  var tasks: seq[TaskDef] = @[]
  for _ in 1..30:
    let numSkills = 2 + rand(3)
    var skills: seq[SkillDomain] = @[]
    for _ in 1..numSkills:
      skills.add(SkillDomain(rand(SkillDomain.high.ord)))
    tasks.add(TaskDef(skills: skills, complexity: rand(1.0)))
  
  echo &"Training on {tasks.len} tasks\n"
  
  # Ejecutar tasks
  for task in tasks:
    for i in 0..<agents.len:
      discard agents[i].executeTask(task.skills, task.complexity)
  
  # Evaluar
  for i in 0..<agents.len:
    agents[i].evaluateFitness()
  
  # Mostrar resultados
  echo "=== Agent Performance ==="
  for agent in agents:
    echo &"{agent.agentType:20s} | Fitness: {agent.fitness:5.3f} | Success: {agent.successfulTasks:3d}/{agent.totalTasks:3d} ({100.0*agent.successfulTasks.float/agent.totalTasks.float:5.1f}%)"
  
  echo "\n=== Top Skills per Agent (sample) ==="
  for agent in [agents[0], agents[1], agents[2]]:  # Python, TS, DevOps
    echo &"\n{agent.agentType}:"
    var skillList: seq[(SkillDomain, float)] = @[]
    for skill, level in agent.genome.skills:
      skillList.add((skill, level))
    skillList.sort(proc(a, b: (SkillDomain, float)): int = cmp(b[1], a[1]))
    for i in 0..<min(5, skillList.len):
      echo &"  {skillList[i][0]:20s} -> {skillList[i][1]:5.3f}"
  
  echo "\n✓ Stack Agents demo completed"
