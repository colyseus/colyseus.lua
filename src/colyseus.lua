local ev = require('ev')
local websocket = require('websocket.client')
local msgpack = require('MessagePack')
local protocol = require('protocol')
local Room = require('room')

Colyseus = {}
Colyseus.__index = Colyseus

function Colyseus.connect (endpoint)
  local instance = {}
  setmetatable(instance, Colyseus)
  instance:init(endpoint)
  return instance
end

function Colyseus:init(endpoint)
  self.roomStates = {} -- object
  self.rooms = {} -- object
  self._enqueuedCalls = {} -- array

  self.ws = websocket.ev()

  self.ws:on_open(function()
    self:on_open()
 end)

  self.ws:connect(endpoint, 'echo')

  self.ws:on_message(function(ws, msg)
    self:on_message(ws, msg)
  end)

  local i = 0

  ev.Timer.new(function()
    i = i + 1
    -- self.ws:send('hello '..i)
  end,1,1):start(ev.Loop.default)

  ev.Loop.default:loop()
end

function Colyseus:on_open()
  print("Successfully connected! Enqueued calls:")
  print(self._enqueuedCalls)
  -- if self._enqueuedCalls.length > 0 then {
  --   for (var i=0; i<self._enqueuedCalls.length; i++) {
  --     let [ method, args ] = self._enqueuedCalls[i]
  --     self[ method ].apply(self, args)
  --   }
  -- }
end

function Colyseus:send(data)
  return self.ws:send( msgpack.pack(data) )
end

function Colyseus:join (roomName, options)
  if not self.rooms[ roomName ] then
    self.rooms[ roomName ] = Room.create(self, roomName)
  end

  if self.ws.readyState == WebSocket.OPEN then
    self.send({ protocol.JOIN_ROOM, roomName, options or {} })

  else
    -- WebSocket not connected.
    -- Enqueue it to be called when readyState == OPEN
    self._enqueuedCalls.push({'join', arguments})
  end

  return self.rooms[ roomName ]
end

function Colyseus:on_message(ws, msg)
  local message = msgpack.unpack( msg )

  if type(message[0]) == "number" then
    local roomId = message[1]

    if message[0] == protocol.USER_ID then
      self.id = message[1]

      if self.listeners['onopen'] then
        self.listeners['onopen'].apply(null)
      end
      return true

    elseif (message[0] == protocol.JOIN_ROOM) then
      -- joining room from room name:
      -- when first room message is received, keep only roomId association on `rooms` object
      if self.rooms[ message[2] ] then
        self.rooms[ roomId ] = self.rooms[ message[2] ]
        delete self.rooms[ message[2] ]
      end
      self.rooms[ roomId ].id = roomId
      self.rooms[ roomId ].emit('join')
      return true

    elseif (message[0] == protocol.JOIN_ERROR) then
      self.rooms[ roomId ].emit('error', message[2])
      delete self.rooms[ roomId ]
      return true

    elseif (message[0] == protocol.LEAVE_ROOM) then
      self.rooms[ roomId ].emit('leave')
      return true

    elseif (message[0] == protocol.ROOM_STATE) then
      let roomState = message[2]

      self.rooms[ roomId ].state = roomState
      self.rooms[ roomId ].emit('update', roomState)

      self.roomStates[ roomId ] = roomState
      return true

    elseif (message[0] == protocol.ROOM_STATE_PATCH) then
      self.rooms[ roomId ].emit('patch', message[2])
      jsonpatch.apply(self.roomStates[ roomId ], message[2])
      self.rooms[ roomId ].emit('update', self.roomStates[ roomId ], message[2])

      return true

    elseif (message[0] == protocol.ROOM_DATA) then
      self.rooms[ roomId ].emit('data', message[2])
      message = [ message[2] ]
    end

  end

  -- if (self.listeners['onmessage']) self.listeners['onmessage'].apply(null, message)
end


return Colyseus
