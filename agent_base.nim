# ============================================================================
# Agent Base Module - Core abstractions for evolutionary agents
# ============================================================================
# Defines base types and interfaces for all evolutionary agent systems

import random, sequtils, algorithm, math, json, tables, times, tool_registry

# ============================================================================
# Type Definitions
# ============================================================================

type
  # Position in 2D space
  Vector2D* = object
    x*, y*: float

  # Agent state representation
  AgentState* = object
    position*: Vector2D
    velocity*: Vector2D
    energy*: float
    age*: int
    fitness*: float

  # Genome representation for evolution
  Genome*[T] = object
    genes*: seq[T]
    fitness*: float
    id*: int
    generation*: int

  # Neural network weights genome
  NeuralGenome* = Genome[float]

  # Behavioral tree genome
  BehaviorGenome* = Genome[string]

  # Base agent interface
  Agent* = ref object of RootObj
    id*: int
    state*: AgentState
    genome*: NeuralGenome
    
  # Environment interface
  Environment* = ref object of RootObj
    width*, height*: float
    agents*: seq[Agent]
    time*: int

  # Evolution parameters
  EvolutionParams* = object
    populationSize*: int
    mutationRate*: float
    crossoverRate*: float
    eliteSize*: int
    maxGenerations*: int
    tournamentSize*: int

# ============================================================================
# Execution Types for Real Task Execution
# ============================================================================

type
  # Execution state for agents
  ExecutionState* = enum
    esIdle
    esInitializing
    esExecuting
    esWaiting
    esCompleted
    esFailed

  # Agent permissions
  Permission* = object
    allowedTools*: set[ToolCapability]
    maxFileSize*: int
    canExecuteShell*: bool
    canAccessNetwork*: bool

  # Task result for execution
  ExecutionResult* = object
    success*: bool
    output*: string
    error*: string
    durationMs*: float
    toolsUsed*: seq[string]

  # Agent with execution capabilities
  ExecutableAgent* = ref object of Agent
    executionState*: ExecutionState
    availableTools*: set[ToolCapability]
    permission*: Permission
    lastResult*: ExecutionResult
    currentTask*: string

# ============================================================================
# Vector2D Operations
# ============================================================================

proc `+`*(a, b: Vector2D): Vector2D =
  Vector2D(x: a.x + b.x, y: a.y + b.y)

proc `-`*(a, b: Vector2D): Vector2D =
  Vector2D(x: a.x - b.x, y: a.y - b.y)

proc `*`*(v: Vector2D, scalar: float): Vector2D =
  Vector2D(x: v.x * scalar, y: v.y * scalar)

proc magnitude*(v: Vector2D): float =
  sqrt(v.x * v.x + v.y * v.y)

proc normalize*(v: Vector2D): Vector2D =
  let mag = v.magnitude()
  if mag > 0.0001:
    Vector2D(x: v.x / mag, y: v.y / mag)
  else:
    Vector2D(x: 0.0, y: 0.0)

proc distance*(a, b: Vector2D): float =
  (b - a).magnitude()

# ============================================================================
# Genome Operations
# ============================================================================

proc newGenome*[T](size: int, generation: int = 0): Genome[T] =
  result.genes = newSeq[T](size)
  result.fitness = 0.0
  result.generation = generation
  result.id = rand(1_000_000)

proc clone*[T](g: Genome[T]): Genome[T] =
  result = g
  result.genes = g.genes
  result.id = rand(1_000_000)

# ============================================================================
# Agent Methods
# ============================================================================

method update*(agent: Agent, env: Environment, dt: float) {.base.} =
  ## Update agent state - to be overridden by specific agent types
  discard

method sense*(agent: Agent, env: Environment): seq[float] {.base.} =
  ## Sense environment - to be overridden
  result = @[]

method act*(agent: Agent, outputs: seq[float], env: Environment) {.base.} =
  ## Perform action based on neural network outputs
  discard

method evaluateFitness*(agent: Agent, env: Environment): float {.base.} =
  ## Calculate fitness score
  result = agent.state.fitness

# ============================================================================
# Utility Functions
# ============================================================================

proc clamp*(value, minVal, maxVal: float): float =
  max(minVal, min(maxVal, value))

proc randomFloat*(minVal, maxVal: float): float =
  rand(maxVal - minVal) + minVal

proc randomVector2D*(width, height: float): Vector2D =
  Vector2D(x: rand(width), y: rand(height))

proc wrapAround*(pos: var Vector2D, width, height: float) =
  ## Wrap position around boundaries (toroidal topology)
  if pos.x < 0: pos.x += width
  if pos.x > width: pos.x -= width
  if pos.y < 0: pos.y += height
  if pos.y > height: pos.y -= height

# ============================================================================
# Export all symbols
# ============================================================================

export Vector2D, AgentState, Genome, NeuralGenome, BehaviorGenome
export Agent, Environment, EvolutionParams
export ExecutableAgent, ExecutionState, ExecutionResult, Permission, ToolCapability
export `+`, `-`, `*`, magnitude, normalize, distance
export newGenome, clone
export update, sense, act, evaluateFitness
export clamp, randomFloat, randomVector2D, wrapAround
