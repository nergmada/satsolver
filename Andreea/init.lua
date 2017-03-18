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

dump = require('pretty')
stringify = require('stringifySat')
table.copy = require('copy')


local data = require('loadSat')

local solver = require('solver')


local result = solver(data[1], data[2])
if true then
    if result then
        print("SATISIFIABLE")
    else
        print("UNSATISFIABLE")
    end
else
    print("UNKNOWN")
end