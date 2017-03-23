return (terms, dnfId, literals) ->
    for term in *terms
        if term < 0
            table.removeValue literals[-term], dnfId
            table.removeValue literals[-term], -dnfId
        else
            table.removeValue literals[term], -dnfId
            table.removeValue literals[term], dnfId
