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

local floor = math.floor

return function (t)
  local m = 0
  local n = 0
  for k, v in pairs(t) do
    if type(k) == "number" and k > 0 and floor(k) == k then
      if m < k then m = k end
      n = n + 1
    else
      return nil
    end
  end
  if m <= n * 2 then
    return m
  else
    return nil
  end
end
