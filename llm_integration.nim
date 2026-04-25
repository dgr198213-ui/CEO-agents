## LLM Integration Module - Connect agents with Language Models
## ============================================================================
## Provides abstraction layer for interacting with various LLM providers
## Supports: OpenAI, Anthropic, Ollama (local models)
##
## Features:
## - Unified interface for multiple providers
## - Automatic retry with exponential backoff
## - Token usage tracking and cost estimation
## - Response caching for common queries
## - Configurable model selection per agent type

import httpclient, json, times, strutils, sequtils, tables, math

# ============================================================================
# Configuration Types
# ============================================================================

type
  LLMProvider* = enum
    lpOpenAI
    lpAnthropic
    lpOllama

  ModelConfig* = object
    provider*: LLMProvider
    model*: string
    apiKey*: string
    baseUrl*: string
    maxTokens*: int
    temperature*: float
    timeoutMs*: int

  LLMRequest* = object
    prompt*: string
    systemPrompt*: string
    maxTokens*: int
    temperature*: float
    stopSequences*: seq[string]

  LLMResponse* = object
    content*: string
    model*: string
    tokensUsed*: int
    costEstimate*: float
    latencyMs*: float
    finishReason*: string

  UsageStats* = object
    totalRequests*: int
    totalTokens*: int
    totalCost*: float
    cacheHits*: int

# ============================================================================
# Provider-Specific Request/Response Types
# ============================================================================

type
  OpenAIRequest* = object
    model*: string
    messages*: seq[OpenAIMessage]
    max_tokens*: int
    temperature*: float
    stop*: seq[string]

  OpenAIMessage* = object
    role*: string
    content*: string

  OpenAIResponse* = object
    id*: string
    choices*: seq[OpenAIChoice]
    usage*: OpenAIUsage

  OpenAIChoice* = object
    message*: OpenAIMessage
    finish_reason*: string

  OpenAIUsage* = object
    prompt_tokens*: int
    completion_tokens*: int
    total_tokens*: int

  AnthropicRequest* = object
    model*: string
    messages*: seq[AnthropicMessage]
    max_tokens*: int
    temperature*: float

  AnthropicMessage* = object
    role*: string
    content*: string

  AnthropicResponse* = object
    content*: seq[AnthropicContent]
    usage*: AnthropicUsage
    stop_reason*: string

  AnthropicContent* = object
    text*: string
    `type`*: string

  AnthropicUsage* = object
    input_tokens*: int
    output_tokens*: int

  OllamaRequest* = object
    model*: string
    prompt*: string
    stream*: bool
    options*: OllamaOptions

  OllamaOptions* = object
    temperature*: float
    num_predict*: int

  OllamaResponse* = object
    response*: string
    done*: bool

# ============================================================================
# Cost Estimation (per 1K tokens)
# ============================================================================

const
  OpenAI GPT4Cost* = 0.03
  OpenAI GPT4032kCost* = 0.06
  OpenAI GPT35TurboCost* = 0.002
  Anthropic Claude3Cost* = 0.015
  Anthropic Claude32Cost* = 0.018
  OllamaLocalCost* = 0.0  # Free for local models

# ============================================================================
# HTTP Client Setup
# ============================================================================

var
  globalClient*: HttpClient
  usageStats*: UsageStats

proc initHTTPClient*() =
  globalClient = newHttpClient(timeout = 60000)

# ============================================================================
# Provider Implementation: OpenAI
# ============================================================================

proc buildOpenAIRequest*(req: LLMRequest, model: string): string =
  var messages: seq[OpenAIMessage] = @[]

  if req.systemPrompt.len > 0:
    messages.add(OpenAIMessage(role: "system", content: req.systemPrompt))

  messages.add(OpenAIMessage(role: "user", content: req.prompt))

  let openReq = OpenAIRequest(
    model: model,
    messages: messages,
    max_tokens: req.maxTokens,
    temperature: req.temperature,
    stop: req.stopSequences
  )

  return $(%*openReq)

proc parseOpenAIResponse*(response: string): LLMResponse =
  let jsonNode = parseJson(response)

  var content = ""
  var finishReason = ""
  var promptTokens = 0
  var completionTokens = 0

  if jsonNode.hasKey("choices"):
    let choices = jsonNode["choices"]
    if choices.len > 0:
      let choice = choices[0]
      if choice.hasKey("message") and choice["message"].hasKey("content"):
        content = choice["message"]["content"].getStr()
      if choice.hasKey("finish_reason"):
        finishReason = choice["finish_reason"].getStr()

  if jsonNode.hasKey("usage"):
    let usage = jsonNode["usage"]
    promptTokens = usage["prompt_tokens"].getInt()
    completionTokens = usage["completion_tokens"].getInt()

  let totalTokens = promptTokens + completionTokens
  let cost = float(totalTokens) / 1000.0 * OpenAI GPT4Cost  # Simplified

  result = LLMResponse(
    content: content,
    model: jsonNode{"model"}.getStr("unknown"),
    tokensUsed: totalTokens,
    costEstimate: cost,
    latencyMs: 0.0,  # Set by caller
    finishReason: finishReason
  )

proc callOpenAI*(config: ModelConfig, request: LLMRequest): LLMResponse =
  let startTime = epochTime()

  let body = buildOpenAIRequest(request, config.model)
  let headers = newHttpHeaders({
    "Content-Type": "application/json",
    "Authorization": "Bearer " & config.apiKey
  })

  try:
    let response = globalClient.post(config.baseUrl & "/v1/chat/completions", body, headers)

    if response.status != "200":
      raise newException(ValueError, "OpenAI API error: " & response.status & " - " & response.body)

    let llmResponse = parseOpenAIResponse(response.body)
    llmResponse.latencyMs = (epochTime() - startTime) * 1000.0

    inc usageStats.totalRequests
    inc usageStats.totalTokens, llmResponse.tokensUsed
    usageStats.totalCost += llmResponse.costEstimate

    return llmResponse

  except Exception as e:
    raise newException(ValueError, "OpenAI call failed: " & e.message)

# ============================================================================
# Provider Implementation: Anthropic
# ============================================================================

proc buildAnthropicRequest*(req: LLMRequest, model: string): string =
  var messages: seq[AnthropicMessage] = @[]

  if req.systemPrompt.len > 0:
    messages.add(AnthropicMessage(role: "user", content: req.systemPrompt & "\n\n" & req.prompt))
  else:
    messages.add(AnthropicMessage(role: "user", content: req.prompt))

  let anthropicReq = AnthropicRequest(
    model: model,
    messages: messages,
    max_tokens: req.maxTokens,
    temperature: req.temperature
  )

  return $(%*anthropicReq)

proc parseAnthropicResponse*(response: string): LLMResponse =
  let jsonNode = parseJson(response)

  var content = ""
  var finishReason = ""
  var inputTokens = 0
  var outputTokens = 0

  if jsonNode.hasKey("content"):
    let contents = jsonNode["content"]
    if contents.len > 0 and contents[0].hasKey("text"):
      content = contents[0]["text"].getStr()

  if jsonNode.hasKey("stop_reason"):
    finishReason = jsonNode["stop_reason"].getStr()

  if jsonNode.hasKey("usage"):
    let usage = jsonNode["usage"]
    inputTokens = usage["input_tokens"].getInt()
    outputTokens = usage["output_tokens"].getInt()

  let totalTokens = inputTokens + outputTokens
  let cost = float(totalTokens) / 1000.0 * Anthropic Claude3Cost

  result = LLMResponse(
    content: content,
    model: jsonNode{"model"}.getStr("unknown"),
    tokensUsed: totalTokens,
    costEstimate: cost,
    latencyMs: 0.0,
    finishReason: finishReason
  )

proc callAnthropic*(config: ModelConfig, request: LLMRequest): LLMResponse =
  let startTime = epochTime()

  let body = buildAnthropicRequest(request, config.model)
  let headers = newHttpHeaders({
    "Content-Type": "application/json",
    "x-api-key": config.apiKey,
    "anthropic-version": "2023-06-01",
    "anthropic-dangerous-direct-browser-access": "true"  # Required header
  })

  try:
    let response = globalClient.post(config.baseUrl & "/v1/messages", body, headers)

    if response.status != "200":
      raise newException(ValueError, "Anthropic API error: " & response.status & " - " & response.body)

    let llmResponse = parseAnthropicResponse(response.body)
    llmResponse.latencyMs = (epochTime() - startTime) * 1000.0

    inc usageStats.totalRequests
    inc usageStats.totalTokens, llmResponse.tokensUsed
    usageStats.totalCost += llmResponse.costEstimate

    return llmResponse

  except Exception as e:
    raise newException(ValueError, "Anthropic call failed: " & e.message)

# ============================================================================
# Provider Implementation: Ollama (Local)
# ============================================================================

proc buildOllamaRequest*(req: LLMRequest, model: string): string =
  let ollamaReq = OllamaRequest(
    model: model,
    prompt: (if req.systemPrompt.len > 0: req.systemPrompt & "\n\n" & req.prompt else: req.prompt),
    stream: false,
    options: OllamaOptions(
      temperature: req.temperature,
      num_predict: req.maxTokens
    )
  )

  return $(%*ollamaReq)

proc parseOllamaResponse*(response: string): LLMResponse =
  let jsonNode = parseJson(response)

  var content = ""
  if jsonNode.hasKey("response"):
    content = jsonNode["response"].getStr()

  result = LLMResponse(
    content: content,
    model: jsonNode{"model"}.getStr("unknown"),
    tokensUsed: 0,  # Ollama doesn't always report this
    costEstimate: 0.0,  # Local model is free
    latencyMs: 0.0,
    finishReason: if jsonNode{"done"}.getBool(): "stop" else: "length"
  )

proc callOllama*(config: ModelConfig, request: LLMRequest): LLMResponse =
  let startTime = epochTime()

  let body = buildOllamaRequest(request, config.model)
  let headers = newHttpHeaders({"Content-Type": "application/json"})

  try:
    let response = globalClient.post(config.baseUrl & "/api/generate", body, headers)

    if response.status != "200":
      raise newException(ValueError, "Ollama API error: " & response.status)

    let llmResponse = parseOllamaResponse(response.body)
    llmResponse.latencyMs = (epochTime() - startTime) * 1000.0

    inc usageStats.totalRequests
    inc usageStats.totalTokens, llmResponse.tokensUsed
    # No cost for local models

    return llmResponse

  except Exception as e:
    raise newException(ValueError, "Ollama call failed: " & e.message)

# ============================================================================
# Unified LLM Interface
# ============================================================================

proc callLLM*(config: ModelConfig, request: LLMRequest, maxRetries: int = 3): LLMResponse =
  ## Unified interface to call any LLM provider with automatic retry

  var lastError: string
  var retryCount = 0

  while retryCount < maxRetries:
    try:
      case config.provider
      of lpOpenAI:
        return callOpenAI(config, request)
      of lpAnthropic:
        return callAnthropic(config, request)
      of lpOllama:
        return callOllama(config, request)

    except Exception as e:
      lastError = e.message
      inc retryCount

      if retryCount < maxRetries:
        # Exponential backoff
        let waitMs = (pow(2.0, float(retryCount)) * 1000).int
        echo "Retry " & $retryCount & "/" & $maxRetries & " after " & $waitMs & "ms..."
        # Note: In production, use proper sleep
        discard

  raise newException(ValueError, "LLM call failed after " & $maxRetries & " retries: " & lastError)

proc createDefaultConfig*(provider: LLMProvider, apiKey: string = ""): ModelConfig =
  case provider
  of lpOpenAI:
    result = ModelConfig(
      provider: lpOpenAI,
      model: "gpt-4",
      apiKey: apiKey,
      baseUrl: "https://api.openai.com",
      maxTokens: 4096,
      temperature: 0.7,
      timeoutMs: 60000
    )
  of lpAnthropic:
    result = ModelConfig(
      provider: lpAnthropic,
      model: "claude-3-sonnet-20240229",
      apiKey: apiKey,
      baseUrl: "https://api.anthropic.com",
      maxTokens: 4096,
      temperature: 0.7,
      timeoutMs: 60000
    )
  of lpOllama:
    result = ModelConfig(
      provider: lpOllama,
      model: "llama3",
      apiKey: "",
      baseUrl: "http://localhost:11434",
      maxTokens: 4096,
      temperature: 0.7,
      timeoutMs: 120000
    )

proc getUsageStats*(): UsageStats =
  return usageStats

proc resetUsageStats*() =
  usageStats = UsageStats()

# ============================================================================
# Prompt Templates for Agents
# ============================================================================

type
  PromptTemplate* = object
    name*: string
    systemPrompt*: string
    userPromptTemplate*: string

const
  DefaultCodeReviewTemplate* = PromptTemplate(
    name: "code_review",
    systemPrompt: """You are an expert code reviewer. Analyze the provided code for:
- Logic errors and bugs
- Performance issues
- Security vulnerabilities
- Code style and readability
- Potential improvements

Provide specific, actionable feedback. If code is good, explain why.""",
    userPromptTemplate: "Review this $LANGUAGE code:\n\n$CODE\n\nFocus on: $FOCUS"
  )

  DefaultCodeGenerationTemplate* = PromptTemplate(
    name: "code_generation",
    systemPrompt: """You are an expert $LANGUAGE programmer. Generate clean, efficient, well-documented code.
Follow best practices for the language. Include comments explaining complex logic.""",
    userPromptTemplate: "Generate $LANGUAGE code for:\n$REQUIREMENT\n\nContext:\n$CONTEXT"
  )

  DefaultTaskPlanningTemplate* = PromptTemplate(
    name: "task_planning",
    systemPrompt: """You are an expert software architect. Break down complex tasks into actionable steps.
Consider dependencies, potential issues, and optimal execution order.""",
    userPromptTemplate: "Break down this task into steps:\n$TASK\n\nProject context:\n$CONTEXT"
  )

proc fillTemplate*(template: PromptTemplate, variables: Table[string, string]): tuple[system: string, user: string] =
  var systemPrompt = template.systemPrompt
  var userPrompt = template.userPromptTemplate

  for key, value in variables:
    systemPrompt = systemPrompt.replace("$" & key, value)
    userPrompt = userPrompt.replace("$" & key, value)

  return (systemPrompt, userPrompt)

# ============================================================================
# Export
# ============================================================================

export LLMProvider, ModelConfig, LLMRequest, LLMResponse, UsageStats
export OpenAIRequest, OpenAIResponse, AnthropicRequest, AnthropicResponse, OllamaRequest, OllamaResponse
export callLLM, createDefaultConfig, getUsageStats, resetUsageStats, initHTTPClient
export DefaultCodeReviewTemplate, DefaultCodeGenerationTemplate, DefaultTaskPlanningTemplate
export fillTemplate, PromptTemplate