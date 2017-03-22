local unitPropagation = require('unitPropagation')
local pureLiteralEliminator = require('pureLiteralEliminator')
local reduceAndMutate = require('reduceAndMutate')
local snapshotManager = require('snapshotManager')
local pickLiteral = require('pickLiteral')
function solver(cnf, literals)
    verbosePrint("initial clauses: " .. #cnf)
    verbosePrint("Literals to find: " .. #literals)
    function handleContradiction()
        verbosePrint("NOTE: Handling contradiction, backtracking")
        if snapshotManager.hasSnapshots() then
            return false
        else
            local snapshot = snapshotManager.retrieveSnapshot()
            if snapshot ~= nil and snapshot[5] == false then
                snapshotManager.saveSnapshot(snapshot[1], snapshot[2], snapshot[3], not snapshot[4], not snapshot[5])
                cnf, literals = snapshot[1], snapshot[2]
                literals[snapshot[3]] = not snapshot[4]
                return true
            else
                return handleContradiction()
            end
        end
    end
    local loopcount = 1
    local dnfCount = #cnf
    while (dnfCount ~= 0) do
        local unitSuccess, unitContradiction = unitPropagation(cnf, literals)
        if unitContradiction then
            verbosePrint("Contradiction found whilst unitising, backtracking")
            if not handleContradiction() then
                return false
            end
        end
        local pureSuccess, pureContradiction = pureLiteralEliminator(cnf, literals)
        if pureContradiction then
            verbosePrint("Contradiction found whilst purising, backtracking")
            if not handleContradiction() then
                return false
            end
        end
        verbosePrint("End of iteration #" .. loopcount)
        loopcount = loopcount + 1
        if not (unitSuccess or pureSuccess) then
            verbosePrint("NOTE: No success with pure or unit elimination")
            --If there are none to recalculate then outcome will be false       
            local nextLiteral, assignment = pickLiteral(literals)
            if nextLiteral == 0 then
                verbosePrint("No next literal found, all literals assigned")
                if not handleContradiction() then
                    return false
                end
            else
                snapshotManager.saveSnapshot(cnf, literals, nextLiteral, assignment, false)
                if not reduceAndMutate(cnf, { nextLiteral }, literals) then
                    verbosePrint("reduced a formula to unsatisfiability")
                    if not handleContradiction() then
                        return false
                    end
                end
            end
        end
        dnfCount = 0
        for _, dnf in ipairs(cnf) do
            if #dnf > 0 then
                dnfCount = dnfCount + 1
            end
        end

        verbosePrint("Remaining Clauses: " .. dnfCount)
    end
    return true
end

return solver