assignLiteralValue = require 'tools.reducer.assignLiteralValue'
removeUnitFromCnf = require 'tools.reducer.removeUnitFromCnf'
removeDnfsFromLiteralsTable = require 'tools.reducer.removeDnfsFromLiteralsTable'

removeUnitFromDnfAndLiterals = (dnfs, literals, unit) ->
    dnfIds, contradiction = assignLiteralValue literals, unit
    if contradiction then return false
    for dnfId in *dnfIds
        satisfied = (
            if dnfId < 0 then (removeUnitFromCnf dnfs[-dnfId], unit) else removeUnitFromCnf dnfs[dnfId], unit)
        if satisfied == nil then return false
        
        if satisfied
            if dnfId < 0
                removeDnfsFromLiteralsTable dnfs[-dnfId], dnfId, literals
                dnfs[-dnfId] = {}
            else
                removeDnfsFromLiteralsTable dnfs[dnfId], dnfId, literals
                dnfs[dnfId] = {}
        removeDnfsFromLiteralsTable { unit }, dnfId, literals
    return true

return (cnf, units, literals) ->
    for unit in *units
        unless removeUnitFromDnfAndLiterals cnf, literals, unit
            return false
    return true