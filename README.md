# CEO-Agents — Sistema de Agentes Evolutivos 🧬

> **Cognitive Evolutionary Orchestrator** — Un framework de agentes inteligentes basado en algoritmos evolutivos, neuroevolución y sistemas multi-agente, implementado en Nim 2.x.

[![Nim 2.0+](https://img.shields.io/badge/Nim-2.0%2B-orange)](https://nim-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Instalación Rápida

```bash
git clone https://github.com/dgr198213-ui/CEO-agents.git
cd CEO-agents
chmod +x install.sh
./install.sh
```

Ver [INSTALL.md](INSTALL.md) para instrucciones detalladas de instalación.

**Requisitos:** Nim 2.0+, GCC 9.0+, Linux/macOS/Windows(WSL2)

---

## 📚 Overview

This framework provides modular, efficient implementations of:

- **Neuroevolution** (NEAT-inspired neural network evolution)
- **Swarm Intelligence** (flocking, foraging, collective behavior)
- **Coevolutionary Systems** (predator-prey, competitive evolution)
- **Generic Evolutionary Algorithms** (selection, crossover, mutation)
- **CEO Orchestrator** (multi-agent software development coordination)
- **PWA Agents** (Progressive Web App optimization agents)
- **Knowledge Agents** (evolutionary knowledge graph management)

Based on cutting-edge research in:
- EvoAgent framework (2024)
- NEAT and neuroevolution variants
- Swarm robotics and collective behavior
- Competitive/cooperative coevolution

---

## 🏗️ Architecture

### Core Modules

```
CEO-agents/
├── agent_base.nim              # Tipos base: Agent, Environment, Vector2D
├── evolution_core.nim          # Motor evolutivo genérico
├── neuro_agent.nim             # NeuroAgent con red neuronal NEAT-inspired
├── swarm_agent.nim             # SwarmAgent: roles y comportamientos emergentes
├── coevo_agent.nim             # CoevoAgent: co-evolución predador-presa
├── knowledge_agent.nim         # KnowledgeAgent: grafos de conocimiento evolutivos
├── ceo_agent.nim               # CEOAgent: orquestador de proyectos de software
├── stack_agents.nim            # StackAgent: agentes especializados
├── cache_strategy_agent.nim    # Agente PWA: estrategias de caché
├── notification_agent.nim      # Agente PWA: notificaciones push
├── sync_agent.nim              # Agente PWA: sincronización offline
├── example_integrated_ceo_stack.nim  # CEO + Stack Agents
├── example_swarm.nim           # Swarm Intelligence
├── example_knowledge.nim       # Knowledge Agents
├── example_coevolution.nim     # Co-evolución predador-presa
├── example_foraging.nim        # Neuroevolución foraging
├── example_pwa_integrated.nim  # Sistema PWA evolutivo
├── install.sh                  # Instalación automática
├── build.sh                    # Script de compilación
└── CEO.nimble                  # Configuración del paquete Nim
```

### Type Hierarchy

```nim
Agent (agent_base.nim)
├── NeuroAgent (neuro_agent.nim)
│   ├── SwarmAgent (swarm_agent.nim)
│   ├── CoevoAgent (coevo_agent.nim)
│   └── KnowledgeAgent (knowledge_agent.nim)
├── CEOAgent (ceo_agent.nim)
├── StackAgent (stack_agents.nim)
├── CacheStrategyAgent (cache_strategy_agent.nim)
├── NotificationAgent (notification_agent.nim)
└── SyncAgent (sync_agent.nim)
```

---

## 🚀 Quick Start

### 1. Neuroevolution Example

Evolve neural networks to control foraging agents:

```bash
nim c -r example_foraging.nim
```

**What it does:**
- Evolves population of 50 agents over 50 generations
- Agents learn to collect food and return to home base
- Uses NEAT-inspired topology evolution
- Tournament selection, crossover, and mutation

**Output:**
```
🧬 Neuroevolutionary Foraging Agents
====================================

Generation: 0
  Best:    45.23
  Average: 12.45
  Worst:   0.00
  Diversity: 15.32

Generation: 1
  Best:    78.50
  Average: 28.91
  ...
```

### 2. Coevolution Example

Competitive evolution between predators and prey:

```bash
nim c -r example_coevolution.nim
```

**Features:**
- Two populations evolve simultaneously
- Arms race: predators evolve hunting, prey evolve evasion
- Combat system with attack/defense rolls
- Fitness based on kills (predators) and escapes (prey)

### 3. Swarm Intelligence Example

Emergent collective behavior:

```bash
nim c -r example_swarm.nim
```

**Behaviors:**
- **Flocking**: Cohesion, separation, alignment (Reynolds' boids)
- **Foraging**: Resource collection and nest delivery
- **Defending**: Territory protection
- **Exploring**: Area coverage

---

## 🧪 Key Features

### 1. Neuroevolution (NEAT-inspired)

```nim
# Create neural network that evolves topology
let network = newNeuralNetwork(inputSize = 5, outputSize = 2)

# Structural mutations
mutateAddNode(network)        # Split connection with new node
mutateAddConnection(network)  # Add random connection
mutateWeights(network, 0.3)   # Perturb weights

# Crossover with innovation numbers
let offspring = crossover(parent1.network, parent2.network)
```

**Features:**
- Evolves both weights AND topology
- Innovation numbers for crossover alignment
- Feedforward and recurrent connections
- Speciation for diversity preservation

### 2. Swarm Behaviors

```nim
# Create swarm agent with role and behavior
let agent = newSwarmAgent(id, srWorker, btForage)

# Automatic local interactions
updateNeighbors(agent, env, radius = 30.0)

# Reynolds' flocking rules
let coh = cohesion(agent, env)        # Steer to center
let sep = separation(agent, env)      # Avoid crowding
let ali = alignment(agent, env)       # Match velocity
```

**Roles:**
- `srScout`: Exploration
- `srWorker`: Resource gathering
- `srGuard`: Territory defense
- `srQueen`: Reproduction

### 3. Coevolutionary Dynamics

```nim
# Create competing populations
let predator = newCoevoAgent(id, ctPredator, 8, 2)
let prey = newCoevoAgent(id, ctPrey, 11, 2)

# Simulate interactions
handleInteractions(env)  # Combat, feeding, energy depletion

# Coevolve both populations
coevolve(predators, prey, params)
```

**Features:**
- Predator-prey dynamics
- Combat resolution with stochastic rolls
- Resource management (food for prey)
- Fitness pressure from both sides

### 4. Evolution Core

```nim
# Configure evolution
let params = EvolutionParams(
  populationSize: 50,
  mutationRate: 0.3,
  crossoverRate: 0.7,
  eliteSize: 5,
  maxGenerations: 100,
  tournamentSize: 3
)

# Selection methods
let parent = tournamentSelection(pop, 3)
let parent = rouletteSelection(pop)
let parent = rankSelection(pop)

# Evolution step
let nextGen = evolvePopulation(pop, params, nextId)
```

---

## 🎯 Use Cases

### 1. **Game AI**
- Evolve controllers for NPCs
- Adaptive difficulty
- Emergent strategies

### 2. **Robotics**
- Swarm coordination
- Path planning
- Behavior synthesis

### 3. **Optimization**
- Parameter tuning
- Multi-objective problems
- Constraint satisfaction

### 4. **Research**
- Artificial life studies
- Evolutionary dynamics
- Collective intelligence

---

## 🔬 Implementation Details

### Vector2D Operations

```nim
let pos = Vector2D(x: 10.0, y: 20.0)
let vel = Vector2D(x: 1.0, y: 0.5)

let newPos = pos + vel              # Vector addition
let dist = distance(pos, target)    # Euclidean distance
let normalized = vel.normalize()    # Unit vector
let magnitude = vel.magnitude()     # Length
```

### Toroidal Topology

```nim
# Wrap around boundaries
wrapAround(agent.state.position, env.width, env.height)
```

### Neural Network Activation

```nim
# Forward pass
let inputs = agent.sense(env)
let outputs = network.activate(inputs)
agent.act(outputs, env)
```

---

## 📊 Performance Characteristics

| Component | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Neural forward pass | O(E) | O(N + E) |
| Mutation | O(1) | O(1) |
| Crossover | O(E) | O(E) |
| Tournament selection | O(k) | O(1) |
| Neighbor detection | O(n²) | O(n) |
| Speciation | O(n·s·E) | O(n) |

Where:
- E = number of connections
- N = number of nodes
- n = population size
- s = number of species
- k = tournament size

---

## 🎨 Customization

### Create Custom Agent Type

```nim
type
  MyAgent = ref object of NeuroAgent
    customField: float

proc newMyAgent(id: int): MyAgent =
  new(result)
  result.id = id
  result.network = newNeuralNetwork(inputSize, outputSize)
  result.customField = 0.0

method sense*(agent: MyAgent, env: Environment): seq[float] =
  # Custom sensing logic
  result = @[agent.state.position.x, agent.state.position.y]

method act*(agent: MyAgent, outputs: seq[float], env: Environment) =
  # Custom action logic
  agent.state.velocity = Vector2D(x: outputs[0], y: outputs[1])

method evaluateFitness*(agent: MyAgent, env: Environment): float =
  # Custom fitness function
  result = agent.customField * 10.0
```

### Custom Evolution Strategy

```nim
proc customSelection[T](pop: Population[T]): T =
  # Implement custom selection
  result = pop.individuals[0]

proc customMutation(agent: MyAgent, rate: float) =
  # Implement custom mutations
  if rand(1.0) < rate:
    agent.customField += randomFloat(-1.0, 1.0)
```

---

## 📖 Research References

1. **Stanley, K. O., & Miikkulainen, R. (2002)**. *Evolving Neural Networks through Augmenting Topologies*. Evolutionary Computation.

2. **Reynolds, C. W. (1987)**. *Flocks, herds and schools: A distributed behavioral model*. SIGGRAPH.

3. **Potter, M. A., & De Jong, K. A. (2000)**. *Cooperative coevolution: An architecture for evolving coadapted subcomponents*. Evolutionary Computation.

4. **Ferrante et al. (2013)**. *GESwarm: Grammatical evolution for the automatic synthesis of collective behaviors in swarm robotics*. GECCO.

5. **Papavasileiou et al. (2021)**. *A systematic literature review of the successors of neuroevolution of augmenting topologies*. Evolutionary Computation.

6. **EvoAgent (2024)**. *Towards Automatic Multi-Agent Generation via Evolutionary Algorithm*. arXiv:2406.14228.

---

## 🛠️ Technical Notes

### Memory Management
- Nim's garbage collector handles agent allocation
- Use `ref object` for polymorphism
- Sequences are automatically resized

### Random Number Generation
- Call `randomize()` to seed RNG
- Use `rand()` for uniform distribution
- Thread-safe variants available

### Compilation Options

```bash
# Debug build
nim c -d:debug example_foraging.nim

# Release build (optimized)
nim c -d:release example_foraging.nim

# Danger mode (max optimization)
nim c -d:danger example_foraging.nim
```

---

## 🤝 Contributing

This framework is designed for extensibility:

1. Add new agent types by inheriting from `Agent`
2. Implement custom sensors and actuators
3. Define domain-specific fitness functions
4. Create new evolutionary operators
5. Implement visualization tools

---

## 📝 License

Open source - feel free to use in research and applications.

---

## 🎓 Educational Value

Perfect for learning:
- Evolutionary algorithms
- Multi-agent systems
- Artificial life
- Emergent behavior
- Neural network evolution
- Nim programming

---

## 🔮 Future Extensions

Potential additions:
- [ ] HyperNEAT for indirect encoding
- [ ] ES-HyperNEAT for substrate evolution
- [ ] Multi-objective optimization (NSGA-II)
- [ ] Novelty search
- [ ] Quality diversity algorithms
- [ ] Visualization tools
- [ ] Parallel evolution
- [ ] GPU acceleration

---

**Happy Evolving! 🧬**
