A Lua REPL in the console with autocompletion and pretty-printing of returned tables. It lets you test mpv's and Lua's API without writing a script.

It is bound to `Ctrl+r` by default, and you can bind a different key to `script-binding lua-repl`.

`return` is automatically inserted before statements when doing so does not break them.

`--script-opt=lua_repl-persist_history=yes` will save the history to disk.
