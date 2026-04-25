# ============================================================================
# Knowledge Agent - Evolutionary Knowledge Generation and Propagation
# ============================================================================
# Agente especializado en generar, evolucionar y propagar conocimiento

import agent_base, types, neuro_agent, evolution_core
import random, sequtils, algorithm, tables, strutils, hashes

# ConceptType, Concept, KnowledgeBase, KnowledgeGenome, KnowledgeAgent, KnowledgeEnvironment are now in types.nim

# ============================================================================
# Knowledge Base Operations
# ============================================================================

proc newKnowledgeBase*(): KnowledgeBase =
  new(result)
  result.concepts = initTable[int, Concept]()
  result.relationMatrix = initTable[(int, int), float]()
  result.nextConceptId = 0
  result.totalConcepts = 0
  result.averageConfidence = 0.0

proc getHash*(cpt: Concept): Hash =
  ## Hash basado en contenido para detectar duplicados
  var h: Hash = 0
  h = h !& hash(cpt.conceptType)
  h = h !& hash(cpt.content)
  result = !$h

proc addConcept*(kb: KnowledgeBase, conceptType: ConceptType, 
                 content: string, confidence: float = 0.5,
                 parents: seq[int] = @[], tags: seq[string] = @[]): int =
  ## Agrega un nuevo concepto a la base de conocimiento
  let cpt = Concept(
    id: kb.nextConceptId,
    conceptType: conceptType,
    content: content,
    confidence: clamp(confidence, 0.0, 1.0),
    utility: 0.0,
    age: 0,
    usageCount: 0,
    parentConcepts: parents,
    tags: tags,
    hash: Hash(0)
  )
  
  # Calcular hash después de crear el concepto
  var mutableConcept = cpt
  mutableConcept.hash = mutableConcept.getHash()
  
  # Verificar si ya existe (deduplicación)
  for existing in kb.concepts.values:
    if existing.hash == mutableConcept.hash:
      return existing.id  # Retornar ID existente
  
  kb.concepts[kb.nextConceptId] = mutableConcept
  inc kb.nextConceptId
  inc kb.totalConcepts
  
  # Establecer relaciones con padres
  for parentId in parents:
    if parentId in kb.concepts:
      kb.relationMatrix[(parentId, mutableConcept.id)] = 0.8
      kb.relationMatrix[(mutableConcept.id, parentId)] = 0.6
  
  return mutableConcept.id

proc getRelatedConcepts*(kb: KnowledgeBase, conceptId: int, 
                         minStrength: float = 0.3): seq[int] =
  ## Obtiene conceptos relacionados
  result = @[]
  for key, strength in kb.relationMatrix:
    if key[0] == conceptId and strength >= minStrength:
      result.add(key[1])

proc strengthenRelation*(kb: KnowledgeBase, id1, id2: int, amount: float = 0.1) =
  ## Fortalece la relación entre dos conceptos
  let key = (id1, id2)
  if key in kb.relationMatrix:
    kb.relationMatrix[key] = min(1.0, kb.relationMatrix[key] + amount)
  else:
    kb.relationMatrix[key] = amount

proc pruneConcepts*(kb: KnowledgeBase, minUtility: float = 0.1, maxAge: int = 1000) =
  ## Elimina conceptos poco útiles o muy antiguos
  var toRemove: seq[int] = @[]
  
  for id, cpt in kb.concepts:
    if cpt.utility < minUtility and cpt.age > maxAge:
      toRemove.add(id)
  
  for id in toRemove:
    kb.concepts.del(id)
    dec kb.totalConcepts

# ============================================================================
# Knowledge Agent Creation
# ============================================================================

proc newKnowledgeAgent*(id: int): KnowledgeAgent =
  new(result)
  result.id = id
  result.knowledgeBase = newKnowledgeBase()
  result.learningRate = randomFloat(0.1, 0.5)
  result.forgettingRate = randomFloat(0.01, 0.05)
  result.synthesisAttempts = 0
  result.successfulSyntheses = 0
  result.conceptsCreated = 0
  result.conceptsPruned = 0
  
  result.knowledgeGenome = KnowledgeGenome(
    strategies: @["analogy", "combination", "abstraction", "specialization"],
    biases: @[randomFloat(0, 1), randomFloat(0, 1), randomFloat(0, 1)],
    synthesisRate: randomFloat(0.1, 0.5),
    criticalThinking: randomFloat(0.3, 0.9),
    creativity: randomFloat(0.3, 0.9)
  )
  
  result.state = AgentState(
    position: Vector2D(x: 0, y: 0),
    velocity: Vector2D(x: 0, y: 0),
    energy: 100.0,
    age: 0,
    fitness: 0.0
  )
  
  # Sembrar conocimiento inicial
  discard result.knowledgeBase.addConcept(ctFact, "El agua hierve a 100°C", 0.9, @[], @["física", "agua"])
  discard result.knowledgeBase.addConcept(ctFact, "2 + 2 = 4", 1.0, @[], @["matemática", "aritmética"])
  discard result.knowledgeBase.addConcept(ctRule, "Si A entonces B", 0.7, @[], @["lógica"])

proc newKnowledgeEnvironment*(width, height: float): KnowledgeEnvironment =
  new(result)
  result.width = width
  result.height = height
  result.time = 0
  result.generation = 0
  result.agents = @[]
  result.sharedKnowledge = newKnowledgeBase()
  result.problems = @[
    "¿Cómo optimizar el aprendizaje?",
    "¿Qué es la inteligencia?",
    "¿Cómo resolver problemas complejos?",
    "¿Cuál es la relación entre creatividad y lógica?",
    "¿Cómo transferir conocimiento eficientemente?"
  ]
  result.rewardedConcepts = @[]

# ============================================================================
# Knowledge Synthesis Strategies
# ============================================================================

proc synthesizeByAnalogy*(agent: KnowledgeAgent): bool =
  ## Crea nuevo conocimiento por analogía entre conceptos existentes
  if agent.knowledgeBase.totalConcepts < 2:
    return false
  
  # Seleccionar dos conceptos aleatorios
  var conceptIds: seq[int] = @[]
  for id in agent.knowledgeBase.concepts.keys:
    conceptIds.add(id)
  
  if conceptIds.len < 2:
    return false
  
  shuffle(conceptIds)
  let c1 = agent.knowledgeBase.concepts[conceptIds[0]]
  let c2 = agent.knowledgeBase.concepts[conceptIds[1]]
  
  # Crear analogía
  let analogyContent = "Si '" & c1.content & "' es como '" & c2.content & "', entonces..."
  let confidence = (c1.confidence + c2.confidence) / 2.0 * agent.knowledgeGenome.creativity
  
  discard agent.knowledgeBase.addConcept(
    ctAnalogy, 
    analogyContent,
    confidence,
    @[c1.id, c2.id],
    c1.tags & c2.tags
  )
  
  inc agent.conceptsCreated
  return true

proc synthesizeByCombination*(agent: KnowledgeAgent): bool =
  ## Combina dos conceptos para crear uno nuevo
  if agent.knowledgeBase.totalConcepts < 2:
    return false
  
  var conceptIds: seq[int] = @[]
  for id in agent.knowledgeBase.concepts.keys:
    conceptIds.add(id)
  
  if conceptIds.len < 2:
    return false
  
  shuffle(conceptIds)
  let c1 = agent.knowledgeBase.concepts[conceptIds[0]]
  let c2 = agent.knowledgeBase.concepts[conceptIds[1]]
  
  # Combinar contenidos
  let combinedContent = c1.content & " Y " & c2.content
  let confidence = min(c1.confidence, c2.confidence) * 0.8
  
  discard agent.knowledgeBase.addConcept(
    ctPattern,
    combinedContent,
    confidence,
    @[c1.id, c2.id],
    c1.tags & c2.tags
  )
  
  inc agent.conceptsCreated
  return true

proc synthesizeByAbstraction*(agent: KnowledgeAgent): bool =
  ## Abstrae patrones comunes de múltiples conceptos
  if agent.knowledgeBase.totalConcepts < 3:
    return false
  
  # Encontrar conceptos con tags comunes
  var tagGroups = initTable[string, seq[int]]()
  
  for id, cpt in agent.knowledgeBase.concepts:
    for tag in cpt.tags:
      if tag notin tagGroups:
        tagGroups[tag] = @[]
      tagGroups[tag].add(id)
  
  # Buscar grupo más grande
  var bestTag = ""
  var maxSize = 0
  for tag, ids in tagGroups:
    if ids.len > maxSize:
      maxSize = ids.len
      bestTag = tag
  
  if maxSize < 2:
    return false
  
  # Crear abstracción
  let abstractContent = "Patrón abstracto en dominio: " & bestTag
  let avgConfidence = agent.knowledgeGenome.criticalThinking * 0.7
  
  discard agent.knowledgeBase.addConcept(
    ctTheory,
    abstractContent,
    avgConfidence,
    tagGroups[bestTag],
    @[bestTag, "abstracto"]
  )
  
  inc agent.conceptsCreated
  return true

proc synthesizeBySpecialization*(agent: KnowledgeAgent): bool =
  ## Especializa un concepto general en uno más específico
  # Buscar teorías o patrones
  var candidates: seq[int] = @[]
  for id, cpt in agent.knowledgeBase.concepts:
    if cpt.conceptType in [ctTheory, ctPattern]:
      candidates.add(id)
  
  if candidates.len == 0:
    return false
  
  let selectedId = candidates[rand(candidates.len - 1)]
  let parent = agent.knowledgeBase.concepts[selectedId]
  
  # Crear especialización
  let specContent = "Caso específico de: " & parent.content
  let confidence = parent.confidence * 0.9
  
  discard agent.knowledgeBase.addConcept(
    ctHeuristic,
    specContent,
    confidence,
    @[selectedId],
    parent.tags & @["específico"]
  )
  
  inc agent.conceptsCreated
  return true

# ============================================================================
# Knowledge Agent Update
# ============================================================================

method update*(agent: KnowledgeAgent, env: Environment, dt: float) =
  let knowledgeEnv = KnowledgeEnvironment(env)
  
  inc agent.synthesisAttempts
  
  # Intentar síntesis de conocimiento según estrategias
  var synthesized = false
  
  for strategy in agent.knowledgeGenome.strategies:
    if rand(1.0) < agent.knowledgeGenome.synthesisRate:
      case strategy:
      of "analogy":
        synthesized = synthesizeByAnalogy(agent) or synthesized
      of "combination":
        synthesized = synthesizeByCombination(agent) or synthesized
      of "abstraction":
        synthesized = synthesizeByAbstraction(agent) or synthesized
      of "specialization":
        synthesized = synthesizeBySpecialization(agent) or synthesized
      else:
        discard
  
  if synthesized:
    inc agent.successfulSyntheses
    agent.state.fitness += 10.0
  
  # Envejecer conceptos
  for id in agent.knowledgeBase.concepts.keys:
    agent.knowledgeBase.concepts[id].age += 1
  
  # Olvidar conceptos poco útiles
  if rand(1.0) < agent.forgettingRate:
    let beforeCount = agent.knowledgeBase.totalConcepts
    agent.knowledgeBase.pruneConcepts(minUtility = 0.05, maxAge = 500)
    agent.conceptsPruned += beforeCount - agent.knowledgeBase.totalConcepts
  
  # Compartir conocimiento con el entorno
  if rand(1.0) < 0.1 and agent.knowledgeBase.totalConcepts > 0:
    # Seleccionar mejor concepto
    var bestConcept: Concept
    var bestScore = -Inf
    
    for cpt in agent.knowledgeBase.concepts.values:
      let score = cpt.confidence * cpt.utility
      if score > bestScore:
        bestScore = score
        bestConcept = cpt
    
    if bestScore > 0.5:
      discard knowledgeEnv.sharedKnowledge.addConcept(
        bestConcept.conceptType,
        bestConcept.content,
        bestConcept.confidence,
        @[],
        bestConcept.tags
      )
      agent.state.fitness += 5.0
  
  # Aprender del conocimiento compartido
  if rand(1.0) < agent.learningRate and knowledgeEnv.sharedKnowledge.totalConcepts > 0:
    # Seleccionar concepto aleatorio del conocimiento compartido
    var sharedIds: seq[int] = @[]
    for id in knowledgeEnv.sharedKnowledge.concepts.keys:
      sharedIds.add(id)
    
    if sharedIds.len > 0:
      let randomId = sharedIds[rand(sharedIds.len - 1)]
      let sharedConcept = knowledgeEnv.sharedKnowledge.concepts[randomId]
      
      discard agent.knowledgeBase.addConcept(
        sharedConcept.conceptType,
        sharedConcept.content,
        sharedConcept.confidence * 0.8,  # Menor confianza al aprender
        @[],
        sharedConcept.tags
      )
      agent.state.fitness += 3.0
  
  inc agent.state.age
  agent.state.energy -= 0.1 * dt

method evaluateFitness*(agent: KnowledgeAgent, env: Environment): float =
  ## Fitness basado en cantidad y calidad de conocimiento
  result = agent.state.fitness
  
  # Bonus por conceptos creados
  result += agent.conceptsCreated.float * 5.0
  
  # Bonus por síntesis exitosa
  let synthesisRate = if agent.synthesisAttempts > 0:
    agent.successfulSyntheses.float / agent.synthesisAttempts.float
  else:
    0.0
  result += synthesisRate * 100.0
  
  # Bonus por diversidad de conocimiento
  var typeCount = 0
  for conceptType in ConceptType:
    for cpt in agent.knowledgeBase.concepts.values:
      if cpt.conceptType == conceptType:
        inc typeCount
        break
  result += typeCount.float * 10.0
  
  # Bonus por conocimiento de alta confianza
  var highConfidenceCount = 0
  for cpt in agent.knowledgeBase.concepts.values:
    if cpt.confidence > 0.7:
      inc highConfidenceCount
  result += highConfidenceCount.float * 3.0
  
  return result

# ============================================================================
# Mutations for Knowledge Genome
# ============================================================================

proc mutateKnowledgeGenome*(agent: KnowledgeAgent, rate: float) =
  ## Muta el genoma de estrategias de conocimiento
  if rand(1.0) < rate:
    agent.knowledgeGenome.synthesisRate += randomFloat(-0.1, 0.1)
    agent.knowledgeGenome.synthesisRate = clamp(agent.knowledgeGenome.synthesisRate, 0.0, 1.0)
  
  if rand(1.0) < rate:
    agent.knowledgeGenome.criticalThinking += randomFloat(-0.1, 0.1)
    agent.knowledgeGenome.criticalThinking = clamp(agent.knowledgeGenome.criticalThinking, 0.0, 1.0)
  
  if rand(1.0) < rate:
    agent.knowledgeGenome.creativity += randomFloat(-0.1, 0.1)
    agent.knowledgeGenome.creativity = clamp(agent.knowledgeGenome.creativity, 0.0, 1.0)
  
  if rand(1.0) < rate * 0.3:
    # Mutar estrategias
    let strategies = @["analogy", "combination", "abstraction", "specialization", "induction", "deduction"]
    if agent.knowledgeGenome.strategies.len > 0 and rand(1.0) < 0.5:
      agent.knowledgeGenome.strategies.delete(rand(agent.knowledgeGenome.strategies.len - 1))
    if rand(1.0) < 0.5:
      agent.knowledgeGenome.strategies.add(strategies[rand(strategies.len - 1)])
  
  if rand(1.0) < rate:
    agent.learningRate += randomFloat(-0.05, 0.05)
    agent.learningRate = clamp(agent.learningRate, 0.0, 1.0)

# ============================================================================
# Crossover for Knowledge Agents
# ============================================================================

proc crossoverKnowledgeAgents*(parent1, parent2: KnowledgeAgent, nextId: int): KnowledgeAgent =
  ## Crea descendiente combinando genomas de conocimiento
  result = newKnowledgeAgent(nextId)
  
  # Heredar estrategias de ambos padres
  result.knowledgeGenome.strategies = @[]
  for strategy in parent1.knowledgeGenome.strategies:
    if rand(1.0) < 0.5:
      result.knowledgeGenome.strategies.add(strategy)
  for strategy in parent2.knowledgeGenome.strategies:
    if rand(1.0) < 0.5 and strategy notin result.knowledgeGenome.strategies:
      result.knowledgeGenome.strategies.add(strategy)
  
  # Promediar parámetros numéricos
  result.knowledgeGenome.synthesisRate = (parent1.knowledgeGenome.synthesisRate + parent2.knowledgeGenome.synthesisRate) / 2.0
  result.knowledgeGenome.criticalThinking = (parent1.knowledgeGenome.criticalThinking + parent2.knowledgeGenome.criticalThinking) / 2.0
  result.knowledgeGenome.creativity = (parent1.knowledgeGenome.creativity + parent2.knowledgeGenome.creativity) / 2.0
  result.learningRate = (parent1.learningRate + parent2.learningRate) / 2.0
  result.forgettingRate = (parent1.forgettingRate + parent2.forgettingRate) / 2.0
  
  # Heredar mejores conceptos
  if parent1.knowledgeBase.totalConcepts > parent2.knowledgeBase.totalConcepts:
    result.knowledgeBase = parent1.knowledgeBase
  else:
    result.knowledgeBase = parent2.knowledgeBase

# ============================================================================
# Export
# ============================================================================

export newKnowledgeBase, addConcept, getRelatedConcepts, strengthenRelation
export newKnowledgeAgent, newKnowledgeEnvironment
export synthesizeByAnalogy, synthesizeByCombination, synthesizeByAbstraction
export mutateKnowledgeGenome, crossoverKnowledgeAgents
