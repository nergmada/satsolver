local unitPropagation = require('unitPropagation')
local pureLiteralEliminator = require('pureLiteralEliminator')


function solver(cnf, literals)
    verbosePrint("initial clauses: " .. #cnf)
    verbosePrint("Literals to find: " .. #literals)
    local snapshots, current = { {cnf, literals, 0, false } }, 1
    
    function handleContradiction()
        if current == 1 then
            return false
        else
            if snapshots[current][4] == false then
                cnf = snapshots[current][1]
                literals = snapshots[current][2]
                literals[snapshots[current][3]] = true
                snapshots[current][4] = true
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
            verbosePrint("Contradiction found")
            if not handleContradiction() then
                return false
            end
        else
            cnf, literals = unitisedCnf, unitisedLiterals
        end
        local pureCnf, pureLiterals, pureSuccess, pureContradiction = pureLiteralEliminator(cnf, literals)
        if pureContradiction then
            verbosePrint("Contradiction found")
            if not handleContradiction() then
                return false
            end
        else
            cnf, literals = pureCnf, pureLiterals
        end
        if not (unitSuccess or pureSuccess) then
            verbosePrint("No success with pure or unit elimination")
            for literal, value in ipairs(literals) do
                if value == 0 then
                    snapshots[current + 1] = { cnf, literals, literal, false }
                    literals = table.copy(literals)
                    literals[literal] = false
                    current = current + 1
                    break
                end
            end
        end
        
        verbosePrint("End of iteration #" .. count)
        count = count + 1
        verbosePrint("Remaining Clauses: " .. #cnf)
    end
    return true
end

return solver