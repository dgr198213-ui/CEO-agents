# Package
version       = "1.0.0"
author        = "Evolutionary Agents Team"
description   = "Cognitive Evolutionary Orchestrator - Framework for evolutionary agents"
license       = "MIT"
srcDir        = "src"
bin           = @["ceo_agent", "stack_agents", "cache_strategy_agent", "notification_agent", "sync_agent"]

# Dependencies
requires "nim >= 2.0.0"

task test, "Full Integration Test Suite":
  let tests = [
    "examples/example_swarm.nim",
    "examples/example_knowledge.nim",
    "examples/example_integrated_ceo_stack.nim",
    "examples/example_coevolution.nim",
    "examples/example_foraging.nim",
    "examples/example_pwa_integrated.nim"
  ]
  for t in tests:
    echo "Running test: " & t
    exec "nim c -r --hints:off --mm:orc --threads:on --path:src " & t
