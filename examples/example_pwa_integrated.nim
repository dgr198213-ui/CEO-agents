## ═══════════════════════════════════════════════════════════════════════════
## Ejemplo Integrado - Sistema PWA Evolutivo Completo
## ═══════════════════════════════════════════════════════════════════════════
## Demuestra la evolución conjunta de los tres agentes PWA:
## 1. CacheStrategyAgent - Optimización de estrategias de caché
## 2. NotificationAgent - Patrones inteligentes de engagement
## 3. SyncAgent - Sincronización offline-online robusta
##
## Este ejemplo simula un escenario realista de una PWA completa con:
## - 100 recursos web estáticos y dinámicos
## - 200 usuarios con diferentes perfiles de actividad
## - 150 operaciones de sincronización pendientes
## - Evolución de 30 generaciones para optimizar cada subsistema
## ═══════════════════════════════════════════════════════════════════════════

import ../src/cache_strategy_agent, ../src/notification_agent, ../src/sync_agent
import ../src/agent_base, ../src/evolution_core
import std/[random, strformat, sequtils, times, algorithm, tables]

## ───────────────────────────────────────────────────────────────────────────
## Sistema PWA Integrado
## ───────────────────────────────────────────────────────────────────────────

type
  PWASystem* = object
    cacheAgent*: CacheStrategyAgent
    notifAgent*: NotificationAgent
    syncAgent*: SyncAgent
    
    # Métricas globales del sistema
    totalUsers*: int
    activeUsers*: int
    offlineCapability*: float  # % funcionalidad disponible offline
    userSatisfaction*: float   # Score combinado de todos los subsistemas
    systemEfficiency*: float   # Recursos vs performance

proc newPWASystem*(cacheGenome: CacheGenome, 
                  notifGenome: NotificationGenome,
                  syncGenome: SyncGenome): PWASystem =
  ## Crea un sistema PWA completo con los genomas especificados
  result.cacheAgent = newCacheStrategyAgent(0, cacheGenome)
  result.notifAgent = newNotificationAgent(1, notifGenome)
  result.syncAgent = newSyncAgent(2, syncGenome)
  
  result.totalUsers = 0
  result.activeUsers = 0
  result.offlineCapability = 0.0
  result.userSatisfaction = 0.0
  result.systemEfficiency = 0.0

proc initializeSystem*(system: var PWASystem, 
                      resourceCount: int,
                      userCount: int,
                      syncOpCount: int) =
  ## Inicializa el sistema con datos de prueba
  
  # 1. Caché: generar catálogo de recursos
  let resources = generateResourceCatalog(resourceCount)
  system.cacheAgent.resources = resources
  
  # 2. Notificaciones: generar base de usuarios
  let users = generateUserBase(userCount)
  system.notifAgent.users = users
  
  # 3. Sincronización: generar operaciones pendientes
  let syncOps = generateSyncOperations(syncOpCount, clientId = 1, currentTime = 0.0)
  system.syncAgent.pendingOps = syncOps
  
  # Poblar estado inicial del servidor
  for i in 0..<(syncOpCount div 2):
    let record = generateDataRecord(i, clientId = 0, currentTime = -100.0)
    tables.`[]=`(system.syncAgent.serverState, record.id, record)
  
  system.totalUsers = userCount
  system.activeUsers = users.countIt(not it.optedOut)

proc updateSystem*(system: var PWASystem, iterations: int) =
  ## Actualiza todos los subsistemas del PWA
  for i in 0..<iterations:
    system.cacheAgent.update(nil, 1.0)
    system.notifAgent.update(nil, 1.0)
    system.syncAgent.update(nil, 1.0)

proc calculateSystemMetrics*(system: var PWASystem) =
  ## Calcula métricas globales del sistema
  
  # Offline capability: combinación de caché y sync
  system.offlineCapability = (
    system.cacheAgent.offlineAvailability * 0.6 +
    system.syncAgent.successRate * 0.4
  )
  
  # Active users
  system.activeUsers = system.notifAgent.users.countIt(not it.optedOut)
  
  # User satisfaction: combinación de todos los subsistemas
  let cacheQuality = system.cacheAgent.evaluateFitness(nil) / 100.0  # Normalizado
  let notifQuality = system.notifAgent.evaluateFitness(nil) / 100.0
  let syncQuality = system.syncAgent.evaluateFitness(nil) / 100.0
  
  system.userSatisfaction = (
    cacheQuality * 0.35 +      # 35% caché (performance percibida)
    notifQuality * 0.30 +      # 30% notificaciones (engagement)
    syncQuality * 0.35         # 35% sync (confiabilidad de datos)
  )
  
  # System efficiency: recursos usados vs valor entregado
  let cacheEfficiency = if system.cacheAgent.cacheGenome.maxCacheSize > 0:
    1.0 - (system.cacheAgent.totalCacheSize / system.cacheAgent.cacheGenome.maxCacheSize)
  else:
    0.0
  
  let dataEfficiency = 1.0 - min(system.syncAgent.dataConsumption / 100.0, 1.0)
  
  system.systemEfficiency = (cacheEfficiency + dataEfficiency) / 2.0

proc systemFitness*(system: var PWASystem): float =
  ## Función de fitness global del sistema PWA
  system.calculateSystemMetrics()
  
  # Fitness combinado (0-100)
  result = system.userSatisfaction * 100.0

## ───────────────────────────────────────────────────────────────────────────
## Evolución Co-adaptativa de Subsistemas PWA
## ───────────────────────────────────────────────────────────────────────────


proc tournamentSelect(scores: seq[tuple[system: PWASystem, fitness: float]], 
                     tournamentSize: int): tuple[system: PWASystem, fitness: float] =
  ## Selección por torneo para sistemas PWA
  var best = scores[rand(scores.len - 1)]
  for i in 1..<tournamentSize:
    let candidate = scores[rand(scores.len - 1)]
    if candidate.fitness > best.fitness:
      best = candidate
  result = best

proc evolvePWASystems*(populationSize: int = 20, 
                      generations: int = 30,
                      resourceCount: int = 100,
                      userCount: int = 200,
                      syncOpCount: int = 150) =
  ## Evoluciona una población de sistemas PWA completos
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  EVOLUCIÓN DE SISTEMAS PWA INTEGRADOS                          ║"
  echo "╚════════════════════════════════════════════════════════════════╝\n"
  
  echo fmt"Configuración:"
  echo fmt"  - Población: {populationSize} sistemas PWA"
  echo fmt"  - Generaciones: {generations}"
  echo fmt"  - Recursos web: {resourceCount}"
  echo fmt"  - Usuarios: {userCount}"
  echo fmt"  - Operaciones de sync: {syncOpCount}"
  echo ""
  
  # Crear población inicial
  var population: seq[PWASystem] = @[]
  
  for i in 0..<populationSize:
    var system = newPWASystem(
      cache_strategy_agent.randomGenome(),  # CacheGenome
      notification_agent.randomGenome(),    # NotificationGenome
      sync_agent.randomGenome()             # SyncGenome
    )
    system.initializeSystem(resourceCount, userCount, syncOpCount)
    population.add(system)
  
  echo "Población inicial creada. Iniciando evolución...\n"
  
  # Evolución
  for gen in 0..<generations:
    # 1. Simular operación de cada sistema
    for system in population.mitems:
      system.updateSystem(50)  # 50 iteraciones por generación
    
    # 2. Evaluar fitness
    var scores: seq[tuple[system: PWASystem, fitness: float]] = @[]
    for system in population.mitems:
      let fit = system.systemFitness()
      scores.add((system, fit))
    
    # Ordenar por fitness descendente
    scores.sort(proc (a, b: auto): int = cmp(b.fitness, a.fitness))
    
    # 3. Reportar mejores
    if gen mod 5 == 0 or gen == generations - 1:
      let best = scores[0]
      echo fmt"╭─ Generación {gen:3d} ─────────────────────────────────────────────╮"
      echo fmt"│ Fitness Global: {best.fitness:6.2f}/100                              │"
      echo fmt"├─ Caché ───────────────────────────────────────────────────────────┤"
      echo fmt"│   Hit Ratio:    {best.system.cacheAgent.cacheHitRatio*100:5.1f}%  │  Latency: {best.system.cacheAgent.avgLatency:5.1f}ms │"
      echo fmt"│   Offline:      {best.system.cacheAgent.offlineAvailability*100:5.1f}%  │  Cache:   {best.system.cacheAgent.totalCacheSize:5.1f}MB  │"
      echo fmt"├─ Notificaciones ──────────────────────────────────────────────────┤"
      echo fmt"│   CTR:          {best.system.notifAgent.avgCTR*100:5.1f}%  │  Engagement: {best.system.notifAgent.avgEngagement*100:5.1f}% │"
      echo fmt"│   Sent:         {best.system.notifAgent.sentNotifications:5d}  │  Opt-outs:   {best.system.notifAgent.totalOptOuts:5d} │"
      echo fmt"├─ Sincronización ──────────────────────────────────────────────────┤"
      echo fmt"│   Success:      {best.system.syncAgent.successRate*100:5.1f}%  │  Conflicts:  {best.system.syncAgent.totalConflicts:5d} │"
      echo fmt"│   Synced:       {best.system.syncAgent.totalSynced:5d}  │  Data:       {best.system.syncAgent.dataConsumption:5.1f}MB  │"
      echo fmt"├─ Sistema ─────────────────────────────────────────────────────────┤"
      echo fmt"│   User Satisfaction: {best.system.userSatisfaction*100:5.1f}%                          │"
      echo fmt"│   Offline Capability: {best.system.offlineCapability*100:5.1f}%                         │"
      echo fmt"│   Active Users: {best.system.activeUsers:3d}/{best.system.totalUsers:3d}                              │"
      echo fmt"╰───────────────────────────────────────────────────────────────────╯\n"
    
    # 4. Selección y reproducción
    if gen < generations - 1:
      let eliteCount = populationSize div 10  # 10% élite
      var newPopulation: seq[PWASystem] = @[]
      
      # Conservar élite
      for i in 0..<eliteCount:
        newPopulation.add(scores[i].system)
      
      # Generar resto mediante torneo + crossover + mutación
      while newPopulation.len < populationSize:
        # Selección por torneo
        let p1 = tournamentSelect(scores, 3)
        let p2 = tournamentSelect(scores, 3)
        
        # Crossover de genomas
        var childCacheGenome = crossoverGenomes(
          p1.system.cacheAgent.cacheGenome,
          p2.system.cacheAgent.cacheGenome
        )
        
        var childNotifGenome = notification_agent.crossoverGenomes(
          p1.system.notifAgent.notifGenome,
          p2.system.notifAgent.notifGenome
        )
        
        var childSyncGenome = sync_agent.crossoverGenomes(
          p1.system.syncAgent.syncGenome,
          p2.system.syncAgent.syncGenome
        )
        
        # Mutación
        cache_strategy_agent.mutateGenome(childCacheGenome, 0.12)
        notification_agent.mutateGenome(childNotifGenome, 0.12)
        sync_agent.mutateGenome(childSyncGenome, 0.12)
        
        # Crear nuevo sistema
        var child = newPWASystem(childCacheGenome, childNotifGenome, childSyncGenome)
        child.initializeSystem(resourceCount, userCount, syncOpCount)
        
        newPopulation.add(child)
      
      # Reemplazar población
      population = newPopulation

proc tournamentSelect(scores: seq[tuple[system: PWASystem, fitness: float]], 
                     size: int): tuple[system: PWASystem, fitness: float] =
  ## Selección por torneo
  var best = scores[rand(scores.len - 1)]
  for i in 1..<size:
    let candidate = scores[rand(scores.len - 1)]
    if candidate.fitness > best.fitness:
      best = candidate
  result = best

## ───────────────────────────────────────────────────────────────────────────
## Comparación con Baselines
## ───────────────────────────────────────────────────────────────────────────

proc createBaselineSystem*(strategy: string): PWASystem =
  ## Crea sistemas baseline con estrategias fijas conocidas
  case strategy
  of "aggressive":
    # Estrategia agresiva: mucha caché, muchas notificaciones, sync rápido
    var cacheGenome = CacheGenome(
      maxCacheSize: 400.0,
      evictionThreshold: 0.9,
      prefetchWindow: 12,
      criticalPathPriority: 0.95,
      stalenessAcceptance: 0.6
    )
    # Completar tablas...
    for rt in ResourceType:
      cacheGenome.strategyMap[rt] = csCacheFirst
      cacheGenome.ttlMultipliers[rt] = 4.0
    
    var notifGenome = NotificationGenome(
      cooldownPeriod: 1.0,
      minEngagementThreshold: 0.2,
      personalizationWeight: 0.5,
      reEngagementAggression: 0.7
    )
    for nt in NotificationType:
      notifGenome.maxFrequencies[nt] = 8.0
      notifGenome.typePriorities[nt] = 0.8
    for seg in UserSegment:
      notifGenome.preferredHours[seg] = @[9, 12, 15, 18, 20]
    
    var syncGenome = SyncGenome(
      maxRetries: 8,
      backoffMultiplier: 1.8,
      initialBackoff: 1.5,
      batchSize: 40,
      autoPriorityThreshold: 2.0,
      conflictTolerance: 0.3,
      preferWiFi: false,
      compressionEnabled: true
    )
    for op in OperationType:
      syncGenome.conflictStrategies[op] = crLastWriteWins
    for sp in SyncPriority:
      syncGenome.syncIntervals[sp] = 10.0
    
    result = newPWASystem(cacheGenome, notifGenome, syncGenome)
  
  of "conservative":
    # Estrategia conservadora: caché selectiva, pocas notificaciones, sync cuidadoso
    var cacheGenome = CacheGenome(
      maxCacheSize: 100.0,
      evictionThreshold: 0.6,
      prefetchWindow: 3,
      criticalPathPriority: 0.7,
      stalenessAcceptance: 0.2
    )
    for rt in ResourceType:
      cacheGenome.strategyMap[rt] = csNetworkFirst
      cacheGenome.ttlMultipliers[rt] = 1.0
    
    var notifGenome = NotificationGenome(
      cooldownPeriod: 8.0,
      minEngagementThreshold: 0.5,
      personalizationWeight: 0.9,
      reEngagementAggression: 0.2
    )
    for nt in NotificationType:
      notifGenome.maxFrequencies[nt] = 2.0
      notifGenome.typePriorities[nt] = 0.5
    for seg in UserSegment:
      notifGenome.preferredHours[seg] = @[10, 14, 19]
    
    var syncGenome = SyncGenome(
      maxRetries: 5,
      backoffMultiplier: 2.5,
      initialBackoff: 3.0,
      batchSize: 10,
      autoPriorityThreshold: 12.0,
      conflictTolerance: 0.6,
      preferWiFi: true,
      compressionEnabled: true
    )
    for op in OperationType:
      syncGenome.conflictStrategies[op] = crMerge
    for sp in SyncPriority:
      syncGenome.syncIntervals[sp] = 120.0
    
    result = newPWASystem(cacheGenome, notifGenome, syncGenome)
  
  else:
    # Balanced baseline
    result = newPWASystem(cache_strategy_agent.randomGenome(), notification_agent.randomGenome(), sync_agent.randomGenome())

## ═══════════════════════════════════════════════════════════════════════════
## Main
## ═══════════════════════════════════════════════════════════════════════════

when isMainModule:
  randomize()
  
  echo "═══════════════════════════════════════════════════════════════════════"
  echo "  SISTEMA PWA EVOLUTIVO - Ejemplo Integrado"
  echo "═══════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Este ejemplo demuestra la co-evolución de tres subsistemas PWA:"
  echo "  1. CacheStrategyAgent - Optimización de caché (Service Workers)"
  echo "  2. NotificationAgent - Engagement inteligente (Web Push)"
  echo "  3. SyncAgent - Sincronización robusta (Background Sync + IndexedDB)"
  echo ""
  echo "La evolución optimiza el fitness global del sistema considerando:"
  echo "  - Performance (latencia, hit ratio)"
  echo "  - User engagement (CTR, retention)"
  echo "  - Reliability (sync success, conflict resolution)"
  echo "  - Efficiency (cache size, data consumption)"
  echo ""
  
  # Opción 1: Evolución completa
  echo "Opción seleccionada: EVOLUCIÓN COMPLETA"
  echo "────────────────────────────────────────────────────────────────────"
  evolvePWASystems(
    populationSize = 20,
    generations = 30,
    resourceCount = 100,
    userCount = 200,
    syncOpCount = 150
  )
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  EVOLUCIÓN COMPLETADA                                          ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  
  # Opción 2: Comparación con baselines (comentada)
  # echo "\nOpción seleccionada: COMPARACIÓN CON BASELINES"
  # echo "────────────────────────────────────────────────────────────────────"
  # 
  # var aggressive = createBaselineSystem("aggressive")
  # var conservative = createBaselineSystem("conservative")
  # var evolved = newPWASystem(randomGenome(), randomGenome(), randomGenome())
  # 
  # aggressive.initializeSystem(100, 200, 150)
  # conservative.initializeSystem(100, 200, 150)
  # evolved.initializeSystem(100, 200, 150)
  # 
  # echo "Simulando sistemas (100 updates cada uno)..."
  # aggressive.updateSystem(100)
  # conservative.updateSystem(100)
  # evolved.updateSystem(100)
  # 
  # echo "\n╔════════════════════════════════════════════════════════════════╗"
  # echo "║  COMPARACIÓN DE ESTRATEGIAS                                    ║"
  # echo "╚════════════════════════════════════════════════════════════════╝\n"
  # 
  # echo fmt"Aggressive:    Fitness = {aggressive.systemFitness():6.2f}"
  # echo fmt"Conservative:  Fitness = {conservative.systemFitness():6.2f}"
  # echo fmt"Random:        Fitness = {evolved.systemFitness():6.2f}"
