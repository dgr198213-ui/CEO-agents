import std/[tables, hashes]

type
  # Position in 2D space
  Vector2D* = object
    x*, y*: float

  # Agent state representation
  AgentState* = object
    position*: Vector2D
    velocity*: Vector2D
    energy*: float
    age*: int
    fitness*: float

  # Genome representation for evolution
  Genome*[T] = object
    genes*: seq[T]
    fitness*: float
    id*: int
    generation*: int

  # Neural network weights genome
  NeuralGenome* = Genome[float]

  # Behavioral tree genome
  BehaviorGenome* = Genome[string]

  # Base agent interface
  Agent* = ref object of RootObj
    id*: int
    state*: AgentState
    genome*: NeuralGenome

  # Environment interface
  Environment* = ref object of RootObj
    width*, height*: float
    agents*: seq[Agent]
    time*: int

  # Evolution parameters
  EvolutionParams* = object
    populationSize*: int
    mutationRate*: float
    crossoverRate*: float
    eliteSize*: int
    maxGenerations*: int
    tournamentSize*: int

  # --- Neuro Agent Types ---
  NodeType* = enum
    ntInput, ntHidden, ntOutput

  Connection* = object
    fromNode*: int
    toNode*: int
    weight*: float
    enabled*: bool
    innovation*: int

  NeuralNode* = object
    id*: int
    nodeType*: NodeType
    value*: float
    bias*: float

  NeuralNetwork* = ref object
    nodes*: seq[NeuralNode]
    connections*: seq[Connection]
    nextNodeId*: int
    innovationNumber*: int

  NeuroAgent* = ref object of Agent
    network*: NeuralNetwork
    species*: int

  # --- Swarm Agent Types ---
  BehaviorType* = enum
    btFlock, btForage, btExplore, btDefend, btHybrid

  SwarmRole* = enum
    srScout, srWorker, srGuard, srQueen

  SwarmAgent* = ref object of Agent
    role*: SwarmRole
    behavior*: BehaviorType
    communication*: seq[float]
    neighbors*: seq[int]
    target*: Vector2D
    carrying*: bool

  Resource* = object
    position*: Vector2D
    amount*: float
    collected*: bool

  SwarmEnvironment* = ref object of Environment
    resources*: seq[Resource]
    nest*: Vector2D
    pheromoneMap*: seq[seq[float]]

  # --- Coevolution Agent Types ---
  CoevoType* = enum
    ctPredator, ctPrey, ctCompetitor

  CoevoAgent* = ref object of NeuroAgent
    coevoType*: CoevoType
    health*: float
    attackPower*: float
    defenseRating*: float
    sensorRange*: float
    kills*: int
    escapes*: int

  CoevoEnvironment* = ref object of Environment
    predators*: seq[CoevoAgent]
    prey*: seq[CoevoAgent]
    foodSources*: seq[Vector2D]
    generation*: int

  # --- Knowledge Agent Types ---
  ConceptType* = enum
    ctFact, ctRule, ctPattern, ctTheory, ctHeuristic, ctAnalogy

  Concept* = object
    id*: int
    conceptType*: ConceptType
    content*: string
    confidence*: float
    utility*: float
    age*: int
    usageCount*: int
    parentConcepts*: seq[int]
    tags*: seq[string]
    hash*: Hash

  KnowledgeBase* = ref object
    concepts*: Table[int, Concept]
    nextConceptId*: int
    relationMatrix*: Table[(int, int), float]
    totalConcepts*: int
    averageConfidence*: float

  KnowledgeGenome* = object
    strategies*: seq[string]
    biases*: seq[float]
    synthesisRate*: float
    criticalThinking*: float
    creativity*: float

  KnowledgeAgent* = ref object of Agent
    knowledgeBase*: KnowledgeBase
    knowledgeGenome*: KnowledgeGenome
    learningRate*: float
    forgettingRate*: float
    synthesisAttempts*: int
    successfulSyntheses*: int
    conceptsCreated*: int
    conceptsPruned*: int

  KnowledgeEnvironment* = ref object of Environment
    sharedKnowledge*: KnowledgeBase
    problems*: seq[string]
    rewardedConcepts*: seq[int]
    generation*: int

  # --- CEO Agent Types ---
  TaskType* = enum
    ttDataProcessing, ttAPIDesign, ttFrontendUI, ttDevOps, ttSecurity,
    ttTesting, ttDocumentation, ttCodeRefactor, ttDatabaseDesign, ttResearch

  TaskUrgency* = enum
    urLow, urMedium, urHigh, urCritical

  Task* = object
    id*: int
    taskType*: TaskType
    complexity*: float
    urgency*: TaskUrgency
    description*: string
    estimatedTime*: float
    assignedAgent*: string
    completed*: bool
    successScore*: float
    skillsRequired*: seq[SkillDomain]

  # Move SkillDomain here to resolve dependency from Task
  SkillDomain* = enum
    sdSyntax, sdArchitecture, sdPerformance, sdSecurity, sdTesting,
    sdDebugging, sdDocumentation, sdIntegration, sdDeployment, sdMaintenance

  StackAgent* = object
    name*: string
    specialization*: seq[TaskType]
    workload*: float
    performance*: float
    tasksCompleted*: int
    agentType*: StackAgentType # Added from stack_agents.nim
    genome*: StackAgentGenome   # Added from stack_agents.nim
    fitness*: float             # Added from stack_agents.nim
    experience*: seq[TaskOutcome] # Added from stack_agents.nim
    totalTasks*: int            # Added from stack_agents.nim
    successfulTasks*: int       # Added from stack_agents.nim

  CEOGenome* = object
    routingWeights*: Table[TaskType, Table[string, float]]
    urgencyMultiplier*: array[TaskUrgency, float]
    complexityThreshold*: Table[string, float]
    workloadCapacity*: float
    reassignmentRate*: float

  CEOAgent* = object
    genome*: CEOGenome
    fitness*: float
    stackAgents*: seq[StackAgent]
    taskHistory*: seq[Task]
    totalTasks*: int
    successfulTasks*: int

  # --- Stack Agent Types ---
  StackAgentGenome* = object
    skills*: Table[SkillDomain, float]
    learningRate*: float
    specializationDepth*: float
    collaborationScore*: float
    adaptabilityRate*: float

  StackAgentType* = enum
    satPython, satTypeScript, satDevOps, satDataScience, satFrontend,
    satBackend, satDatabase, satSecurity, satTesting, satDocs

  TaskOutcome* = object
    taskId*: int
    success*: bool
    timeSpent*: float
    qualityScore*: float
    skillsUsed*: seq[SkillDomain]

  # --- PWA Agent Types ---
  ResourceType* = enum
    rtHTML, rtCSS, rtJS, rtImage, rtFont, rtAPI, rtVideo, rtDocument

  CacheStrategy* = enum
    csCacheFirst, csNetworkFirst, csStaleWhileRevalidate, csCacheOnly, csNetworkOnly

  ResourceProfile* = object
    resType*: ResourceType
    url*: string
    size*: float
    accessFrequency*: float
    updateRate*: float
    criticalPath*: bool
    lastAccess*: float

  CacheEntry* = object
    profile*: ResourceProfile
    strategy*: CacheStrategy
    cacheHits*: int
    cacheMisses*: int
    networkLatency*: float
    cacheLatency*: float
    staleness*: float

  CacheGenome* = object
    strategyMap*: Table[ResourceType, CacheStrategy]
    maxCacheSize*: float
    evictionThreshold*: float
    prefetchWindow*: int
    ttlMultipliers*: Table[ResourceType, float]
    criticalPathPriority*: float
    stalenessAcceptance*: float

  CacheStrategyAgent* = ref object of Agent
    cacheGenome*: CacheGenome
    cacheState*: seq[CacheEntry]
    resources*: seq[ResourceProfile]
    totalCacheSize*: float
    totalRequests*: int
    cacheHitRatio*: float
    avgLatency*: float
    offlineAvailability*: float

  NotificationType* = enum
    ntTransactional, ntPromotional, ntSocial, ntContent, ntReminder, ntAlert, ntEngagement

  NotificationPriority* = enum
    npLow, npMedium, npHigh, npUrgent

  UserSegment* = enum
    usNewUser, usActiveUser, usPassiveUser, usDormantUser, usPowerUser

  UserProfile* = object
    id*: int
    segment*: UserSegment
    timezone*: int
    activeHours*: seq[int]
    engagementRate*: float
    optOutThreshold*: float
    preferences*: set[NotificationType]
    lastNotification*: float
    notificationCount*: int
    clickCount*: int
    optedOut*: bool

  Notification* = object
    id*: int
    notifType*: NotificationType
    priority*: NotificationPriority
    title*: string
    body*: string
    timestamp*: float
    targetSegment*: UserSegment
    minEngagementRate*: float
    expirationHours*: float

  NotificationGenome* = object
    maxFrequencies*: Table[NotificationType, float]
    preferredHours*: Table[UserSegment, seq[int]]
    cooldownPeriod*: float
    minEngagementThreshold*: float
    personalizationWeight*: float
    typePriorities*: Table[NotificationType, float]
    reEngagementAggression*: float

  NotificationAgent* = ref object of Agent
    notifGenome*: NotificationGenome
    users*: seq[UserProfile]
    pendingNotifications*: seq[Notification]
    sentNotifications*: int
    totalClicks*: int
    totalOptOuts*: int
    avgCTR*: float
    avgEngagement*: float
    reputationScore*: float

  OperationType* = enum
    opCreate, opUpdate, opDelete, opRead

  ConflictResolution* = enum
    crLastWriteWins, crFirstWriteWins, crMerge, crUserDecision, crServerWins, crClientWins

  SyncPriority* = enum
    spLow, spMedium, spHigh, spCritical

  DataRecord* = object
    id*: int
    entityType*: string
    version*: int
    timestamp*: float
    clientId*: int
    data*: Table[string, string]
    checksum*: int

  SyncOperation* = object
    id*: int
    opType*: OperationType
    record*: DataRecord
    priority*: SyncPriority
    timestamp*: float
    retryCount*: int
    lastRetry*: float
    conflictDetected*: bool

  SyncGenome* = object
    conflictStrategies*: Table[OperationType, ConflictResolution]
    syncIntervals*: Table[SyncPriority, float]
    maxRetries*: int
    backoffMultiplier*: float
    initialBackoff*: float
    batchSize*: int
    autoPriorityThreshold*: float
    conflictTolerance*: float
    preferWiFi*: bool
    compressionEnabled*: bool

  NetworkState* = enum
    nsOffline, nsOnline3G, nsOnline4G, nsWiFi

  SyncAgent* = ref object of Agent
    syncGenome*: SyncGenome
    pendingOps*: seq[SyncOperation]
    serverState*: Table[int, DataRecord]
    localState*: Table[int, DataRecord]
    networkState*: NetworkState
    totalSynced*: int
    totalConflicts*: int
    resolvedConflicts*: int
    failedSyncs*: int
    avgSyncLatency*: float
    dataConsumption*: float
    successRate*: float
