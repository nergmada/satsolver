function getNextGuessedLiteral(literals)
    local nextLiteral, noOfAppearances = 0, 0
    for literal, value in pairs(literals) do
        if type(value) == "table" and (math.abs(#value) > noOfAppearances) then
            nextLiteral, noOfAppearances = literal, math.abs(#value)
        end
    end
    return nextLiteral, false
end
return getNextGuessedLiteral