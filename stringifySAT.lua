function stringifySAT(cnfSAT)
    if type(cnfSAT) == 'table' then
        local result = ''
        for i = 1, #cnfSAT do
            if #cnfSAT[i] > 1 then
                result = result .. '('
            end
            
            for j = 1, #cnfSAT[i] do
                result = result .. cnfSAT[i][j]
                if j ~= #cnfSAT[i] then
                    result = result .. ' V '
                end
            end
            
            if #cnfSAT[i] > 1 then
                result = result .. ')'
            end
            if i ~= #cnfSAT then
                result = result .. ' /\\ '
            end
        end
        return result
    else
        return 'not a SAT'
    end
end

return stringifySAT