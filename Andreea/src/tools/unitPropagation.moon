reducer = require 'tools.reducer'

return (cnf, literals) ->
    units = [dnf[1] for dnf in *cnf when #dnf == 1]
    if #units == 0
        return false, false
    table.sort units
    success = reducer cnf, units, literals
    unless success
        return true, true
    return true, false