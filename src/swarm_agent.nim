# ============================================================================
# Swarm Agent - Collective behavior through local interactions
# ============================================================================
# Implements flocking, foraging, and emergent collective behaviors

import agent_base, types
import random, sequtils, algorithm, math

# BehaviorType, SwarmRole, SwarmAgent, Resource, SwarmEnvironment are now in types.nim

# ============================================================================
# Swarm Agent Creation
# ============================================================================

proc newSwarmAgent*(id: int, role: SwarmRole, behavior: BehaviorType): SwarmAgent =
  new(result)
  result.id = id
  result.role = role
  result.behavior = behavior
  result.communication = newSeq[float](4)  # 4 pheromone channels
  result.neighbors = @[]
  result.carrying = false
  result.state = AgentState(
    position: Vector2D(x: 0.0, y: 0.0),
    velocity: Vector2D(x: randomFloat(-1, 1), y: randomFloat(-1, 1)),
    energy: 100.0,
    age: 0,
    fitness: 0.0
  )

proc newSwarmEnvironment*(width, height: float, resourceCount: int): SwarmEnvironment =
  new(result)
  result.width = width
  result.height = height
  result.agents = @[]
  result.time = 0
  result.nest = Vector2D(x: width / 2.0, y: height / 2.0)
  result.resources = @[]
  
  # Create resources
  for i in 0..<resourceCount:
    result.resources.add(Resource(
      position: randomVector2D(width, height),
      amount: randomFloat(10.0, 50.0),
      collected: false
    ))

# ============================================================================
# Flocking Behaviors (Reynolds' Boids)
# ============================================================================

proc cohesion(agent: SwarmAgent, env: SwarmEnvironment): Vector2D =
  ## Steer towards average position of neighbors
  if agent.neighbors.len == 0:
    return Vector2D(x: 0.0, y: 0.0)
  
  var center = Vector2D(x: 0.0, y: 0.0)
  for neighborId in agent.neighbors:
    for other in env.agents:
      if other.id == neighborId:
        center = center + other.state.position
        break
  
  if agent.neighbors.len > 0:
    center = center * (1.0 / float(agent.neighbors.len))
    return (center - agent.state.position).normalize()
  return Vector2D(x: 0.0, y: 0.0)

proc separation(agent: SwarmAgent, env: SwarmEnvironment, minDist: float = 5.0): Vector2D =
  ## Avoid crowding neighbors
  var steer = Vector2D(x: 0.0, y: 0.0)
  var count = 0
  
  for neighborId in agent.neighbors:
    for other in env.agents:
      if other.id == neighborId:
        let dist = distance(agent.state.position, other.state.position)
        if dist > 0 and dist < minDist:
          var diff = agent.state.position - other.state.position
          diff = diff.normalize() * (1.0 / dist)  # Weight by distance
          steer = steer + diff
          inc count
        break
  
  if count > 0:
    steer = steer * (1.0 / float(count))
  
  return steer.normalize()

proc alignment(agent: SwarmAgent, env: SwarmEnvironment): Vector2D =
  ## Steer towards average heading of neighbors
  if agent.neighbors.len == 0:
    return Vector2D(x: 0.0, y: 0.0)
  
  var avgVel = Vector2D(x: 0.0, y: 0.0)
  for neighborId in agent.neighbors:
    for other in env.agents:
      if other.id == neighborId:
        avgVel = avgVel + other.state.velocity
        break
  
  if agent.neighbors.len > 0:
    avgVel = avgVel * (1.0 / float(agent.neighbors.len))
    return avgVel.normalize()
  return Vector2D(x: 0.0, y: 0.0)

# ============================================================================
# Foraging Behaviors
# ============================================================================

proc findNearestResource(agent: SwarmAgent, env: SwarmEnvironment): int =
  ## Find closest uncollected resource
  result = -1
  var minDist = Inf
  
  for i, res in env.resources:
    if not res.collected:
      let dist = distance(agent.state.position, res.position)
      if dist < minDist:
        minDist = dist
        result = i

proc moveToTarget(agent: SwarmAgent, target: Vector2D, strength: float = 1.0): Vector2D =
  ## Generate force towards target
  let desired = (target - agent.state.position).normalize() * strength
  return desired - agent.state.velocity

# ============================================================================
# Neighbor Detection
# ============================================================================

proc updateNeighbors(agent: SwarmAgent, env: SwarmEnvironment, radius: float = 30.0) =
  ## Update list of nearby agents
  agent.neighbors = @[]
  for other in env.agents:
    if other.id != agent.id:
      let dist = distance(agent.state.position, other.state.position)
      if dist < radius:
        agent.neighbors.add(other.id)

# ============================================================================
# Swarm Agent Update
# ============================================================================

method update*(agent: SwarmAgent, env: Environment, dt: float) =
  let swarmEnv = SwarmEnvironment(env)
  
  # Update neighbors
  updateNeighbors(agent, swarmEnv, 30.0)
  
  # Calculate forces based on behavior and role
  var force = Vector2D(x: 0.0, y: 0.0)
  
  case agent.behavior:
  of btFlock:
    # Classic flocking behavior
    let coh = cohesion(agent, swarmEnv) * 1.0
    let sep = separation(agent, swarmEnv) * 1.5
    let ali = alignment(agent, swarmEnv) * 1.0
    force = coh + sep + ali
    
  of btForage:
    # Foraging behavior
    if not agent.carrying:
      let resIdx = findNearestResource(agent, swarmEnv)
      if resIdx >= 0:
        force = moveToTarget(agent, swarmEnv.resources[resIdx].position, 2.0)
        # Check if reached resource
        if distance(agent.state.position, swarmEnv.resources[resIdx].position) < 3.0:
          agent.carrying = true
          swarmEnv.resources[resIdx].collected = true
          agent.state.fitness += 10.0
    else:
      # Return to nest
      force = moveToTarget(agent, swarmEnv.nest, 2.0)
      if distance(agent.state.position, swarmEnv.nest) < 5.0:
        agent.carrying = false
        agent.state.fitness += 20.0
    
    # Add separation to avoid collisions
    force = force + separation(agent, swarmEnv) * 0.5
    
  of btExplore:
    # Exploration with repulsion from visited areas
    if rand(1.0) < 0.01:  # Occasionally pick new random target
      agent.target = randomVector2D(swarmEnv.width, swarmEnv.height)
    force = moveToTarget(agent, agent.target, 1.0)
    force = force + separation(agent, swarmEnv) * 1.0
    
  of btDefend:
    # Defend nest area
    let distToNest = distance(agent.state.position, swarmEnv.nest)
    if distToNest > 50.0:
      force = moveToTarget(agent, swarmEnv.nest, 2.0)
    else:
      # Circle around nest
      let angle = agent.state.age.float * 0.05
      let circlePos = swarmEnv.nest + Vector2D(
        x: cos(angle) * 40.0,
        y: sin(angle) * 40.0
      )
      force = moveToTarget(agent, circlePos, 1.0)
    
  of btHybrid:
    # Mix behaviors based on role
    case agent.role:
    of srScout:
      force = cohesion(agent, swarmEnv) * 0.5 + 
              alignment(agent, swarmEnv) * 0.5
      if rand(1.0) < 0.02:
        agent.target = randomVector2D(swarmEnv.width, swarmEnv.height)
      force = force + moveToTarget(agent, agent.target, 0.5)
    of srWorker:
      # Foraging behavior
      if not agent.carrying:
        let resIdx = findNearestResource(agent, swarmEnv)
        if resIdx >= 0:
          force = moveToTarget(agent, swarmEnv.resources[resIdx].position, 2.0)
      else:
        force = moveToTarget(agent, swarmEnv.nest, 2.0)
    of srGuard:
      # Defensive behavior
      force = moveToTarget(agent, swarmEnv.nest, 1.0)
    of srQueen:
      # Stay near nest
      force = moveToTarget(agent, swarmEnv.nest, 0.5)
  
  # Apply force
  agent.state.velocity = agent.state.velocity + force * 0.2
  
  # Limit speed
  let speed = agent.state.velocity.magnitude()
  let maxSpeed = 3.0
  if speed > maxSpeed:
    agent.state.velocity = agent.state.velocity.normalize() * maxSpeed
  
  # Update position
  agent.state.position = agent.state.position + agent.state.velocity
  wrapAround(agent.state.position, swarmEnv.width, swarmEnv.height)
  
  # Update age and energy
  agent.state.age += 1
  agent.state.energy -= 0.05 * dt
  
  # Fitness increases for staying alive
  agent.state.fitness += 0.1 * dt

method evaluateFitness*(agent: SwarmAgent, env: Environment): float =
  result = agent.state.fitness

# ============================================================================
# Export
# ============================================================================

export newSwarmAgent, newSwarmEnvironment
export cohesion, separation, alignment, findNearestResource
