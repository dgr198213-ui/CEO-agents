# ============================================================================
# Evolutionary Algorithm Core - Population management and evolution
# ============================================================================
# Generic evolutionary algorithm implementation for all agent types

import agent_base, types, neuro_agent
import random, sequtils, algorithm, math, tables, strformat

# ============================================================================
# Population Management
# ============================================================================

type
  Population*[T] = ref object
    individuals*: seq[T]
    generation*: int
    bestFitness*: float
    avgFitness*: float
    bestIndividual*: T

  SelectionMethod* = enum
    smTournament,
    smRoulette,
    smRank,
    smElitism

  EvolutionStats* = object
    generation*: int
    bestFitness*: float
    avgFitness*: float
    worstFitness*: float
    diversity*: float

# ============================================================================
# Population Creation
# ============================================================================

proc newPopulation*[T](): Population[T] =
  new(result)
  result.individuals = @[]
  result.generation = 0
  result.bestFitness = -Inf
  result.avgFitness = 0.0

# ============================================================================
# Fitness Evaluation
# ============================================================================

proc evaluatePopulation*[T: Agent](pop: Population[T], env: Environment) =
  ## Evaluate fitness for all individuals
  var totalFitness = 0.0
  pop.bestFitness = -Inf
  
  for individual in pop.individuals:
    let fitness = individual.evaluateFitness(env)
    totalFitness += fitness
    
    if fitness > pop.bestFitness:
      pop.bestFitness = fitness
      pop.bestIndividual = individual
  
  pop.avgFitness = totalFitness / float(pop.individuals.len)

# ============================================================================
# Selection Operators
# ============================================================================

proc tournamentSelection*[T](pop: Population[T], tournamentSize: int): T =
  ## Select individual via tournament selection
  var best: T
  var bestFitness = -Inf
  
  for i in 0..<tournamentSize:
    let candidate = pop.individuals[rand(pop.individuals.len - 1)]
    let fitness = candidate.state.fitness
    if fitness > bestFitness:
      bestFitness = fitness
      best = candidate
  
  return best

proc rouletteSelection*[T](pop: Population[T]): T =
  ## Fitness-proportionate selection
  var totalFitness = 0.0
  var minFitness = Inf
  
  # Find minimum fitness to handle negative values
  for ind in pop.individuals:
    if ind.state.fitness < minFitness:
      minFitness = ind.state.fitness
  
  # Shift fitness to be positive
  let offset = if minFitness < 0: abs(minFitness) + 1.0 else: 0.0
  
  for ind in pop.individuals:
    totalFitness += ind.state.fitness + offset
  
  var spin = rand(totalFitness)
  var sum = 0.0
  
  for ind in pop.individuals:
    sum += ind.state.fitness + offset
    if sum >= spin:
      return ind
  
  return pop.individuals[^1]

proc rankSelection*[T](pop: Population[T]): T =
  ## Rank-based selection
  var sorted = pop.individuals
  sorted.sort(proc(a, b: T): int =
    cmp(a.state.fitness, b.state.fitness)
  )
  
  let totalRanks = (sorted.len * (sorted.len + 1)) div 2
  let spin = rand(totalRanks)
  var sum = 0
  
  for i, ind in sorted:
    sum += i + 1
    if sum >= spin:
      return ind
  
  return sorted[^1]

# ============================================================================
# Mutation Operators (for NeuroAgents)
# ============================================================================

proc mutateNeuroAgent*(agent: var NeuroAgent, params: EvolutionParams) =
  ## Apply mutations to a neuroevolutionary agent
  
  # Weight mutation
  if rand(1.0) < params.mutationRate:
    mutateWeights(agent.network, params.mutationRate)
  
  # Structural mutations (less frequent)
  if rand(1.0) < params.mutationRate * 0.1:
    discard mutateAddNode(agent.network)
  
  if rand(1.0) < params.mutationRate * 0.2:
    discard mutateAddConnection(agent.network)

# ============================================================================
# Crossover Operators
# ============================================================================

proc crossoverNeuroAgents*(parent1, parent2: NeuroAgent, nextId: int): NeuroAgent =
  ## Create offspring from two neuroagent parents
  result = NeuroAgent(
    id: nextId,
    network: crossover(parent1.network, parent2.network),
    state: AgentState(
      position: Vector2D(x: 0.0, y: 0.0),
      velocity: Vector2D(x: 0.0, y: 0.0),
      energy: 100.0,
      age: 0,
      fitness: 0.0
    ),
    species: parent1.species
  )

# ============================================================================
# Evolution Step
# ============================================================================

proc evolvePopulation*[T: NeuroAgent](pop: Population[T], params: EvolutionParams, 
                                       nextIdStart: int): Population[T] =
  ## Evolve population to next generation
  result = newPopulation[T]()
  result.generation = pop.generation + 1
  
  var nextId = nextIdStart
  
  # Elitism: keep best individuals
  var sorted = pop.individuals
  sorted.sort(proc(a, b: T): int =
    cmp(b.state.fitness, a.state.fitness)
  )
  
  for i in 0..<params.eliteSize:
    if i < sorted.len:
      result.individuals.add(sorted[i])
  
  # Generate offspring
  while result.individuals.len < params.populationSize:
    let parent1 = tournamentSelection(pop, params.tournamentSize)
    let parent2 = tournamentSelection(pop, params.tournamentSize)
    
    # Clone parent1 to preserve the concrete type T
    # (direct object construction would lose subtype fields)
    var offspring: T = parent1
    offspring.id = nextId
    offspring.state = AgentState(
      position: Vector2D(x: 0.0, y: 0.0),
      velocity: Vector2D(x: 0.0, y: 0.0),
      energy: 100.0,
      age: 0,
      fitness: 0.0
    )
    
    # Crossover: mix neural networks
    if rand(1.0) < params.crossoverRate:
      offspring.network = crossover(parent1.network, parent2.network)
    else:
      offspring.network = parent1.network
    
    # Mutation
    var neuroOffspring: NeuroAgent = offspring
    mutateNeuroAgent(neuroOffspring, params)
    
    result.individuals.add(offspring)
    inc nextId

# ============================================================================
# Statistics
# ============================================================================

proc computeStats*[T: Agent](pop: Population[T]): EvolutionStats =
  ## Compute statistics for the population
  result.generation = pop.generation
  result.bestFitness = -Inf
  result.worstFitness = Inf
  var totalFitness = 0.0
  
  for ind in pop.individuals:
    let fitness = ind.state.fitness
    totalFitness += fitness
    
    if fitness > result.bestFitness:
      result.bestFitness = fitness
    if fitness < result.worstFitness:
      result.worstFitness = fitness
  
  result.avgFitness = totalFitness / float(pop.individuals.len)
  
  # Diversity (simplified: fitness standard deviation)
  var variance = 0.0
  for ind in pop.individuals:
    let diff = ind.state.fitness - result.avgFitness
    variance += diff * diff
  variance /= float(pop.individuals.len)
  result.diversity = sqrt(variance)

proc printStats*(stats: EvolutionStats) =
  ## Print evolution statistics
  echo "Generation: ", stats.generation
  echo &"  Best:    {stats.bestFitness:.2f}"
  echo &"  Average: {stats.avgFitness:.2f}"
  echo &"  Worst:   {stats.worstFitness:.2f}"
  echo &"  Diversity: {stats.diversity:.2f}"
  echo ""

# ============================================================================
# Speciation (NEAT-style)
# ============================================================================

type
  Species* = ref object
    id*: int
    members*: seq[NeuroAgent]
    representative*: NeuroAgent
    bestFitness*: float
    avgFitness*: float
    stagnation*: int

proc compatibilityDistance*(net1, net2: NeuralNetwork, 
                            c1, c2, c3: float): float =
  ## Calculate compatibility distance between two networks (NEAT-style)
  var matching = 0
  var disjoint = 0
  var excess = 0
  var weightDiff = 0.0
  
  var innovations1 = initTable[int, Connection]()
  var innovations2 = initTable[int, Connection]()
  
  for conn in net1.connections:
    innovations1[conn.innovation] = conn
  for conn in net2.connections:
    innovations2[conn.innovation] = conn
  
  let maxInnov1 = if net1.connections.len > 0: net1.connections[^1].innovation else: 0
  let maxInnov2 = if net2.connections.len > 0: net2.connections[^1].innovation else: 0
  let maxInnov = max(maxInnov1, maxInnov2)
  
  for innov in innovations1.keys:
    if innov in innovations2:
      matching += 1
      weightDiff += abs(innovations1[innov].weight - innovations2[innov].weight)
    elif innov < maxInnov:
      disjoint += 1
    else:
      excess += 1
  
  for innov in innovations2.keys:
    if innov notin innovations1:
      if innov < maxInnov:
        disjoint += 1
      else:
        excess += 1
  
  let avgWeightDiff = if matching > 0: weightDiff / float(matching) else: 0.0
  let n = max(net1.connections.len, net2.connections.len).float
  let normalizer = if n < 20: 1.0 else: n
  
  result = (c1 * excess.float / normalizer) + 
           (c2 * disjoint.float / normalizer) + 
           (c3 * avgWeightDiff)

proc assignToSpecies*(agent: NeuroAgent, species: var seq[Species], 
                      threshold: float) =
  ## Assign agent to species based on compatibility
  for sp in species:
    let dist = compatibilityDistance(
      agent.network, sp.representative.network,
      1.0, 1.0, 0.4  # c1, c2, c3 coefficients
    )
    
    if dist < threshold:
      sp.members.add(agent)
      agent.species = sp.id
      return
  
  # Create new species
  let newSpecies = Species(
    id: species.len,
    members: @[agent],
    representative: agent,
    bestFitness: agent.state.fitness,
    avgFitness: agent.state.fitness,
    stagnation: 0
  )
  species.add(newSpecies)
  agent.species = newSpecies.id

# ============================================================================
# Export
# ============================================================================

export Population, SelectionMethod, EvolutionStats, Species
export newPopulation, evaluatePopulation
export tournamentSelection, rouletteSelection, rankSelection
export mutateNeuroAgent, crossoverNeuroAgents, evolvePopulation
export computeStats, printStats
export compatibilityDistance, assignToSpecies
