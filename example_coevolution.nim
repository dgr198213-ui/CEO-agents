# ============================================================================
# Example: Predator-Prey Coevolution
# ============================================================================
# Demonstrates competitive coevolution between predators and prey

import agent_base, coevo_agent, evolution_core
import random, sequtils

proc runCoevolutionExperiment() =
  randomize()
  
  echo "🐺🐰 Predator-Prey Coevolution"
  echo "===============================\n"
  
  let params = EvolutionParams(
    populationSize: 30,
    mutationRate: 0.25,
    crossoverRate: 0.7,
    eliteSize: 3,
    maxGenerations: 100,
    tournamentSize: 3
  )
  
  # Create initial populations
  var predatorPop = newPopulation[CoevoAgent]()
  var preyPop = newPopulation[CoevoAgent]()
  
  # Initialize predators
  for i in 0..<params.populationSize:
    let agent = newCoevoAgent(i, ctPredator, inputSize = 8, outputSize = 2)
    agent.state.position = randomVector2D(400.0, 400.0)
    predatorPop.individuals.add(agent)
  
  # Initialize prey
  for i in 0..<params.populationSize:
    let agent = newCoevoAgent(i + params.populationSize, ctPrey, inputSize = 11, outputSize = 2)
    agent.state.position = randomVector2D(400.0, 400.0)
    preyPop.individuals.add(agent)
  
  # Coevolution loop
  for gen in 0..<params.maxGenerations:
    echo "Generation ", gen + 1, ":"
    
    # Create environment
    let env = newCoevoEnvironment(400.0, 400.0, params.populationSize, params.populationSize)
    env.predators = predatorPop.individuals
    env.prey = preyPop.individuals
    
    # Reset all agents
    for pred in env.predators:
      pred.state.position = randomVector2D(env.width, env.height)
      pred.state.velocity = Vector2D(x: 0.0, y: 0.0)
      pred.state.fitness = 0.0
      pred.state.age = 0
      pred.health = 100.0
      pred.kills = 0
    
    for prey in env.prey:
      prey.state.position = randomVector2D(env.width, env.height)
      prey.state.velocity = Vector2D(x: 0.0, y: 0.0)
      prey.state.fitness = 0.0
      prey.state.age = 0
      prey.health = 100.0
      prey.escapes = 0
    
    # Simulate interactions
    for step in 0..999:
      # Update all agents
      for pred in env.predators:
        if pred.health > 0:
          pred.update(env, 1.0)
      
      for prey in env.prey:
        if prey.health > 0:
          prey.update(env, 1.0)
      
      # Handle interactions
      handleInteractions(env)
      
      env.time += 1
    
    # Evaluate fitness
    evaluatePopulation(predatorPop, env)
    evaluatePopulation(preyPop, env)
    
    # Print statistics
    let predStats = computeStats(predatorPop)
    let preyStats = computeStats(preyPop)
    
    echo "  Predators:"
    echo "    Best: ", predStats.bestFitness.formatFloat(ffDecimal, 1)
    echo "    Avg:  ", predStats.avgFitness.formatFloat(ffDecimal, 1)
    echo "    Best kills: ", CoevoAgent(predatorPop.bestIndividual).kills
    
    echo "  Prey:"
    echo "    Best: ", preyStats.bestFitness.formatFloat(ffDecimal, 1)
    echo "    Avg:  ", preyStats.avgFitness.formatFloat(ffDecimal, 1)
    echo "    Best escapes: ", CoevoAgent(preyPop.bestIndividual).escapes
    echo ""
    
    # Evolve both populations
    if gen < params.maxGenerations - 1:
      predatorPop = evolvePopulation(predatorPop, params, 1000 + gen * 100)
      preyPop = evolvePopulation(preyPop, params, 2000 + gen * 100)
  
  echo "🎉 Coevolution complete!"

when isMainModule:
  runCoevolutionExperiment()
