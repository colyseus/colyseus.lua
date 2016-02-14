local EventEmitter = require('colyseus.events').EventEmitter
local protocol = require('colyseus.protocol')

Room = {}
Room.__index = Room

function Room.create(client, name)
  local room = EventEmitter:new({
    id = nil,
    state = {}
  })
  setmetatable(room, Room)
  room:init(client, name)
  return room
end

function Room:init(client, name)
  self.client = client
  self.name = name

  -- remove all listeners on leave
  self:on('leave', self.off)
end

function Room:leave()
  if this.id >= 0 then
    self.client.send({ protocol.LEAVE_ROOM, self.id })
  end
end

function Room:send (data)
  self.client:send({ protocol.ROOM_DATA, self.id, data })
end

return Room
