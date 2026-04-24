# ============================================================================
# Example: Swarm Flocking Behavior
# ============================================================================
# Demonstrates emergent collective behavior in swarm agents

import agent_base, swarm_agent
import random, sequtils

proc runSwarmDemo() =
  randomize()
  
  echo "🐦 Swarm Flocking Simulation"
  echo "============================\n"
  
  # Create swarm environment
  let env = newSwarmEnvironment(500.0, 500.0, resourceCount = 15)
  
  # Create heterogeneous swarm with different roles
  let numAgents = 40
  
  for i in 0..<numAgents:
    var agent: SwarmAgent
    
    if i < 5:
      # Scouts
      agent = newSwarmAgent(i, srScout, btHybrid)
    elif i < 25:
      # Workers (foragers)
      agent = newSwarmAgent(i, srWorker, btForage)
    elif i < 35:
      # Flocking agents
      agent = newSwarmAgent(i, srWorker, btFlock)
    else:
      # Guards
      agent = newSwarmAgent(i, srGuard, btDefend)
    
    agent.state.position = env.nest + Vector2D(
      x: randomFloat(-20, 20),
      y: randomFloat(-20, 20)
    )
    
    env.agents.add(agent)
  
  echo "Simulating ", numAgents, " agents for 1000 timesteps...\n"
  
  # Simulation loop
  for step in 0..999:
    for agent in env.agents:
      SwarmAgent(agent).update(env, 1.0)
    
    env.time += 1
    
    # Print progress every 100 steps
    if (step + 1) mod 100 == 0:
      var totalFitness = 0.0
      var resourcesCollected = 0
      
      for agent in env.agents:
        totalFitness += agent.state.fitness
      
      for res in env.resources:
        if res.collected:
          resourcesCollected += 1
      
      echo "Step ", step + 1, ":"
      echo "  Total fitness: ", totalFitness.formatFloat(ffDecimal, 1)
      echo "  Resources collected: ", resourcesCollected, " / ", env.resources.len
  
  echo "\n🎉 Simulation complete!"
  
  # Final statistics
  var totalFitness = 0.0
  var bestFitness = -Inf
  var bestAgent: SwarmAgent
  
  for agent in env.agents:
    totalFitness += agent.state.fitness
    if agent.state.fitness > bestFitness:
      bestFitness = agent.state.fitness
      bestAgent = SwarmAgent(agent)
  
  echo "\nFinal Results:"
  echo "  Average fitness: ", (totalFitness / float(numAgents)).formatFloat(ffDecimal, 2)
  echo "  Best fitness: ", bestFitness.formatFloat(ffDecimal, 2)
  echo "  Best agent role: ", bestAgent.role
  echo "  Best agent behavior: ", bestAgent.behavior

when isMainModule:
  runSwarmDemo()
