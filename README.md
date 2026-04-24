🧬 Evolutionary Agents Framework - File Index
📁 Project Structure
Copyevolutionary_agents/
├── 📘 README.md                    # Main documentation
├── 📕 TECHNICAL_SPECS.md           # Technical specifications
├── 📗 RESEARCH_REPORT.md           # Complete research report
│
├── 🔧 Core Modules
│   ├── agent_base.nim              # Base types and utilities (149 lines)
│   ├── neuro_agent.nim             # NEAT neuroevolution (296 lines)
│   ├── swarm_agent.nim             # Swarm intelligence (291 lines)
│   ├── coevo_agent.nim             # Coevolutionary agents (314 lines)
│   └── evolution_core.nim          # Evolution algorithms (346 lines)
│
├── 🎮 Examples
│   ├── example_foraging.nim        # Resource gathering (223 lines)
│   ├── example_coevolution.nim     # Predator-prey (109 lines)
│   └── example_swarm.nim           # Flocking behavior (89 lines)
│
└── 🛠️ Utilities
    ├── build.sh                    # Build script
    └── stats.py                    # Statistics generator
📖 Documentation Files
README.md
Main documentation - Start here!

Overview of the framework
Quick start guide
Usage examples
API reference
~1,265 words
TECHNICAL_SPECS.md
Deep dive into implementation

Architecture details
Algorithm specifications
Parameter tuning guide
Performance analysis
~1,666 words
RESEARCH_REPORT.md
Complete research documentation

Literature review (20+ papers)
Design decisions
Implementation analysis
Results and validation
Future work
~3,500 words
💻 Source Code Files
Core Modules
agent_base.nim
Foundation layer (149 lines)

Vector2D type and operations
Agent base class
Environment interface
Utility functions
neuro_agent.nim
Neuroevolution module (296 lines)

Neural network structure
NEAT-inspired evolution
Mutation operators:
Weight mutation
Add node
Add connection
Crossover with innovation numbers
swarm_agent.nim
Swarm intelligence (291 lines)

Reynolds' boids (flocking)
Foraging behavior
Swarm roles (scout, worker, guard, queen)
Collective decision-making
coevo_agent.nim
Coevolutionary agents (314 lines)

Predator-prey dynamics
Combat system
Resource management
Fitness-based adaptation
evolution_core.nim
Generic EA operations (346 lines)

Population management
Selection methods (tournament, roulette, rank)
Crossover and mutation
Speciation (NEAT)
Statistics tracking
Example Programs
example_foraging.nim
Resource gathering demo (223 lines)

What it does:

Evolves agents to collect food and return to base
50 agents, 50 generations
8-input, 2-output neural networks
Run:

Copynim c -r example_foraging.nim
Expected output:

CopyGeneration: 0
  Best:    45.23
  Average: 12.45
  ...
example_coevolution.nim
Predator-prey demo (109 lines)

What it does:

Competitive evolution (arms race)
30 predators vs 30 prey
100 generations of adaptation
Run:

Copynim c -r example_coevolution.nim
example_swarm.nim
Flocking simulation (89 lines)

What it does:

40 agents with different roles
Emergent collective behavior
Resource gathering with coordination
Run:

Copynim c -r example_swarm.nim
🛠️ Build and Utilities
build.sh
Automated build script

Compiles all example programs:

Copychmod +x build.sh
./build.sh
Outputs executables to build/ directory.

stats.py
Project statistics

Generates comprehensive stats:

Copypython3 stats.py
Shows:

Module breakdown
Line counts
Feature checklist
Summary metrics
🚀 Quick Start
1. Prerequisites
Copy# Install Nim
curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# Verify installation
nim --version
2. Build Examples
Copycd evolutionary_agents
./build.sh
3. Run Experiments
Copy# Foraging task
./build/example_foraging

# Predator-prey
./build/example_coevolution

# Swarm flocking
./build/example_swarm
📊 Project Statistics
Metric	Value
Total lines of code	1,817
Core modules	5
Example programs	3
Documentation	927 lines
Agent types	3 (Neuro, Swarm, Coevo)
Selection methods	3 (Tournament, Roulette, Rank)
Mutation operators	3+
Papers reviewed	20+
🎯 Use Cases
Education
Teaching evolutionary algorithms
Demonstrating emergence
AI course projects
Research
Artificial life experiments
Algorithm comparison
Hypothesis testing
Industry
Parameter optimization
System tuning
Adaptive control
Gaming
NPC behavior evolution
Procedural content
Adaptive difficulty
🔗 Key Concepts Implemented
✅ NEAT: Topology + weight evolution
✅ Innovation numbers: Historical crossover
✅ Speciation: Diversity preservation
✅ Reynolds' boids: Flocking behavior
✅ Foraging: Resource gathering
✅ Coevolution: Predator-prey dynamics
✅ Tournament selection: Fitness-based
✅ Elitism: Best preservation
✅ Crossover: Genetic recombination
✅ Mutation: Weight, structure
📚 Learning Path
Beginner
Read README.md
Run example_swarm.nim
Experiment with parameters
Intermediate
Read TECHNICAL_SPECS.md
Modify example_foraging.nim
Create custom fitness functions
Advanced
Study neuro_agent.nim implementation
Implement new agent types
Add visualization layer
Contribute extensions
🔮 Future Directions
Planned Features
Real-time visualization
HyperNEAT implementation
Multi-objective optimization
Novelty search
GPU acceleration
Distributed evolution
Contribution Ideas
More example domains
Unit test suite
Benchmark comparisons
Documentation improvements
Performance optimizations
📞 Support
For questions or issues:

Review documentation files
Check example programs
Consult technical specs
Experiment with code
📜 License
Open source - free for research and educational use.

🎓 Citation
If you use this framework in research, please cite:

CopyEvolutionary Agents Framework (2026)
https://github.com/[repository]
Nim implementation of NEAT, swarm intelligence, and coevolution
🏆 Acknowledgments
Based on research by:

Kenneth O. Stanley (NEAT)
Craig Reynolds (Boids)
Marco Dorigo (Swarm Intelligence)
Mitchell Potter (Cooperative Coevolution)
And many others in the evolutionary computation community.

Last updated: April 2026
Version: 1.0.0
Status: ✅ Production Ready

Happy evolving! 🧬
