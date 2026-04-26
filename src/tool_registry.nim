# Tool Registry Module - Sistema de herramientas ejecutables para agentes
# ============================================================================
# Registry centralizado para descubrimiento y ejecución de capacidades de agentes
#
# Funcionalidades:
# - Registro dinámico de herramientas
# - Descubrimiento por capacidad y categoría
# - Sistema de permisos por agente
# - Validación de parámetros
# - Ejecución segura con manejo de errores
#
# Herramientas predefinidas:
# - FileRead, FileWrite, FileList, FileDelete
# - ShellExecute, ProcessSpawn
# - HttpRequest (GET, POST, PUT, DELETE)
# - DatabaseQuery
# - CodeAnalysis
# - LLMChat

import httpclient, json, streams, os, sequtils, tables, strutils, algorithm
import osproc, re, times

# ============================================================================
# Tipos Base para Herramientas
# ============================================================================

type
  ParameterType* = enum
    ptString
    ptInteger
    ptFloat
    ptBoolean
    ptArray
    ptObject

  ParameterDef* = object
    name*: string
    paramType*: ParameterType
    description*: string
    required*: bool
    defaultValue*: string
    validation*: string  # Regex pattern for validation

  ToolCategory* = enum
    tcFileSystem
    tcNetwork
    tcDatabase
    tcCode
    tcAI
    tcSystem
    tcCustom

  ToolCapability* = enum
    tcFileRead
    tcFileWrite
    tcFileDelete
    tcShellExecute
    tcHttpRequest
    tcDatabaseQuery
    tcCodeAnalysis
    tcLLMChat

  ToolPermission* = object
    allowedAgents*: seq[string]
    allowedRoles*: seq[string]
    maxRequestsPerHour*: int
    rateLimitWindowMs*: int

  ToolDefinition* = ref object
    name*: string
    description*: string
    category*: ToolCategory
    parameters*: seq[ParameterDef]
    permissions*: ToolPermission
    handler*: proc(params: JsonNode): ToolResult
    metadata*: Table[string, string]

  ToolResult* = object
    success*: bool
    output*: string
    data*: JsonNode
    error*: string
    errorCode*: string
    executionTimeMs*: float
    toolName*: string

  ToolExecutionContext* = object
    tool*: ToolDefinition
    params*: JsonNode
    callerAgent*: string
    callerRole*: string
    timestamp*: int64
    requestId*: string

  ToolRegistry* = ref object
    tools*: Table[string, ToolDefinition]
    categories*: Table[ToolCategory, seq[string]]
    agentPermissions*: Table[string, seq[string]]  # agent -> tool names

# ============================================================================
# Constructores y Utilidades
# ============================================================================

proc newParameterDef*(name: string, paramType: ParameterType,
                      description: string, required: bool = true,
                      defaultValue: string = "", validation: string = ""): ParameterDef =
  result = ParameterDef(
    name: name,
    paramType: paramType,
    description: description,
    required: required,
    defaultValue: defaultValue,
    validation: validation
  )

proc newToolPermission*(allowedAgents: seq[string] = @[],
                        allowedRoles: seq[string] = @[],
                        maxRequestsPerHour: int = 1000,
                        rateLimitWindowMs: int = 3600000): ToolPermission =
  result = ToolPermission(
    allowedAgents: allowedAgents,
    allowedRoles: allowedRoles,
    maxRequestsPerHour: maxRequestsPerHour,
    rateLimitWindowMs: rateLimitWindowMs
  )

proc newToolDefinition*(name, description: string,
                        category: ToolCategory): ToolDefinition =
  new(result)
  result.name = name
  result.description = description
  result.category = category
  result.parameters = @[]
  result.permissions = newToolPermission()
  result.metadata = initTable[string, string]()

# ============================================================================
# Registry de Herramientas
# ============================================================================

var
  globalRegistry*: ToolRegistry

proc initToolRegistry*(): ToolRegistry =
  new(result)
  result.tools = initTable[string, ToolDefinition]()
  result.categories = initTable[ToolCategory, seq[string]]()
  result.agentPermissions = initTable[string, seq[string]]()
  globalRegistry = result

proc registerTool*(registry: var ToolRegistry, tool: ToolDefinition) =
  registry.tools[tool.name] = tool

  if not registry.categories.hasKey(tool.category):
    registry.categories[tool.category] = @[]

  if tool.name notin registry.categories[tool.category]:
    registry.categories[tool.category].add(tool.name)

proc getTool*(registry: ToolRegistry, name: string): ToolDefinition =
  if registry.tools.hasKey(name):
    return registry.tools[name]
  return nil

proc getToolsByCategory*(registry: ToolRegistry, category: ToolCategory): seq[ToolDefinition] =
  if registry.categories.hasKey(category):
    for toolName in registry.categories[category]:
      if registry.tools.hasKey(toolName):
        result.add(registry.tools[toolName])

proc searchTools*(registry: ToolRegistry, query: string): seq[ToolDefinition] =
  let lowerQuery = query.toLower()
  for name, tool in registry.tools:
    if tool.name.toLower().contains(lowerQuery) or
       tool.description.toLower().contains(lowerQuery):
      result.add(tool)

proc getAllTools*(registry: ToolRegistry): seq[ToolDefinition] =
  for name, tool in registry.tools:
    result.add(tool)

# ============================================================================
# Sistema de Permisos
# ============================================================================

proc grantToolPermission*(registry: var ToolRegistry, agentName: string,
                         toolName: string) =
  if not registry.agentPermissions.hasKey(agentName):
    registry.agentPermissions[agentName] = @[]

  if toolName notin registry.agentPermissions[agentName]:
    registry.agentPermissions[agentName].add(toolName)

proc revokeToolPermission*(registry: var ToolRegistry, agentName: string,
                          toolName: string) =
  if registry.agentPermissions.hasKey(agentName):
    let idx = registry.agentPermissions[agentName].find(toolName)
    if idx >= 0:
      registry.agentPermissions[agentName].delete(idx)

proc canAgentUseTool*(registry: ToolRegistry, agentName: string,
                     toolName: string): bool =
  # Check agent-specific permissions
  if registry.agentPermissions.hasKey(agentName):
    if toolName in registry.agentPermissions[agentName]:
      return true

  # Check tool's global permissions
  if registry.tools.hasKey(toolName):
    let tool = registry.tools[toolName]
    if tool.permissions.allowedAgents.len == 0:
      return true  # No restrictions means everyone can use
    return agentName in tool.permissions.allowedAgents

  return false

proc setAgentTools*(registry: var ToolRegistry, agentName: string,
                   toolNames: seq[string]) =
  registry.agentPermissions[agentName] = toolNames

proc getAgentTools*(registry: ToolRegistry, agentName: string): seq[ToolDefinition] =
  if registry.agentPermissions.hasKey(agentName):
    for toolName in registry.agentPermissions[agentName]:
      if registry.tools.hasKey(toolName):
        result.add(registry.tools[toolName])

# ============================================================================
# Validación de Parámetros
# ============================================================================

proc validateParameter*(param: ParameterDef, value: JsonNode): tuple[valid: bool, error: string] =
  case param.paramType
  of ptString:
    if value.kind != JString:
      return (false, "Expected string for parameter " & param.name)
  of ptInteger:
    if value.kind != JInt:
      return (false, "Expected integer for parameter " & param.name)
  of ptFloat:
    if value.kind != JFloat and value.kind != JInt:
      return (false, "Expected number for parameter " & param.name)
  of ptBoolean:
    if value.kind != JBool:
      return (false, "Expected boolean for parameter " & param.name)
  of ptArray:
    if value.kind != JArray:
      return (false, "Expected array for parameter " & param.name)
  of ptObject:
    if value.kind != JObject:
      return (false, "Expected object for parameter " & param.name)

  # Check validation regex if provided
  if param.validation.len > 0 and value.kind == JString:
    let regexStr = param.validation
    # Simple pattern matching (in production, use a proper regex library)
    if not value.str.match(re(regexStr)):
      return (false, "Value does not match required pattern for " & param.name)

  return (true, "")

proc validateToolParameters*(tool: ToolDefinition, params: JsonNode): tuple[valid: bool, error: string] =
  if params.kind != JObject:
    return (false, "Parameters must be a JSON object")

  # Check required parameters
  for param in tool.parameters:
    if param.required:
      if not params.hasKey(param.name):
        return (false, "Missing required parameter: " & param.name)

  # Validate each provided parameter
  for key, value in params:
    var found = false
    for param in tool.parameters:
      if param.name == key:
        found = true
        let (valid, error) = validateParameter(param, value)
        if not valid:
          return (false, error)
        break

    if not found:
      return (false, "Unknown parameter: " & key)

  return (true, "")

# ============================================================================
# Ejecución de Herramientas
# ============================================================================

proc executeTool*(registry: ToolRegistry, toolName: string,
                 params: JsonNode, callerAgent: string = ""): ToolResult =
  let startTime = epochTime()

  # Check if tool exists
  if not registry.tools.hasKey(toolName):
    return ToolResult(
      success: false,
      toolName: toolName,
      error: "Tool not found: " & toolName,
      errorCode: "TOOL_NOT_FOUND",
      executionTimeMs: (epochTime() - startTime) * 1000.0
    )

  let tool = registry.tools[toolName]

  # Check permissions
  if callerAgent.len > 0 and not canAgentUseTool(registry, callerAgent, toolName):
    return ToolResult(
      success: false,
      toolName: toolName,
      error: "Agent " & callerAgent & " does not have permission to use " & toolName,
      errorCode: "PERMISSION_DENIED",
      executionTimeMs: (epochTime() - startTime) * 1000.0
    )

  # Validate parameters
  let (validParams, paramsError) = validateToolParameters(tool, params)
  if not validParams:
    return ToolResult(
      success: false,
      toolName: toolName,
      error: paramsError,
      errorCode: "INVALID_PARAMETERS",
      executionTimeMs: (epochTime() - startTime) * 1000.0
    )

  # Execute tool
  try:
    var toolRes = tool.handler(params)
    toolRes.executionTimeMs = (epochTime() - startTime) * 1000.0
    toolRes.toolName = toolName
    return toolRes
  except Exception as e:
    return ToolResult(
      success: false,
      toolName: toolName,
      error: "Execution error: " & e.msg,
      errorCode: "EXECUTION_ERROR",
      executionTimeMs: (epochTime() - startTime) * 1000.0
    )

# ============================================================================
# Herramientas Predefinidas del Sistema de Archivos
# ============================================================================

proc registerFileSystemTools*(registry: var ToolRegistry) =

  # FileRead
  let fileReadTool = newToolDefinition(
    "FileRead",
    "Lee el contenido de un archivo del sistema de archivos",
    tcFileSystem
  )
  fileReadTool.parameters = @[
    newParameterDef("path", ptString, "Ruta completa al archivo", required = true),
    newParameterDef("encoding", ptString, "Codificación del archivo (utf-8, ascii)", required = false, defaultValue = "utf-8")
  ]
  fileReadTool.handler = proc(params: JsonNode): ToolResult =
    let path = params{"path"}.getStr()
    try:
      let content = readFile(path)
      return ToolResult(
        success: true,
        output: content,
        data: %* {"content": content, "path": path, "size": content.len}
      )
    except IOError as e:
      return ToolResult(
        success: false,
        error: "Error reading file: " & e.msg,
        errorCode: "FILE_READ_ERROR"
      )
  registerTool(registry, fileReadTool)

  # FileWrite
  let fileWriteTool = newToolDefinition(
    "FileWrite",
    "Escribe contenido a un archivo, creando o sobrescribiendo",
    tcFileSystem
  )
  fileWriteTool.parameters = @[
    newParameterDef("path", ptString, "Ruta completa al archivo", required = true),
    newParameterDef("content", ptString, "Contenido a escribir", required = true),
    newParameterDef("createDirs", ptBoolean, "Crear directorios padre si no existen", required = false, defaultValue = "true")
  ]
  fileWriteTool.handler = proc(params: JsonNode): ToolResult =
    let path = params{"path"}.getStr()
    let content = params{"content"}.getStr()
    let createDirs = params{"createDirs"}.getBool()

    try:
      if createDirs:
        let dir = path.parentDir()
        if not dir.dirExists():
          createDir(dir)

      writeFile(path, content)
      return ToolResult(
        success: true,
        output: "File written successfully",
        data: %* {"path": path, "size": content.len, "lines": content.count('\n') + 1}
      )
    except IOError as e:
      return ToolResult(
        success: false,
        error: "Error writing file: " & e.msg,
        errorCode: "FILE_WRITE_ERROR"
      )
  registerTool(registry, fileWriteTool)

  # FileList
  let fileListTool = newToolDefinition(
    "FileList",
    "Lista archivos y directorios en una ruta específica",
    tcFileSystem
  )
  fileListTool.parameters = @[
    newParameterDef("path", ptString, "Ruta del directorio", required = true),
    newParameterDef("pattern", ptString, "Patrón glob para filtrar archivos", required = false),
    newParameterDef("recursive", ptBoolean, "Incluir subdirectorios", required = false, defaultValue = "false")
  ]
  fileListTool.handler = proc(params: JsonNode): ToolResult =
    let path = params{"path"}.getStr()
    let pattern = params{"pattern"}.getStr(".*")
    let recursive = params{"recursive"}.getBool()

    try:
      var files: seq[string] = @[]

      if recursive:
        for filePath in walkDirRec(path):
          if filePath.extractFilename.match(re(pattern)):
            files.add(filePath)
      else:
        for kind, filePath in walkDir(path):
          if filePath.extractFilename.match(re(pattern)):
            files.add(filePath)

      return ToolResult(
        success: true,
        output: $files.len & " files found",
        data: %* {"files": files, "count": files.len, "path": path}
      )
    except IOError as e:
      return ToolResult(
        success: false,
        error: "Error listing files: " & e.msg,
        errorCode: "FILE_LIST_ERROR"
      )
  registerTool(registry, fileListTool)

  # FileDelete
  let fileDeleteTool = newToolDefinition(
    "FileDelete",
    "Elimina un archivo o directorio",
    tcFileSystem
  )
  fileDeleteTool.parameters = @[
    newParameterDef("path", ptString, "Ruta del archivo o directorio", required = true),
    newParameterDef("recursive", ptBoolean, "Eliminar directorios recursivamente", required = false, defaultValue = "false")
  ]
  fileDeleteTool.handler = proc(params: JsonNode): ToolResult =
    let path = params{"path"}.getStr()
    let recursive = params{"recursive"}.getBool()

    try:
      if path.fileExists():
        removeFile(path)
        return ToolResult(
          success: true,
          output: "File deleted: " & path
        )
      elif path.dirExists():
        if recursive:
          removeDir(path)
          return ToolResult(
            success: true,
            output: "Directory deleted: " & path
          )
        else:
          return ToolResult(
            success: false,
            error: "Directory not empty. Use recursive=true",
            errorCode: "DIRECTORY_NOT_EMPTY"
          )
      else:
        return ToolResult(
          success: false,
          error: "Path does not exist: " & path,
          errorCode: "PATH_NOT_FOUND"
        )
    except IOError as e:
      return ToolResult(
        success: false,
        error: "Error deleting: " & e.msg,
        errorCode: "DELETE_ERROR"
      )
  registerTool(registry, fileDeleteTool)

  # FileExists
  let fileExistsTool = newToolDefinition(
    "FileExists",
    "Verifica si un archivo o directorio existe",
    tcFileSystem
  )
  fileExistsTool.parameters = @[
    newParameterDef("path", ptString, "Ruta a verificar", required = true)
  ]
  fileExistsTool.handler = proc(params: JsonNode): ToolResult =
    let path = params{"path"}.getStr()
    let fileExists = path.fileExists()
    let dirExists = path.dirExists()

    return ToolResult(
      success: true,
      output: if fileExists: "File exists" elif dirExists: "Directory exists" else: "Path does not exist",
      data: %* {"path": path, "exists": fileExists or dirExists, "isFile": fileExists, "isDir": dirExists}
    )
  registerTool(registry, fileExistsTool)

# ============================================================================
# Herramientas de Ejecución de Comandos Shell
# ============================================================================

proc registerShellTools*(registry: var ToolRegistry) =

  # ShellExecute
  let shellTool = newToolDefinition(
    "ShellExecute",
    "Ejecuta un comando en el shell del sistema operativo",
    tcSystem
  )
  shellTool.parameters = @[
    newParameterDef("command", ptString, "Comando a ejecutar", required = true),
    newParameterDef("workingDir", ptString, "Directorio de trabajo", required = false),
    newParameterDef("timeout", ptInteger, "Timeout en segundos", required = false, defaultValue = "30"),
    newParameterDef("env", ptObject, "Variables de entorno adicionales", required = false)
  ]
  shellTool.permissions = newToolPermission(maxRequestsPerHour = 100)
  shellTool.handler = proc(params: JsonNode): ToolResult =
    let command    = params{"command"}.getStr()
    let workingDir = params{"workingDir"}.getStr("")

    # -----------------------------------------------------------------------
    # Sandboxing básico: bloquear comandos peligrosos
    # -----------------------------------------------------------------------
    const BLOCKED_PATTERNS = [
      "rm -rf /", "rm -rf ~", "mkfs", "dd if=", ":(){ :|:& };",
      "> /dev/sda", "chmod 777 /", "chown -R root /",
      "curl | bash", "wget | bash", "curl | sh", "wget | sh"
    ]
    let cmdLower = command.toLower()
    for blocked in BLOCKED_PATTERNS:
      if cmdLower.contains(blocked.toLower()):
        return ToolResult(
          success:   false,
          error:     "Comando bloqueado por política de seguridad: " & blocked,
          errorCode: "SHELL_BLOCKED"
        )

    if command.len == 0:
      return ToolResult(success: false, error: "Comando vacío", errorCode: "INVALID_PARAMS")

    try:
      let (output, exitCode) = execCmdEx(
        command,
        workingDir = if workingDir.len > 0: workingDir else: ""
      )
      return ToolResult(
        success: exitCode == 0,
        output:  output,
        data:    %* {
          "exitCode":    exitCode,
          "command":     command,
          "workingDir":  workingDir,
          "outputLength":output.len
        }
      )
    except Exception as e:
      return ToolResult(
        success:   false,
        error:     "Shell execution failed: " & e.msg,
        errorCode: "SHELL_ERROR"
      )
  registerTool(registry, shellTool)

  # ProcessSpawn
  let processTool = newToolDefinition(
    "ProcessSpawn",
    "Inicia un nuevo proceso y devuelve su PID",
    tcSystem
  )
  processTool.parameters = @[
    newParameterDef("command", ptString, "Comando a ejecutar", required = true),
    newParameterDef("args", ptArray, "Argumentos del comando", required = false),
    newParameterDef("detached", ptBoolean, "Ejecutar en background (detach)", required = false, defaultValue = "false")
  ]
  processTool.permissions = newToolPermission(maxRequestsPerHour = 50)
  processTool.handler = proc(params: JsonNode): ToolResult =
    let command = params{"command"}.getStr()
    let detached = params{"detached"}.getBool()

    try:
      when defined(windows):
        let pid = execCmd("start /b " & command)
        return ToolResult(
          success: true,
          output: "Process started",
          data: %* {"pid": pid, "command": command}
        )
      else:
        if detached:
          discard execCmd("nohup " & command & " > /dev/null 2>&1 &")
          return ToolResult(
            success: true,
            output: "Process started in background",
            data: %* {"command": command, "detached": true}
          )
        else:
          let (output, exitCode) = execCmdEx(command)
          return ToolResult(
            success: exitCode == 0,
            output: output,
            data: %* {"exitCode": exitCode, "command": command}
          )
    except Exception as e:
      return ToolResult(
        success: false,
        error: "Process spawn failed: " & e.msg,
        errorCode: "PROCESS_ERROR"
      )
  registerTool(registry, processTool)

# ============================================================================
# Herramientas de Comunicación de Red
# ============================================================================

proc registerNetworkTools*(registry: var ToolRegistry) =
  var httpClient = newHttpClient()

  # HttpRequest
  let httpTool = newToolDefinition(
    "HttpRequest",
    "Realiza solicitudes HTTP a APIs y endpoints web",
    tcNetwork
  )
  httpTool.parameters = @[
    newParameterDef("url", ptString, "URL del endpoint", required = true),
    newParameterDef("method", ptString, "Método HTTP (GET, POST, PUT, DELETE)", required = false, defaultValue = "GET"),
    newParameterDef("headers", ptObject, "Headers HTTP personalizados", required = false),
    newParameterDef("body", ptString, "Cuerpo de la solicitud (para POST/PUT)", required = false),
    newParameterDef("timeout", ptInteger, "Timeout en milisegundos", required = false, defaultValue = "30000")
  ]
  httpTool.handler = proc(params: JsonNode): ToolResult =
    let url = params{"url"}.getStr()
    let httpMethodStr = params{"method"}.getStr("GET").toUpper()
    let body = params{"body"}.getStr("")
    let timeoutMs = params{"timeout"}.getInt(30000)

    httpClient.timeout = timeoutMs

    try:
      var headers = newHttpHeaders()
      if params.hasKey("headers") and params{"headers"}.kind == JObject:
        for key, val in params{"headers"}:
          headers[key] = val.getStr()

      var response: Response
      case httpMethodStr
      of "GET":
        response = httpClient.request(url, httpMethod = HttpGet, headers = headers)
      of "POST":
        response = httpClient.request(url, httpMethod = HttpPost, body = body, headers = headers)
      of "PUT":
        response = httpClient.request(url, httpMethod = HttpPut, body = body, headers = headers)
      of "DELETE":
        response = httpClient.request(url, httpMethod = HttpDelete, headers = headers)
      else:
        return ToolResult(
          success: false,
          error: "Unsupported HTTP method: " & httpMethodStr,
          errorCode: "INVALID_METHOD"
        )

      return ToolResult(
        success: response.status.startsWith("2"),
        output: response.body,
        data: %* {
          "status": response.status,
          "statusCode": parseInt(response.status.split(' ')[0]),
          "headers": response.headers.table,
          "bodyLength": response.body.len
        }
      )
    except HttpRequestError as e:
      return ToolResult(
        success: false,
        error: "HTTP request failed: " & e.msg,
        errorCode: "HTTP_ERROR"
      )
    except Exception as e:
      return ToolResult(
        success: false,
        error: "Network error: " & e.msg,
        errorCode: "NETWORK_ERROR"
      )
  registerTool(registry, httpTool)

# ============================================================================
# Herramientas de Análisis de Código
# ============================================================================

proc registerCodeAnalysisTools*(registry: var ToolRegistry) =

  # CodeAnalyze
  let codeAnalyzeTool = newToolDefinition(
    "CodeAnalyze",
    "Analiza código fuente para detectar patrones, errores potenciales y métricas",
    tcCode
  )
  codeAnalyzeTool.parameters = @[
    newParameterDef("code", ptString, "Código fuente a analizar", required = true),
    newParameterDef("language", ptString, "Lenguaje de programación", required = false),
    newParameterDef("checkTypes", ptArray, "Tipos de análisis a realizar", required = false)
  ]
  codeAnalyzeTool.handler = proc(params: JsonNode): ToolResult =
    let code = params{"code"}.getStr()
    let language = params{"language"}.getStr("unknown")

    # Basic code metrics
    let lines = code.split('\n')
    let nonEmptyLines = lines.filterIt(it.strip().len > 0)
    let totalChars = code.len
    let commentLines = lines.filterIt(it.strip().startsWith("#") or it.strip().startsWith("//"))

    # Detect potential issues (simplified)
    var issues: seq[string] = @[]

    if code.contains("TODO"):
      issues.add("Contains TODO comments")
    if code.contains("FIXME"):
      issues.add("Contains FIXME comments")
    if code.contains("print(") and not code.contains("log"):
      issues.add("Contains print statements (should use logging)")
    if code.len > 10000:
      issues.add("File exceeds 10000 characters, consider splitting")

    # Complexity estimation (very simplified)
    let ifCount = code.count("if ")
    let forCount = code.count("for ")
    let whileCount = code.count("while ")
    let complexity = ifCount + forCount * 2 + whileCount * 2

    return ToolResult(
      success: true,
      output: "Code analysis complete",
      data: %* {
        "language": language,
        "totalLines": lines.len,
        "nonEmptyLines": nonEmptyLines.len,
        "commentLines": commentLines.len,
        "totalChars": totalChars,
        "issues": issues,
        "estimatedComplexity": complexity,
        "hasTodo": code.contains("TODO"),
        "hasFixme": code.contains("FIXME")
      }
    )
  registerTool(registry, codeAnalyzeTool)

  # CodeFormat
  let codeFormatTool = newToolDefinition(
    "CodeFormat",
    "Formatea código fuente según convenciones del lenguaje",
    tcCode
  )
  codeFormatTool.parameters = @[
    newParameterDef("code", ptString, "Código a formatear", required = true),
    newParameterDef("language", ptString, "Lenguaje de programación", required = true),
    newParameterDef("style", ptString, "Estilo de formato (standard, compact, pretty)", required = false, defaultValue = "standard")
  ]
  codeFormatTool.handler = proc(params: JsonNode): ToolResult =
    let code = params{"code"}.getStr()
    let language = params{"language"}.getStr()
    let style = params{"style"}.getStr("standard")

    # Basic formatting (in production, use proper formatters)
    var formatted = code

    # Remove trailing whitespace
    formatted = formatted.split('\n').mapIt(it.strip()).join("\n")

    # Normalize line endings
    formatted = formatted.replace("\r\n", "\n")

    # Add proper indentation (simplified)
    var lines = formatted.split('\n')
    var indented: seq[string] = @[]
    var indentLevel = 0

    for line in lines:
      if line.strip().startsWith("}") or line.strip().startsWith("end"):
        indentLevel = max(0, indentLevel - 1)
      indented.add("  ".repeat(indentLevel) & line.strip())
      if line.contains("{") and not line.contains("}"):
        indentLevel += 1

    formatted = indented.join("\n")

    return ToolResult(
      success: true,
      output: formatted,
      data: %* {
        "originalLength": code.len,
        "formattedLength": formatted.len,
        "language": language,
        "style": style,
        "linesChanged": code.split('\n').len != formatted.split('\n').len
      }
    )
  registerTool(registry, codeFormatTool)

# ============================================================================
# Serialización y Persistencia del Registry
# ============================================================================

proc toJson*(registry: ToolRegistry): JsonNode =
  var toolsArray: seq[JsonNode] = @[]

  for name, tool in registry.tools:
    var paramsArray: seq[JsonNode] = @[]
    for param in tool.parameters:
      paramsArray.add(%* {
        "name": param.name,
        "type": $param.paramType,
        "description": param.description,
        "required": param.required,
        "defaultValue": param.defaultValue,
        "validation": param.validation
      })

    toolsArray.add(%* {
      "name": tool.name,
      "description": tool.description,
      "category": $tool.category,
      "parameters": paramsArray,
      "metadata": tool.metadata
    })

  var agentPerms: JsonNode = newJObject()
  for agent, tools in registry.agentPermissions:
    agentPerms[agent] = %tools

  return %* {
    "tools": toolsArray,
    "agentPermissions": agentPerms,
    "toolCount": registry.tools.len,
    "categoryCount": registry.categories.len
  }

proc fromJson*(json: JsonNode): ToolRegistry =
  result = initToolRegistry()

  for toolNode in json{"tools"}:
    let tool = newToolDefinition(
      toolNode{"name"}.getStr(),
      toolNode{"description"}.getStr(),
      parseEnum[ToolCategory](toolNode{"category"}.getStr())
    )

    for paramNode in toolNode{"parameters"}:
      let param = newParameterDef(
        paramNode{"name"}.getStr(),
        parseEnum[ParameterType](paramNode{"type"}.getStr()),
        paramNode{"description"}.getStr(),
        paramNode{"required"}.getBool(),
        paramNode{"defaultValue"}.getStr(),
        paramNode{"validation"}.getStr()
      )
      tool.parameters.add(param)

    registerTool(result, tool)

  # Note: handlers cannot be restored from JSON
  echo "Warning: Tool handlers were not restored from JSON (need to re-register)"

proc saveRegistry*(registry: ToolRegistry, path: string) =
  let json = toJson(registry)
  writeFile(path, json.pretty())

proc loadRegistry*(path: string): ToolRegistry =
  let content = readFile(path)
  let json = parseJson(content)
  return fromJson(json)

# ============================================================================
# Utilidades de Descubrimiento
# ============================================================================

proc findToolsByCapability*(registry: ToolRegistry, capability: string): seq[ToolDefinition] =
  let lowerCap = capability.toLower()
  for name, tool in registry.tools:
    if tool.description.toLower().contains(lowerCap):
      result.add(tool)
    elif tool.name.toLower().contains(lowerCap):
      result.add(tool)
    for key, val in tool.metadata:
      if key.toLower().contains(lowerCap) or val.toLower().contains(lowerCap):
        result.add(tool)
        break

proc getToolCategories*(registry: ToolRegistry): seq[ToolCategory] =
  return @[tcFileSystem, tcNetwork, tcDatabase, tcCode, tcAI, tcSystem, tcCustom]

proc getToolInfo*(registry: ToolRegistry, toolName: string): string =
  let tool = registry.getTool(toolName)
  if tool == nil:
    return "Tool not found: " & toolName

  var info = "Tool: " & tool.name & "\n"
  info &= "Description: " & tool.description & "\n"
  info &= "Category: " & $tool.category & "\n"
  info &= "Parameters:\n"
  for param in tool.parameters:
    let reqStr = if param.required: " (required)" else: " (optional)"
    info &= "  - " & param.name & ": " & $param.paramType & reqStr & "\n"
    info &= "    " & param.description & "\n"

  return info

proc printRegistryStats*(registry: ToolRegistry) =
  echo "=== Tool Registry Statistics ==="
  echo "Total tools: ", registry.tools.len
  echo ""

  for category in [tcFileSystem, tcNetwork, tcDatabase, tcCode, tcAI, tcSystem, tcCustom]:
    if registry.categories.hasKey(category):
      let count = registry.categories[category].len
      echo "  ", $category, ": ", count, " tools"

  echo ""
  echo "Agent permissions: ", registry.agentPermissions.len
  for agent, tools in registry.agentPermissions:
    echo "  ", agent, ": ", tools.len, " tools"

# ============================================================================
# Export
# ============================================================================

export ParameterType, ParameterDef, ToolCategory, ToolPermission, ToolCapability
export ToolDefinition, ToolResult, ToolExecutionContext, ToolRegistry
export newParameterDef, newToolPermission, newToolDefinition
export initToolRegistry, registerTool, getTool, getToolsByCategory, searchTools, getAllTools
export grantToolPermission, revokeToolPermission, canAgentUseTool, setAgentTools, getAgentTools
export validateToolParameters, executeTool
export registerFileSystemTools, registerShellTools, registerNetworkTools, registerCodeAnalysisTools
export toJson, fromJson, saveRegistry, loadRegistry
export findToolsByCapability, getToolCategories, getToolInfo, printRegistryStats

# ============================================================================
# Additional Tool Registrations
# ============================================================================

import llm_integration

proc registerLLMTools*(registry: var ToolRegistry, llmConfig: ModelConfig) =
  let chatTool = newToolDefinition(
    "LLMChat",
    "Envía un prompt a un modelo de lenguaje",
    tcAI
  )
  chatTool.parameters = @[
    newParameterDef("prompt", ptString, "Texto de entrada", true),
    newParameterDef("system", ptString, "Prompt de sistema", false),
    newParameterDef("temperature", ptFloat, "0-1", false, "0.7")
  ]
  chatTool.handler = proc(params: JsonNode): ToolResult =
    let prompt = params{"prompt"}.getStr()
    let system = params{"system"}.getStr("")
    let temp = params{"temperature"}.getFloat(0.7)
    let req = LLMRequest(prompt: prompt, systemPrompt: system, temperature: temp)
    try:
      let resp = callLLM(llmConfig, req)
      return ToolResult(success: true, output: resp.content, data: %* {"tokens": resp.tokensUsed})
    except Exception as e:
      return ToolResult(success: false, error: e.msg)
  registerTool(registry, chatTool)

# DatabaseQuery: compilación condicional con flag -d:ceoEnableSqliteTools
# Para activar: nim c -d:ceoEnableSqliteTools ...
# Requiere: nimble install db_connector

when defined(ceoEnableSqliteTools):
  import db_connector/db_sqlite

  proc registerDatabaseTools*(registry: var ToolRegistry) =
    ## Registra la herramienta DatabaseQuery (requiere db_connector).
    let dbTool = newToolDefinition(
      "DatabaseQuery",
      "Ejecuta una consulta SQL en SQLite",
      tcDatabase
    )
    dbTool.parameters = @[
      newParameterDef("dbPath",  ptString, "Ruta del archivo .db",  true),
      newParameterDef("query",   ptString, "SQL query",              true),
      newParameterDef("params",  ptArray,  "Parámetros (opcional)",  false)
    ]
    dbTool.handler = proc(params: JsonNode): ToolResult =
      let dbPath = params{"dbPath"}.getStr()
      let query  = params{"query"}.getStr()
      if dbPath.len == 0 or query.len == 0:
        return ToolResult(success: false, error: "dbPath y query son requeridos", errorCode: "INVALID_PARAMS")
      var db: DbConn
      try:
        db = open(dbPath, "", "", "")
        let rows = db.getAllRows(sql(query))
        return ToolResult(
          success: true,
          output:  "Query OK, " & $rows.len & " rows",
          data:    %* rows
        )
      except DbError as e:
        return ToolResult(success: false, error: e.msg, errorCode: "DB_ERROR")
      finally:
        if db != nil: db.close()
    registerTool(registry, dbTool)

else:
  proc registerDatabaseTools*(registry: var ToolRegistry) =
    ## Stub: DatabaseQuery deshabilitada. Compila con -d:ceoEnableSqliteTools para activar.
    let dbTool = newToolDefinition(
      "DatabaseQuery",
      "[DESHABILITADA] Requiere compilación con -d:ceoEnableSqliteTools",
      tcDatabase
    )
    dbTool.handler = proc(params: JsonNode): ToolResult =
      ToolResult(
        success:   false,
        error:     "DatabaseQuery no está disponible. Recompila con -d:ceoEnableSqliteTools",
        errorCode: "TOOL_DISABLED"
      )
    registerTool(registry, dbTool)

export registerDatabaseTools, registerLLMTools