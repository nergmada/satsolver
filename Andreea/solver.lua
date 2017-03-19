local unitPropagation = require('unitPropagation')
local pureLiteralEliminator = require('pureLiteralEliminator')
local mutateLiterals = require('mutateLiterals')
local reduceSats = require('reduceSats')
local recalculateHeuristic = require('recalculateHeuristic')

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
    local count = 1
    while (#cnf ~= 0) do
        local unitisedCnf, unitisedLiterals, unitSuccess, unitContradiction = unitPropagation(cnf, literals)
        if unitContradiction then
            verbosePrint("Contradiction found whilst unitising, backtracking")
            if not handleContradiction() then
                return false
            end
        else
            cnf, literals = unitisedCnf, unitisedLiterals
        end
        local pureCnf, pureLiterals, pureSuccess, pureContradiction = pureLiteralEliminator(cnf, literals)
        if pureContradiction then
            verbosePrint("Contradiction found whilst purising, backtracking")
            if not handleContradiction() then
                return false
            end
        else
            cnf, literals = pureCnf, pureLiterals
        end
        verbosePrint("End of iteration #" .. count)
        count = count + 1
        if not (unitSuccess or pureSuccess) then
            verbosePrint("NOTE: No success with pure or unit elimination")
            --If there are none to recalculate then outcome will be false
            local outcome = false
            literals, outcome = recalculateHeuristic(cnf, literals)
            --if all literals are assigned but not all are satisified that's a contradiction?
            if (not outcome) and #cnf > 0 then
                verbosePrint("We have no more literals to assign, but formulas are still unsatisifed, backtracking")
                if not handleContradiction() then
                    return false
                end
            else
                local nextLiteral, noOfAppearances = 0, 0
                for literal, value in ipairs(literals) do
                    if type(value) == "number" and (math.abs(value) >= noOfAppearances) then
                        nextLiteral, noOfAppearances = literal, math.abs(value)
                    end
                end
                if nextLiteral == 0 then
                    verbosePrint("No next literal found, all literals assigned")
                    if not handleContradiction() then
                        return false
                    end
                else
                    snapshots[current + 1] = { cnf, literals, nextLiteral, true, false }
                    literals = mutateLiterals(literals, { nextLiteral })
                    cnf = reduceSats(cnf, { nextLiteral })
                    current = current + 1
                end
            end
        end
        verbosePrint("Remaining Clauses: " .. #cnf)
        
    end
    return true
end

return solver