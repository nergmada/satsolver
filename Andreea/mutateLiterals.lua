function literalsMutation(literals, units)
    --copy the previous literals
    local newLiterals = table.copy(literals)
    --for each unit identified
    for _, unit in ipairs(units) do
        --if it's a negative unit'
        if (unit < 0) then
            --check the literals table to ensure that it is unset or set to false
            if newLiterals[-unit] == 0 or newLiterals[-unit] == false then
                --if so, set it to false
                newLiterals[-unit] = false
            else 
                --otherwise it must be set to true, producing a contradiction
                return nil
            end
        else
            --otherwise we've got a positive unit, check that it's unset or true
            if newLiterals[unit] == 0 or newLiterals[unit] == true then
                --set to true
                newLiterals[unit] = true
            else
                --otherwise we have a contradiction
                return nil
            end
        end
    end
    return newLiterals
end

return literalsMutation