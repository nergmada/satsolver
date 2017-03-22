--Configure require settings
local handle = io.popen('cd')
local executePath = handle:read()
package.path = executePath .. '\\?.lua;' .. executePath .. '\\?\\init.lua;' .. package.path
--create a global dump function so that we can spit out sets
VERBOSE_PRINT = true

function verbosePrint(input)
    if VERBOSE_PRINT then
        print(input)
    end
end

dump = require('utils.pretty')
stringify = require('utils.stringifySat')
table.copy = require('utils.copy')
table.search = require('utils.search')
table.removeValue = require('utils.remove')


local data = require('loadSat')

-- dump(data[2])

local solver = require('solver')

local result = solver(data[1], data[2])
if true then
    if result then
        local result = ''
        for literal, value in ipairs(data[2]) do
            if value == true then
                result = result .. literal .. ' -> T, '
            elseif value == false then
                result = result .. literal .. ' -> F, '
            end
        end
        print(result)
        print("SATISIFIABLE")
    else
        print("UNSATISFIABLE")
    end
else
    print("UNKNOWN")
end