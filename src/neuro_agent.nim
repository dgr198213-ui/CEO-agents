# ============================================================================
# Neuroevolution Agent - NEAT-inspired neural evolution
# ============================================================================
# Implements neuroevolutionary agents that evolve both topology and weights

import agent_base, types
import random, sequtils, algorithm, math, tables

# NodeType, Connection, NeuralNode, NeuralNetwork, NeuroAgent are now in types.nim

# ============================================================================
# Neural Network Creation
# ============================================================================

proc newNeuralNetwork*(inputSize, outputSize: int): NeuralNetwork =
  new(result)
  result.nodes = @[]
  result.connections = @[]
  result.nextNodeId = 0
  result.innovationNumber = 0

  # Create input nodes
  for i in 0..<inputSize:
    result.nodes.add(NeuralNode(
      id: result.nextNodeId,
      nodeType: ntInput,
      value: 0.0,
      bias: 0.0
    ))
    inc result.nextNodeId

  # Create output nodes
  for i in 0..<outputSize:
    result.nodes.add(NeuralNode(
      id: result.nextNodeId,
      nodeType: ntOutput,
      value: 0.0,
      bias: randomFloat(-1.0, 1.0)
    ))
    inc result.nextNodeId

  # Fully connect input to output
  for i in 0..<inputSize:
    for o in inputSize..<(inputSize + outputSize):
      result.connections.add(Connection(
        fromNode: i,
        toNode: o,
        weight: randomFloat(-2.0, 2.0),
        enabled: true,
        innovation: result.innovationNumber
      ))
      inc result.innovationNumber

proc newNeuroAgent*(id: int, inputSize, outputSize: int): NeuroAgent =
  new(result)
  result.id = id
  result.network = newNeuralNetwork(inputSize, outputSize)
  result.state = AgentState(
    position: Vector2D(x: 0.0, y: 0.0),
    velocity: Vector2D(x: 0.0, y: 0.0),
    energy: 100.0,
    age: 0,
    fitness: 0.0
  )
  result.species = 0

# ============================================================================
# Neural Network Forward Pass
# ============================================================================

proc activate*(nn: NeuralNetwork, inputs: seq[float]): seq[float] =
  # Reset all node values
  for i in 0..<nn.nodes.len:
    nn.nodes[i].value = 0.0

  # Set input values
  let inputCount = min(inputs.len, nn.nodes.len)
  for i in 0..<inputCount:
    if nn.nodes[i].nodeType == ntInput:
      nn.nodes[i].value = inputs[i]

  # Process connections (simple feedforward for now)
  # var processed = newSeq[bool](nn.nodes.len)
  
  for conn in nn.connections:
    if conn.enabled and conn.fromNode < nn.nodes.len and conn.toNode < nn.nodes.len:
      let fromVal = nn.nodes[conn.fromNode].value
      nn.nodes[conn.toNode].value += fromVal * conn.weight

  # Apply activation function (tanh) to output nodes
  var outputs = newSeq[float]()
  for node in nn.nodes:
    if node.nodeType == ntOutput:
      outputs.add(tanh(node.value + node.bias))

  return outputs

# ============================================================================
# Mutation Operators
# ============================================================================

proc mutateWeights*(nn: NeuralNetwork, rate: float, perturbStrength: float = 0.3) =
  ## Mutate connection weights
  for i in 0..<nn.connections.len:
    if rand(1.0) < rate:
      if rand(1.0) < 0.1:
        # 10% chance: completely randomize
        nn.connections[i].weight = randomFloat(-2.0, 2.0)
      else:
        # 90% chance: perturb existing weight
        nn.connections[i].weight += randomFloat(-perturbStrength, perturbStrength)
        nn.connections[i].weight = clamp(nn.connections[i].weight, -5.0, 5.0)

proc mutateAddNode*(nn: NeuralNetwork): bool =
  ## Add a new node by splitting an existing connection
  if nn.connections.len == 0:
    return false

  let connIdx = rand(nn.connections.len - 1)
  var conn = nn.connections[connIdx]
  
  if not conn.enabled:
    return false

  # Disable old connection
  nn.connections[connIdx].enabled = false

  # Create new node
  let newNode = NeuralNode(
    id: nn.nextNodeId,
    nodeType: ntHidden,
    value: 0.0,
    bias: randomFloat(-1.0, 1.0)
  )
  nn.nodes.add(newNode)
  let newNodeIdx = nn.nodes.len - 1
  inc nn.nextNodeId

  # Add two new connections through the new node
  nn.connections.add(Connection(
    fromNode: conn.fromNode,
    toNode: newNodeIdx,
    weight: 1.0,
    enabled: true,
    innovation: nn.innovationNumber
  ))
  inc nn.innovationNumber

  nn.connections.add(Connection(
    fromNode: newNodeIdx,
    toNode: conn.toNode,
    weight: conn.weight,
    enabled: true,
    innovation: nn.innovationNumber
  ))
  inc nn.innovationNumber

  return true

proc mutateAddConnection*(nn: NeuralNetwork): bool =
  ## Add a new random connection
  if nn.nodes.len < 2:
    return false

  let attempts = 20
  for _ in 0..<attempts:
    let fromIdx = rand(nn.nodes.len - 1)
    let toIdx = rand(nn.nodes.len - 1)
    
    # Avoid self-connections and input-to-input
    if fromIdx == toIdx:
      continue
    if nn.nodes[fromIdx].nodeType == ntOutput:
      continue
    if nn.nodes[toIdx].nodeType == ntInput:
      continue

    # Check if connection already exists
    var exists = false
    for conn in nn.connections:
      if conn.fromNode == fromIdx and conn.toNode == toIdx:
        exists = true
        break

    if not exists:
      nn.connections.add(Connection(
        fromNode: fromIdx,
        toNode: toIdx,
        weight: randomFloat(-2.0, 2.0),
        enabled: true,
        innovation: nn.innovationNumber
      ))
      inc nn.innovationNumber
      return true

  return false

# ============================================================================
# Neuroevolution-specific Methods
# ============================================================================

method update*(agent: NeuroAgent, env: Environment, dt: float) =
  # Get sensor inputs
  let inputs = agent.sense(env)
  
  # Process through neural network
  let outputs = agent.network.activate(inputs)
  
  # Act based on outputs
  agent.act(outputs, env)
  
  # Update state
  agent.state.age += 1
  agent.state.energy -= 0.1 * dt

method sense*(agent: NeuroAgent, env: Environment): seq[float] =
  ## Default sensing: position, velocity, energy
  result = @[
    agent.state.position.x / env.width,
    agent.state.position.y / env.height,
    agent.state.velocity.x,
    agent.state.velocity.y,
    agent.state.energy / 100.0
  ]

method act*(agent: NeuroAgent, outputs: seq[float], env: Environment) =
  ## Default action: move based on first two outputs
  if outputs.len >= 2:
    let force = Vector2D(x: outputs[0], y: outputs[1])
    agent.state.velocity = agent.state.velocity + force * 0.1
    agent.state.velocity = agent.state.velocity.normalize() * clamp(agent.state.velocity.magnitude(), 0.0, 5.0)
    agent.state.position = agent.state.position + agent.state.velocity
    wrapAround(agent.state.position, env.width, env.height)

# ============================================================================
# Crossover
# ============================================================================

proc crossover*(parent1, parent2: NeuralNetwork): NeuralNetwork =
  ## Perform crossover between two neural networks (NEAT-style)
  result = newNeuralNetwork(0, 0)
  result.nodes = parent1.nodes # Inherit nodes from fitter parent
  result.nextNodeId = parent1.nextNodeId
  
  # Align connections by innovation number
  var connectionMap = initTable[int, Connection]()
  
  for conn in parent1.connections:
    connectionMap[conn.innovation] = conn
  
  for conn in parent2.connections:
    if conn.innovation in connectionMap:
      # Matching gene: randomly choose from either parent
      if rand(1.0) < 0.5:
        connectionMap[conn.innovation] = conn
    # Disjoint/excess genes only inherited from parent1 (fitter)
  
  # Ensure topology consistency (basic weight alignment)
  result.connections = @[]
  for innov in sorted(toSeq(connectionMap.keys)):
    result.connections.add(connectionMap[innov])

  result.innovationNumber = max(parent1.innovationNumber, parent2.innovationNumber)

# ============================================================================
# Export
# ============================================================================

export newNeuralNetwork, newNeuroAgent, activate
export mutateWeights, mutateAddNode, mutateAddConnection, crossover
