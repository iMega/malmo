--
-- Copyright (C) 2015 iMega ltd Dmitry Gavriloff (email: info@imega.ru),
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--

-- Determine whether a variable is empty
--
-- @return bool
--
local function empty(value)
    return value == nil or value == ''
end

-- Split string
-- @todo https://github.com/openresty/lua-nginx-module/issues/217
--
-- @return table
--
local function split(value, inSplitPattern, outResults)
    if not outResults then
        outResults = {}
    end
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find(value, inSplitPattern, theStart)
    while theSplitStart do
        table.insert(outResults, string.sub(value, theStart, theSplitStart-1))
        theStart = theSplitEnd + 1
        theSplitStart, theSplitEnd = string.find(value, inSplitPattern, theStart)
    end
    table.insert(outResults, string.sub(value, theStart))

    return outResults
end

return {
    empty = empty,
    split = split
}
