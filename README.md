# colyseus.lua [![Join the chat at https://gitter.im/gamestdio/colyseus](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/gamestdio/colyseus?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

CoronaSDK/LUA client for [colyseus](https://github.com/gamestdio/colyseus) - a
Minimalist Multiplayer Game Server.

## Usage

There's a sample project on
[coronasdk-example](https://github.com/gamestdio/colyseus.lua/tree/master/coronasdk-example),
which connects to a simple [chat application
demo](https://github.com/endel/colyseus-react-example).

```lua
local colyseus = require('colyseus')

local client = colyseus.connect('ws://localhost:2657');
local roomName = "room_name"
local room = client:join(roomName)

client:on('open', function()
  print("connected successfully:", client.id)
end)

room:on('join', function()
  print(client.id, "joined", roomName)
  room:send({ message = "I'm connected!" })
end)

room:on('error', function()
  print(client.id, "couldn't join", roomName)
end)

room:on('leave', function()
  print(client.id, "left", roomName)
end)

room:on('data', function(data)
  print(client.id, "received on", roomName, data)
end)

room:on('patch', function(patches)
  print(roomName, "will apply these changes:", patches)
})

room:on('update', function(newState, patches)
  print(roomName, "new state:", newState, "changes applied:", patches)
end)
```

## Installation

You will need to let Corona play nice with `luarocks`, which is a powerful
package manager for the LUA programming language.

- Download and install
  [luarocks](https://github.com/keplerproject/luarocks/wiki/Download#installing).
- Install [luarocks](https://luarocks.org/modules/hisham/luarocks) package
  inside your source directory. (`luarocks install luarocks --tree=src/luarocks`)
- Install [colyseus](https://luarocks.org/modules/endel/colyseus) package inside
  your source directory. (`luarocks install colyseus --tree=src/luarocks`)
- Download and copy
  [dmc_corona](https://github.com/dmccuskey/dmc-websockets) into your
  source directory.
- Add [openssl](https://docs.coronalabs.com/plugin/openssl/) and
  [bit](https://docs.coronalabs.com/plugin/bit/) plugins to your project.
  (inside `build.settings` file, plugins section)

Add this little piece of code at the very top of your `main.lua` file:

```lua
-- Integration with luarocks
package.path = string.gsub(system.pathForFile('luarocks/bin/luarocks', system.ResourceDirectory), 'bin/luarocks', '') .. 'share/lua/5.2/?.lua' .. ';' .. package.path
require("luarocks.loader")
```

Finally, your source directory should look like this: (only relevant files)

```
▾ source-files/
  ▸ luarocks/
  ▸ dmc_corona/
    dmc_corona.cfg
    dmc_corona_boot.lua
    build.settings
    main.lua
```

**Dependencies**

- [dmc-websockets](https://github.com/dmccuskey/dmc-websockets)
- [dromozoa-json](https://github.com/dromozoa/dromozoa-json)
- [lua-messagepack](https://github.com/fperrad/lua-MessagePack)

## License

MIT
