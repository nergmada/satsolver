--stringify a SAT formula
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

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--- Pretty-printing Lua tables.
-- Also provides a sandboxed Lua table reader and
-- a function to present large numbers in human-friendly format.
--
-- Dependencies: `pl.utils`, `pl.lexer`, `pl.stringx`, `debug`
-- @module pl.pretty

local append = table.insert
local concat = table.concat
local mfloor, mhuge, mtype = math.floor, math.huge, math.type
local utils = nil
local lexer = nil
local debug = nil
local quote_string = nil
local assert_arg = nil

local original_tostring = tostring

-- Patch tostring to format numbers with better precision
-- and to produce cross-platform results for
-- infinite values and NaN.
local function tostring(value)
    if type(value) ~= "number" then
        return original_tostring(value)
    elseif value ~= value then
        return "NaN"
    elseif value == mhuge then
        return "Inf"
    elseif value == -mhuge then
        return "-Inf"
    elseif (_VERSION ~= "Lua 5.3" or mtype(value) == "integer") and mfloor(value) == value then
        return ("%d"):format(value)
    else
        local res = ("%.14g"):format(value)
        if _VERSION == "Lua 5.3" and mtype(value) == "float" and not res:find("%.") then
            -- Number is internally a float but looks like an integer.
            -- Insert ".0" after first run of digits.
            res = res:gsub("%d+", "%0.0", 1)
        end
        return res
    end
end

local pretty = {}

local function save_global_env()
    local env = {}
    env.hook, env.mask, env.count = debug.gethook()
    debug.sethook()
    env.string_mt = getmetatable("")
    debug.setmetatable("", nil)
    return env
end

local function restore_global_env(env)
    if env then
        debug.setmetatable("", env.string_mt)
        debug.sethook(env.hook, env.mask, env.count)
    end
end

--- Read a string representation of a Lua table.
-- This function loads and runs the string as Lua code, but bails out
-- if it contains a function definition.
-- Loaded string is executed in an empty environment.
-- @string s string to read in `{...}` format, possibly with some whitespace
-- before or after the curly braces. A single line comment may be present
-- at the beginning.
-- @return a table in case of success.
-- If loading the string failed, return `nil` and error message.
-- If executing loaded string failed, return `nil` and the error it raised.
function pretty.read(s)
    assert_arg(1,s,'string')
    if s:find '^%s*%-%-' then -- may start with a comment..
        s = s:gsub('%-%-.-\n','')
    end
    if not s:find '^%s*{' then return nil,"not a Lua table" end
    if s:find '[^\'"%w_]function[^\'"%w_]' then
        local tok = lexer.lua(s)
        for t,v in tok do
            if t == 'keyword' and v == 'function' then
                return nil,"cannot have functions in table definition"
            end
        end
    end
    s = 'return '..s
    local chunk,err = utils.load(s,'tbl','t',{})
    if not chunk then return nil,err end
    local global_env = save_global_env()
    local ok,ret = pcall(chunk)
    restore_global_env(global_env)
    if ok then return ret
    else
        return nil,ret
    end
end

--- Read a Lua chunk.
-- @string s Lua code.
-- @tab[opt] env environment used to run the code, empty by default.
-- @bool[opt] paranoid abort loading if any looping constructs a found in the code
-- and disable string methods.
-- @return the environment in case of success or `nil` and syntax or runtime error
-- if something went wrong.
function pretty.load (s, env, paranoid)
    env = env or {}
    if paranoid then
        local tok = lexer.lua(s)
        for t,v in tok do
            if t == 'keyword'
                and (v == 'for' or v == 'repeat' or v == 'function' or v == 'goto')
            then
                return nil,"looping not allowed"
            end
        end
    end
    local chunk,err = utils.load(s,'tbl','t',env)
    if not chunk then return nil,err end
    local global_env = paranoid and save_global_env()
    local ok,err = pcall(chunk)
    restore_global_env(global_env)
    if not ok then return nil,err end
    return env
end

local function quote_if_necessary (v)
    if not v then return ''
    else
        --AAS
        if v:find ' ' then v = quote_string(v) end
    end
    return v
end

local keywords

local function is_identifier (s)
    return type(s) == 'string' and s:find('^[%a_][%w_]*$') and not keywords[s]
end

local function quote (s)
    if type(s) == 'table' then
        return pretty.write(s,'')
    else
        --AAS
        return quote_string(s)-- ('%q'):format(tostring(s))
    end
end

local function index (numkey,key)
    --AAS
    if not numkey then
        key = quote(key)
         key = key:find("^%[") and (" " .. key .. " ") or key
    end
    return '['..key..']'
end


---	Create a string representation of a Lua table.
-- This function never fails, but may complain by returning an
-- extra value. Normally puts out one item per line, using
-- the provided indent; set the second parameter to an empty string
-- if you want output on one line.
-- @tab tbl Table to serialize to a string.
-- @string[opt] space The indent to use.
-- Defaults to two spaces; pass an empty string for no indentation.
-- @bool[opt] not_clever Pass `true` for plain output, e.g `{['key']=1}`.
-- Defaults to `false`.
-- @return a string
-- @return an optional error message
function pretty.write (tbl,space,not_clever)
    if type(tbl) ~= 'table' then
        local res = tostring(tbl)
        if type(tbl) == 'string' then return quote(tbl) end
        return res, 'not a table'
    end
    if not keywords then
        keywords = lexer.get_keywords()
    end
    local set = ' = '
    if space == '' then set = '=' end
    space = space or '  '
    local lines = {}
    local line = ''
    local tables = {}


    local function put(s)
        if #s > 0 then
            line = line..s
        end
    end

    local function putln (s)
        if #line > 0 then
            line = line..s
            append(lines,line)
            line = ''
        else
            append(lines,s)
        end
    end

    local function eat_last_comma ()
        local n,lastch = #lines
        local lastch = lines[n]:sub(-1,-1)
        if lastch == ',' then
            lines[n] = lines[n]:sub(1,-2)
        end
    end


    local writeit
    writeit = function (t,oldindent,indent)
        local tp = type(t)
        if tp ~= 'string' and  tp ~= 'table' then
            putln(quote_if_necessary(tostring(t))..',')
        elseif tp == 'string' then
            -- if t:find('\n') then
            --     putln('[[\n'..t..']],')
            -- else
            --     putln(quote(t)..',')
            -- end
            --AAS
            putln(quote_string(t) ..",")
        elseif tp == 'table' then
            if tables[t] then
                putln('<cycle>,')
                return
            end
            tables[t] = true
            local newindent = indent..space
            putln('{')
            local used = {}
            if not not_clever then
                for i,val in ipairs(t) do
                    put(indent)
                    writeit(val,indent,newindent)
                    used[i] = true
                end
            end
            for key,val in pairs(t) do
                local tkey = type(key)
                local numkey = tkey == 'number'
                if not_clever then
                    key = tostring(key)
                    put(indent..index(numkey,key)..set)
                    writeit(val,indent,newindent)
                else
                    if not numkey or not used[key] then -- non-array indices
                        if tkey ~= 'string' then
                            key = tostring(key)
                        end
                        if numkey or not is_identifier(key) then
                            key = index(numkey,key)
                        end
                        put(indent..key..set)
                        writeit(val,indent,newindent)
                    end
                end
            end
            tables[t] = nil
            eat_last_comma()
            putln(oldindent..'},')
        else
            putln(tostring(t)..',')
        end
    end
    writeit(tbl,'',space)
    eat_last_comma()
    return concat(lines,#space > 0 and '\n' or '')
end

--- Dump a Lua table out to a file or stdout.
-- @tab t The table to write to a file or stdout.
-- @string[opt] filename File name to write too. Defaults to writing
-- to stdout.
function pretty.dump (t, filename)
    if not filename then
        print(pretty.write(t))
        return true
    else
        return utils.writefile(filename, pretty.write(t))
    end
end

local memp,nump = {'B','KiB','MiB','GiB'},{'','K','M','B'}

local function comma (val)
    local thou = math.floor(val/1000)
    if thou > 0 then return comma(thou)..','.. tostring(val % 1000)
    else return tostring(val) end
end

--- Format large numbers nicely for human consumption.
-- @number num a number.
-- @string[opt] kind one of `'M'` (memory in `KiB`, `MiB`, etc.),
-- `'N'` (postfixes are `'K'`, `'M'` and `'B'`),
-- or `'T'` (use commas as thousands separator), `'N'` by default.
-- @int[opt] prec number of digits to use for `'M'` and `'N'`, `1` by default.
function pretty.number (num,kind,prec)
    local fmt = '%.'..(prec or 1)..'f%s'
    if kind == 'T' then
        return comma(num)
    else
        local postfixes, fact
        if kind == 'M' then
            fact = 1024
            postfixes = memp
        else
            fact = 1000
            postfixes = nump
        end
        local div = fact
        local k = 1
        while num >= div and k <= #postfixes do
            div = div * fact
            k = k + 1
        end
        div = div / fact
        if k > #postfixes then k = k - 1; div = div/fact end
        if k > 1 then
            return fmt:format(num/div,postfixes[k] or 'duh')
        else
            return num..postfixes[1]
        end
    end
end


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
        pretty.dump(partialAssignment)
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
            pretty.dump(partialAssignment)
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
