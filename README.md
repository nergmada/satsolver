# ANDA SAT Solver
If you want to understand how this code works, open the init.lua file, scroll to the bottom
and find the function titled ```anda(disjunctions)``` (P.S. to the person whom knows why I named it Anda, love ya)

the way lua is interpreted is just like C++ this means that all the dependency functions have to be written
or declared before they are called. Hence, the actual solver i.e. the code that you would want to call
is at the bottom.

I have also provided a file called repl.lua 

If you go to repl.it and select the lua language on the site, in theory this single file
should run on the repl.it website.

Does this SAT Solver work? Good question, answer: I think so. If it doesn't for you, file an
issue on this repo