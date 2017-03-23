unitPropagation = require 'tools.unitPropagation'
pureLiteral = require 'tools.pureLiteral'
reducer = require 'tools.reducer'
snapshotManager = require 'tools.snapshotManager'
pickLiteral = require 'tools.pickLiteral'

handleContradiction = () ->
    verbosePrint "Handling contradiction, backtracking"
    if not snapshotManager.hasSnapshots!
        return false
    else
        snapshot = snapshotManager.retrieveSnapshot!
        if snapshot ~= nil and snapshot[5] == false
            snapshotManager.saveSnapshot snapshot[1], snapshot[2], snapshot[3], not snapshot[4], not snapshot[5]
            cnf, literals  = snapshot[1], snapshot[2]
            literals[snapshot[3]] = not snapshot[4]
            return true
        else
            return handleContradiction!

return (cnf, literals) ->
    verbosePrint "Initial clauses: " .. #cnf
    verbosePrint "Literals to find: " .. #literals
    loopcount, dnfCount = 1, #cnf
    while dnfCount ~= 0
        unitSuccess, unitContradiction = unitPropagation cnf, literals
        if unitContradiction
            verbosePrint "Contradiction found whilst unitising"
            unless handleContradiction!
                return false
        
        pureSuccess, pureContradiction = pureLiteral cnf, literals
        if pureContradiction
            verbosePrint "Contradiction found whilst purising"
            unless handleContradiction!
                return false
        verbosePrint "End of iteration #" .. loopcount
        loopcount += 1
        unless (unitSuccess or pureSuccess)
            verbosePrint "No success with pure or unit elimination"
            nextLiteral, assignment = pickLiteral literals
            if nextLiteral == 0
                verbosePrint "No next literal found, all literals assigned"
                unless handleContradiction!
                    return false
            else
                snapshotManager.saveSnapshot cnf, literals, nextLiteral, assignment, false
                unless reducer cnf, { nextLiteral }, literals
                    verbosePrint "Reduced a formula to unsatisfiability"
                    unless handleContradiction!
                        return false
        dnfCount = 0
        for dnf in *cnf
            if #dnf > 0 then dnfCount += 1
        verbosePrint "Remaining clauses: " .. dnfCount
    return true
    