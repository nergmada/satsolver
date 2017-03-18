function reduceSats(cnf, units)
    --Creating a new set of CNF
    local newCnf = {}
    --For each DNF clause
    for _, dnf in ipairs(cnf) do
        --if the clause is not equal to 1 
        if (#dnf ~= 1) then
            --Create a new DNF of it
            local newDnf = {}
            --Create a skip boolean to skip the DNF if it's satisified
            local skipDnf = false
            --Loop through each term in the dnf
            for _, term in ipairs(dnf) do
                --create a skip boolean to skip the term if it's already false
                local skipTerm = false
                --For each unit clause found
                for _, unit in ipairs(units) do
                    --check if it matches the term (if it does then the entire dnf is true)
                    if (term == unit) then
                        --set skip this dnf to true
                        skipDnf = true
                        --break loop
                        break
                        --if it's the negated of the unit, then just skip this term in the dnf
                    elseif (term == -unit) then
                        --skip term is true
                        skipTerm = true
                        --break the loop 
                        break
                    end
                end
                --if we're to skip the entire dnf then break'
                if skipDnf == true then
                    break
                end
                --if we're not to skip this term, then add it to the new dnf'
                if not skipTerm then
                    table.insert(newDnf, term)
                end
            end
            --if we're not to skip this dnf then add it to the new cnf
            if not skipDnf then
                table.insert(newCnf, newDnf) 
            end 
        end
    end
    return newCnf
end

return reduceSats