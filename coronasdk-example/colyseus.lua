local WebSocket = require('dmc_corona.dmc_websockets')

local protocol = require('colyseus.protocol')
local room = require('colyseus.room')
local EventEmitter = require('colyseus.events').EventEmitter

local msgpack = require('MessagePack')
local json = require('dromozoa.json.pure')
local patch = require('dromozoa.json.patch')

Colyseus = {}
Colyseus.__index = Colyseus

function Colyseus.connect (endpoint)
  local instance = EventEmitter:new({
    id = nil ,
    roomStates = {}, -- object
    rooms = {}, -- object
    _enqueuedCalls = {}, -- array
  })
  setmetatable(instance, Colyseus)
  instance:init(endpoint)
  return instance
end

function Colyseus:init(endpoint)
  self.ws = WebSocket({ uri = endpoint })
  self.ws:addEventListener(self.ws.EVENT, function(event)
    local evt_type = event.type

    if evt_type == self.ws.ONOPEN then
      for i,cmd in ipairs(self._enqueuedCalls) do
        local method = self[ cmd[1] ]
        local arguments = cmd[2]
        method(self, unpack(arguments))
      end

    elseif evt_type == self.ws.ONMESSAGE then
      self:on_message(event.message.data)

    elseif evt_type == self.ws.ONCLOSE then
      self:emit('close', event)

    elseif evt_type == self.ws.ONERROR then
      self:emit('error', event)

    end
  end)
end

function Colyseus:close()
  self.ws:close()
end

function Colyseus:send(data)
  if self.ws.readyState == WebSocket.ESTABLISHED then -- same as WebSocket.OPEN in JavaScript
    self.ws:send( msgpack.pack(data), {
      type = WebSocket.BINARY
    } )

  else
    -- WebSocket not connected.
    -- Enqueue data to be sent when readyState == OPEN
    table.insert(self._enqueuedCalls, {'send', {data}})
  end
end

function Colyseus:join(...)
  local args = {...}

  local roomName = args[1]
  local options = args[2]

  if not self.rooms[ roomName ] then
    self.rooms[ roomName ] = room.create(self, roomName)
  end

  self:send({ protocol.JOIN_ROOM, roomName, options or {} })

  return self.rooms[ roomName ]
end

function Colyseus:on_message(msg)
  local message = msgpack.unpack( msg )

  if type(message[1]) == "number" then
    local roomId = message[2]

    if message[1] == protocol.USER_ID then
      self.id = message[2]
      self:emit('open')
      return true

    elseif (message[1] == protocol.JOIN_ROOM) then
      -- joining room from room name:
      -- when first room message is received, keep only roomId association on `rooms` object
      if self.rooms[ message[3] ] then
        self.rooms[ roomId ] = self.rooms[ message[3] ]
        self.rooms[ message[3] ] = nil
        -- delete self.rooms[ message[3] ]

      end
      self.rooms[ roomId ].id = roomId
      self.rooms[ roomId ]:emit('join')
      return true

    elseif (message[1] == protocol.JOIN_ERROR) then
      self.rooms[ roomId ]:emit('error', message[3])
      table.remove(self.rooms, roomId)
      -- delete self.rooms[ roomId ]
      return true

    elseif (message[1] == protocol.LEAVE_ROOM) then
      self.rooms[ roomId ]:emit('leave')
      return true

    elseif (message[1] == protocol.ROOM_STATE) then
      local roomState = message[3]

      self.rooms[ roomId ].state = roomState
      self.rooms[ roomId ]:emit('update', roomState)

      self.roomStates[ roomId ] = roomState
      return true

    elseif (message[1] == protocol.ROOM_STATE_PATCH) then
      self.rooms[ roomId ]:emit('patch', message[3])
      patch(self.roomStates[ roomId ], message[3])
      self.rooms[ roomId ]:emit('update', self.roomStates[ roomId ], message[3])

      return true

    elseif (message[1] == protocol.ROOM_DATA) then
      self.rooms[ roomId ]:emit('data', message[3])
      message = { message[3] }
    end

  end

  self:emit('message', message)
end

return Colyseus
