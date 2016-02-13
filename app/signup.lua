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
local redis      = require "resty.redis"
local uuid       = require "tieske.uuid"

local redis_ip   = ngx.var.redis_ip
local redis_port = ngx.var.redis_port

--
-- Generate token
--
-- @return string
--
local function generateUuid(step)
    uuid.randomseed(os.time() * step)
    return uuid()
end

local validatorItem = validation.new{
    token = validation.string.trim:len(36,36),
}

local isValid, values = validatorItem({
    token = ngx.var.token,
})

if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

local user = generateUuid(1)
local pass = generateUuid(200)

local email, err = db:get("activate:" .. validData['token'])
if not email then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

local ok, err = db:set("auth:" .. user, pass)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

local ok, err = db:expire("auth:" .. user, 2592000)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

ngx.header["X-Accel-Redirect"] = "/send_activate/?action=account&to=" .. email .. "&user=" .. user .. "&pass=" .. pass .. "&host_cdn=" .. ngx.var.host_cdn .. "&host=" .. ngx.var.host_primary
