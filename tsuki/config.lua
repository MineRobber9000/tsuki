-- tsuki.config: Configuration for the REPL
local utils = require"tsuki.utils"
local config = {}

config.DEFAULT_CONFIG = {
    -- Prompt for normal input
    PROMPT = ">>> ";
    -- Prompt for more input (i.e; continuation)
    PROMPT2 = "... ";
    -- Whether to use color or not
    COLOR = (not not (os.getenv'TERM' or ''):find("color$"));
    -- Ran before the REPL begins
    preinit = function(env) end;
    -- Ran before the REPL exits
    atexit = function(env) end;
}

local seen = {}
local function merge(t1,t2)
    local out = {}
    for k, v in pairs(t1) do
        out[k]=v
    end
    if t2==nil then return out end
    for k, v in pairs(t2) do
        out[k]=v
    end
    return out
end

config.CONFIG = merge(config.DEFAULT_CONFIG,{})

local _findconfig
function config.findconfig()
    if not _findconfig then
        _findconfig = utils.searchfor("tsuki.lua",utils.configdirs(),"file")
    end
    return _findconfig
end

function config.load()
    local path = config.findconfig()
    if not path then
        config.CONFIG = merge(config.DEFAULT_CONFIG,{})
        return
    end
    local fh <close> = io.open(path,"r")
    local script = fh:read("a")
    fh:close()
    local returnvalue = assert(load(script,"@"..path,"t",_ENV))()
    assert(type(returnvalue)=="table" or returnvalue==nil,"Config must return table (returned "..type(returnvalue)..")")
    config.CONFIG = merge(config.DEFAULT_CONFIG,returnvalue)
end

function config.get(key,default)
    local returnvalue = config.CONFIG[key]
    if returnvalue==nil then return default end
    return returnvalue
end

return config
