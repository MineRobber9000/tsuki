# tsuki

A REPL for Lua. Built for my own use, but maybe you can use it too?

Requires luafilesystem. Can support readline.

## Installation

```
luarocks-5.4 make
```

It's that easy :tm: !

## Configuration

The configuration file is located in `tsuki.lua`, which is itself located in one of the XDG config dirs (typically `~/.config`). It's a Lua script running in the _ENV of tsuki itself, and it's expected to return a table with some keys and values.

Some meaningful keys:
 - `PROMPT`: the prompt used for the first line of input (default: `">>> "`)
 - `PROMPT2`: the prompt used for consecutive lines of input (default: `"... "`)
 - `COLOR`: whether or not to use color when printing results (default: `true` if the value of `$TERM` ends with `color`, `false` otherwise)
 - `preinit`: a function ran before the REPL begins, with access to the REPL's env (the env new code will be run in; default: empty function)
 - `atexit`: a function ran before the REPL exits, with access to the REPL's env (see above; default: empty function)

In addition, you can `require("tsuki.repl")` and replace the `input` function there; if you don't do that, tsuki will try and help you out:
 - If the `readline` library is available, the REPL will use it; uses more config keys:
     - `COMPLETION`: whether to use completion (default: `true`)
     - `KEEPLINES`: how many lines to keep in the file (default: `500`)
     - `HISTFILE`: the history file to use (default: `$XDG_DATA_HOME/tsukihistory`)
 - (PLANNED) If the `linenoise` library is available, the REPL will use it.

