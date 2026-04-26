# Package
version       = "2.0.0"
author        = "CEO-Agents Team"
description   = "Sistema de Agentes Evolutivos CEO - Orquestación jerárquica con algoritmos genéticos, integración LLM y motor de ejecución real"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"
# db_connector es opcional; activa con: nimble build -d:ceoEnableSqliteTools
# requires "db_connector"

# ============================================================================
# Tareas de Compilación
# ============================================================================

task build, "Compila todos los módulos (modo debug)":
  exec "bash build.sh all"

task buildRelease, "Compila en modo release optimizado":
  exec "bash build.sh --release all"

task buildCore, "Valida los módulos del núcleo":
  exec "bash build.sh core"

task buildExamples, "Compila todos los ejemplos":
  exec "bash build.sh examples"

task buildAPI, "Compila el servidor API REST":
  exec "bash build.sh api"

task clean, "Limpia artefactos de compilación":
  exec "bash build.sh --clean"

# ============================================================================
# Tareas de Ejecución
# ============================================================================

task runFunctional, "Ejecuta la demo funcional completa (CEO + Stack Agents)":
  exec "nim c -r examples/example_ceo_functional.nim"

task runCEO, "Ejecuta el ejemplo integrado CEO + Stack Agents (simulación)":
  exec "nim c -r examples/example_integrated_ceo_stack.nim"

task runSwarm, "Ejecuta la simulación de Swarm Intelligence":
  exec "nim c -r examples/example_swarm.nim"

task runKnowledge, "Ejecuta la simulación de Knowledge Agents":
  exec "nim c -r examples/example_knowledge.nim"

task runCoevo, "Ejecuta la simulación de Co-evolución":
  exec "nim c -r examples/example_coevolution.nim"

task runForaging, "Ejecuta la simulación de Foraging Behavior":
  exec "nim c -r examples/example_foraging.nim"

task runPWA, "Ejecuta la demo de PWA Agents":
  exec "nim c -r examples/example_pwa_integrated.nim"

task runAPI, "Inicia el servidor API REST (puerto 8080)":
  exec "nim c -r --threads:off src/api_wrapper.nim"

# ============================================================================
# Tareas de Testing
# ============================================================================

task test, "Ejecuta todos los tests unitarios":
  exec "nim c -r tests/test_agent_base.nim"
  exec "nim c -r tests/test_evolution_core.nim"
  exec "nim c -r tests/test_tool_registry.nim"
  exec "nim c -r tests/test_ceo_agent.nim"
  exec "nim c -r tests/test_api_endpoints.nim"
  echo "Todos los tests completados"

task testCore, "Ejecuta tests del nucleo unicamente":
  exec "nim c -r tests/test_agent_base.nim"
  exec "nim c -r tests/test_evolution_core.nim"

task testAPI, "Ejecuta tests de la API":
  exec "nim c -r tests/test_api_endpoints.nim"
