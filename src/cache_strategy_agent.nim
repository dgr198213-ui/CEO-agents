## ═══════════════════════════════════════════════════════════════════════════
## CacheStrategyAgent - Agente Evolutivo de Estrategias de Caché PWA
## ═══════════════════════════════════════════════════════════════════════════
## Inspirado en Service Workers y estrategias de caching de PWAs modernas.
## Evoluciona patrones óptimos de caché considerando:
## - Cache-First, Network-First, Stale-While-Revalidate
## - Predicción de recursos críticos
## - Políticas de eviction adaptativas
## - Prefetching inteligente basado en patrones de uso
##
## Referencias científicas:
## - Workbox (Google Chrome Labs) - https://github.com/GoogleChrome/workbox
## - "Offline Web Applications" (W3C) - https://www.w3.org/TR/offline-webapps/
## - "Service Workers: An Introduction" (Google Developers)
## ═══════════════════════════════════════════════════════════════════════════

import agent_base, types
import std/[random, math, sequtils, tables, strformat, algorithm]

# ResourceType, CacheStrategy, ResourceProfile, CacheEntry, CacheGenome, CacheStrategyAgent are now in types.nim
    
## ───────────────────────────────────────────────────────────────────────────
## Constructor y Genoma Random
## ───────────────────────────────────────────────────────────────────────────

proc randomGenome*(): CacheGenome =
  ## Genera un genoma de caché aleatorio
  result.maxCacheSize = rand(50.0..500.0)  ## 50-500 MB
  result.evictionThreshold = rand(0.5..0.95)
  result.prefetchWindow = rand(3..15)
  result.criticalPathPriority = rand(0.6..1.0)
  result.stalenessAcceptance = rand(0.0..0.7)
  
  # Estrategias por tipo de recurso
  result.strategyMap = initTable[ResourceType, CacheStrategy]()
  for rt in ResourceType:
    result.strategyMap[rt] = sample([csCacheFirst, csNetworkFirst, 
                                      csStaleWhileRevalidate, csCacheOnly])
  
  # Multiplicadores de TTL (Time To Live)
  result.ttlMultipliers = initTable[ResourceType, float]()
  for rt in ResourceType:
    result.ttlMultipliers[rt] = rand(0.5..5.0)

proc newCacheStrategyAgent*(id: int, genome: CacheGenome = randomGenome()): CacheStrategyAgent =
  ## Crea un nuevo agente de estrategia de caché
  result = CacheStrategyAgent(
    id: id,
    cacheGenome: genome,
    cacheState: @[],
    resources: @[],
    totalCacheSize: 0.0,
    totalRequests: 0,
    cacheHitRatio: 0.0,
    avgLatency: 0.0,
    offlineAvailability: 0.0
  )

## ───────────────────────────────────────────────────────────────────────────
## Simulación de Recursos Web
## ───────────────────────────────────────────────────────────────────────────

proc generateResourceCatalog*(count: int): seq[ResourceProfile] =
  ## Genera un catálogo de recursos web simulado
  result = @[]
  
  for i in 0..<count:
    let resType = sample([rtHTML, rtCSS, rtJS, rtImage, rtFont, rtAPI, rtVideo, rtDocument])
    
    # Tamaños típicos por tipo de recurso
    let size = case resType
      of rtHTML: rand(5.0..50.0)
      of rtCSS: rand(10.0..100.0)
      of rtJS: rand(50.0..500.0)
      of rtImage: rand(20.0..300.0)
      of rtFont: rand(30.0..150.0)
      of rtAPI: rand(1.0..10.0)
      of rtVideo: rand(1000.0..5000.0)
      of rtDocument: rand(100.0..2000.0)
    
    # Frecuencias de acceso típicas
    let freq = case resType
      of rtHTML: rand(10.0..100.0)   # Alta frecuencia
      of rtCSS: rand(5.0..50.0)
      of rtJS: rand(5.0..50.0)
      of rtImage: rand(1.0..20.0)
      of rtFont: rand(0.5..5.0)
      of rtAPI: rand(20.0..200.0)    # Muy alta frecuencia
      of rtVideo: rand(0.1..2.0)
      of rtDocument: rand(0.5..10.0)
    
    result.add(ResourceProfile(
      resType: resType,
      url: fmt"/resource/{i}/{resType}",
      size: size,
      accessFrequency: freq,
      updateRate: rand(0.0..1.0),
      criticalPath: rand(100) < 30,  # 30% son críticos
      lastAccess: 0.0
    ))

## ───────────────────────────────────────────────────────────────────────────
## Simulación de Solicitudes
## ───────────────────────────────────────────────────────────────────────────

proc simulateRequest(agent: CacheStrategyAgent, resource: ResourceProfile, 
                     currentTime: float): tuple[latency: float, hit: bool] =
  ## Simula una solicitud de recurso con la estrategia de caché configurada
  let strategy = agent.cacheGenome.strategyMap[resource.resType]
  
  # Latencias simuladas (ms)
  const 
    cacheLatency = 1.0      # ~1ms desde caché
    networkLatency = 150.0  # ~150ms desde red (promedio)
  
  # Verificar si está en caché
  let inCache = agent.cacheState.anyIt(it.profile.url == resource.url)
  
  case strategy
  of csCacheFirst:
    if inCache:
      return (cacheLatency, true)
    else:
      return (networkLatency, false)
      
  of csNetworkFirst:
    # Siempre intenta red primero (asumimos éxito)
    return (networkLatency, false)
    
  of csStaleWhileRevalidate:
    if inCache:
      # Devuelve caché inmediatamente, actualiza en background (async)
      return (cacheLatency, true)
    else:
      return (networkLatency, false)
      
  of csCacheOnly:
    if inCache:
      return (cacheLatency, true)
    else:
      return (9999.0, false)  # Fallo total si no está en caché
      
  of csNetworkOnly:
    return (networkLatency, false)

## ───────────────────────────────────────────────────────────────────────────
## Políticas de Eviction (LRU, Prioridad, Tamaño)
## ───────────────────────────────────────────────────────────────────────────

proc evictResources(agent: CacheStrategyAgent) =
  ## Elimina recursos del caché según política de eviction
  if agent.totalCacheSize <= agent.cacheGenome.maxCacheSize:
    return  # No hay necesidad de evictar
  
  # Ordenar por: prioridad crítica (ascendente), luego por último acceso (ascendente) - LRU
  agent.cacheState.sort do (a, b: CacheEntry) -> int:
    if a.profile.criticalPath and not b.profile.criticalPath:
      return 1  # a tiene más prioridad
    elif not a.profile.criticalPath and b.profile.criticalPath:
      return -1
    else:
      return cmp(a.profile.lastAccess, b.profile.lastAccess)
  
  # Eliminar hasta alcanzar threshold
  let targetSize = agent.cacheGenome.maxCacheSize * agent.cacheGenome.evictionThreshold
  while agent.totalCacheSize > targetSize and agent.cacheState.len > 0:
    let evicted = agent.cacheState[0]
    agent.cacheState.delete(0)
    agent.totalCacheSize -= evicted.profile.size / 1024.0  # KB → MB

proc addToCache(agent: CacheStrategyAgent, resource: ResourceProfile) =
  ## Añade un recurso al caché
  # Verificar si ya está
  if agent.cacheState.anyIt(it.profile.url == resource.url):
    # Actualizar lastAccess
    for entry in agent.cacheState.mitems:
      if entry.profile.url == resource.url:
        entry.profile.lastAccess = float(agent.totalRequests)
        entry.cacheHits += 1
    return
  
  # Crear nueva entrada
  let newEntry = CacheEntry(
    profile: resource,
    strategy: agent.cacheGenome.strategyMap[resource.resType],
    cacheHits: 0,
    cacheMisses: 0,
    networkLatency: 150.0,
    cacheLatency: 1.0,
    staleness: 0.0
  )
  
  agent.cacheState.add(newEntry)
  agent.totalCacheSize += resource.size / 1024.0  # KB → MB
  
  # Aplicar política de eviction si es necesario
  agent.evictResources()

## ───────────────────────────────────────────────────────────────────────────
## Prefetching Predictivo
## ───────────────────────────────────────────────────────────────────────────

proc predictNextResources(agent: CacheStrategyAgent, 
                         currentResource: ResourceProfile): seq[ResourceProfile] =
  ## Predice los próximos recursos a prefetch basándose en patrones
  result = @[]
  
  # Estrategia simple: recursos del mismo tipo con alta frecuencia de acceso
  var candidates = agent.resources.filterIt(
    it.resType == currentResource.resType and 
    it.url != currentResource.url and
    it.accessFrequency > 5.0
  )
  
  # Ordenar por frecuencia de acceso descendente
  candidates.sort(proc (a, b: ResourceProfile): int = 
    cmp(b.accessFrequency, a.accessFrequency)
  )
  
  # Tomar ventana de prefetch
  let window = min(agent.cacheGenome.prefetchWindow, candidates.len)
  result = candidates[0..<window]

## ───────────────────────────────────────────────────────────────────────────
## Métricas de Performance
## ───────────────────────────────────────────────────────────────────────────

proc calculateMetrics(agent: CacheStrategyAgent) =
  ## Calcula métricas de performance de caché
  var totalHits = 0
  var totalMisses = 0
  var totalLatency = 0.0
  
  for entry in agent.cacheState:
    totalHits += entry.cacheHits
    totalMisses += entry.cacheMisses
    totalLatency += float(entry.cacheHits) * entry.cacheLatency
    totalLatency += float(entry.cacheMisses) * entry.networkLatency
  
  let total = totalHits + totalMisses
  agent.cacheHitRatio = if total > 0: float(totalHits) / float(total) else: 0.0
  agent.avgLatency = if total > 0: totalLatency / float(total) else: 0.0
  
  # Disponibilidad offline: % de recursos críticos en caché
  let criticalResources = agent.resources.filterIt(it.criticalPath)
  let criticalInCache = criticalResources.filterIt(
    (let resUrl = it.url; agent.cacheState.anyIt(it.profile.url == resUrl))
  )
  agent.offlineAvailability = if criticalResources.len > 0:
    float(criticalInCache.len) / float(criticalResources.len)
  else:
    0.0

## ───────────────────────────────────────────────────────────────────────────
## Interfaz de Agent
## ───────────────────────────────────────────────────────────────────────────

method update*(agent: CacheStrategyAgent, env: Environment, dt: float) =
  ## Simula un ciclo de actualización (procesamiento de solicitudes)
  const requestsPerUpdate = 20
  
  for i in 0..<requestsPerUpdate:
    # Seleccionar recurso aleatorio ponderado por frecuencia de acceso
    let totalFreq = agent.resources.mapIt(it.accessFrequency).foldl(a + b, 0.0)
    var r = rand(totalFreq)
    var selectedResource: ResourceProfile
    
    for res in agent.resources:
      r -= res.accessFrequency
      if r <= 0:
        selectedResource = res
        break
    
    # Simular solicitud
    let (latency, hit) = agent.simulateRequest(selectedResource, float(agent.totalRequests))
    
    agent.totalRequests += 1
    
    # Actualizar entrada en caché
    if hit:
      for entry in agent.cacheState.mitems:
        if entry.profile.url == selectedResource.url:
          entry.cacheHits += 1
          entry.profile.lastAccess = float(agent.totalRequests)
    else:
      # Miss: añadir a caché si la estrategia lo permite
      if agent.cacheGenome.strategyMap[selectedResource.resType] != csNetworkOnly:
        agent.addToCache(selectedResource)
      
      for entry in agent.cacheState.mitems:
        if entry.profile.url == selectedResource.url:
          entry.cacheMisses += 1
    
    # Prefetching (cada N solicitudes)
    if agent.totalRequests mod 50 == 0:
      let predictions = agent.predictNextResources(selectedResource)
      for pred in predictions:
        if not agent.cacheState.anyIt(it.profile.url == pred.url):
          agent.addToCache(pred)
  
  # Recalcular métricas
  agent.calculateMetrics()

method evaluateFitness*(agent: CacheStrategyAgent, env: Environment): float =
  ## Función de fitness multi-objetivo:
  ## 1. Maximizar cache hit ratio (40%)
  ## 2. Minimizar latencia promedio (30%)
  ## 3. Maximizar disponibilidad offline (20%)
  ## 4. Minimizar uso de caché (10%)
  
  let hitScore = agent.cacheHitRatio * 40.0
  
  # Latencia normalizada (menor es mejor)
  let maxLatency = 200.0  # ms
  let latencyScore = (1.0 - min(agent.avgLatency / maxLatency, 1.0)) * 30.0
  
  let offlineScore = agent.offlineAvailability * 20.0
  
  # Eficiencia de caché (menor uso relativo es mejor)
  let cacheEfficiency = if agent.cacheGenome.maxCacheSize > 0:
    1.0 - (agent.totalCacheSize / agent.cacheGenome.maxCacheSize)
  else:
    0.0
  let cacheScore = cacheEfficiency * 10.0
  
  result = hitScore + latencyScore + offlineScore + cacheScore

## ───────────────────────────────────────────────────────────────────────────
## Operadores Genéticos Especializados
## ───────────────────────────────────────────────────────────────────────────

proc mutateGenome*(genome: var CacheGenome, rate: float = 0.1) =
  ## Mutación del genoma de caché
  # Mutar estrategias de caché
  for rt in ResourceType:
    if rand(1.0) < rate:
      genome.strategyMap[rt] = sample([csCacheFirst, csNetworkFirst, 
                                        csStaleWhileRevalidate, csCacheOnly])
  
  # Mutar parámetros numéricos
  if rand(1.0) < rate:
    genome.maxCacheSize = clamp(genome.maxCacheSize + rand(100.0) - 50.0, 50.0, 500.0)
  
  if rand(1.0) < rate:
    genome.evictionThreshold = clamp(genome.evictionThreshold + rand(0.2) - 0.1, 0.5, 0.95)
  
  if rand(1.0) < rate:
    genome.prefetchWindow = clamp(genome.prefetchWindow + rand(6) - 3, 3, 15)
  
  if rand(1.0) < rate:
    genome.criticalPathPriority = clamp(genome.criticalPathPriority + rand(0.2) - 0.1, 0.6, 1.0)
  
  if rand(1.0) < rate:
    genome.stalenessAcceptance = clamp(genome.stalenessAcceptance + rand(0.2) - 0.1, 0.0, 0.7)
  
  # Mutar TTL multipliers
  for rt in ResourceType:
    if rand(1.0) < rate:
      genome.ttlMultipliers[rt] = clamp(genome.ttlMultipliers[rt] + rand(1.0) - 0.5, 0.5, 5.0)

proc crossoverGenomes*(g1, g2: CacheGenome): CacheGenome =
  ## Crossover de dos genomas de caché
  result = CacheGenome()
  
  # Heredar estrategias de ambos padres
  result.strategyMap = initTable[ResourceType, CacheStrategy]()
  for rt in ResourceType:
    result.strategyMap[rt] = if rand(2) == 0: g1.strategyMap[rt] else: g2.strategyMap[rt]
  
  # Promediar parámetros numéricos
  result.maxCacheSize = (g1.maxCacheSize + g2.maxCacheSize) / 2.0
  result.evictionThreshold = (g1.evictionThreshold + g2.evictionThreshold) / 2.0
  result.prefetchWindow = (g1.prefetchWindow + g2.prefetchWindow) div 2
  result.criticalPathPriority = (g1.criticalPathPriority + g2.criticalPathPriority) / 2.0
  result.stalenessAcceptance = (g1.stalenessAcceptance + g2.stalenessAcceptance) / 2.0
  
  # TTL multipliers heredados aleatoriamente
  result.ttlMultipliers = initTable[ResourceType, float]()
  for rt in ResourceType:
    result.ttlMultipliers[rt] = if rand(2) == 0: g1.ttlMultipliers[rt] else: g2.ttlMultipliers[rt]

## ───────────────────────────────────────────────────────────────────────────
## Evolución de Población
## ───────────────────────────────────────────────────────────────────────────

proc tournamentSelection(scores: seq[tuple[agent: CacheStrategyAgent, score: float]], 
                        tournamentSize: int): tuple[agent: CacheStrategyAgent, score: float] =
  ## Selección por torneo
  var best = scores[rand(scores.len - 1)]
  for i in 1..<tournamentSize:
    let candidate = scores[rand(scores.len - 1)]
    if candidate.score > best.score:
      best = candidate
  result = best

proc evolvePopulation*(agents: var seq[CacheStrategyAgent], 
                      resources: seq[ResourceProfile],
                      generations: int = 50) =
  ## Evoluciona una población de agentes de caché
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  EVOLUCIÓN DE ESTRATEGIAS DE CACHÉ PWA                         ║"
  echo "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Asignar catálogo de recursos a todos los agentes
  for agent in agents.mitems:
    agent.resources = resources
  
  for gen in 0..<generations:
    # 1. Simular solicitudes (100 updates = ~2000 requests)
    for agent in agents.mitems:
      for i in 0..<100:
        agent.update(nil, 1.0)
    
    # 2. Evaluar fitness
    var fitnessScores: seq[tuple[agent: CacheStrategyAgent, score: float]] = @[]
    for agent in agents:
      fitnessScores.add((agent, agent.evaluateFitness(nil)))
    
    # Ordenar por fitness descendente
    fitnessScores.sort(proc (a, b: auto): int = cmp(b.score, a.score))
    
    # 3. Reportar mejores
    if gen mod 10 == 0:
      let best = fitnessScores[0]
      echo fmt"Gen {gen:3d} | Fitness: {best.score:6.2f} | Hit: {best.agent.cacheHitRatio*100:5.1f}% | " &
           fmt"Latency: {best.agent.avgLatency:5.1f}ms | Offline: {best.agent.offlineAvailability*100:5.1f}% | " &
           fmt"Cache: {best.agent.totalCacheSize:5.1f}/{best.agent.cacheGenome.maxCacheSize:5.1f}MB"
    
    # 4. Selección y reproducción (elitismo + torneo)
    let eliteCount = agents.len div 10  # Top 10%
    var newPopulation: seq[CacheStrategyAgent] = @[]
    
    # Conservar élite
    for i in 0..<eliteCount:
      newPopulation.add(newCacheStrategyAgent(
        fitnessScores[i].agent.id, 
        fitnessScores[i].agent.cacheGenome
      ))
    
    # Generar resto mediante torneo + crossover + mutación
    while newPopulation.len < agents.len:
      let p1 = tournamentSelection(fitnessScores, 3)
      let p2 = tournamentSelection(fitnessScores, 3)
      
      var childGenome = crossoverGenomes(p1.agent.cacheGenome, p2.agent.cacheGenome)
      mutateGenome(childGenome, 0.15)
      
      newPopulation.add(newCacheStrategyAgent(newPopulation.len, childGenome))
    
    # 5. Reemplazar población
    agents = newPopulation



## ═══════════════════════════════════════════════════════════════════════════
## Ejemplo de Uso
## ═══════════════════════════════════════════════════════════════════════════

when isMainModule:
  randomize()
  
  echo "Generando catálogo de recursos web..."
  let resources = generateResourceCatalog(100)  # 100 recursos web
  
  echo fmt"Catálogo: {resources.len} recursos"
  echo fmt"  - HTML: {resources.countIt(it.resType == rtHTML)}"
  echo fmt"  - CSS: {resources.countIt(it.resType == rtCSS)}"
  echo fmt"  - JS: {resources.countIt(it.resType == rtJS)}"
  echo fmt"  - Images: {resources.countIt(it.resType == rtImage)}"
  echo fmt"  - API: {resources.countIt(it.resType == rtAPI)}"
  echo fmt"  - Críticos: {resources.countIt(it.criticalPath)}"
  
  echo "\nCreando población inicial de 30 agentes..."
  var population: seq[CacheStrategyAgent] = @[]
  for i in 0..<30:
    population.add(newCacheStrategyAgent(i))
  
  echo "Iniciando evolución..."
  evolvePopulation(population, resources, 50)
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  MEJOR ESTRATEGIA EVOLUCIONADA                                 ║"
  echo "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Encontrar el mejor agente
  var best = population[0]
  for agent in population:
    if agent.evaluateFitness(nil) > best.evaluateFitness(nil):
      best = agent
  
  echo fmt"Fitness final: {best.evaluateFitness(nil):.2f}"
  echo fmt"Cache hit ratio: {best.cacheHitRatio * 100:.1f}%"
  echo fmt"Latencia promedio: {best.avgLatency:.1f}ms"
  echo fmt"Disponibilidad offline: {best.offlineAvailability * 100:.1f}%"
  echo fmt"Uso de caché: {best.totalCacheSize:.1f}/{best.cacheGenome.maxCacheSize:.1f}MB"
  
  echo "\nEstrategias por tipo de recurso:"
  for rt in ResourceType:
    echo fmt"  {rt}: {best.cacheGenome.strategyMap[rt]}"
  
  echo fmt"\nPrefetch window: {best.cacheGenome.prefetchWindow} recursos"
  echo fmt"Eviction threshold: {best.cacheGenome.evictionThreshold * 100:.1f}%"
  echo fmt"Critical path priority: {best.cacheGenome.criticalPathPriority * 100:.1f}%"
