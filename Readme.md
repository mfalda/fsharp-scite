##fsharp-scite

In this repository there is an alpha-quality SciTE extension for ScriptManager and a F# properties file for syntax and other commands.


## Features

- Syntax highlighting
- Auto completions (only sketched but still not working)
- Error highlighting in the code and error list in output panel
- Tooltips with type signatures
- Go to declaration
- F# Interactive (REPL) Panel
- Usages (only sketched but still not working)
- Type signatures in the stripbar
- Compile FS files and invoke FSX scripts


## Screenshot

![fsharp-scite](https://github.com/mfalda/fsharp-scite/blob/master/ss.png)


## Installation

Copy all files in SciTE folder and then set the Lua startup script to ScriptManager:
```
ext.lua.startup.script=$(SciteDefaultHome)/ScriptManager.lua 
ext.lua.script.directory=$(SciteDefaultHome)/scite_lua
```


## Usage

The current extension will parse the current file whenever saved (<kbd>Ctrl+s</kbd>). Errors will be listed in the output panel and the relative line can be easily reached in the code by double-clicking on them; errors will also be underlined in the code. Once correctly parsed, it will be possible to jump to the definition of a symbol (<kbd>Alt+f</kbd>) and inspect its type signature (<kbd>Alt+t</kbd>). Usages and completions are still not working (help is welcome). To compile a `fs` file hit <kbd>Ctrl+F7</kbd>, to run it or a`fsx` script hit <kbd>F5</kbd>.


## Still missing

- Greater stability
- Working usages and completions commands
- F# Interactive (REPL) Panel
- Highligh usages


## Contributing and copyright

The project is hosted on [GitHub](https://github.com/fsharp-scite).

The library is available under [Q public license](https://github.com/fsharp-scite/blob/master/License.md).


### Maintainer

- [@mfalda](https://github.com/mfalda)
