return (dnf, unit) ->
    matches = table.search dnf, unit
    if matches and #matches > 0
        table.removeValue dnf, unit
        return true
    else
        table.removeValue dnf, -unit
        if #dnf ~= 0 then false else nil