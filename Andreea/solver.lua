local unitPropagation = require('unitPropagation')
local pureLiteralEliminator = require('pureLiteralEliminator')
local reduceAndMutate = require('reduceAndMutate')
function solver(cnf, literals)
    verbosePrint("initial clauses: " .. #cnf)
    verbosePrint("Literals to find: " .. #literals)

    --SNAPSHOT: The CNF, The Literals, literal changed, what value was assigned, whether not we've backtracked to it yet
    local snapshots, current = { {cnf, literals, 0, false, false } }, 1
    
    function handleContradiction()
        verbosePrint("NOTE: Handling contradiction, backtracking")
        if current == 1 then
            return false
        else
            if snapshots[current][5] == false then
                cnf = snapshots[current][1]
                literals = snapshots[current][2]
                literals[snapshots[current][3]] = true
                snapshots[current][4] = not snapshots[current][4]
                snapshots[current][5] = true
                return true
            else
                current = current - 1
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
            local nextLiteral, noOfAppearances = 0, 0
            for literal, value in pairs(literals) do
                if type(value) == "table" and (math.abs(#value) > noOfAppearances) then
                    nextLiteral, noOfAppearances = literal, math.abs(#value)
                end
            end
            verbosePrint("Guessing next literal: " .. nextLiteral)
            verbosePrint("No of Appearances " .. noOfAppearances)
            if nextLiteral == 0 then
                verbosePrint("No next literal found, all literals assigned")
                if not handleContradiction() then
                    return false
                end
            else
                snapshots[current + 1] = { table.copy(cnf), table.copy(literals), nextLiteral, true, false }
                current = current + 1
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
        verbosePrint("snapshot count: " .. current)
        if current > 400 then
            table.remove(snapshots, 1)
            current = current - 1
        end
    end
    return true
end

return solver