-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-json.
--
-- dromozoa-json is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-json is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-json.  If not, see <http://www.gnu.org/licenses/>.

local pointer = require "dromozoa.json.pointer"

return function (root, patch)
  local doc = { root }
  for i = 1, #patch do
    local v = patch[i]
    local op = v.op
    local result = false
    if op == "add" then
      result = pointer(v.path):add(doc, v.value)
    elseif op == "remove" then
      result = pointer(v.path):remove(doc)
    elseif op == "replace" then
      result = pointer(v.path):replace(doc, v.value)
    elseif op == "move" then
      result = pointer(v.path):move(doc, pointer(v.from))
    elseif op == "copy" then
      result = pointer(v.path):copy(doc, pointer(v.from))
    elseif op == "test" then
      result = pointer(v.path):test(doc, v.value)
    end
    if not result then
      return false, "coult not apply operation #" .. i
    end
  end
  return true, doc[1]
end
