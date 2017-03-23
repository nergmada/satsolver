executionPath = (io.popen 'cd')\read!
package.path = executionPath .. '\\?.lua;' .. executionPath .. '\\?\\init.lua;' .. package.path

table.copy = require 'utils.copy'
table.search = require 'utils.search' 
table.removeValue = require 'utils.remove'

export dump = require 'utils.pretty'
export stringify = require 'utils.stringifySat'
export verbosePrint = require 'utils.debug'

data = require 'loadSat'
solver = require 'solver'

result = solver data[1], data[2]
if true
    if result
        result = ''
        for literal, value in ipairs data[2]
            if value == true
                result = result .. literal .. ' -> T, '
            elseif value == false
                result = result .. literal .. ' -> F, '
        print result
        print "SATISFIABLE"
    else
        print "UNSATISFIABLE"
else
    print "UNKNOWN"