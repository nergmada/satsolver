function recalculateHeuristic(cnf, literals)
    local noLiteralsUnassigned = true
    local newLiterals = {}
    for literal, value in ipairs(literals) do
        if type(value) == "number" then
            noLiteralsUnassigned = false
            newLiterals[literal] = 0
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
            local heuristic = 1
            if (#dnf == 2) then
                --Favour terms that if guessed result in unit literals
                heuristic = 2
            end
            if (term < 0) then
                if type(newLiterals[-term]) == "number" then
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