# Package
version       = "2.0.0"
author        = "CEO-Agents Team"
description   = "Sistema de Agentes Evolutivos CEO con ejecución funcional de tareas - Integración LLM, Tool Registry y Motor de Ejecución"
license       = "MIT"
srcDir        = "."

# Dependencies
requires "nim >= 2.0.0"
requires "db_connector"

# Tasks
task build, "Compila todos los ejemplos":
  exec "bash build.sh"

task buildRelease, "Compila en modo release optimizado":
  exec "bash build.sh --release"

task clean, "Limpia artefactos de compilación":
  exec "bash build.sh --clean"

task runFunctional, "Ejecuta el sistema funcional completo con integración LLM y herramientas":
  exec "nim c -r example_ceo_functional.nim"

task runCEO, "Ejecuta el ejemplo principal CEO + Stack Agents (modo simulación)":
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
