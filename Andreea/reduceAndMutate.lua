--[[
    cnf:
        -1 -2 -3
        1 -2 -3
        -2
    literals:
        1: -1, 2
        2: -1, -2, -3
        3: -1, -2
    unit: -2
]]

--[[cnf: -1, -2, -3 unit: -1 -> True satisifed 
    unit: 3 -> False unsatisifed so far
    return nil if unsatisified ]]

function assignLiteralValueAndRetrieveDnfIds(literals, unit)
    if unit < 0 then
        if type(literals[-unit]) == 'table' then
            local dnfIds = literals[-unit]
            literals[-unit] = false
            return dnfIds, false
        elseif literals[-unit] == true then
            return {}, true
        else 
            return {}, false
        end 
    else
        if type(literals[unit]) == 'table' then
            local dnfIds = literals[unit]
            literals[unit] = false
            return dnfIds, false
        elseif literals[unit] == true then
            return {}, true
        else
            return {}, false
        end
    end
end

function removeUnitFromCnf(dnf, unit) 
    local matches = table.search(dnf, unit)
    if matches and #matches > 0 then
        table.removeValue(dnf, unit)
        return true
    else
        table.removeValue(dnf, -unit)
        if #dnf == 0 then
            return nil
        end
        return false
    end
end


--If a negative dnfId is passed in 
function removeTermsBelongingToDnfIdFromLiterals(terms, dnfId, literals) 
    for _, term in ipairs(terms) do
        if term < 0 then
            table.removeValue(literals[-term], dnfId)
            table.removeValue(literals[-term], -dnfId)
        else
            table.removeValue(literals[term], -dnfId)
            table.removeValue(literals[term], dnfId)
        end
    end
end

function eliminateUnitFromDnfsAndLiterals(dnfs, literals, unit)
    local dnfIds, contradiction = assignLiteralValueAndRetrieveDnfIds(literals, unit)
    if contradiction then
        return false
    end
    for _, dnfId in ipairs(dnfIds) do
        local satisifed
        if dnfId < 0 then
            local dnf = dnfs[-dnfId]
            satisifed = removeUnitFromCnf(dnf, unit)
        else
            local dnf = dnfs[dnfId]
            satisifed = removeUnitFromCnf(dnf, unit)
        end
        if satisifed == nil then
            return false
        elseif satisifed then
            if dnfId < 0 then
                removeTermsBelongingToDnfIdFromLiterals(dnfs[-dnfId], dnfId, literals)
                dnfs[-dnfId] = {}
            else
                removeTermsBelongingToDnfIdFromLiterals(dnfs[dnfId], dnfId, literals)
                dnfs[dnfId] = {}
            end
        end
        removeTermsBelongingToDnfIdFromLiterals({ unit }, dnfId, literals)
    end
    return true
end


function reduceSatsAndMutateLiterals(cnf, units, literals)
    -- print("remove these: ")
    -- dump(units)
    -- dump(literals[4498])
    -- dump(cnf[16314])
    for _, unit in ipairs(units) do
        if not eliminateUnitFromDnfsAndLiterals(cnf, literals, unit) then
            return false
        end
    end
    return true
end
return reduceSatsAndMutateLiterals