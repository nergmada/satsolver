function removeValue(tbl, value)
    if type(tbl) == 'table' then
        local matchIndexes = table.search(tbl, value)
        if matchIndexes and #matchIndexes > 0 then
            table.remove(tbl, matchIndexes[1])
        else
            return false
        end
        return true
    end
    return false
end
return removeValue