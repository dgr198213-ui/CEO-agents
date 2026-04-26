# ============================================================================
# Coevolutionary Agent - Competitive and cooperative evolution
# ============================================================================
# Implements predator-prey dynamics and competitive coevolution

import agent_base, neuro_agent, evolution_core
import random, sequtils, algorithm, math

# ============================================================================
# Coevolution Types
# ============================================================================

type
  CoevoType* = enum
    ctPredator,   # Hunts prey
    ctPrey,       # Avoids predators
    ctCompetitor  # Competes for resources

  CoevoAgent* = ref object of NeuroAgent
    coevoType*: CoevoType
    health*: float
    attackPower*: float
    defenseRating*: float
    sensorRange*: float
    kills*: int
    escapes*: int

  CoevoEnvironment* = ref object of Environment
    predators*: seq[CoevoAgent]
    prey*: seq[CoevoAgent]
    foodSources*: seq[Vector2D]
    generation*: int

# ============================================================================
# Agent Creation
# ============================================================================

proc newCoevoAgent*(id: int, coevoType: CoevoType, inputSize, outputSize: int): CoevoAgent =
  new(result)
  result.id = id
  result.coevoType = coevoType
  result.network = newNeuralNetwork(inputSize, outputSize)
  result.health = 100.0
  result.kills = 0
  result.escapes = 0
  
  # Type-specific attributes
  case coevoType:
  of ctPredator:
    result.attackPower = randomFloat(5.0, 15.0)
    result.defenseRating = randomFloat(1.0, 5.0)
    result.sensorRange = randomFloat(50.0, 100.0)
  of ctPrey:
    result.attackPower = randomFloat(1.0, 3.0)
    result.defenseRating = randomFloat(5.0, 15.0)
    result.sensorRange = randomFloat(40.0, 80.0)
  of ctCompetitor:
    result.attackPower = randomFloat(3.0, 10.0)
    result.defenseRating = randomFloat(3.0, 10.0)
    result.sensorRange = randomFloat(45.0, 90.0)
  
  result.state = AgentState(
    position: Vector2D(x: 0.0, y: 0.0),
    velocity: Vector2D(x: 0.0, y: 0.0),
    energy: 100.0,
    age: 0,
    fitness: 0.0
  )

proc newCoevoEnvironment*(width, height: float, numPredators, numPrey: int): CoevoEnvironment =
  new(result)
  result.width = width
  result.height = height
  result.time = 0
  result.generation = 0
  result.predators = @[]
  result.prey = @[]
  result.foodSources = @[]
  
  # Create food sources
  for i in 0..19:
    result.foodSources.add(randomVector2D(width, height))

# ============================================================================
# Sensing for Coevolutionary Agents
# ============================================================================

method sense*(agent: CoevoAgent, env: Environment): seq[float] =
  let coevoEnv = CoevoEnvironment(env)
  var inputs = newSeq[float]()
  
  # Self state (5 inputs)
  inputs.add(agent.state.position.x / env.width)
  inputs.add(agent.state.position.y / env.height)
  inputs.add(agent.state.velocity.x / 5.0)
  inputs.add(agent.state.velocity.y / 5.0)
  inputs.add(agent.health / 100.0)
  
  case agent.coevoType:
  of ctPredator:
    # Sense nearest prey (3 inputs: dx, dy, distance)
    var nearestPrey: CoevoAgent = nil
    var minDist = Inf
    
    for prey in coevoEnv.prey:
      let dist = distance(agent.state.position, prey.state.position)
      if dist < minDist and dist < agent.sensorRange:
        minDist = dist
        nearestPrey = prey
    
    if nearestPrey != nil:
      let diff = nearestPrey.state.position - agent.state.position
      inputs.add(diff.x / agent.sensorRange)
      inputs.add(diff.y / agent.sensorRange)
      inputs.add(minDist / agent.sensorRange)
    else:
      inputs.add(0.0)
      inputs.add(0.0)
      inputs.add(1.0)
    
  of ctPrey:
    # Sense nearest predator (3 inputs)
    var nearestPredator: CoevoAgent = nil
    var minDist = Inf
    
    for pred in coevoEnv.predators:
      let dist = distance(agent.state.position, pred.state.position)
      if dist < minDist and dist < agent.sensorRange:
        minDist = dist
        nearestPredator = pred
    
    if nearestPredator != nil:
      let diff = agent.state.position - nearestPredator.state.position  # Away from predator
      inputs.add(diff.x / agent.sensorRange)
      inputs.add(diff.y / agent.sensorRange)
      inputs.add(minDist / agent.sensorRange)
    else:
      inputs.add(0.0)
      inputs.add(0.0)
      inputs.add(1.0)
    
    # Sense nearest food (3 inputs)
    var nearestFood: Vector2D
    var foodDist = Inf
    
    for food in coevoEnv.foodSources:
      let dist = distance(agent.state.position, food)
      if dist < foodDist:
        foodDist = dist
        nearestFood = food
    
    if foodDist < Inf:
      let diff = nearestFood - agent.state.position
      inputs.add(diff.x / agent.sensorRange)
      inputs.add(diff.y / agent.sensorRange)
      inputs.add(foodDist / agent.sensorRange)
    else:
      inputs.add(0.0)
      inputs.add(0.0)
      inputs.add(1.0)
  
  of ctCompetitor:
    # Sense nearest competitor and food
    inputs.add(0.0)  # Placeholder
    inputs.add(0.0)
    inputs.add(1.0)
  
  return inputs

# ============================================================================
# Actions
# ============================================================================

method act*(agent: CoevoAgent, outputs: seq[float], env: Environment) =
  if outputs.len < 2:
    return
  
  # Movement (outputs 0, 1)
  let force = Vector2D(x: outputs[0] * 2.0, y: outputs[1] * 2.0)
  agent.state.velocity = agent.state.velocity + force * 0.15
  
  # Speed limits based on type
  var maxSpeed = 3.0
  case agent.coevoType:
  of ctPredator:
    maxSpeed = 4.0
  of ctPrey:
    maxSpeed = 5.0  # Prey is faster
  of ctCompetitor:
    maxSpeed = 3.5
  
  let speed = agent.state.velocity.magnitude()
  if speed > maxSpeed:
    agent.state.velocity = agent.state.velocity.normalize() * maxSpeed
  
  # Update position
  agent.state.position = agent.state.position + agent.state.velocity
  wrapAround(agent.state.position, env.width, env.height)

# ============================================================================
# Interaction Logic
# ============================================================================

proc handleInteractions*(env: CoevoEnvironment) =
  ## Handle predator-prey interactions and resource consumption
  
  # Predator catches prey
  for predator in env.predators:
    for prey in env.prey:
      let dist = distance(predator.state.position, prey.state.position)
      if dist < 5.0:  # Catch radius
        # Combat resolution
        let attackRoll = rand(predator.attackPower)
        let defenseRoll = rand(prey.defenseRating)
        
        if attackRoll > defenseRoll:
          # Successful kill
          prey.health -= 30.0
          predator.state.fitness += 50.0
          predator.kills += 1
          predator.health = min(100.0, predator.health + 20.0)
          
          if prey.health <= 0:
            prey.state.fitness -= 100.0
        else:
          # Prey escapes
          prey.state.fitness += 20.0
          prey.escapes += 1
  
  # Prey eat food
  for prey in env.prey:
    for i, food in env.foodSources:
      let dist = distance(prey.state.position, food)
      if dist < 5.0:
        prey.health = min(100.0, prey.health + 10.0)
        prey.state.fitness += 10.0
        # Respawn food elsewhere
        env.foodSources[i] = randomVector2D(env.width, env.height)
  
  # Energy depletion
  for predator in env.predators:
    predator.health -= 0.1
    if predator.health <= 0:
      predator.state.fitness -= 50.0
  
  for prey in env.prey:
    prey.health -= 0.05

# ============================================================================
# Update
# ============================================================================

method update*(agent: CoevoAgent, env: Environment, dt: float) =
  let inputs = agent.sense(env)
  let outputs = agent.network.activate(inputs)
  agent.act(outputs, env)
  
  agent.state.age += 1
  agent.state.energy -= 0.1 * dt
  
  # Survival bonus
  agent.state.fitness += 0.1 * dt

method evaluateFitness*(agent: CoevoAgent, env: Environment): float =
  ## Fitness based on type-specific objectives
  var fitness = agent.state.fitness
  
  case agent.coevoType:
  of ctPredator:
    # Fitness = kills + health - age penalty
    fitness += agent.kills.float * 100.0
    fitness += agent.health * 0.5
    fitness -= agent.state.age.float * 0.01
  
  of ctPrey:
    # Fitness = survival time + escapes + health
    fitness += agent.state.age.float * 0.5
    fitness += agent.escapes.float * 50.0
    fitness += agent.health * 0.3
  
  of ctCompetitor:
    fitness += agent.health
  
  return fitness

# ============================================================================
# Evolutionary Operators for Coevolution
# ============================================================================

proc coevolve*(predators, prey: var seq[CoevoAgent], params: EvolutionParams) =
  ## Coevolve both populations based on fitness
  
  # Sort by fitness
  predators.sort(proc (a, b: CoevoAgent): int =
    cmp(b.evaluateFitness(nil), a.evaluateFitness(nil))
  )
  
  prey.sort(proc (a, b: CoevoAgent): int =
    cmp(b.evaluateFitness(nil), a.evaluateFitness(nil))
  )
  
  # Elite preservation + mutation of best
  let eliteCount = max(1, params.populationSize div 10)
  
  # Mutate and breed new generation
  # (Simplified - in practice would use tournament selection, crossover, etc.)

# ============================================================================
# Export
# ============================================================================

export CoevoType, CoevoAgent, CoevoEnvironment
export newCoevoAgent, newCoevoEnvironment
export handleInteractions, coevolve

# ============================================================================
# Crossover especializado para CoevoAgent
# ============================================================================
proc crossoverCoevoAgents*(parent1, parent2: CoevoAgent, nextId: int): CoevoAgent =
  ## Crea un descendiente CoevoAgent desde dos padres CoevoAgent
  result = CoevoAgent(
    id: nextId,
    coevoType: parent1.coevoType,
    network: crossover(parent1.network, parent2.network),
    state: AgentState(
      position: Vector2D(x: 0.0, y: 0.0),
      velocity: Vector2D(x: 0.0, y: 0.0),
      energy: 100.0,
      age: 0,
      fitness: 0.0
    ),
    species: parent1.species,
    health: (parent1.health + parent2.health) / 2.0,
    attackPower: (parent1.attackPower + parent2.attackPower) / 2.0,
    defenseRating: (parent1.defenseRating + parent2.defenseRating) / 2.0,
    sensorRange: (parent1.sensorRange + parent2.sensorRange) / 2.0,
    kills: 0,
    escapes: 0
  )

export crossoverCoevoAgents


# ============================================================================
# Evolución especializada para CoevoAgent
# ============================================================================
proc evolveCoevoPopulation*(pop: Population[CoevoAgent], params: EvolutionParams,
                             nextIdStart: int): Population[CoevoAgent] =
  ## Evoluciona una población de CoevoAgents preservando el tipo de coevolución
  result = newPopulation[CoevoAgent]()
  result.generation = pop.generation + 1
  
  var nextId = nextIdStart
  
  # Elitismo: conservar los mejores
  var sorted = pop.individuals
  sorted.sort(proc(a, b: CoevoAgent): int =
    cmp(b.state.fitness, a.state.fitness)
  )
  
  for i in 0..<params.eliteSize:
    if i < sorted.len:
      result.individuals.add(sorted[i])
  
  # Generar descendencia
  while result.individuals.len < params.populationSize:
    let parent1 = tournamentSelection(pop, params.tournamentSize)
    let parent2 = tournamentSelection(pop, params.tournamentSize)
    
    var offspring: CoevoAgent
    
    if rand(1.0) < params.crossoverRate:
      offspring = crossoverCoevoAgents(parent1, parent2, nextId)
    else:
      # Clonar padre con nuevo estado
      offspring = CoevoAgent(
        id: nextId,
        coevoType: parent1.coevoType,
        network: parent1.network,
        state: AgentState(
          position: Vector2D(x: 0.0, y: 0.0),
          velocity: Vector2D(x: 0.0, y: 0.0),
          energy: 100.0,
          age: 0,
          fitness: 0.0
        ),
        species: parent1.species,
        health: 100.0,
        attackPower: parent1.attackPower,
        defenseRating: parent1.defenseRating,
        sensorRange: parent1.sensorRange,
        kills: 0,
        escapes: 0
      )
    
    mutateNeuroAgent(offspring, params)
    result.individuals.add(offspring)
    inc nextId

export evolveCoevoPopulation
