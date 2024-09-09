-- tsuki.pretty: A pretty printer
-- based vaguely on "A prettier printer" by Philip Wadler
-- https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf
local pretty = {}
local colors = require"tsuki.colors"
pretty.indent = "    "

local Doc = {}
Doc.__index = Doc
pretty.Doc = Doc

function Doc:new(type,...)
    return setmetatable({type=type,...},self)
end

local doc_types = {}
pretty.types = doc_types
doc_types._nil = Doc:new("nil")
function doc_types.text(...)
    return Doc:new("text",...)
end
doc_types.line = Doc:new("line")
function doc_types.nest(i, doc)
    return Doc:new("nest",i,doc)
end
function doc_types.concat(lhs,rhs)
    if getmetatable(lhs)~=Doc then lhs=doc_types.text(tostring(lhs)) end
    if getmetatable(rhs)~=Doc then rhs=doc_types.text(tostring(rhs)) end
    if lhs.type=="nil" then
        return rhs
    end
    if lhs.type=="concat" then
        local returnvalue = Doc:new("concat", table.unpack(lhs))
        returnvalue[#returnvalue+1] = rhs
        return returnvalue
    end
    return Doc:new("concat",lhs,rhs)
end
Doc.__concat = doc_types.concat

function Doc:coalesce()
    if self.type=="nest" then
        self[2] = self[2]:coalesce()
        return self
    end
    if self.type~="concat" then return self end
    if #self==1 then return self[1] end
    for i=1, #self do
        if self[i].type=="concat" then
            local merged, n = {}, 1
            for j=1,i-1 do
                merged[n], n = self[j], n+1
            end
            for j=1,#self[i] do
                merged[n], n = self[i][j], n+1
            end
            for j=i+1,#self do
                merged[n], n = self[j], n+1
            end
            return Doc:new("concat",table.unpack(merged,1,n-1)):coalesce()
        else
            self[i]=self[i]:coalesce()
        end
    end
    return self
end

function Doc:layout(color)
    if self.type=="nil" then return "" end
    if self.type=="concat" then
        local s = ""
        for i=1,#self do
            s=s..self[i]:layout(color)
        end
        return s
    end
    if self.type=="text" then
        if #self>1 and color then
            return self[2]..self[1]..colors.RESET
        end
        return self[1]
    end
    if self.type=="line" then
        return "\n"
    end
    if self.type=="nest" then
        local i, doc = table.unpack(self)
        local indent = string.rep(pretty.indent,i)
        local s = ""
        for line in (doc:layout(color).."\n"):gmatch("(.-)\n") do
            s = s .. indent .. line .. "\n"
        end
        return s:sub(1,-2)
    end
end

local function _keys_sort(a,b)
    local typea, typeb = type(a), type(b)

    if typea=="string" then
        return typeb~="string" or a<b
    elseif typea=="number" then
        return typeb~="number" or a<b
    else
        return false
    end
end

local function _pretty(val, tracking)
    if tracking then
        tracking = setmetatable({},{__index=tracking})
    else
        tracking = {}
    end
    if type(val)=="string" then
        local quoted = string.format("%q", val)
            :gsub([[\7]],[[\a]])
            :gsub([[\8]],[[\b]])
            :gsub([[\12]],[[\f]])
            :gsub("\\\n",[[\n]])
            :gsub([[\13]],[[\r]])
            :gsub([[\9]],[[\t]])
            :gsub([[\11]],[[\v]])
        return doc_types.text(quoted,colors.RED)
    end
    if type(val)=="number" then
        return doc_types.text(tostring(val),colors.PURPLE)
    end
    if type(val)=="table" and not tracking[val] then
        tracking[val]=true
        local doc = doc_types._nil
        local val_n = #val
        local keys, keysn = {}, 1
        for k in pairs(val) do
            if type(k)~="number" or k%1~=0 or k<1 or k>val_n then
                keys[keysn], keysn = k, keysn+1
            end
        end
        table.sort(keys,_keys_sort)
        for i=1,keysn-1 do
            local k, v = keys[i], val[keys[i]]
            tracking[k]=true
            doc = doc .. (doc_types.text("[")
                .. _pretty(k,tracking)
                .. doc_types.text("] = ")
                .. _pretty(v,tracking)
                .. doc_types.text(",")
                .. doc_types.line):coalesce()
            tracking[k]=nil
        end
        for i=1,val_n do
            doc = doc .. (_pretty(val[i],tracking)
                .. doc_types.text(",")
                .. doc_types.line):coalesce()
        end
        if doc.type=="nil" then
            return doc_types.text"{}"
        end
        last = doc[#doc].type=="concat" and doc[#doc] or doc
        last[#last]=nil last[#last]=nil
        return (doc_types.text("{")
            ..doc_types.line
            ..doc_types.nest(1,doc)
            ..doc_types.line
            ..doc_types.text("}")):coalesce()
    end
    if type(val)=="function" then
        local info = debug.getinfo(val,"Su")
        if not info then return doc_types.text(tostring(val), colors.gray) end
        local doc
        if info.short_src and info.linedefined and info.linedefined>=1 then
            doc = doc_types.text(("function<%s:%d>"):format(info.short_src, info.linedefined), colors.gray)
        else
            doc = doc_types.text(tostring(val),colors.gray)
        end
        if info.what=="Lua" and info.nparams then
            local args = {}
            for i=1,info.nparams do args[i]=debug.getlocal(val, i) or "?" end
            if info.isvararg then table.insert(arg,"...") end
            doc = doc .. doc_types.text("(" .. table.concat(args, ", ") .. ")", colors.gray)
        end
        return doc
    end
    return doc_types.text(tostring(val),colors.gray)
end

function pretty.pretty(...)
    local args = table.pack(...)
    local doc = doc_types._nil
    for i=1,args.n do
        doc = doc .. _pretty(args[i])
        if i<args.n then doc = doc .. doc_types.line end
    end
    return doc
end

return pretty