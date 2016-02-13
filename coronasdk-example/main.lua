-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
package.path = string.gsub(system.pathForFile('main.lua'), "main.lua", 'luarocks/share/lua/5.2/?.lua') .. ';' .. package.path
require("luarocks.loader")

local widget = require('widget')

-- local colyseus = require('colyseus')
-- local client = colyseus:connect('ws://localhost:2657')
-- local room = client:join("chat")
-- room:on('update', function(newState, patches)
--   print(newState)
--   print(patches)
-- end)

local inputHeight = 50
local input = native.newTextField( display.contentWidth / 2, display.contentHeight - (inputHeight*2), display.contentWidth - 32, inputHeight )
local submit = widget.newButton({
  top = display.contentHeight-inputHeight,
  id = "submit",
  label = "Send",
  labelAlign = "right",
  onEvent = function(e)
    if "ended" == e.phase then
      print("Clicked!")
    end
  end
})

-- Your code here
