--Load SAT file
local satFile = io.open("tests/sat_prob_3.cnf", "r")
--Read line from sat file
local line = satFile:read()
--Loop through lines until the start of the SAT formula is found (denoted by P)
while (line:sub(1, 1) ~= "p") do
    line = satFile:read()
end

--The first line contains details about SAT Formulae provided
local details = {}
--load details into the details table
for i in string.gmatch(line, "%S+") do
   table.insert(details, i)
end

local terms = {}
--EXPEDIENCIES: It might be computationally cheaper to shift terms into base 1 array and shift back
--to base zero for the result
for i = 0, tonumber(details[3]) do
    terms[i] = 0
end

--Create a table for all the clauses
local clauses = {}
--Start reading lines
line = satFile:read()

--EXPEDIENCIES: It might be computationally cheaper to identify pure literals here
--while there are still lines
while (line ~= nil) do
    --create a new individual clause table
    local clause = {}
    --add each term to it
    for term in string.gmatch(line, "%S+") do
        if (term ~= "0") then
            local unit = tonumber(term)
            table.insert(clause, unit)
            if (unit < 0) then
                terms[-unit] = terms[-unit] + 1
            else
                terms[unit] = terms[unit] + 1
            end
        end
    end
    --add the new clause to the clauses table
    table.sort(clause)
    if #clause ~= 0 then
        table.insert(clauses, clause)
    end
    --read a new line
    line = satFile:read()
end
-- throw an error if the clauses found don't match clauses specified'
if (#clauses ~= tonumber(details[4])) then
    error("clauses expected do not match clauses found")
end


return { clauses, terms }