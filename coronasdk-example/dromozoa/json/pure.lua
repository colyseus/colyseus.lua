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

local is_array = require "dromozoa.json.is_array"
local utf8 = require "dromozoa.utf8"

local concat = table.concat
local format = string.format

local function encoder()
  local self = {
    _buffer = {};
  }

  function self:write(value)
    local buffer = self._buffer
    buffer[#buffer + 1] = value
  end

  function self:encode_string(value)
    local buffer = self._buffer
    buffer[#buffer + 1] = [["]]
    for p, c in utf8.codes(tostring(value)) do
      if c == 0x22 then
        buffer[#buffer + 1] = [[\"]]
      elseif c == 0x5C then
        buffer[#buffer + 1] = [[\\]]
      elseif c == 0x2F then
        buffer[#buffer + 1] = [[\/]]
      elseif c == 0x08 then
        buffer[#buffer + 1] = [[\b]]
      elseif c == 0x0C then
        buffer[#buffer + 1] = [[\f]]
      elseif c == 0x0A then
        buffer[#buffer + 1] = [[\n]]
      elseif c == 0x0D then
        buffer[#buffer + 1] = [[\r]]
      elseif c == 0x09 then
        buffer[#buffer + 1] = [[\t]]
      elseif c < 0x20 then
        buffer[#buffer + 1] = format([[\u%04X]], c)
      else
        buffer[#buffer + 1] = utf8.char(c)
      end
    end
    buffer[#buffer + 1] = [["]]
  end

  function self:encode_value(value, depth)
    if depth > 16 then
      error "too much recursion"
    end

    local t = type(value)
    if t == "number" then
      self:write(format("%.17g", value))
    elseif t == "string" then
      self:encode_string(value)
    elseif t == "boolean" then
      if value then
        self:write("true")
      else
        self:write("false")
      end
    elseif t == "table" then
      local size = is_array(value)
      if size == nil then
        self:write("{")
        local k, v = next(value)
        self:encode_string(k)
        self:write(":")
        self:encode_value(v, depth + 1)
        for k, v in next, value, k do
          self:write(",")
          self:encode_string(k)
          self:write(":")
          self:encode_value(v, depth + 1)
        end
        self:write("}")
      elseif size == 0 then
        self:write("[]")
      else
        self:write("[")
        self:encode_value(value[1], depth + 1)
        for i = 2, size do
          self:write(",")
          self:encode_value(value[i], depth + 1)
        end
        self:write("]")
      end
    else
      self:write("null")
    end
  end

  function self:encode(value)
    self:encode_value(value, 0)
    return concat(self._buffer)
  end

  return self
end

local function stack()
  local self = {
    _data = {};
    _size = 0;
  }

  function self:push(value)
    self._size = self._size + 1
    self._data[self._size] = value
  end

  function self:pop()
    assert(self._size > 0)
    local value = self._data[self._size]
    self._size = self._size - 1
    return value
  end

  function self:top()
    assert(self._size > 0)
    return self._data[self._size]
  end

  function self:size()
    return self._size
  end

  return self
end


local function decoder(s)
  local self = {
    _s = s;
    _i = 1;
    _stack = stack();
  }

  function self:scan(pattern)
    local i, j, a, b = self._s:find("^" .. pattern, self._i)
    if j == nil then
      return false
    else
      self._i = j + 1
      self._1 = a
      self._2 = b
      return true
    end
  end

  function self:scan_whitespace()
    return self:scan("[ \t\n\r]+")
  end

  function self:die()
    error("decode error at position " .. self._i)
  end

  function self:decode()
    self:decode_value()
    self:scan_whitespace()
    if self._stack:size() == 1 and self._i == #self._s + 1 then
      return self._stack:top()
    else
      self:die()
    end
  end

  function self:decode_value()
    self:scan_whitespace()
    if self:decode_literal()
    or self:decode_object()
    or self:decode_array()
    or self:decode_number()
    or self:decode_string() then
      return true
    else
      return false
    end
  end

  function self:decode_literal()
    if self:scan("true") then
      self._stack:push(true)
      return true
    elseif self:scan("false") then
      self._stack:push(false)
      return true
    elseif self:scan("null") then
      self._stack:push(nil)
      return true
    else
      return false
    end
  end

  function self:decode_object()
    if self:scan("{") then
      self._stack:push({})
      self:scan_whitespace()
      if self:scan("}") then
        return true
      end
      while self._i < #self._s do
        self:scan_whitespace()
        if not self:decode_string() then
          self:die()
        end
        self:scan_whitespace()
        if not self:scan(":") then
          self:die()
        end
        self:scan_whitespace()
        if not self:decode_value() then
          self:die()
        end
        self:scan_whitespace()
        if not self:scan("([,}])") then
          self:die()
        end
        local v = self._stack:pop()
        local n = self._stack:pop()
        self._stack:top()[n] = v
        if self._1 == "}" then
          return true
        end
      end
      self:die()
    else
      return false
    end
  end

  function self:decode_array()
    if self:scan("%[") then
      self._stack:push({})
      self:scan_whitespace()
      if self:scan("%]") then
        return true
      end
      local i = 1
      while self._i <= #self._s do
        self:scan_whitespace()
        if not self:decode_value() then
          self:die()
        end
        self:scan_whitespace()
        if not self:scan("([,%]])") then
          self:die()
        end
        local v = self._stack:pop()
        self._stack:top()[i] = v
        i = i + 1
        if self._1 == "]" then
          return true
        end
      end
      self:die()
    else
      return false
    end
  end

  function self:decode_number()
    local i = self._i
    if self:scan("%-?0") or self:scan("%-?[1-9]%d*") then
      self:scan("%.%d*")
      self:scan("[eE][%+%-]?%d+")
      self._stack:push(tonumber(self._s:sub(i, self._i - 1)))
      return true
    else
      return false
    end
  end

  function self:decode_string()
    if self:scan([["]]) then
      local buffer = {}
      while self._i <= #self._s do
        if self:scan([[([^"\]+)]]) then
          buffer[#buffer + 1] = self._1
        end
        if self:scan([["]]) then
          self._stack:push(concat(buffer))
          return true
        elseif self:scan([[\(["\/])]]) then
          buffer[#buffer + 1] = self._1
        elseif self:scan([[\b]]) then
          buffer[#buffer + 1] = "\b"
        elseif self:scan([[\f]]) then
          buffer[#buffer + 1] = "\f"
        elseif self:scan([[\n]]) then
          buffer[#buffer + 1] = "\n"
        elseif self:scan([[\r]]) then
          buffer[#buffer + 1] = "\r"
        elseif self:scan([[\t]]) then
          buffer[#buffer + 1] = "\t"
        elseif self:scan([[\u([Dd][89ABab]%x%x)\u([Dd][C-Fc-f]%x%x)]]) then
          local a = tonumber(self._1, 16) % 0x0400 * 0x0400
          local b = tonumber(self._2, 16) % 0x0400
          buffer[#buffer + 1] = utf8.char(a + b + 0x010000)
        elseif self:scan([[\u(%x%x%x%x)]]) then
          buffer[#buffer + 1] = utf8.char(tonumber(self._1, 16))
        else
          self:die()
        end
      end
      return true
    else
      return false
    end
  end

  return self
end

local function encode(value)
  return encoder():encode(value)
end

local function decode(s)
  return decoder(s):decode()
end

return {
  decode = decode;
  encode = encode;
}
