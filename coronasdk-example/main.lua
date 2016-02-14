-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
package.path = string.gsub(system.pathForFile('main.lua'), "main.lua", 'luarocks/share/lua/5.2/?.lua') .. ';' .. package.path
require("luarocks.loader")

local widget = require('widget')
local colyseus = require('colyseus')

-- create UI for sending / viewing messages
local inputHeight = 50
local input = native.newTextField( display.contentWidth / 2, display.contentHeight - (inputHeight*2), display.contentWidth - 32, inputHeight )
input.placeholder = "(message)"

local messageBox = native.newTextBox(  display.contentWidth / 2, display.contentHeight / 2 - inputHeight, display.contentWidth - 32, display.contentHeight / 2 )
messageBox.isEditable = false

-- instantiate colyseus client
local client = colyseus.connect('ws://localhost:2657')

-- join chat room
local room = client:join("chat")

-- listen to room updates
room:on('update', function(newState, patches)
  if not patches then
    print('== new state ==', newState['messages'])
    for k, message in pairs(newState['messages']) do
      messageBox.text = message .. "\n" .. messageBox.text
    end

  else
    print('== patched state ==', patches)

    for i, patch in pairs(patches) do
      if patch['op'] == 'add' then
        messageBox.text = patch['value'] .. "\n" .. messageBox.text
      end
    end

  end
end)

-- submit button
local submit = widget.newButton({
  top = display.contentHeight-inputHeight,
  id = "submit",
  label = "Send",
  labelAlign = "right",
  onEvent = function(e)
    if "ended" == e.phase and input.text ~= "" then
      room:send(input.text)
      input.text = ""
    end
  end
})
