--set satfile to nil
satFile = nil
if arg[1] then satFile = io.open 'tests/sat_prob_1.cnf', 'r' else error 'no file specified'
print arg[1]
--loop through file until we find the p definition line
line = satFile\read!
while (line\sub 1, 1) ~= 'p' do line = satFile\read!
--get details out of the details string
details = [detail for detail in string.gmatch line, '%S+']
--create a new list of all terms
terms = [{} for term = 1, tonumber details[3]]
--Loop through each line, convert to a dnf and record it's position in the literals table
line = satFile\read!
clauses = {}
while line ~= nil
    clause = {}
    for term in string.gmatch(line, '%S+')
        if term ~= '0'
            unit = tonumber(term)
            table.insert clause, unit
            if unit < 0
                table.insert terms[-unit], -(#clauses + 1)
            else
                table.insert terms[unit], (#clauses + 1)
    table.sort clause
    unless #clause == 0
        table.insert clauses, clause
    line = satFile\read!
--for any terms which have no corresponding DNFs set to nil
terms = [(if dnfs == 0 then nil else dnfs) for _, dnfs in ipairs terms]
--as long as the clauses equal number expected, close the file and return
unless #clauses ~= tonumber details[4]
    satFile\close!
    return { clauses, terms }
--error if we haven't returned'
error "clauses expected do not match number found"