--This allows me to pull files from inside the same directory, because, lua being lua,
--it's not as simple as just oh require this please
local handle = io.popen('cd')
local executePath = handle:read()
package.path = executePath .. '\\?.lua;' .. executePath .. '\\?\\init.lua;' .. package.path
--ALLOWS REQUIRE function to work

--require the stringifySAT function (a function for stringifying SAT formulas)
local stringifySAT = require('stringifySAT')
--require the additional table functions (we have to shallow copy because lua passes by ref)
require('table')
--Just a useful script for pretty printing
local pretty = require('pretty').dump


--A SAT formula in CNF is a set of conjuncted disjunctive clauses
--in this code to create for example A /\ (¬B V C) /\ (D V F)
--we write
local exampleDisjunctions = {
    {'A'},
    {'-B', 'C'},
    {'D', 'F'}
}
--As many terms as desired can be added to any clause But no guarantees on performance are made

local testDisjunctions = {
    {'A'}, 
    {'-A'}
}



function simplifyClauses(disjunctions, partialAssignment)
    local nextDisjunctions = {}
    --for each disjunction
    for _, disjunction in ipairs(disjunctions) do 
        --assume we are going to add this disjunction to the new set of disjunctions
        local addDisjunction = true
        --assume that this new disjunction is empty though
        local newDisjunction = {}
        --for each clause literal in the previous disjunction
        for _, clauseLiteral in ipairs(disjunction) do
            --check if it's a negative literal
            local _, _, negatedLiteral = string.find(clauseLiteral, '-(%a)')
            --if it's a negative literal
            if negatedLiteral then
                --check if the partial assignment is nil
                if partialAssignment[negatedLiteral] == 0 then
                    --if it is then insert the clauseLiteral into the new disjunction
                    table.insert(newDisjunction, clauseLiteral)
                --otherwise, if it is not nil and the partialAssignment for this positive version of this negated literal is false
                --i.e. if this clauseLiteral is -A then the negatedLiteral will be A
                elseif partialAssignment[negatedLiteral] ~= 0 and partialAssignment[negatedLiteral] == false then
                    --then don't add this disjunction because -False = True making this disjunction true
                    addDisjunction = false
                end
            else 
                --check if the partial assignment is nil
                if partialAssignment[clauseLiteral] == 0 then
                    --if it is then insert the clauseLiteral into the new disjunction
                    table.insert(newDisjunction, clauseLiteral)
                --otherwise, if it is not nil and the partialAssignment for this positive version of this negated literal is false
                --i.e. if this clauseLiteral is -A then the negatedLiteral will be A
                elseif partialAssignment[clauseLiteral] ~= 0 and partialAssignment[clauseLiteral] == true then
                    --then don't add this disjunction because -False = True making this disjunction true
                    addDisjunction = false
                end
            end
        end
        --if the addDisjunction is still true
        if addDisjunction then
            --and there are literals in said disjunction
            if #newDisjunction > 0 then
                --then add it to the set of nextDisjunctions
                table.insert(nextDisjunctions, newDisjunction)
            else 
                --if there aren't literals this means all literals evaluated to false
                -- hence return false because the entire disjunction is false
                return false
            end
        end
    end
    return nextDisjunctions
end

--takes a conjunction of disjunctions and pulls all the terms in it (negative get mapped to positive)
--i.e. ¬A V B V C becomes {A = 0, B = 0, C = 0}
function pullTerms(disjunctions)
    --create an empty set
    local terms = {}
    --loop through the disjunctions
    for _, disjunction in ipairs(disjunctions) do
        --loop through the terms in the current disjunction
        for _, term in ipairs(disjunction) do 
            --pull out the term using a regex
            local _, _, literal = string.find(term, '-*(%a)')
            --Set it to zero
            terms[literal] = 0
        end
    end
    --return the set of terms
    return terms
end

function satsolver(disjunctions, partialAssignment)
    --if no disjunctions left then return true and print the partial assignment
    if #disjunctions == 0 then
        --print the partial assignments
        pretty(partialAssignment)
        --return true
        return true
    end
    local noUnitPropagation, noLiteralElimination = true, true
    --loop through all disjunctions looking for disjunctions with a single literal
    for _, disjunction in ipairs(disjunctions) do
        --if the disjunctive clause is a single literal
        if #disjunction == 1 then
            --evaluate if the literal has a negative dash before it
            local _, _, negativeLiteral = string.find(disjunction[1], '-(%a)')
            --if a value has been found for the negativeliteral
            if negativeLiteral then
                --check if it already exists in our partial assignment and if that assignment is true
                if partialAssignment[negativeLiteral] ~= 0 and partialAssignment[negativeLiteral] == true then
                    --if the partial assignment exists and it's contradictory return false'
                    return false
                else
                    --if the partial assignment doesn't exist or it's in agreement assign false
                    partialAssignment[negativeLiteral] = false
                end
            --else if no negative literal found
            else
                --then it's a positive literal check that it's partial assignment isn't already false
                if partialAssignment[disjunction[1]] ~= 0 and partialAssignment[disjunction[1]] == false then
                    --if the partial assignment is false, then it's a contradiction
                    return false
                --otherwise if not assigned or not contradictory, assign it
                else
                    partialAssignment[disjunction[1]] = true
                end
            end
            --There has been a unit propagation, so this is false
            noUnitPropagation = false
        end
    end
    --simplifies the clauses (see function...)
    local nextDisjunctions = simplifyClauses(disjunctions, partialAssignment)
    --if the simplifyFunction returns false, it means it's found a contradiction
    if not nextDisjunctions then
        --so we return false also
        return false
    end
    --a table containing a count of positive and negative terms i.e.
    -- positiveTerms = {'A': 0, 'B': 2, 'C': 1} negativeTerms = {'A': 2, 'B': 1, 'C': 2}
    --implies a pure literal of negative A
    local positiveTerms, negativeTerms = {}, {}

    --loop through all disjunctions
    for _, disjunction in ipairs(nextDisjunctions) do
        --if the disjunction has more than one term (don't need to run this for single terms as they are unit literals)
        if #disjunction > 1 then
            --loop through clause literals in each disjunction
            for _, clauseLiteral in ipairs(disjunction) do
                --check to see if the clause literal is negated
                local _, _, negatedLiteral = string.find(clauseLiteral, '-(%a)')
                --if the clause literal is a negative literal
                if negatedLiteral then
                    --check to see if the literal is already in the negative terms set
                    if not negativeTerms[negatedLiteral] then
                        --initialise value in negative term set
                        negativeTerms[negatedLiteral] = 0
                    end
                    --check to see if the literal is already in the positive terms set
                    if not positiveTerms[negatedLiteral] then
                        --initial value in positive term set
                        positiveTerms[negatedLiteral] = 0
                    end
                    --increase the count of this literal in the negativeTerms set
                    negativeTerms[negatedLiteral] = negativeTerms[negatedLiteral] + 1
                --else if it's a positive literal
                else
                    --check to see if the literal is already in the negative terms set
                    if not negativeTerms[clauseLiteral] then
                        --initialise value in the negative term set
                        negativeTerms[clauseLiteral] = 0
                    end
                    --check to see if the literal is already in the positive terms set
                    if not positiveTerms[clauseLiteral] then
                        --initialise in the positive term set
                        positiveTerms[clauseLiteral] = 0
                    end
                    --increase count in positive term set by one of the given literal
                    positiveTerms[clauseLiteral] = positiveTerms[clauseLiteral] + 1
                end
            end
        end
    end
    --for all terms and count of those terms in the positive term set 
    for term, count in pairs(positiveTerms) do
        --if the count is greater than zero and the corresponding negative term is not found in any disjunction
        if count > 0 and negativeTerms[term] == 0 then
            --check to see if a partial assignment exists and contradicts the desired assignment
            if partialAssignment[term] ~= 0 and partialAssignment[term] == false then
                --if it does then return false
                return false
            else
                --otherwise partially assign positive (as only positive literals were found)
                partialAssignment[term] = true
            end
            --there has been a literal elimination so this false
            noLiteralElimination = false
        --else if the count of positive literals was zero and the count of corresponding negative literals was greater than zero
        elseif count == 0 and negativeTerms[term] > 0 then
            --check to see if a partial assignment already exists and if it does, does it contradict the assignment we want to make
            if partialAssignment[term] ~= 0 and partialAssignment[term] == true then
                --if it does contradict then return false
                return false
            else
                --otherwise perform the partial assignment
                partialAssignment[term] = false
            end
            --there has been a literal elimination so this is false
            noLiteralElimination = false
        end
    end
    --if no literal elimination or unit propagation took place in this round
    -- then we play a game of potluck
    if noLiteralElimination and noUnitPropagation then
        --create variable for our lucky random term to be assigned
        local chosenUnassignedVariable = nil
        --loop through all the terms
        for term, value in pairs(partialAssignment) do
            --find the first unassigned one (i.e. one equalling zero)
            if value == 0 then
                --set chosenUnassignedVariable to that found term
                chosenUnassignedVariable = term
                --break the loop
                break
            end
        end
        --if there are no unassigned variables, then we can return true because we've got a solution
        if chosenUnassignedVariable == nil then
            --pretty print the assignments and return true
            pretty(partialAssignment)
            return true
        end
        --let's assume our random variable to be true first
        partialAssignment[chosenUnassignedVariable] = true
        --run sat solver on the this new partial assignment including our guess
        --(NB we do table.shallow_copy because lua likes to be efficient and not duplicate tables)
        if satsolver(disjunctions, table.shallow_copy(partialAssignment)) then
            --if satsolver returns true then the recursive call seems to think it's solved it
            --if this is the case then return true
            return true 
        end
        --if the previous assignment was unsuccessful (i.e. it didn't return)
        --reassign the term to be false this time
        partialAssignment[chosenUnassignedVariable] = false
        --if sat solver returns true for this assignment
        if satsolver(disjunctions, table.shallow_copy(partialAssignment)) then
            --then return true
            return true
        end
        --A contradiction exists if we cannot solve for either term A or -A (where A is our randomly chosenUnassignedVariable)
        --So return false
        return false
        --in the event UnitPropagation or LiteralElimination have taken place
    else
        --let's simplify the clauses one more time
        local recDisjunctions = simplifyClauses(nextDisjunctions, partialAssignment)
        --if we simplified and find a contradiction
        if not recDisjunctions then
            --return false because we hate contradictions
            return false
        end
        --otherwise, shallow copy the partial assignment table and run satsolver
        satsolver(recDisjunctions, table.shallow_copy(partialAssignment))
    end
end

function anda(disjunctions)
    print('Annoying NerDy Acronym - Adam Green - 2017')
    print("The Disjunction you've provided:")
    print(stringifySAT(testDisjunctions))
    if not satsolver(disjunctions, pullTerms(disjunctions)) then
        print('unable to solve, probably contradictory')
    end
end

anda(testDisjunctions)
