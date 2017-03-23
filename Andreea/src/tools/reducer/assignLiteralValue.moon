return (literals, unit) ->
    if unit < 0
        if (type literals[-unit]) == 'table'
            dnfIds, literals[-unit] = literals[-unit], false
            return dnfIds, false
        elseif literals[-unit] == true
            return {}, true
        else
            return {}, false
    else
        if (type literals[unit]) == 'table'
            dnfIds, literals[unit] = literals[unit], true
            return dnfIds, false
        elseif literals[unit] == true
            return {}, true
        else
            return {}, false