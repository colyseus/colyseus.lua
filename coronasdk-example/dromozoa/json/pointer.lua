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

local function key_to_index(key)
  if key == "0" then
    return 1
  elseif key:match("^[1-9]%d*$") then
    return tonumber(key) + 1
  else
    return 0
  end
end

local function decode(escaped)
  if escaped == "~0" then
    return "~"
  elseif escaped == "~1" then
    return "/"
  else
    error "could not decode"
  end
end

local function tokenize(path)
  if #path == 0 then
    return {}
  else
    if not path:match("^/") then
      error "could not tokenize"
    end
    local result = {}
    for i in path:gmatch("/([^/]*)") do
      result[#result + 1] = i:gsub("~.", decode)
    end
    return result
  end
end

function evaluate(doc, token, n)
  local value = doc[1]
  for i = 1, n do
    if type(value) == "table" then
      local size = is_array(value)
      if size == nil then
        value = value[token[i]]
        if value == nil then
          return false
        end
      else
        local index = key_to_index(token[i])
        if 1 <= index and index <= size then
          value = value[index]
        else
          return false
        end
      end
    else
      return false
    end
  end
  return true, value
end

local function copy(value, depth)
  if depth > 16 then
    error "too much recursion"
  end
  if type(value) == "table" then
    local result = {}
    for k, v in pairs(value) do
      result[k] = copy(v, depth + 1)
    end
    return result
  else
    return value
  end
end

local function test(x, y, depth)
  if depth > 16 then
    error "too much recursion"
  end
  local t = type(x)
  if t == type(y) then
    if t == "table" then
      for k, v in pairs(x) do
        if not test(v, y[k], depth + 1) then
          return false
        end
      end
      for k, v in pairs(y) do
        if x[k] == nil then
          return false
        end
      end
      return true
    else
      return x == y
    end
  else
    return false
  end
end

return function (path)
  local self = {
    _token = tokenize(path);
  }

  function self:get(doc)
    local token = self._token
    return evaluate(doc, token, #token)
  end

  function self:put(doc, value)
    local token = self._token
    local n = #token
    if n == 0 then
      doc[1] = value
      return true
    end
    if doc[1] == nil then
      doc[1] = {}
    end
    local this = doc[1]
    for i = 1, n - 1 do
      if type(this) == "table" then
        local size = is_array(this)
        local key = token[i]
        if size == nil or size == 0 and key ~= "0" then
          if this[key] == nil then
            this[key] = {}
          end
          this = this[key]
        else
          local index = key_to_index(key)
          if 1 <= index and index <= size + 1 then
            if this[index] == nil then
              this[index] = {}
            end
            this = this[index]
          else
            return false
          end
        end
      else
        return false
      end
    end
    if type(this) == "table" then
      local key = token[n]
      local size = is_array(this)
      if size == nil or size == 0 and key ~= "0" then
        this[key] = value
        return true
      else
        local index = key_to_index(key)
        if 1 <= index and index <= size + 1 then
          this[index] = value
          return true
        else
          return false
        end
      end
    else
      return false
    end
  end

  function self:add(doc, value)
    local token = self._token
    local n = #token
    if n == 0 then
      doc[1], value = value, doc[1]
      return true, value
    end
    local a, b = evaluate(doc, token, n - 1)
    if a and type(b) == "table" then
      local key = token[n]
      local size = is_array(b)
      if size == nil or size == 0 and key ~= "0" and key ~= "-" then
        b[key], value = value, b[key]
        return true, value
      else
        local index
        if key == "-" then
          index = size + 1
        else
          index = key_to_index(key)
        end
        if 1 <= index and index <= size + 1 then
          for i = size, index, -1 do
            b[i + 1] = b[i]
          end
          b[index] = value
          return true
        else
          return false
        end
      end
    else
      return false
    end
  end

  function self:remove(doc)
    local token = self._token
    local n = #token
    if n == 0 then
      local value = doc[1]
      doc[1] = nil
      return true, value
    end
    local a, b = evaluate(doc, token, n - 1)
    if type(b) == "table" then
      local key = token[n]
      local size = is_array(b)
      if size == nil then
        local value = b[key]
        if value == nil then
          return false
        end
        b[key] = nil
        return true, value
      else
        local index = key_to_index(key)
        if 1 <= index and index <= size then
          local value = b[index]
          for i = index, size - 1 do
            b[i] = b[i + 1]
          end
          b[size] = nil
          return true, value
        else
          return false
        end
      end
    else
      return false
    end
  end

  function self:replace(doc, value)
    local a, b = self:remove(doc)
    if a then
      local c, d = self:add(doc, value)
      if c then
        assert(d == nil)
        return true, b
      else
        assert((from:add(doc, b)))
        return false
      end
    else
      return false
    end
  end

  function self:move(doc, from)
    local a, b = from:remove(doc)
    if a then
      local c, d = self:add(doc, b)
      if c then
        return true, d
      else
        assert((from:add(doc, b)))
        return false
      end
    else
      return false
    end
  end

  function self:copy(doc, from)
    local a, b = from:get(doc)
    if a then
      return self:add(doc, copy(b, 0))
    else
      return false
    end
  end

  function self:test(doc, value)
    local a, b = self:get(doc)
    if a then
      return test(b, value, 0)
    else
      return false
    end
  end

  return self
end
