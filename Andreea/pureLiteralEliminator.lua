local reduceAndMutate = require('reduceAndMutate')

function pureLiteralEliminator(cnf, literals) 
    local pureLiterals = {}
    for literal, dnfs in ipairs(literals) do
        if type(dnfs) == 'table' and #dnfs > 0 then
            table.sort(dnfs)
            if dnfs[1] > 0 then
                table.insert(pureLiterals, literal)
            elseif dnfs[#dnfs] < 0 then
                table.insert(pureLiterals, -literal)
            end
        end
    end
    if #pureLiterals == 0 then
        return false, false
    end
    table.sort(pureLiterals)
    local success = reduceAndMutate(cnf, pureLiterals, literals)
    if success == false then
        return true, true
    end

    return true, false
end

return pureLiteralEliminator