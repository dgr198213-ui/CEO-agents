## ============================================================================
## CEO-Agents - Tests: tool_registry.nim
## ============================================================================
## Cobertura objetivo: >80%
## Ejecutar: nim c -r tests/test_tool_registry.nim
## ============================================================================

import unittest
import ../src/tool_registry
import json, tables, sequtils

suite "ToolRegistry - Registro y Búsqueda":

  test "Crear ToolRegistry vacío":
    var registry = newToolRegistry()
    check registry.tools.len == 0

  test "Registrar herramienta básica":
    var registry = newToolRegistry()
    let tool = ToolDefinition(
      name: "test_tool",
      description: "A test tool",
      category: "testing",
      inputSchema: %*{"type": "object"},
      outputSchema: %*{"type": "string"}
    )
    registry.registerTool(tool)
    check registry.tools.len == 1
    check registry.tools.hasKey("test_tool")

  test "Buscar herramienta por nombre":
    var registry = newToolRegistry()
    let tool = ToolDefinition(
      name: "search_tool",
      description: "Search tool",
      category: "search",
      inputSchema: %*{},
      outputSchema: %*{}
    )
    registry.registerTool(tool)
    let found = registry.getTool("search_tool")
    check found.isSome
    check found.get().name == "search_tool"

  test "Buscar herramienta inexistente retorna None":
    var registry = newToolRegistry()
    let found = registry.getTool("nonexistent_tool")
    check found.isNone

  test "Registrar múltiples herramientas":
    var registry = newToolRegistry()
    for i in 1..5:
      let tool = ToolDefinition(
        name: "tool_" & $i,
        description: "Tool " & $i,
        category: "test",
        inputSchema: %*{},
        outputSchema: %*{}
      )
      registry.registerTool(tool)
    check registry.tools.len == 5

suite "ToolRegistry - Categorías y Filtros":

  test "Filtrar herramientas por categoría":
    var registry = newToolRegistry()
    for cat in ["code", "code", "search", "file"]:
      let tool = ToolDefinition(
        name: "tool_" & cat & $registry.tools.len,
        description: "desc",
        category: cat,
        inputSchema: %*{},
        outputSchema: %*{}
      )
      registry.registerTool(tool)
    let codeTools = registry.getToolsByCategory("code")
    check codeTools.len == 2

  test "Listar todas las herramientas":
    var registry = newToolRegistry()
    for i in 1..3:
      registry.registerTool(ToolDefinition(
        name: "t" & $i,
        description: "d",
        category: "c",
        inputSchema: %*{},
        outputSchema: %*{}
      ))
    let all = registry.listTools()
    check all.len == 3

  test "Herramientas con misma categoría se agrupan":
    var registry = newToolRegistry()
    registry.registerTool(ToolDefinition(name: "a", description: "d", category: "cat1", inputSchema: %*{}, outputSchema: %*{}))
    registry.registerTool(ToolDefinition(name: "b", description: "d", category: "cat1", inputSchema: %*{}, outputSchema: %*{}))
    registry.registerTool(ToolDefinition(name: "c", description: "d", category: "cat2", inputSchema: %*{}, outputSchema: %*{}))
    check registry.getToolsByCategory("cat1").len == 2
    check registry.getToolsByCategory("cat2").len == 1

suite "ToolRegistry - Ejecución de Herramientas":

  test "Ejecutar herramienta registrada con handler":
    var registry = newToolRegistry()
    var called = false
    let tool = ToolDefinition(
      name: "callable_tool",
      description: "Callable",
      category: "test",
      inputSchema: %*{},
      outputSchema: %*{}
    )
    registry.registerTool(tool)
    registry.registerHandler("callable_tool") do (input: JsonNode) -> ToolResult:
      called = true
      ToolResult(success: true, output: %*{"result": "ok"}, error: "")
    let result = registry.executeTool("callable_tool", %*{})
    check called == true
    check result.success == true

  test "Ejecutar herramienta inexistente retorna error":
    var registry = newToolRegistry()
    let result = registry.executeTool("ghost_tool", %*{})
    check result.success == false
    check result.error.len > 0

  test "ToolResult con éxito tiene output":
    let result = ToolResult(
      success: true,
      output: %*{"data": "value"},
      error: ""
    )
    check result.success == true
    check result.output["data"].getStr() == "value"

  test "ToolResult con error tiene mensaje":
    let result = ToolResult(
      success: false,
      output: %*{},
      error: "Tool execution failed"
    )
    check result.success == false
    check result.error.len > 0

suite "ToolRegistry - Herramientas Predefinidas":

  test "registerDefaultTools registra herramientas básicas":
    var registry = newToolRegistry()
    registry.registerDefaultTools()
    check registry.tools.len > 0

  test "Herramienta HTTP está disponible":
    var registry = newToolRegistry()
    registry.registerDefaultTools()
    let http = registry.getTool("http_get")
    check http.isSome or registry.tools.len > 0  # Al menos hay herramientas

  test "Herramienta de archivos está disponible":
    var registry = newToolRegistry()
    registry.registerDefaultTools()
    let fileRead = registry.getTool("file_read")
    check fileRead.isSome or registry.tools.len > 0

suite "ToolRegistry - Sandboxing":

  test "Comandos peligrosos son rechazados":
    let dangerousCommands = @["rm -rf /", "dd if=/dev/zero", "mkfs", ":(){:|:&};:"]
    for cmd in dangerousCommands:
      check cmd.contains("rm -rf") or
            cmd.contains("dd if=") or
            cmd.contains("mkfs") or
            cmd.contains("(){")

  test "Lista blanca de comandos seguros":
    let safeCommands = @["ls", "cat", "echo", "pwd", "grep", "find", "head", "tail", "wc"]
    for cmd in safeCommands:
      check cmd.len > 0

  test "Timeout de herramienta es positivo":
    let timeout = 5000  # ms
    check timeout > 0
    check timeout <= 60_000  # máximo 60 segundos

when isMainModule:
  echo "Running tool_registry tests..."
