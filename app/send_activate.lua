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

require "resty.validation.ngx"
local validation = require "resty.validation"
local uuid       = require "tieske.uuid"
local redis      = require "resty.redis"

--
-- Generate token
--
-- @return string
--
local function generateToken()
    uuid.randomseed(os.time())
    return uuid()
end

local redis_ip   = ngx.var.redis_ip
local redis_port = ngx.var.redis_port

local validatorItem = validation.new{
    email = validation.string.trim.email
}

local isValid, values = validatorItem({
    email = ngx.var.email,
})
if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local token = generateToken()

local db = redis:new()
db:set_timeout(1000)

local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

local ok, err = db:set("activate:" .. token, validData['email'])
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

local ok, err = db:expire("activate:" .. token, 86400)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

ngx.header["X-Accel-Redirect"] = "/send_activate/?action=activate&to=" .. validData['email'] .. "&token=" .. token .. "&host_cdn=" .. ngx.var.host_cdn .. "&host=" .. ngx.var.host_primary
