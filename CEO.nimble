# Package
version       = "1.0.0"
author        = "CEO-Agents Team"
description   = "Sistema de Agentes Evolutivos CEO (Cognitive Evolutionary Orchestrator)"
license       = "MIT"
srcDir        = "."

# Dependencies
requires "nim >= 2.0.0"

# Tasks
task build, "Compila todos los ejemplos":
  exec "bash build.sh"

task buildRelease, "Compila en modo release optimizado":
  exec "bash build.sh --release"

task clean, "Limpia artefactos de compilación":
  exec "bash build.sh --clean"

task runCEO, "Ejecuta el ejemplo principal CEO + Stack Agents":
  exec "nim c -r example_integrated_ceo_stack.nim"

task runSwarm, "Ejecuta el ejemplo de Swarm Intelligence":
  exec "nim c -r example_swarm.nim"

task runKnowledge, "Ejecuta el ejemplo de Knowledge Agents":
  exec "nim c -r example_knowledge.nim"

task runCoevo, "Ejecuta el ejemplo de Co-evolución":
  exec "nim c -r example_coevolution.nim"

task runForaging, "Ejecuta el ejemplo de Foraging Behavior":
  exec "nim c -r example_foraging.nim"

task runPWA, "Ejecuta el ejemplo de PWA Agents":
  exec "nim c -r example_pwa_integrated.nim"

task test, "Ejecuta todos los ejemplos en modo de verificación":
  exec "nim c -r example_integrated_ceo_stack.nim"
  exec "nim c -r example_swarm.nim"
  echo "Tests básicos completados"
