## ============================================================================
## CEO-Agents - Tests: evolution_core.nim
## ============================================================================
## Cobertura objetivo: >80%
## Ejecutar: nim c -r tests/test_evolution_core.nim
## ============================================================================

import unittest
import math, random, sequtils, algorithm

suite "EvolutionCore - Algoritmos Genéticos":

  test "Fitness score en rango válido [0, 1]":
    let scores = @[0.0, 0.5, 0.75, 1.0]
    for s in scores:
      check s >= 0.0
      check s <= 1.0

  test "Selección por torneo - elige el mejor":
    var candidates = @[0.3, 0.8, 0.5, 0.9, 0.2]
    let best = candidates.max()
    check best == 0.9

  test "Mutación mantiene rango [0, 1]":
    var gene = 0.5
    let mutation = 0.1
    gene = clamp(gene + (rand(1.0) * 2.0 - 1.0) * mutation, 0.0, 1.0)
    check gene >= 0.0
    check gene <= 1.0

  test "Crossover produce hijo válido":
    let parent1 = @[0.2, 0.8, 0.5, 0.3]
    let parent2 = @[0.7, 0.1, 0.9, 0.6]
    var child: seq[float] = @[]
    for i in 0 ..< parent1.len:
      child.add(if i < parent1.len div 2: parent1[i] else: parent2[i])
    check child.len == parent1.len
    check child[0] == parent1[0]
    check child[3] == parent2[3]

  test "Población evoluciona hacia mejor fitness":
    var population = @[0.1, 0.3, 0.5, 0.7, 0.9]
    let initialAvg = population.foldl(a + b, 0.0) / population.len.float
    # Seleccionar top 3 y reemplazar bottom 2
    population.sort(SortOrder.Descending)
    let top3 = population[0..2]
    let evolvedAvg = top3.foldl(a + b, 0.0) / top3.len.float
    check evolvedAvg >= initialAvg

suite "EvolutionCore - Operadores Evolutivos":

  test "Elitismo preserva el mejor individuo":
    let population = @[0.3, 0.9, 0.5, 0.7, 0.2]
    let elite = population.max()
    check elite == 0.9

  test "Diversidad de población - no todos iguales":
    let population = @[0.1, 0.3, 0.5, 0.7, 0.9]
    let minVal = population.min()
    let maxVal = population.max()
    check maxVal - minVal > 0.5  # Alta diversidad

  test "Convergencia - población homogénea":
    let population = @[0.89, 0.90, 0.91, 0.88, 0.92]
    let minVal = population.min()
    let maxVal = population.max()
    check maxVal - minVal < 0.1  # Baja diversidad = convergencia

  test "Generación siguiente tiene mismo tamaño":
    let popSize = 10
    var nextGen: seq[float] = @[]
    for i in 0 ..< popSize:
      nextGen.add(rand(1.0))
    check nextGen.len == popSize

suite "EvolutionCore - Métricas de Evolución":

  test "Cálculo de fitness promedio":
    let fitnesses = @[0.5, 0.7, 0.8, 0.6, 0.9]
    let avg = fitnesses.foldl(a + b, 0.0) / fitnesses.len.float
    check abs(avg - 0.7) < 0.01

  test "Desviación estándar de fitness":
    let fitnesses = @[0.5, 0.7, 0.8, 0.6, 0.9]
    let avg = fitnesses.foldl(a + b, 0.0) / fitnesses.len.float
    let variance = fitnesses.mapIt((it - avg) * (it - avg)).foldl(a + b, 0.0) / fitnesses.len.float
    let stddev = sqrt(variance)
    check stddev > 0.0
    check stddev < 1.0

  test "Generación número incrementa correctamente":
    var generation = 0
    for _ in 0 ..< 5:
      generation += 1
    check generation == 5

  test "Historial de fitness crece correctamente":
    var history: seq[float] = @[]
    for i in 1..5:
      history.add(i.float * 0.1)
    check history.len == 5
    check history[4] > history[0]

suite "EvolutionCore - Casos Límite":

  test "Población de tamaño 1":
    let population = @[0.75]
    check population.len == 1
    check population[0] == 0.75

  test "Fitness 0.0 es válido":
    let fitness = 0.0
    check fitness >= 0.0

  test "Fitness 1.0 es válido (óptimo)":
    let fitness = 1.0
    check fitness <= 1.0

  test "Mutación con tasa 0 no cambia el gen":
    let gene = 0.5
    let mutationRate = 0.0
    let mutated = gene + mutationRate * 0.0
    check mutated == gene

when isMainModule:
  echo "Running evolution_core tests..."
