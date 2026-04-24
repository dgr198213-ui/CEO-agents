# ============================================================================
# Example: Knowledge Generator Evolution
# ============================================================================
# Evolución de agentes que generan y propagan conocimiento

import agent_base, knowledge_agent, evolution_core
import random, sequtils, tables, strformat, algorithm

proc displayKnowledgeBase(kb: KnowledgeBase, maxConcepts: int = 10) =
  echo "  📚 Base de Conocimiento:"
  echo &"     Total conceptos: {kb.totalConcepts}"
  
  var displayCount = 0
  for id, cpt in kb.concepts:
    if displayCount >= maxConcepts:
      echo &"     ... y {kb.totalConcepts - maxConcepts} más"
      break
    
    let typeEmoji = case cpt.conceptType:
      of ctFact: "📌"
      of ctRule: "⚖️"
      of ctPattern: "🔍"
      of ctTheory: "🧠"
      of ctHeuristic: "💡"
      of ctAnalogy: "🔗"
    
    echo &"     {typeEmoji} [{cpt.conceptType}] {cpt.content[0..min(60, cpt.content.len-1)]}"
    echo &"        Confianza: {cpt.confidence:.2f} | Edad: {cpt.age} | Uso: {cpt.usageCount}"
    inc displayCount

proc runKnowledgeEvolution() =
  randomize()
  
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║     🧠 ENGENDRADOR DE CONOCIMIENTO EVOLUTIVO 🧠              ║"
  echo "║                                                               ║"
  echo "║  Agentes que aprenden, sintetizan y propagan conocimiento     ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Parámetros de evolución
  let params = EvolutionParams(
    populationSize: 20,
    mutationRate: 0.4,
    crossoverRate: 0.6,
    eliteSize: 3,
    maxGenerations: 30,
    tournamentSize: 3
  )
  
  echo "⚙️  Configuración:"
  echo &"   Población: {params.populationSize} agentes"
  echo &"   Generaciones: {params.maxGenerations}"
  echo &"   Tasa de mutación: {params.mutationRate}"
  echo &"   Tasa de cruce: {params.crossoverRate}"
  echo ""
  
  # Crear población inicial
  var agents: seq[KnowledgeAgent] = @[]
  for i in 0..<params.populationSize:
    agents.add(newKnowledgeAgent(i))
  
  # Evolución
  for gen in 0..<params.maxGenerations:
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo &"🧬 GENERACIÓN {gen + 1}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Crear entorno
    let env = newKnowledgeEnvironment(400.0, 400.0)
    
    # Resetear agentes
    for agent in agents:
      agent.state.fitness = 0.0
      agent.state.age = 0
      agent.synthesisAttempts = 0
      agent.successfulSyntheses = 0
      let prevConcepts = agent.conceptsCreated
      agent.conceptsCreated = 0
    
    # Simulación de 100 timesteps
    for step in 0..99:
      for agent in agents:
        agent.update(env, 1.0)
    
    # Evaluar fitness
    var totalFitness = 0.0
    var bestAgent: KnowledgeAgent
    var bestFitness = -Inf
    var totalConcepts = 0
    var totalSyntheses = 0
    
    for agent in agents:
      let fitness = agent.evaluateFitness(env)
      agent.state.fitness = fitness
      totalFitness += fitness
      totalConcepts += agent.knowledgeBase.totalConcepts
      totalSyntheses += agent.successfulSyntheses
      
      if fitness > bestFitness:
        bestFitness = fitness
        bestAgent = agent
    
    let avgFitness = totalFitness / float(agents.len)
    let avgConcepts = totalConcepts.float / agents.len.float
    let avgSyntheses = totalSyntheses.float / agents.len.float
    
    # Estadísticas
    echo ""
    echo "📊 Estadísticas de la Generación:"
    echo &"   Fitness promedio:      {avgFitness:.1f}"
    echo &"   Mejor fitness:         {bestFitness:.1f}"
    echo &"   Conceptos promedio:    {avgConcepts:.1f}"
    echo &"   Sintesis promedio:     {avgSyntheses:.1f}"
    echo &"   Conocimiento compartido: {env.sharedKnowledge.totalConcepts}"
    echo ""
    
    # Mostrar mejor agente
    echo "🏆 Mejor Agente de la Generación:"
    echo &"   ID: {bestAgent.id}"
    echo &"   Fitness: {bestFitness:.1f}"
    echo &"   Conceptos totales: {bestAgent.knowledgeBase.totalConcepts}"
    echo &"   Síntesis exitosas: {bestAgent.successfulSyntheses} / {bestAgent.synthesisAttempts}"
    echo &"   Tasa de aprendizaje: {bestAgent.learningRate:.3f}"
    echo &"   Creatividad: {bestAgent.knowledgeGenome.creativity:.3f}"
    echo &"   Pensamiento crítico: {bestAgent.knowledgeGenome.criticalThinking:.3f}"
    echo &"   Estrategias: {bestAgent.knowledgeGenome.strategies}"
    echo ""
    
    displayKnowledgeBase(bestAgent.knowledgeBase, maxConcepts = 5)
    echo ""
    
    # Mostrar conocimiento compartido
    if env.sharedKnowledge.totalConcepts > 0:
      echo "🌐 Conocimiento Compartido (Pool Global):"
      displayKnowledgeBase(env.sharedKnowledge, maxConcepts = 3)
      echo ""
    
    # Evolucionar población (excepto última generación)
    if gen < params.maxGenerations - 1:
      var nextGen: seq[KnowledgeAgent] = @[]
      var nextId = (gen + 1) * params.populationSize
      
      # Elitismo
      var sorted = agents
      sorted.sort(proc(a, b: KnowledgeAgent): int =
        cmp(b.state.fitness, a.state.fitness)
      , Descending)
      
      for i in 0..<params.eliteSize:
        nextGen.add(sorted[i])
      
      # Generar descendientes
      while nextGen.len < params.populationSize:
        # Selección por torneo
        var parent1 = sorted[0]
        var parent2 = sorted[0]
        
        for _ in 0..<params.tournamentSize:
          let candidate = agents[rand(agents.len - 1)]
          if candidate.state.fitness > parent1.state.fitness:
            parent1 = candidate
        
        for _ in 0..<params.tournamentSize:
          let candidate = agents[rand(agents.len - 1)]
          if candidate.state.fitness > parent2.state.fitness:
            parent2 = candidate
        
        var offspring: KnowledgeAgent
        
        # Crossover
        if rand(1.0) < params.crossoverRate:
          offspring = crossoverKnowledgeAgents(parent1, parent2, nextId)
        else:
          offspring = newKnowledgeAgent(nextId)
          offspring.knowledgeGenome = parent1.knowledgeGenome
          offspring.learningRate = parent1.learningRate
        
        # Mutación
        mutateKnowledgeGenome(offspring, params.mutationRate)
        
        nextGen.add(offspring)
        inc nextId
      
      agents = nextGen
      echo "🔄 Nueva generación creada con éxito"
      echo ""
  
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                  🎉 EVOLUCIÓN COMPLETADA 🎉                  ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Análisis final
  var bestFinalAgent: KnowledgeAgent
  var bestFinalFitness = -Inf
  
  for agent in agents:
    if agent.state.fitness > bestFinalFitness:
      bestFinalFitness = agent.state.fitness
      bestFinalAgent = agent
  
  echo "🏆 AGENTE CAMPEÓN FINAL:"
  echo &"   Fitness final: {bestFinalFitness:.1f}"
  echo &"   Conceptos en base: {bestFinalAgent.knowledgeBase.totalConcepts}"
  echo &"   Síntesis exitosas: {bestFinalAgent.successfulSyntheses}"
  echo &"   Conceptos creados (total): {bestFinalAgent.conceptsCreated}"
  echo &"   Conceptos podados: {bestFinalAgent.conceptsPruned}"
  echo ""
  echo "   Genoma optimizado:"
  echo &"     • Creatividad: {bestFinalAgent.knowledgeGenome.creativity:.3f}"
  echo &"     • Pensamiento crítico: {bestFinalAgent.knowledgeGenome.criticalThinking:.3f}"
  echo &"     • Tasa de síntesis: {bestFinalAgent.knowledgeGenome.synthesisRate:.3f}"
  echo &"     • Tasa de aprendizaje: {bestFinalAgent.learningRate:.3f}"
  echo &"     • Estrategias: {bestFinalAgent.knowledgeGenome.strategies}"
  echo ""
  
  echo "📚 Base de Conocimiento Final (muestra):"
  displayKnowledgeBase(bestFinalAgent.knowledgeBase, maxConcepts = 15)
  echo ""
  
  # Análisis de tipos de conocimiento
  var typeCounts: array[ConceptType, int]
  for cpt in bestFinalAgent.knowledgeBase.concepts.values:
    inc typeCounts[cpt.conceptType]
  
  echo "📊 Distribución de Tipos de Conocimiento:"
  for conceptType in ConceptType:
    if typeCounts[conceptType] > 0:
      let bar = "█".repeat(typeCounts[conceptType])
      echo &"   {conceptType:12s} [{typeCounts[conceptType]:3d}] {bar}"
  echo ""
  
  echo "✨ El agente ha evolucionado capacidades avanzadas de:"
  echo "   • Generación de conocimiento por analogía"
  echo "   • Síntesis mediante combinación de conceptos"
  echo "   • Abstracción de patrones comunes"
  echo "   • Especialización de teorías generales"
  echo "   • Transferencia de conocimiento entre agentes"
  echo ""
  echo "🧠 ¡El engendrador de conocimiento está listo!"

when isMainModule:
  runKnowledgeEvolution()
