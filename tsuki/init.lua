-- tsuki: Lua REPL
local VERSION = "v0.1"
local repl = require"tsuki.repl"
local config = require"tsuki.config"
local utils = require"tsuki.utils"

-- only replace input ourselves if the user didn't replace input before
local replace_input = true
if config.findconfig() then
    local _input = repl.input
    config.load()
    if repl.input~=_input then
        replace_input = false
    end
end

local keywords = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
    "true", "until", "while"
}
local env_completion -- will be set later
local function completion(text, from, to)
    local fragment = text:sub(from, to)
    local matches, n = {}, 1
    local function append(match)
        matches[n]=match
        n=n+1
    end
    for _, v in ipairs(keywords) do
        if v:sub(1,#fragment)==fragment then
            append(v)
        end
    end
    env_completion(fragment, append)
    return matches
end
local function set_completion_append_character() end

if replace_input then
    utils.ifhas("readline",function(RL)
        RL.set_options{
            completion = config.get("COMPLETION", true);
            keeplines = config.get("KEEPLINES", 500);
            histfile = config.get("HISTFILE",utils.default_history());
        }
        RL.set_readline_name'tsuki'
        RL.set_complete_function(completion)
        set_completion_append_character = RL.set_completion_append_character
        repl.input = RL.readline
        local atexit = config.CONFIG.atexit or function() end
        config.CONFIG.atexit = function(env)
            RL.save_history()
            return atexit(env)
        end
    end,function()
        -- TODO: linenoise
    end)
end

return function()
    local env = repl.make_env()
    env._PROMPT = config.get("PROMPT")
    env._PROMPT2 = config.get("PROMPT2")
    env._COLOR = config.get("COLOR")
    function env_completion(fragment, append)
        local setchar = false
        local sep = fragment:find("[.:]")
        if not sep then
            for k in pairs(env) do
                if k:sub(1,#fragment)==fragment then
                    append(k)
                    if not setchar then
                        set_completion_append_character''
                        setchar = true
                    end
                end
            end
            for k in pairs(getmetatable(env).__index) do
                if k:sub(1,#fragment)==fragment then
                    append(k)
                    if not setchar then
                        set_completion_append_character''
                        setchar = true
                    end
                end
            end
        else
            -- First, what we're indexing.
            local tbl = fragment:sub(1,sep-1)
            -- Also, grab the separator char while we're here.
            local sepc = fragment:sub(sep,sep)
            -- If it doesn't exist, we're done.
            if not env[tbl] then return end
            -- If it isn't a table or some type with __index and __pairs, we're
            -- done.
            if type(env[tbl])~="table" and not (
                getmetatable(env[tbl]) and getmetatable(env[tbl]).__index
                and getmetatable(env[tbl]).__pairs
            ) then
                append("not a table")
                return
            end
            -- Next, what we're indexing with.
            local keyfragment = fragment:sub(sep+1)
            -- If it's nested, we're done.
            if keyfragment:find("[.:]") then return end
            -- All keys in the table itself.
            if type(env[tbl])=="table" or
                (getmetatable(env[tbl]) or {}).__pairs then
                for k in pairs(env[tbl]) do
                    if k:sub(1,#keyfragment)==keyfragment then
                        append(tbl..sepc..k)
                        if not setchar then
                            set_completion_append_character''
                            setchar = true
                        end
                    end
                end
            end
            -- Everything in the __index if it's a table
            local index = (getmetatable(env[tbl]) or {}).__index
            if index and type(index)=="table" then
                for k in pairs(index) do
                    if k:sub(1,#keyfragment)==keyfragment then
                        append(tbl..sepc..k)
                        if not setchar then
                            set_completion_append_character''
                            setchar = true
                        end
                    end
                end
            end
        end
    end
    print("Tsuki "..VERSION.." for ".._VERSION)
    config.get("preinit")(env)
    repl.doREPL(env)
    config.get("atexit")(env)
end