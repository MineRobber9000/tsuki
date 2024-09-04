-- tsuki.repl: the actual REPL
local exports = {}
local pretty = require'tsuki.pretty'

-- Makes an environment for the REPL.
-- Metatable is reused.
local env__mt = {__index=_G}
local function make_env()
    return setmetatable({},env__mt)
end
exports.make_env = make_env

-- Prints a line to stderr.
local function printError(line)
    io.stderr:write(line,"\n")
end

-- Resolves an error object.
-- 1. If it's a string, use that.
-- 2. If it has a __tostring metamethod, use that.
-- 3. (error object is a <type> value)
local function resolveErrorObj(o)
    if type(o)=="string" then return o end
    if getmetatable(o) and getmetatable(o).__tostring then
        local s = getmetatable(o).__tostring(o)
        if type(s)=="string" then return s end
    end
    return string.format("(error object is a %s value)",type(o))
end

-- Takes in a line of input after a prompt.
-- Can be replaced by replacing exports.input
function exports.input(prompt)
    io.write(prompt)
    local line = io.read("l")
    if line==nil then io.write('\n') end
    return line
end

-- Detects if the code included is incomplete.
-- This is rudimentary, but it works for the Lua standalone REPL so it works
-- for me!
-- Basically, premature EOF is almost always an error ending in "<eof>" so we
-- can just check for that
local function incomplete(err)
    return err:find("<eof>$")
end

-- Takes in extra lines until we have complete Lua code.
-- Returns same as loadinput (see below).
local function multiline(env, first_line)
    local lines = {first_line, n=1}
    while true do
        local line = exports.input(env._PROMPT2 or "... ")
        -- If the user presses ^D on a continuation line, just hand them the
        -- EOF error.
        if line==nil then
            local _, err = load(table.concat(lines,"\n"),"=stdin","t",env)
            return false, err
        end
        lines[lines.n+1]=line
        lines.n=lines.n+1
        local func, err = load(table.concat(lines,"\n"),"=stdin","t",env)
        if func then return true, func end
        if not incomplete(err) then return false, err end
    end
end

-- Takes in a first line of input and tries to compile it.
-- Returns `true, <function>` if compilation works, `false, <error message>`
-- if compilation fails, or `nil` if the user pressed ^D.
local function loadinput(env)
    local line = exports.input(env._PROMPT or ">>> ")
    if line==nil then return end
    local func = load(string.format("return %s;",line),"=stdin","t",env)
    if func then return true, func end
    local func, err = load(line,"=stdin","t",env)
    if func then return true, func end
    if incomplete(err) then return multiline(env, line) end
    return false, err
end

-- Does one iteration of the REPL.
-- Returns false if the REPL should exit, true otherwise.
local function doREP(env)
    local ok, func_or_err = loadinput(env)
    if ok then
        local results = table.pack(xpcall(func_or_err,function(err)
            local tb = debug.traceback(err,2)
            local i = tb:find("\n\t%[C%]: in function 'xpcall'")
            if not i then return tb end
            return tb:sub(1,i).."\t[C]: in ?"
        end))
        if results[1] then
            if results.n>1 then
                print(pretty.pretty(table.unpack(results,2,results.n)):layout(
                    env._COLOR
                ))
            end
        else
            printError(resolveErrorObj(results[2]))
        end
    elseif ok==nil then
        return false
    else
        printError(tostring(func_or_err))
    end
    return true
end

-- Does the REPL.
-- Basically, make an env (or use a provided one) and repeatedly call
-- doREP(env) until doREP says to stop.
local function doREPL(env)
    local env = env or make_env()
    local running = true
    while running do
        running = doREP(env)
    end
end
exports.doREPL = doREPL

return exports