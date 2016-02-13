# Not working yet!

# colyseus.lua [![Join the chat at https://gitter.im/gamestdio/colyseus](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/gamestdio/colyseus?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

CoronaSDK/LUA client for [colyseus](https://github.com/gamestdio/colyseus) - a
Minimalistic MMO Game Server.

## Usage

```lua
local colyseus = require('colyseus')

local client = colyseus.connect('ws://localhost:2657');
local roomName = "room_name"
local room = client:join(roomName)

room:on('join', function()
  print(client.id, "joined", roomName)
  room:send({ message = "I'm connected!" })
end)

room:on('error', function()
  print(client.id, "couldn't join", roomName)
end)

room:on('leave', function()
  print(client.id, "leaved", roomName)
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

## License

MIT
