local mutateLiterals = require('mutateLiterals')
local reduceSats = require('reduceSats')

function pureLiteralEliminator(cnf, literals) 
    local pureLiterals = {}
    for i = 1, #literals do
        local foundNegative = false
        local foundPositive = false
        for _, dnf in ipairs(cnf) do
            for _, term in ipairs(dnf) do
                if term == i then
                    foundPositive = true
                elseif term == -i then
                    foundNegative = true
                end
                if foundPositive and foundNegative then
                    break
                end
            end
            if foundPositive and foundNegative then
                break
            end
        end
        if not (foundPositive and foundNegative) then
            if foundPositive then
                table.insert(pureLiterals, i)
            elseif foundNegative then
                table.insert(pureLiterals, -i)
            end
        end
    end
    if #pureLiterals == 0 then
        return cnf, literals, false, false
    end

    table.sort(pureLiterals)
    local newLiterals = mutateLiterals(literals, pureLiterals)
    if newLiterals == nil then
        return cnf, literals, true, true
    end

    local newCnf = reduceSats(cnf, pureLiterals)

    return newCnf, newLiterals, true, false
end

return pureLiteralEliminator