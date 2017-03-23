return (literals) ->
    nextLiteral, noOfAppearance = 0, 0
    for literal, value in pairs literals
        if (type value) == 'table' and #value > noOfAppearance
            nextLiteral, noOfAppearance = literal, #value
    return nextLiteral, false