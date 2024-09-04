package = "tsuki"
version = "dev-1"
source = {
   url = "git://github.com/MineRobber9000/tsuki"
}
description = {
   summary = "A REPL for Lua. Built for my own use, but maybe you can use it too?",
   detailed = "A REPL for Lua. Built for my own use, but maybe you can use it too?",
   homepage = "https://github.com/MineRobber9000/tsuki",
   license = "MIT"
}
dependencies = {
	"lua >= 5.4, < 5.5",
	"luafilesystem >= 1.8, < 2.0"
}
build = {
   type = "builtin",
   modules = {
      ["tsuki.colors"] = "tsuki/colors.lua",
      ["tsuki.config"] = "tsuki/config.lua",
      ["tsuki.init"] = "tsuki/init.lua",
      ["tsuki.pretty"] = "tsuki/pretty.lua",
      ["tsuki.repl"] = "tsuki/repl.lua",
      ["tsuki.utils"] = "tsuki/utils.lua"
   },
   install = {
      bin = {
         "bin/tsuki"
      }
   }
}
