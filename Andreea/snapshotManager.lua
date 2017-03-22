local snapshots, current = {}, 0

function saveSnapshot(cnf, literals, term, assignment, backtracked)
    local newSnapshot = { table.copy(cnf), table.copy(literals), term, assignment, backtracked}
    snapshots[current + 1] = newSnapshot
    current = current + 1
    if current > 200 then
        verbosePrint("WARNING: Saving memory by dropping earliest snapshot")
        table.remove(snapshots, 1)
        current = current - 1
    end
end

function retrieveLastSnapshot()
    if current > 0 then
        local lastSnapshot = snapshots[current]
        snapshots[current] = nil
        current = current - 1
        return lastSnapshot
    end
end

function hasSnapshots()
    return (current <= 0)
end

return { 
    saveSnapshot = saveSnapshot,
    retrieveSnapshot = retrieveLastSnapshot,
    hasSnapshots = hasSnapshots
 }