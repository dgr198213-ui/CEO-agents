# ============================================================================
# Example: Foraging Task with Neuroevolutionary Agents
# ============================================================================
# Demonstrates neuroevolution for a resource gathering task

import ../src/agent_base, ../src/neuro_agent, ../src/evolution_core
import strformat, random, sequtils, os, math

# ============================================================================
# Foraging Environment
# ============================================================================

type
  Food = object
    position: Vector2D
    value: float
    active: bool

  ForagingEnv = ref object of Environment
    foods: seq[Food]
    homeBase: Vector2D

proc newForagingEnv(width, height: float, numFoods: int): ForagingEnv =
  new(result)
  result.width = width
  result.height = height
  result.time = 0
  result.agents = @[]
  result.homeBase = Vector2D(x: width / 2.0, y: height / 2.0)
  result.foods = @[]
  
  for i in 0..<numFoods:
    result.foods.add(Food(
      position: randomVector2D(width, height),
      value: randomFloat(5.0, 20.0),
      active: true
    ))

# ============================================================================
# Custom Foraging Agent
# ============================================================================

type
  ForagingAgent = ref object of NeuroAgent
    carrying: bool
    foodCollected: int

proc newForagingAgent(id: int): ForagingAgent =
  new(result)
  result.id = id
  result.carrying = false
  result.foodCollected = 0
  result.network = newNeuralNetwork(
    inputSize = 8,   # pos_x, pos_y, vel_x, vel_y, energy, food_dx, food_dy, food_dist
    outputSize = 2   # move_x, move_y
  )
  result.state = AgentState(
    position: Vector2D(x: 200.0, y: 200.0),  # Start at home
    velocity: Vector2D(x: 0.0, y: 0.0),
    energy: 100.0,
    age: 0,
    fitness: 0.0
  )

method sense*(agent: ForagingAgent, env: Environment): seq[float] =
  let foragingEnv = ForagingEnv(env)
  var inputs = newSeq[float]()
  
  # Self state (5 inputs)
  inputs.add(agent.state.position.x / env.width)
  inputs.add(agent.state.position.y / env.height)
  inputs.add(agent.state.velocity.x / 5.0)
  inputs.add(agent.state.velocity.y / 5.0)
  inputs.add(agent.state.energy / 100.0)
  
  # Find nearest food or home
  if not agent.carrying:
    var nearestFood: Vector2D
    var minDist = Inf
    
    for food in foragingEnv.foods:
      if food.active:
        let dist = distance(agent.state.position, food.position)
        if dist < minDist:
          minDist = dist
          nearestFood = food.position
    
    if minDist < Inf:
      let diff = nearestFood - agent.state.position
      inputs.add(diff.x / env.width)
      inputs.add(diff.y / env.height)
      inputs.add(minDist / sqrt(env.width * env.width + env.height * env.height))
    else:
      inputs.add(0.0)
      inputs.add(0.0)
      inputs.add(1.0)
  else:
    # Return to home
    let diff = foragingEnv.homeBase - agent.state.position
    let dist = distance(agent.state.position, foragingEnv.homeBase)
    inputs.add(diff.x / env.width)
    inputs.add(diff.y / env.height)
    inputs.add(dist / sqrt(env.width * env.width + env.height * env.height))
  
  return inputs

method act*(agent: ForagingAgent, outputs: seq[float], env: Environment) =
  if outputs.len < 2:
    return
  
  let foragingEnv = ForagingEnv(env)
  
  # Movement
  let force = Vector2D(x: outputs[0] * 3.0, y: outputs[1] * 3.0)
  agent.state.velocity = agent.state.velocity + force * 0.2
  
  let maxSpeed = 4.0
  let speed = agent.state.velocity.magnitude()
  if speed > maxSpeed:
    agent.state.velocity = agent.state.velocity.normalize() * maxSpeed
  
  agent.state.position = agent.state.position + agent.state.velocity
  wrapAround(agent.state.position, env.width, env.height)
  
  # Check food collection
  if not agent.carrying:
    for i, food in foragingEnv.foods:
      if food.active:
        let dist = distance(agent.state.position, food.position)
        if dist < 5.0:
          agent.carrying = true
          foragingEnv.foods[i].active = false
          agent.state.fitness += food.value
          break
  
  # Check home delivery
  if agent.carrying:
    let dist = distance(agent.state.position, foragingEnv.homeBase)
    if dist < 10.0:
      agent.carrying = false
      agent.foodCollected += 1
      agent.state.fitness += 50.0  # Bonus for delivery

method evaluateFitness*(agent: ForagingAgent, env: Environment): float =
  result = agent.state.fitness
  result += agent.foodCollected.float * 100.0  # Strong bonus for completed deliveries
  result += agent.state.age.float * 0.01  # Small bonus for survival

# ============================================================================
# Main Evolution Loop
# ============================================================================

proc main() =
  randomize()
  
  echo "🧬 Neuroevolutionary Foraging Agents"
  echo "====================================\n"
  
  # Evolution parameters
  let params = EvolutionParams(
    populationSize: 50,
    mutationRate: 0.3,
    crossoverRate: 0.7,
    eliteSize: 5,
    maxGenerations: 50,
    tournamentSize: 3
  )
  
  # Create initial population
  var pop = newPopulation[ForagingAgent]()
  for i in 0..<params.populationSize:
    pop.individuals.add(newForagingAgent(i))
  
  var nextId = params.populationSize
  
  # Evolution loop
  for gen in 0..<params.maxGenerations:
    # Create environment for this generation
    let env = newForagingEnv(400.0, 400.0, 20)
    
    # Evaluate each agent
    for agent in pop.individuals:
      # Reset agent
      agent.state.position = env.homeBase
      agent.state.velocity = Vector2D(x: 0.0, y: 0.0)
      agent.state.energy = 100.0
      agent.state.age = 0
      agent.state.fitness = 0.0
      agent.carrying = false
      agent.foodCollected = 0
      
      # Simulate for 500 timesteps
      for step in 0..499:
        agent.update(env, 1.0)
        agent.state.energy -= 0.02
        
        if agent.state.energy <= 0:
          break
    
    # Evaluate population
    evaluatePopulation(pop, env)
    
    # Print statistics
    let stats = computeStats(pop)
    printStats(stats)
    
    # Check for convergence
    if stats.bestFitness > 500.0:
      echo "✅ Solution found! Best fitness: ", stats.bestFitness
      echo "Food collected by best agent: ", ForagingAgent(pop.bestIndividual).foodCollected
      break
    
    # Evolve to next generation
    if gen < params.maxGenerations - 1:
      pop = evolvePopulation(pop, params, nextId)
      nextId += params.populationSize
  
  echo "\n🎉 Evolution complete!"
  echo "Final best fitness: ", fmt"{pop.bestFitness:.2f}"
  echo "Final average fitness: ", fmt"{pop.avgFitness:.2f}"

when isMainModule:
  main()
