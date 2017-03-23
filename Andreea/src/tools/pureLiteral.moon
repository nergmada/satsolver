reducer = require 'tools.reducer'

return (cnf, literals) ->
    pureLiterals = {}
    for literal, dnfs in ipairs literals
        if type(dnfs) == 'table' and #dnfs > 0
            table.sort dnfs
            if dnfs[1] > 0
                table.insert pureLiterals, literal
            elseif dnfs[#dnfs] < 0
                table.insert pureLiterals, -literal
    if #pureLiterals == 0
        return false, false
    table.sort pureLiterals
    success = reducer cnf, pureLiterals, literals
    unless success
        return true, true
    return true, false