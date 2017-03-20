function recalculateHeuristic(cnf, literals)
    local noLiteralsUnassigned = true
    local newLiterals = {}
    for literal, value in pairs(literals) do
        if type(value) == 'table' then
            noLiteralsUnassigned = false
            newLiterals[literal] = {}
        else
            newLiterals[literal] = value
        end
    end
    if noLiteralsUnassigned then
        verbosePrint("No literal unassigned")
        return literals, false
    end

    for _, dnf in ipairs(cnf) do
        for _, term in ipairs(dnf) do
            if (term < 0) then
                if type(newLiterals[-term]) == "table" then
                    newLiterals[-term] = newLiterals[-term] + heuristic
                end
            else
                if type(newLiterals[term]) == "number" then
                    newLiterals[term] = newLiterals[term] + heuristic
                end
            end
        end
    end
    return newLiterals, true
end

return recalculateHeuristic