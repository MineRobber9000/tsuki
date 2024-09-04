-- tsuki.colors: Handy-dandy ANSI reference
local colors = {}

local function color(n)
    if not n then return "\27[0m" end
    return "\27[0;"..tostring(n).."m"
end

colors.RESET = color()
for i, name in ipairs{
    "BLACK", "RED", "GREEN", "YELLOW",
    "BLUE", "PURPLE", "CYAN", "WHITE"
} do
    colors[name] = color(29+i)
end

return colors