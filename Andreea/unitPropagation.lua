local reduceAndMutate = require('reduceAndMutate')

function unitPropagation(cnf, literals)
    local units = {}
    
    for _, dnf in ipairs(cnf) do
        if (#dnf == 1) then
            table.insert(units, dnf[1])
        end
    end
    
    if (#units == 0) then
        return false, false
    end
    table.sort(units)
    --transform literals to match unit
    local success = reduceAndMutate(cnf, units, literals)
    if success == false then
        return true, true
    end

    return true, false
end

return unitPropagation