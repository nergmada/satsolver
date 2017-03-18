local mutateLiterals = require('mutateLiterals')
local reduceSats = require('reduceSats')

function unitPropagation(cnf, literals)
    local units = {}
    
    for _, dnf in ipairs(cnf) do
        if (#dnf == 1) then
            table.insert(units, dnf[1])
        end
    end
    
    if (#units == 0) then
        return cnf, literals, false, false
    end

    table.sort(units)
    --transform literals to match unit
    local newLiterals = mutateLiterals(literals, units)

    if newLiterals == nil then
        return cnf, literals, true, true
    end

    --Creating a new set of CNF
    local newCnf = reduceSats(cnf, units)

    return newCnf, newLiterals, true, false

end

return unitPropagation