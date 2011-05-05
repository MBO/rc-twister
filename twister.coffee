#!/usr/bin/env coffee

assert = require "assert"
util = require "util"

DEBUG = false

validMoves = ["R", "L", "U", "D", "F", "B", "r", "l", "u", "d", "f", "b"]
validTwists = ["x", "y", "z"]
validModificators = ["2", "'"]
ws = [" ", "\n"]

normalizeTwist = (twistsCount) ->
  (twistsCount + 4) % 4

parseAlgorithm = (str) ->
  console.info "parseAlgorithm", str if DEBUG
  movesList = []

  for move in str.split //
    if move in ws
      /* skip it */
    else if move in validMoves or move in validTwists
      movesList.push (move: move, twists: 1)
    else if move in validModificators
      lastMove = movesList.pop()
      throw Error("invalid modificator: #{move}") unless lastMove.move
      lastMove.twists = normalizeTwist(lastMove.twists * (if move == "'" then -1 else 2))
      movesList.push lastMove
    else if move == "+"
      movesList.push (tr_start: true)
    else if move == "-"
      movesList.push (tr_end: true)
    else
      throw Error("invalid move: #{move}")

  console.info ".parseAlgorithm", movesList if DEBUG
  movesList

transposeStep = (twist, step) ->
  console.info "transposeStep", twist, step if DEBUG
  transpositions = {
    x: {u:"b", U:"B", b:"d", B:"D", d:"f", D:"F", f:"u", F:"U", y:"z", z:"y"},
    y: {r:"f", R:"F", f:"l", F:"L", l:"b", L:"B", b:"r", B:"R", x:"z", z:"x"},
    z: {u:"r", U:"R", r:"d", R:"D", d:"l", D:"L", l:"u", L:"U", x:"y", y:"x"}
  }
  direction = {
    x: {y:-1},
    y: {z:-1},
    z: {x:-1}
  }
  move = transpositions[twist][step.move] || step.move
  twists = normalizeTwist(step.twists * (direction[twist][step.move] || 1))
  result = (move: move, twists: twists)

  console.info ".transposeStep", result if DEBUG
  result

translateStep = (transpositions, step) ->
  console.info "translateStep", transpositions, step if DEBUG
  for transposition in transpositions
    for twist in validTwists
      for i in [0...transposition[twist]]
        step = transposeStep(twist, step)
  console.info ".translateStep", step if DEBUG
  step

translateAlgorithm = (algorithm) ->
  transpositions = []
  resultingAlgorithm = []
  waitForTwists = false
  for step in algorithm
    if step.tr_start
      transpositions.push (x:0, y:0, z:0)
      waitForTwists = true
    else if step.tr_end
      lastTransposition = transpositions.pop()
      for twist in validTwists
        resultingAlgorithm.push translateStep(transpositions, (move: twist, twists: normalizeTwist(4-lastTransposition[twist]))) if lastTransposition[twist] > 0
    else if step.move
      if waitForTwists
        throw Error("invalid transposition move") unless step.move in validTwists
        lastTransposition = transpositions.pop()
        lastTransposition[step.move] += normalizeTwist(lastTransposition[step.move] + step.twists)
        transpositions.push lastTransposition
        resultingAlgorithm.push step
        waitForTwists = false
      else
        resultingAlgorithm.push translateStep(transpositions, step)
  resultingAlgorithm
    

encodeStep = (step) ->
  switch step.twists
    when 1 then step.move
    when 2 then "#{step.move}2"
    when 3 then "#{step.move}'"

encodeAlgorithm = (algorithm) ->
  (encodeStep(step) for step in algorithm).join(" ")

if process.argv.length > 2
  for arg in process.argv[2..]
    algorithm = parseAlgorithm arg
    /*console.log algorithm*/
    algorithm = translateAlgorithm algorithm

    /*console.log algorithm*/
    console.log arg, ": ", encodeAlgorithm(algorithm)
else
  runTests()
