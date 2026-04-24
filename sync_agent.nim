## ═══════════════════════════════════════════════════════════════════════════
## SyncAgent - Agente Evolutivo de Sincronización Offline-Online
## ═══════════════════════════════════════════════════════════════════════════
## Inspirado en Background Sync API e IndexedDB de PWAs.
## Evoluciona estrategias óptimas de sincronización considerando:
## - Resolución de conflictos (Last-Write-Wins, Merge, Custom)
## - Priorización de operaciones pendientes
## - Políticas de retry con backoff exponencial
## - Detección y manejo de conflictos de escritura
## - Optimización de ancho de banda y batería
##
## Referencias científicas:
## - Background Sync API (W3C) - https://wicg.github.io/background-sync/spec/
## - IndexedDB API (W3C) - https://www.w3.org/TR/IndexedDB/
## - "Offline First" principles - https://offlinefirst.org/
## - CRDTs (Conflict-free Replicated Data Types) - Shapiro et al. 2011
## ═══════════════════════════════════════════════════════════════════════════

import agent_base, evolution_core
import std/[random, math, sequtils, tables, strformat, algorithm, hashes]

## ───────────────────────────────────────────────────────────────────────────
## Tipos de Operaciones
## ───────────────────────────────────────────────────────────────────────────

type
  OperationType* = enum
    opCreate    ## Crear nuevo registro
    opUpdate    ## Actualizar registro existente
    opDelete    ## Eliminar registro
    opRead      ## Lectura (no sincronizable, solo para stats)

  ConflictResolution* = enum
    crLastWriteWins      ## El más reciente gana (simple)
    crFirstWriteWins     ## El primero gana (conservador)
    crMerge              ## Merge inteligente de campos
    crUserDecision       ## Requiere intervención del usuario
    crServerWins         ## Servidor siempre gana
    crClientWins         ## Cliente siempre gana

  SyncPriority* = enum
    spLow       ## Sincronización diferida (cuando hay WiFi)
    spMedium    ## Sincronización normal
    spHigh      ## Sincronización prioritaria
    spCritical  ## Sincronización inmediata

## ───────────────────────────────────────────────────────────────────────────
## Data Record
## ───────────────────────────────────────────────────────────────────────────

type
  DataRecord* = object
    id*: int
    entityType*: string         ## Tipo de entidad (user, post, comment, etc)
    version*: int               ## Versión del registro
    timestamp*: float           ## Timestamp de última modificación
    clientId*: int              ## ID del cliente que lo modificó
    data*: Table[string, string] ## Datos (simulado como clave-valor)
    checksum*: int              ## Hash de los datos para detección de conflictos

proc hash*(r: DataRecord): Hash =
  ## Calcula hash del contenido para detección de conflictos
  result = r.id.hash !& r.version.hash !& r.timestamp.hash
  for k, v in r.data.pairs:
    result = result !& k.hash !& v.hash
  result = !$result

## ───────────────────────────────────────────────────────────────────────────
## Sync Operation (operación pendiente)
## ───────────────────────────────────────────────────────────────────────────

type
  SyncOperation* = object
    id*: int
    opType*: OperationType
    record*: DataRecord
    priority*: SyncPriority
    timestamp*: float           ## Cuándo se creó la operación
    retryCount*: int            ## Número de intentos fallidos
    lastRetry*: float           ## Timestamp del último intento
    conflictDetected*: bool

## ───────────────────────────────────────────────────────────────────────────
## Genoma de Estrategia de Sincronización
## ───────────────────────────────────────────────────────────────────────────

type
  SyncGenome* = object
    ## Genoma que codifica políticas de sincronización
    # Estrategia de resolución de conflictos por tipo de operación
    conflictStrategies*: Table[OperationType, ConflictResolution]
    
    # Intervalos de sincronización por prioridad (segundos)
    syncIntervals*: Table[SyncPriority, float]
    
    # Política de retry
    maxRetries*: int
    backoffMultiplier*: float    ## Multiplicador para backoff exponencial
    initialBackoff*: float       ## Backoff inicial (segundos)
    
    # Batch size (operaciones por lote)
    batchSize*: int
    
    # Priorización automática
    autoPriorityThreshold*: float  ## Edad para auto-elevar prioridad (horas)
    
    # Conflicto tolerance
    conflictTolerance*: float    ## Tolerancia a diferencias (0.0-1.0)
    
    # Network optimization
    preferWiFi*: bool            ## Solo sincronizar en WiFi para low priority
    compressionEnabled*: bool    ## Comprimir payloads

## ───────────────────────────────────────────────────────────────────────────
## SyncAgent
## ───────────────────────────────────────────────────────────────────────────

type
  NetworkState* = enum
    nsOffline
    nsOnline3G
    nsOnline4G
    nsWiFi

  SyncAgent* = ref object of Agent
    syncGenome*: SyncGenome
    pendingOps*: seq[SyncOperation]
    serverState*: Table[int, DataRecord]   ## Estado del servidor (simulado)
    localState*: Table[int, DataRecord]    ## Estado local del cliente
    networkState*: NetworkState
    
    # Métricas
    totalSynced*: int
    totalConflicts*: int
    resolvedConflicts*: int
    failedSyncs*: int
    avgSyncLatency*: float       ## ms
    dataConsumption*: float      ## MB transferidos
    successRate*: float

## ───────────────────────────────────────────────────────────────────────────
## Constructor y Genoma Random
## ───────────────────────────────────────────────────────────────────────────

proc randomGenome*(): SyncGenome =
  ## Genera un genoma de sincronización aleatorio
  result.maxRetries = rand(3..10)
  result.backoffMultiplier = rand(1.5..3.0)
  result.initialBackoff = rand(1.0..5.0)
  result.batchSize = rand(5..50)
  result.autoPriorityThreshold = rand(1.0..24.0)  # 1-24 horas
  result.conflictTolerance = rand(0.1..0.8)
  result.preferWiFi = rand(100) < 50  # 50% probabilidad
  result.compressionEnabled = rand(100) < 70  # 70% probabilidad
  
  # Estrategias de conflicto por tipo
  result.conflictStrategies = initTable[OperationType, ConflictResolution]()
  for op in OperationType:
    result.conflictStrategies[op] = sample([
      crLastWriteWins, crFirstWriteWins, crMerge, crServerWins
    ])
  
  # Intervalos de sincronización
  result.syncIntervals = initTable[SyncPriority, float]()
  result.syncIntervals[spLow] = rand(300.0..3600.0)      # 5min - 1h
  result.syncIntervals[spMedium] = rand(30.0..300.0)     # 30s - 5min
  result.syncIntervals[spHigh] = rand(5.0..30.0)         # 5s - 30s
  result.syncIntervals[spCritical] = rand(0.5..5.0)      # 0.5s - 5s

proc newSyncAgent*(id: int, genome: SyncGenome = randomGenome()): SyncAgent =
  ## Crea un nuevo agente de sincronización
  result = SyncAgent(
    id: id,
    syncGenome: genome,
    pendingOps: @[],
    serverState: initTable[int, DataRecord](),
    localState: initTable[int, DataRecord](),
    networkState: nsWiFi,  # Empieza en WiFi
    totalSynced: 0,
    totalConflicts: 0,
    resolvedConflicts: 0,
    failedSyncs: 0,
    avgSyncLatency: 0.0,
    dataConsumption: 0.0,
    successRate: 1.0
  )

## ───────────────────────────────────────────────────────────────────────────
## Generación de Operaciones Simuladas
## ───────────────────────────────────────────────────────────────────────────

proc generateDataRecord*(id: int, clientId: int, currentTime: float): DataRecord =
  ## Genera un registro de datos simulado
  result = DataRecord(
    id: id,
    entityType: sample(["user", "post", "comment", "like", "message"]),
    version: 1,
    timestamp: currentTime,
    clientId: clientId,
    data: initTable[string, string]()
  )
  
  # Generar 3-8 campos de datos
  for i in 0..<rand(3..8):
    result.data[fmt"field_{i}"] = fmt"value_{rand(1000)}"
  
  result.checksum = result.hash()

proc generateSyncOperations*(count: int, clientId: int, currentTime: float): seq[SyncOperation] =
  ## Genera operaciones de sincronización simuladas
  result = @[]
  
  for i in 0..<count:
    let opType = sample([opCreate, opUpdate, opDelete])
    let priority = sample([spLow, spMedium, spHigh, spCritical])
    let record = generateDataRecord(i, clientId, currentTime)
    
    result.add(SyncOperation(
      id: i,
      opType: opType,
      record: record,
      priority: priority,
      timestamp: currentTime,
      retryCount: 0,
      lastRetry: 0.0,
      conflictDetected: false
    ))

## ───────────────────────────────────────────────────────────────────────────
## Detección de Conflictos
## ───────────────────────────────────────────────────────────────────────────

proc detectConflict*(agent: SyncAgent, op: SyncOperation): bool =
  ## Detecta si existe un conflicto con el estado del servidor
  
  # Solo operaciones de actualización y eliminación pueden tener conflictos
  if op.opType notin {opUpdate, opDelete}:
    return false
  
  # Verificar si el registro existe en el servidor
  if op.record.id notin agent.serverState:
    # El registro no existe en el servidor pero el cliente intenta actualizarlo/eliminarlo
    return op.opType == opUpdate or op.opType == opDelete
  
  let serverRecord = agent.serverState[op.record.id]
  
  # Conflicto si:
  # 1. Las versiones difieren
  if serverRecord.version != op.record.version:
    return true
  
  # 2. Los checksums difieren (datos modificados)
  if serverRecord.checksum != op.record.checksum:
    return true
  
  # 3. El timestamp del servidor es más reciente
  if serverRecord.timestamp > op.record.timestamp:
    return true
  
  return false

## ───────────────────────────────────────────────────────────────────────────
## Resolución de Conflictos
## ───────────────────────────────────────────────────────────────────────────

proc resolveConflict*(agent: SyncAgent, op: var SyncOperation): DataRecord =
  ## Resuelve un conflicto según la estrategia configurada
  let strategy = agent.syncGenome.conflictStrategies[op.opType]
  
  if op.record.id notin agent.serverState:
    # No hay conflicto real, aplicar operación
    return op.record
  
  let serverRecord = agent.serverState[op.record.id]
  let clientRecord = op.record
  
  case strategy
  of crLastWriteWins:
    # El más reciente gana
    if clientRecord.timestamp > serverRecord.timestamp:
      return clientRecord
    else:
      return serverRecord
  
  of crFirstWriteWins:
    # El primero gana (servidor)
    return serverRecord
  
  of crServerWins:
    return serverRecord
  
  of crClientWins:
    return clientRecord
  
  of crMerge:
    # Merge inteligente: combinar campos no conflictivos
    var merged = serverRecord
    merged.version = max(serverRecord.version, clientRecord.version) + 1
    merged.timestamp = max(serverRecord.timestamp, clientRecord.timestamp)
    
    # Merge de datos campo por campo
    for key, value in clientRecord.data.pairs:
      if key notin merged.data or clientRecord.timestamp > serverRecord.timestamp:
        merged.data[key] = value
    
    merged.checksum = merged.hash()
    return merged
  
  of crUserDecision:
    # Simulación: 50% gana cliente, 50% gana servidor
    if rand(2) == 0:
      return clientRecord
    else:
      return serverRecord

## ───────────────────────────────────────────────────────────────────────────
## Simulación de Sincronización
## ───────────────────────────────────────────────────────────────────────────

proc calculateBackoff*(agent: SyncAgent, retryCount: int): float =
  ## Calcula backoff exponencial
  result = agent.syncGenome.initialBackoff * pow(agent.syncGenome.backoffMultiplier, float(retryCount))
  result = min(result, 3600.0)  # Max 1 hora

proc shouldSync*(agent: SyncAgent, op: SyncOperation, currentTime: float): bool =
  ## Decide si debe intentar sincronizar una operación
  
  # 1. Verificar estado de red
  if agent.networkState == nsOffline:
    return false
  
  # 2. Si prefiere WiFi y es low priority, esperar WiFi
  if agent.syncGenome.preferWiFi and op.priority == spLow:
    if agent.networkState != nsWiFi:
      return false
  
  # 3. Verificar intervalo de sincronización
  let interval = agent.syncGenome.syncIntervals[op.priority]
  let timeSinceOp = currentTime - op.timestamp
  
  if timeSinceOp < interval:
    return false
  
  # 4. Verificar backoff si hubo retries
  if op.retryCount > 0:
    let backoff = agent.calculateBackoff(op.retryCount)
    let timeSinceRetry = currentTime - op.lastRetry
    if timeSinceRetry < backoff:
      return false
  
  # 5. Verificar max retries
  if op.retryCount >= agent.syncGenome.maxRetries:
    return false  # Abandonar
  
  return true

proc syncOperation*(agent: SyncAgent, op: var SyncOperation, currentTime: float): bool =
  ## Intenta sincronizar una operación con el servidor
  
  # Simular latencia de red (5-200ms)
  let latency = case agent.networkState
    of nsOffline: 9999.0
    of nsOnline3G: rand(50.0..200.0)
    of nsOnline4G: rand(20.0..80.0)
    of nsWiFi: rand(5.0..30.0)
  
  # Simular probabilidad de fallo de red
  let failureProb = case agent.networkState
    of nsOffline: 1.0
    of nsOnline3G: 0.15
    of nsOnline4G: 0.05
    of nsWiFi: 0.01
  
  if rand(1.0) < failureProb:
    # Fallo de red
    op.retryCount += 1
    op.lastRetry = currentTime
    return false
  
  # Detección de conflicto
  let hasConflict = agent.detectConflict(op)
  
  if hasConflict:
    agent.totalConflicts += 1
    op.conflictDetected = true
    
    # Resolver conflicto
    let resolved = agent.resolveConflict(op)
    agent.serverState[resolved.id] = resolved
    agent.localState[resolved.id] = resolved
    agent.resolvedConflicts += 1
  else:
    # Sin conflicto, aplicar directamente
    case op.opType
    of opCreate, opUpdate:
      agent.serverState[op.record.id] = op.record
      agent.localState[op.record.id] = op.record
    of opDelete:
      agent.serverState.del(op.record.id)
      agent.localState.del(op.record.id)
    of opRead:
      discard  # No sincronizable
  
  # Actualizar métricas
  agent.totalSynced += 1
  
  # Actualizar latencia promedio (EWMA)
  const alpha = 0.1
  agent.avgSyncLatency = agent.avgSyncLatency * (1.0 - alpha) + latency * alpha
  
  # Simular consumo de datos (1-50 KB por operación)
  let dataSize = rand(1.0..50.0) / 1024.0  # MB
  let compressionFactor = if agent.syncGenome.compressionEnabled: 0.4 else: 1.0
  agent.dataConsumption += dataSize * compressionFactor
  
  return true

## ───────────────────────────────────────────────────────────────────────────
## Auto-priorización
## ───────────────────────────────────────────────────────────────────────────

proc autoPrioritize*(agent: SyncAgent, currentTime: float) =
  ## Eleva automáticamente la prioridad de operaciones antiguas
  for op in agent.pendingOps.mitems:
    let ageHours = (currentTime - op.timestamp) / 3600.0
    
    if ageHours > agent.syncGenome.autoPriorityThreshold:
      # Elevar prioridad
      case op.priority
      of spLow: op.priority = spMedium
      of spMedium: op.priority = spHigh
      of spHigh: op.priority = spCritical
      of spCritical: discard  # Ya es máxima

## ───────────────────────────────────────────────────────────────────────────
## Interfaz de Agent
## ───────────────────────────────────────────────────────────────────────────

method update*(agent: SyncAgent, env: Environment, dt: float) =
  ## Ciclo de actualización: procesa sincronizaciones pendientes
  var currentTime = float(agent.totalSynced)
  
  # Simular cambios de estado de red (ocasionalmente)
  if rand(100) < 5:  # 5% de probabilidad
    agent.networkState = sample([nsOffline, nsOnline3G, nsOnline4G, nsWiFi])
  
  # Auto-priorizar operaciones antiguas
  agent.autoPrioritize(currentTime)
  
  # Ordenar por prioridad (crítica primero)
  agent.pendingOps.sort do (a, b: SyncOperation) -> int:
    cmp(ord(b.priority), ord(a.priority))
  
  # Procesar lotes
  var batchCount = 0
  var successCount = 0
  var failCount = 0
  var toRemove: seq[int] = @[]
  
  for i, op in agent.pendingOps.mpairs:
    if batchCount >= agent.syncGenome.batchSize:
      break
    
    if agent.shouldSync(op, currentTime):
      let success = agent.syncOperation(op, currentTime)
      
      if success:
        successCount += 1
        toRemove.add(i)
      else:
        failCount += 1
      
      batchCount += 1
  
  # Eliminar operaciones sincronizadas
  for i in countdown(toRemove.len - 1, 0):
    agent.pendingOps.delete(toRemove[i])
  
  agent.failedSyncs += failCount
  
  # Calcular success rate
  let totalAttempts = agent.totalSynced + agent.failedSyncs
  if totalAttempts > 0:
    agent.successRate = float(agent.totalSynced) / float(totalAttempts)

method evaluateFitness*(agent: SyncAgent, env: Environment): float =
  ## Función de fitness multi-objetivo:
  ## 1. Maximizar success rate (35%)
  ## 2. Minimizar conflictos no resueltos (25%)
  ## 3. Minimizar latencia promedio (20%)
  ## 4. Minimizar consumo de datos (20%)
  
  let successScore = agent.successRate * 35.0
  
  # Tasa de resolución de conflictos
  let conflictResolution = if agent.totalConflicts > 0:
    float(agent.resolvedConflicts) / float(agent.totalConflicts)
  else:
    1.0  # Sin conflictos = perfecto
  let conflictScore = conflictResolution * 25.0
  
  # Latencia normalizada (menor es mejor)
  let maxLatency = 200.0  # ms
  let latencyScore = (1.0 - min(agent.avgSyncLatency / maxLatency, 1.0)) * 20.0
  
  # Eficiencia de datos (menor consumo es mejor, normalizado a 100MB)
  let maxData = 100.0  # MB
  let dataEfficiency = 1.0 - min(agent.dataConsumption / maxData, 1.0)
  let dataScore = dataEfficiency * 20.0
  
  result = successScore + conflictScore + latencyScore + dataScore

method clone*(agent: SyncAgent): Agent =
  ## Clona el agente
  result = newSyncAgent(agent.id, agent.syncGenome)

## ───────────────────────────────────────────────────────────────────────────
## Operadores Genéticos
## ───────────────────────────────────────────────────────────────────────────

proc mutateGenome*(genome: var SyncGenome, rate: float = 0.1) =
  ## Mutación del genoma de sincronización
  
  # Mutar estrategias de conflicto
  for op in OperationType:
    if rand(1.0) < rate:
      genome.conflictStrategies[op] = sample([
        crLastWriteWins, crFirstWriteWins, crMerge, crServerWins
      ])
  
  # Mutar intervalos
  for sp in SyncPriority:
    if rand(1.0) < rate:
      let current = genome.syncIntervals[sp]
      genome.syncIntervals[sp] = clamp(current * rand(0.5..1.5), 0.5, 3600.0)
  
  # Mutar parámetros de retry
  if rand(1.0) < rate:
    genome.maxRetries = clamp(genome.maxRetries + rand(-2..2), 3, 10)
  
  if rand(1.0) < rate:
    genome.backoffMultiplier = clamp(genome.backoffMultiplier + rand(-0.5..0.5), 1.5, 3.0)
  
  if rand(1.0) < rate:
    genome.initialBackoff = clamp(genome.initialBackoff + rand(-1.0..1.0), 1.0, 5.0)
  
  # Mutar batch size
  if rand(1.0) < rate:
    genome.batchSize = clamp(genome.batchSize + rand(-10..10), 5, 50)
  
  # Mutar otros parámetros
  if rand(1.0) < rate:
    genome.autoPriorityThreshold = clamp(genome.autoPriorityThreshold + rand(-5.0..5.0), 1.0, 24.0)
  
  if rand(1.0) < rate:
    genome.conflictTolerance = clamp(genome.conflictTolerance + rand(-0.1..0.1), 0.1, 0.8)
  
  if rand(1.0) < rate:
    genome.preferWiFi = not genome.preferWiFi
  
  if rand(1.0) < rate:
    genome.compressionEnabled = not genome.compressionEnabled

proc crossoverGenomes*(g1, g2: SyncGenome): SyncGenome =
  ## Crossover de dos genomas de sincronización
  result = SyncGenome()
  
  # Promediar parámetros numéricos
  result.maxRetries = (g1.maxRetries + g2.maxRetries) div 2
  result.backoffMultiplier = (g1.backoffMultiplier + g2.backoffMultiplier) / 2.0
  result.initialBackoff = (g1.initialBackoff + g2.initialBackoff) / 2.0
  result.batchSize = (g1.batchSize + g2.batchSize) div 2
  result.autoPriorityThreshold = (g1.autoPriorityThreshold + g2.autoPriorityThreshold) / 2.0
  result.conflictTolerance = (g1.conflictTolerance + g2.conflictTolerance) / 2.0
  
  # Heredar booleanos aleatoriamente
  result.preferWiFi = if rand(2) == 0: g1.preferWiFi else: g2.preferWiFi
  result.compressionEnabled = if rand(2) == 0: g1.compressionEnabled else: g2.compressionEnabled
  
  # Heredar tablas alternando
  result.conflictStrategies = initTable[OperationType, ConflictResolution]()
  for op in OperationType:
    result.conflictStrategies[op] = if rand(2) == 0: g1.conflictStrategies[op] else: g2.conflictStrategies[op]
  
  result.syncIntervals = initTable[SyncPriority, float]()
  for sp in SyncPriority:
    result.syncIntervals[sp] = if rand(2) == 0: g1.syncIntervals[sp] else: g2.syncIntervals[sp]

## ═══════════════════════════════════════════════════════════════════════════
## Ejemplo de Uso
## ═══════════════════════════════════════════════════════════════════════════

when isMainModule:
  randomize()
  
  echo "Creando agente de sincronización..."
  var agent = newSyncAgent(0)
  
  # Generar operaciones pendientes
  agent.pendingOps = generateSyncOperations(100, clientId = 1, currentTime = 0.0)
  
  echo fmt"Operaciones pendientes: {agent.pendingOps.len}"
  echo fmt"  - Create: {agent.pendingOps.countIt(it.opType == opCreate)}"
  echo fmt"  - Update: {agent.pendingOps.countIt(it.opType == opUpdate)}"
  echo fmt"  - Delete: {agent.pendingOps.countIt(it.opType == opDelete)}"
  echo fmt"\nPrioridades:"
  echo fmt"  - Critical: {agent.pendingOps.countIt(it.priority == spCritical)}"
  echo fmt"  - High: {agent.pendingOps.countIt(it.priority == spHigh)}"
  echo fmt"  - Medium: {agent.pendingOps.countIt(it.priority == spMedium)}"
  echo fmt"  - Low: {agent.pendingOps.countIt(it.priority == spLow)}"
  
  # Poblar estado inicial del servidor (simular algunos registros pre-existentes)
  for i in 0..<50:
    let record = generateDataRecord(i, clientId = 0, currentTime = -100.0)
    agent.serverState[record.id] = record
  
  echo fmt"\nEstado inicial del servidor: {agent.serverState.len} registros"
  
  echo "\nSimulando sincronización (50 updates)..."
  for i in 0..<50:
    agent.update(nil, 1.0)
    
    if i mod 10 == 0:
      echo fmt"Update {i:3d} | Synced: {agent.totalSynced:4d} | Pending: {agent.pendingOps.len:3d} | " &
           fmt"Conflicts: {agent.totalConflicts:2d} | Success: {agent.successRate*100:5.1f}% | " &
           fmt"Latency: {agent.avgSyncLatency:5.1f}ms | Data: {agent.dataConsumption:6.2f}MB"
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  RESULTADOS FINALES                                            ║"
  echo "╚════════════════════════════════════════════════════════════════╝\n"
  
  echo fmt"Total sincronizadas: {agent.totalSynced}"
  echo fmt"Pendientes: {agent.pendingOps.len}"
  echo fmt"Conflictos detectados: {agent.totalConflicts}"
  echo fmt"Conflictos resueltos: {agent.resolvedConflicts}"
  echo fmt"Fallos: {agent.failedSyncs}"
  echo fmt"Success rate: {agent.successRate * 100:.1f}%"
  echo fmt"Latencia promedio: {agent.avgSyncLatency:.1f}ms"
  echo fmt"Consumo de datos: {agent.dataConsumption:.2f}MB"
  echo fmt"Fitness: {agent.evaluateFitness(nil):.2f}"
  
  echo "\nEstrategias de resolución de conflictos:"
  for op, strat in agent.syncGenome.conflictStrategies.pairs:
    echo fmt"  {op}: {strat}"
