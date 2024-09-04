-- tsuki.utils: utility functions
local utils = {}
local lfs = require"lfs"

utils.DIR_SEP = package.config:sub(1,1)

function utils.remove_dir_sep(s)
    return (s:gsub(utils.DIR_SEP.."+$",''))
end

function utils.ensure_dir_sep(s)
    return utils.remove_dir_sep(s)..utils.DIR_SEP
end

function utils.searchfor(file,paths,mode)
    for i=1, #paths do
        local path = utils.ensure_dir_sep(paths[i])..file
        if lfs.attributes(path,'mode')==mode then
            return path
        end
    end
    return nil
end

function utils.configdirs()
    if utils.DIR_SEP=="/" then
        local xdg_config_home = os.getenv'XDG_CONFIG_HOME' or utils.ensure_dir_sep(os.getenv'HOME')..".config"
        local xdg_config_dirs = os.getenv'XDG_CONFIG_DIRS' or '/etc/xdg'
        local configdirs = {xdg_config_home}
        for path in string.gmatch(xdg_config_dirs,"[^:]+") do
            configdirs[#configdirs+1]=path
        end
        return configdirs
    else
        error("NYI: tsuki.utils.configdirs on non-Unix")
    end
end

function utils.default_history()
    if utils.DIR_SEP=="/" then
        local data_home = os.getenv'XDG_DATA_HOME' or utils.ensure_dir_sep(os.getenv'HOME')..".local/share"
        return utils.ensure_dir_sep(data_home).."tsukihistory"
    else
        error("NYI: tsuki.utils.default_history on non-Unix")
    end
end

local function getchar()
    return io.read(1)
end

local rawmode__mt = {__close=function() os.execute("stty -raw echo") end}
local function rawmode()
    os.execute("stty raw -echo")
    return setmetatable({},rawmode__mt)
end

utils.DEFAULT_COLS = 80

function utils.termcols()
    if utils.DIR_SEP=="/" then
        local saveterm <close> = rawmode()
        io.write("\027[s\027[999A\027[999C\027[6n")
        if getchar()~="\027" then return utils.DEFAULT_COLS end
        if getchar()~="[" then return utils.DEFAULT_COLS end
        local s = ""
        local c = getchar()
        while c~="R" do
            s=s..c
            c=getchar()
        end
        local _,_,cols = string.find(s,";(%d+)$")
        io.write("\027[u")
        return tonumber(cols)
    else
        error("NYI: tsuki.utils.termsize on non-Unix")
    end
end

function utils.ifhas(modname,then_,else_)
    local ok, mod = pcall(require,modname)
    if ok then return then_(mod) else else_() end
end

return utils