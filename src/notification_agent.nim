## ═══════════════════════════════════════════════════════════════════════════
## NotificationAgent - Agente Evolutivo de Estrategias de Push Notifications
## ═══════════════════════════════════════════════════════════════════════════
## Inspirado en Web Push Notifications y mejores prácticas de engagement PWA.
## Evoluciona patrones óptimos de notificaciones considerando:
## - Timing inteligente (momento del día, frecuencia)
## - Personalización de contenido
## - Segmentación de usuarios
## - Predicción de engagement (click-through rate)
## - Minimización de opt-outs
##
## Referencias científicas:
## - "The Sorry State of Web Push in 2024" - https://www.dr-lex.be/info-stuff/web-push.html
## - Web Push API (W3C) - https://www.w3.org/TR/push-api/
## - Notification Best Practices (Google) - https://web.dev/push-notifications-overview/
## ═══════════════════════════════════════════════════════════════════════════

import agent_base, evolution_core
import std/[random, math, sequtils, tables, strformat, times, algorithm]

## ───────────────────────────────────────────────────────────────────────────
## Tipos de Notificaciones
## ───────────────────────────────────────────────────────────────────────────

type
  NotificationType* = enum
    ntTransactional   ## Confirmaciones, recibos, status updates
    ntPromotional     ## Ofertas, descuentos, campañas marketing
    ntSocial          ## Menciones, mensajes, interacciones sociales
    ntContent         ## Nuevo contenido, actualizaciones, newsletters
    ntReminder        ## Recordatorios, tareas pendientes
    ntAlert           ## Alertas urgentes, avisos importantes
    ntEngagement      ## Re-engagement, "te extrañamos", inactivity

  NotificationPriority* = enum
    npLow       ## Información no urgente
    npMedium    ## Información relevante
    npHigh      ## Información importante
    npUrgent    ## Acción inmediata requerida

  UserSegment* = enum
    usNewUser         ## Usuario nuevo (< 7 días)
    usActiveUser      ## Usuario activo (diario/semanal)
    usPassiveUser     ## Usuario pasivo (mensual)
    usDormantUser     ## Usuario inactivo (> 30 días)
    usPowerUser       ## Usuario intensivo (> 10 sesiones/día)

## ───────────────────────────────────────────────────────────────────────────
## Perfil de Usuario
## ───────────────────────────────────────────────────────────────────────────

type
  UserProfile* = object
    id*: int
    segment*: UserSegment
    timezone*: int              ## Offset UTC (-12 a +14)
    activeHours*: seq[int]      ## Horas del día activas (0-23)
    engagementRate*: float      ## Histórico de CTR (0.0-1.0)
    optOutThreshold*: float     ## Tolerancia a notificaciones (0.0-1.0)
    preferences*: set[NotificationType]  ## Tipos preferidos
    lastNotification*: float    ## Timestamp última notificación
    notificationCount*: int     ## Total recibidas
    clickCount*: int            ## Total de clicks
    optedOut*: bool

## ───────────────────────────────────────────────────────────────────────────
## Notificación
## ───────────────────────────────────────────────────────────────────────────

type
  Notification* = object
    id*: int
    notifType*: NotificationType
    priority*: NotificationPriority
    title*: string
    body*: string
    timestamp*: float           ## Hora de envío
    targetSegment*: UserSegment
    minEngagementRate*: float   ## Engagement mínimo esperado
    expirationHours*: float     ## Validez de la notificación

## ───────────────────────────────────────────────────────────────────────────
## Genoma de Estrategia de Notificaciones
## ───────────────────────────────────────────────────────────────────────────

type
  NotificationGenome* = object
    ## Genoma que codifica políticas de notificaciones
    # Frecuencias máximas por tipo (notificaciones por día)
    maxFrequencies*: Table[NotificationType, float]
    
    # Ventanas de tiempo preferidas por segmento (hora del día)
    preferredHours*: Table[UserSegment, seq[int]]
    
    # Cooldown mínimo entre notificaciones (horas)
    cooldownPeriod*: float
    
    # Umbral de engagement para enviar (0.0-1.0)
    minEngagementThreshold*: float
    
    # Peso de personalización (0.0 = genérico, 1.0 = ultra-personalizado)
    personalizationWeight*: float
    
    # Prioridad de tipos de notificación (0.0-1.0)
    typePriorities*: Table[NotificationType, float]
    
    # Agresividad de re-engagement (0.0-1.0)
    reEngagementAggression*: float

## ───────────────────────────────────────────────────────────────────────────
## NotificationAgent
## ───────────────────────────────────────────────────────────────────────────

type
  NotificationAgent* = ref object of Agent
    notifGenome*: NotificationGenome
    users*: seq[UserProfile]
    pendingNotifications*: seq[Notification]
    sentNotifications*: int
    totalClicks*: int
    totalOptOuts*: int
    avgCTR*: float                ## Click-Through Rate promedio
    avgEngagement*: float
    reputationScore*: float       ## Score de reputación (0-100)

## ───────────────────────────────────────────────────────────────────────────
## Constructor y Genoma Random
## ───────────────────────────────────────────────────────────────────────────

proc randomGenome*(): NotificationGenome =
  ## Genera un genoma de notificaciones aleatorio
  result.cooldownPeriod = rand(0.5..12.0)  # 30min - 12h
  result.minEngagementThreshold = rand(0.1..0.7)
  result.personalizationWeight = rand(0.3..1.0)
  result.reEngagementAggression = rand(0.0..0.8)
  
  # Frecuencias máximas por tipo
  result.maxFrequencies = initTable[NotificationType, float]()
  for nt in NotificationType:
    result.maxFrequencies[nt] = rand(0.5..10.0)  # 0.5 - 10 notif/día
  
  # Horas preferidas por segmento
  result.preferredHours = initTable[UserSegment, seq[int]]()
  for seg in UserSegment:
    var hours: seq[int] = @[]
    # Generar 4-8 horas preferidas
    for i in 0..<rand(4..8):
      hours.add(rand(0..23))
    result.preferredHours[seg] = hours.deduplicate()
  
  # Prioridades por tipo
  result.typePriorities = initTable[NotificationType, float]()
  for nt in NotificationType:
    result.typePriorities[nt] = rand(0.3..1.0)

proc newNotificationAgent*(id: int, genome: NotificationGenome = randomGenome()): NotificationAgent =
  ## Crea un nuevo agente de notificaciones
  result = NotificationAgent(
    id: id,
    notifGenome: genome,
    users: @[],
    pendingNotifications: @[],
    sentNotifications: 0,
    totalClicks: 0,
    totalOptOuts: 0,
    avgCTR: 0.0,
    avgEngagement: 0.0,
    reputationScore: 100.0  # Empieza con reputación perfecta
  )

## ───────────────────────────────────────────────────────────────────────────
## Generación de Usuarios Simulados
## ───────────────────────────────────────────────────────────────────────────

proc generateUserBase*(count: int): seq[UserProfile] =
  ## Genera una base de usuarios simulada
  result = @[]
  
  for i in 0..<count:
    let segment = sample([usNewUser, usActiveUser, usPassiveUser, 
                          usDormantUser, usPowerUser])
    
    # Engagement rate típico por segmento
    let baseEngagement = case segment
      of usNewUser: rand(0.2..0.5)
      of usActiveUser: rand(0.4..0.8)
      of usPassiveUser: rand(0.1..0.3)
      of usDormantUser: rand(0.0..0.1)
      of usPowerUser: rand(0.6..0.95)
    
    # Opt-out threshold (tolerancia a notificaciones)
    let optOutThresh = case segment
      of usNewUser: rand(0.3..0.6)
      of usActiveUser: rand(0.6..0.9)
      of usPassiveUser: rand(0.2..0.5)
      of usDormantUser: rand(0.1..0.3)
      of usPowerUser: rand(0.8..0.99)
    
    # Generar horas activas (3-12 horas)
    var activeHours: seq[int] = @[]
    let hourCount = case segment
      of usNewUser: rand(3..6)
      of usActiveUser: rand(6..10)
      of usPassiveUser: rand(2..4)
      of usDormantUser: rand(1..2)
      of usPowerUser: rand(10..16)
    
    for j in 0..<hourCount:
      activeHours.add(rand(0..23))
    activeHours = activeHours.deduplicate()
    
    # Preferencias de tipos
    var prefs: set[NotificationType] = {}
    let prefCount = rand(2..5)
    for j in 0..<prefCount:
      prefs.incl(sample([ntTransactional, ntPromotional, ntSocial, 
                         ntContent, ntReminder, ntAlert, ntEngagement]))
    
    result.add(UserProfile(
      id: i,
      segment: segment,
      timezone: rand(-12..14),
      activeHours: activeHours,
      engagementRate: baseEngagement,
      optOutThreshold: optOutThresh,
      preferences: prefs,
      lastNotification: 0.0,
      notificationCount: 0,
      clickCount: 0,
      optedOut: false
    ))

## ───────────────────────────────────────────────────────────────────────────
## Generación de Notificaciones
## ───────────────────────────────────────────────────────────────────────────

proc generateNotifications*(count: int, currentTime: float): seq[Notification] =
  ## Genera un conjunto de notificaciones pendientes
  result = @[]
  
  for i in 0..<count:
    let notifType = sample([ntTransactional, ntPromotional, ntSocial, 
                            ntContent, ntReminder, ntAlert, ntEngagement])
    
    let priority = case notifType
      of ntTransactional: npHigh
      of ntPromotional: npLow
      of ntSocial: npMedium
      of ntContent: npMedium
      of ntReminder: npMedium
      of ntAlert: npUrgent
      of ntEngagement: npLow
    
    let segment = sample([usNewUser, usActiveUser, usPassiveUser, 
                          usDormantUser, usPowerUser])
    
    result.add(Notification(
      id: i,
      notifType: notifType,
      priority: priority,
      title: fmt"Notification {i}",
      body: fmt"Body of notification {i}",
      timestamp: currentTime,
      targetSegment: segment,
      minEngagementRate: rand(0.1..0.5),
      expirationHours: rand(1.0..48.0)
    ))

## ───────────────────────────────────────────────────────────────────────────
## Scoring y Decisión de Envío
## ───────────────────────────────────────────────────────────────────────────

proc shouldSendNotification(agent: NotificationAgent, 
                           notif: Notification,
                           user: UserProfile,
                           currentTime: float): tuple[should: bool, score: float] =
  ## Decide si debe enviar una notificación a un usuario específico
  var score = 0.0
  
  # 1. Usuario ya opted-out
  if user.optedOut:
    return (false, 0.0)
  
  # 2. Cooldown period
  let hoursSinceLastNotif = (currentTime - user.lastNotification) / 3600.0
  if hoursSinceLastNotif < agent.notifGenome.cooldownPeriod:
    return (false, 0.0)
  
  # 3. Matching de segmento
  if user.segment != notif.targetSegment:
    score -= 20.0
  else:
    score += 30.0
  
  # 4. Tipo de notificación en preferencias
  if notif.notifType in user.preferences:
    score += 25.0
  else:
    score -= 10.0
  
  # 5. Engagement rate del usuario vs threshold
  if user.engagementRate >= agent.notifGenome.minEngagementThreshold:
    score += user.engagementRate * 30.0
  else:
    score -= 15.0
  
  # 6. Prioridad del tipo de notificación
  score += agent.notifGenome.typePriorities[notif.notifType] * 20.0
  
  # 7. Hora del día (simulado: asumimos hora actual 0-23)
  let currentHour = int(currentTime) mod 24
  if currentHour in agent.notifGenome.preferredHours[user.segment]:
    score += 15.0
  
  if currentHour in user.activeHours:
    score += 20.0
  
  # 8. Personalización
  score += agent.notifGenome.personalizationWeight * 10.0
  
  # Threshold final
  let shouldSend = score > 50.0
  return (shouldSend, score)

## ───────────────────────────────────────────────────────────────────────────
## Simulación de Engagement
## ───────────────────────────────────────────────────────────────────────────

proc simulateUserResponse(user: var UserProfile, 
                         notif: Notification,
                         score: float): tuple[clicked: bool, optedOut: bool] =
  ## Simula la respuesta del usuario a una notificación
  
  # Probabilidad de click basada en engagement + score
  let clickProb = user.engagementRate * (1.0 + score / 100.0) * 
                  (if notif.notifType in user.preferences: 1.5 else: 0.8)
  
  let clicked = rand(1.0) < clamp(clickProb, 0.0, 0.95)
  
  # Actualizar engagement rate del usuario (EWMA)
  const alpha = 0.1  # Factor de suavizado
  if clicked:
    user.engagementRate = user.engagementRate * (1.0 - alpha) + 1.0 * alpha
  else:
    user.engagementRate = user.engagementRate * (1.0 - alpha) + 0.0 * alpha
  
  # Probabilidad de opt-out (aumenta con notificaciones no clickeadas)
  var optOutProb = 0.0
  if not clicked:
    # Más notificaciones = mayor probabilidad de opt-out
    let notifOverload = float(user.notificationCount) / 100.0
    optOutProb = (1.0 - user.optOutThreshold) * notifOverload * 0.05
  
  let optedOut = rand(1.0) < optOutProb
  
  if optedOut:
    user.optedOut = true
  
  return (clicked, optedOut)

## ───────────────────────────────────────────────────────────────────────────
## Interfaz de Agent
## ───────────────────────────────────────────────────────────────────────────

method update*(agent: NotificationAgent, env: Environment, dt: float) =
  ## Ciclo de actualización: procesa notificaciones pendientes
  var currentTime = float(agent.sentNotifications)
  
  # Generar nuevas notificaciones pendientes
  if agent.pendingNotifications.len < 10:
    agent.pendingNotifications.add(generateNotifications(20, currentTime))
  
  var processedCount = 0
  var clicks = 0
  var optOuts = 0
  
  # Procesar hasta 50 notificaciones por update
  for notif in agent.pendingNotifications:
    if processedCount >= 50:
      break
    
    # Intentar enviar a usuarios relevantes
    for user in agent.users.mitems:
      let (shouldSend, score) = agent.shouldSendNotification(notif, user, currentTime)
      
      if shouldSend:
        # Simular respuesta del usuario
        let (clicked, optedOut) = simulateUserResponse(user, notif, score)
        
        user.notificationCount += 1
        user.lastNotification = currentTime
        
        if clicked:
          user.clickCount += 1
          clicks += 1
        
        if optedOut:
          optOuts += 1
        
        agent.sentNotifications += 1
        processedCount += 1
    
    currentTime += 1.0  # Avanzar 1 hora (simulado)
  
  # Limpiar notificaciones procesadas
  if processedCount > 0:
    agent.pendingNotifications.delete(0, min(processedCount - 1, agent.pendingNotifications.len - 1))
  
  # Actualizar métricas globales
  agent.totalClicks += clicks
  agent.totalOptOuts += optOuts
  
  if agent.sentNotifications > 0:
    agent.avgCTR = float(agent.totalClicks) / float(agent.sentNotifications)
  
  # Calcular engagement promedio de usuarios activos
  let activeUsers = agent.users.filterIt(not it.optedOut)
  if activeUsers.len > 0:
    agent.avgEngagement = activeUsers.mapIt(it.engagementRate).sum() / float(activeUsers.len)
  
  # Reputation score: penaliza opt-outs, premia engagement
  let optOutRate = if agent.sentNotifications > 0:
    float(agent.totalOptOuts) / float(agent.sentNotifications)
  else:
    0.0
  
  agent.reputationScore = 100.0 * (1.0 - optOutRate) * agent.avgEngagement

method evaluateFitness*(agent: NotificationAgent, env: Environment): float =
  ## Función de fitness multi-objetivo:
  ## 1. Maximizar CTR (30%)
  ## 2. Maximizar engagement promedio (30%)
  ## 3. Minimizar opt-outs (25%)
  ## 4. Maximizar reputation score (15%)
  
  let ctrScore = agent.avgCTR * 30.0 / 0.5  # Normalizado a CTR ideal ~50%
  let engagementScore = agent.avgEngagement * 30.0
  
  let activeUsers = agent.users.filterIt(not it.optedOut).len
  let retention = if agent.users.len > 0:
    float(activeUsers) / float(agent.users.len)
  else:
    1.0
  let optOutScore = retention * 25.0
  
  let reputationScore = (agent.reputationScore / 100.0) * 15.0
  
  result = ctrScore + engagementScore + optOutScore + reputationScore

method clone*(agent: NotificationAgent): Agent =
  ## Clona el agente
  result = newNotificationAgent(agent.id, agent.notifGenome)

## ───────────────────────────────────────────────────────────────────────────
## Operadores Genéticos
## ───────────────────────────────────────────────────────────────────────────

proc mutateGenome*(genome: var NotificationGenome, rate: float = 0.1) =
  ## Mutación del genoma de notificaciones
  
  # Mutar frecuencias máximas
  for nt in NotificationType:
    if rand(1.0) < rate:
      genome.maxFrequencies[nt] = clamp(
        genome.maxFrequencies[nt] + rand(-2.0..2.0), 
        0.5, 10.0
      )
  
  # Mutar cooldown
  if rand(1.0) < rate:
    genome.cooldownPeriod = clamp(
      genome.cooldownPeriod + rand(-2.0..2.0), 
      0.5, 12.0
    )
  
  # Mutar thresholds
  if rand(1.0) < rate:
    genome.minEngagementThreshold = clamp(
      genome.minEngagementThreshold + rand(-0.1..0.1), 
      0.1, 0.7
    )
  
  if rand(1.0) < rate:
    genome.personalizationWeight = clamp(
      genome.personalizationWeight + rand(-0.1..0.1), 
      0.3, 1.0
    )
  
  if rand(1.0) < rate:
    genome.reEngagementAggression = clamp(
      genome.reEngagementAggression + rand(-0.1..0.1), 
      0.0, 0.8
    )
  
  # Mutar prioridades de tipos
  for nt in NotificationType:
    if rand(1.0) < rate:
      genome.typePriorities[nt] = clamp(
        genome.typePriorities[nt] + rand(-0.2..0.2), 
        0.3, 1.0
      )
  
  # Mutar horas preferidas
  for seg in UserSegment:
    if rand(1.0) < rate:
      var hours = genome.preferredHours[seg]
      # Añadir o eliminar una hora
      if rand(2) == 0 and hours.len < 12:
        hours.add(rand(0..23))
      elif hours.len > 2:
        hours.delete(rand(hours.len - 1))
      genome.preferredHours[seg] = hours.deduplicate()

proc crossoverGenomes*(g1, g2: NotificationGenome): NotificationGenome =
  ## Crossover de dos genomas de notificaciones
  result = NotificationGenome()
  
  # Promediar parámetros escalares
  result.cooldownPeriod = (g1.cooldownPeriod + g2.cooldownPeriod) / 2.0
  result.minEngagementThreshold = (g1.minEngagementThreshold + g2.minEngagementThreshold) / 2.0
  result.personalizationWeight = (g1.personalizationWeight + g2.personalizationWeight) / 2.0
  result.reEngagementAggression = (g1.reEngagementAggression + g2.reEngagementAggression) / 2.0
  
  # Heredar tablas alternando
  result.maxFrequencies = initTable[NotificationType, float]()
  for nt in NotificationType:
    result.maxFrequencies[nt] = if rand(2) == 0: g1.maxFrequencies[nt] else: g2.maxFrequencies[nt]
  
  result.typePriorities = initTable[NotificationType, float]()
  for nt in NotificationType:
    result.typePriorities[nt] = if rand(2) == 0: g1.typePriorities[nt] else: g2.typePriorities[nt]
  
  result.preferredHours = initTable[UserSegment, seq[int]]()
  for seg in UserSegment:
    result.preferredHours[seg] = if rand(2) == 0: g1.preferredHours[seg] else: g2.preferredHours[seg]

## ═══════════════════════════════════════════════════════════════════════════
## Ejemplo de Uso
## ═══════════════════════════════════════════════════════════════════════════

when isMainModule:
  randomize()
  
  echo "Generando base de usuarios..."
  let users = generateUserBase(200)  # 200 usuarios
  
  echo fmt"Base: {users.len} usuarios"
  echo fmt"  - Nuevos: {users.countIt(it.segment == usNewUser)}"
  echo fmt"  - Activos: {users.countIt(it.segment == usActiveUser)}"
  echo fmt"  - Pasivos: {users.countIt(it.segment == usPassiveUser)}"
  echo fmt"  - Dormidos: {users.countIt(it.segment == usDormantUser)}"
  echo fmt"  - Power: {users.countIt(it.segment == usPowerUser)}"
  
  echo "\nCreando agente de notificaciones..."
  var agent = newNotificationAgent(0)
  agent.users = users
  agent.pendingNotifications = generateNotifications(100, 0.0)
  
  echo fmt"Notificaciones pendientes: {agent.pendingNotifications.len}"
  
  echo "\nSimulando campaña de notificaciones (100 updates)..."
  for i in 0..<100:
    agent.update(nil, 1.0)
    
    if i mod 20 == 0:
      echo fmt"Update {i:3d} | Sent: {agent.sentNotifications:5d} | CTR: {agent.avgCTR*100:5.2f}% | " &
           fmt"Engagement: {agent.avgEngagement*100:5.1f}% | OptOuts: {agent.totalOptOuts:3d} | " &
           fmt"Reputation: {agent.reputationScore:5.1f}"
  
  echo "\n╔════════════════════════════════════════════════════════════════╗"
  echo "║  RESULTADOS FINALES                                            ║"
  echo "╚════════════════════════════════════════════════════════════════╝\n"
  
  echo fmt"Total enviadas: {agent.sentNotifications}"
  echo fmt"Total clicks: {agent.totalClicks}"
  echo fmt"CTR: {agent.avgCTR * 100:.2f}%"
  echo fmt"Engagement promedio: {agent.avgEngagement * 100:.1f}%"
  echo fmt"Opt-outs: {agent.totalOptOuts} ({agent.totalOptOuts.float / agent.users.len.float * 100:.1f}%)"
  echo fmt"Reputation score: {agent.reputationScore:.1f}/100"
  echo fmt"Fitness: {agent.evaluateFitness(nil):.2f}"
