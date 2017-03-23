persistence = require 'utils.save'
snapshots, current, saves = {}, 0, 0

saveSnapshot = (cnf, literals, term, assignment, backtracked) ->
    newSnapshot = {
        table.copy(cnf),
        table.copy(literals),
        term,
        assignment,
        backtracked
    }
    snapshots[current + 1] = newSnapshot
    current = current + 1
    verbosePrint "adding snapshot #" .. current .. " page #" .. saves
    if current > 200
        persistence.store ('snapshot' .. saves .. '.lua'), [shots for shots in *snapshots[,200]]
        saves = saves + 1
        snapshots = { snapshots[201] }
        current = 1

retrieveLastSnapshot = ->
    if current > 0
        lastSnapshot = snapshots[current]
        snapshots[current] = nil
        current = current - 1
        return lastSnapshot
    elseif saves > 0
        snapshots = persistence.load 'snapshot' .. (saves - 1) .. '.lua'
        saves = saves - 1
        current = 200
        return retrieveLastSnapshot!
    verbosePrint "removing current snapshot #" .. current .. " page #" .. saves

hasSnapshots = ->
    return (current > 0) or (saves > 0)

return {
    saveSnapshot: saveSnapshot,
    retrieveSnapshot: retrieveLastSnapshot,
    hasSnapshots: hasSnapshots
}