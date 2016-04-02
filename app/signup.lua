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
local json       = require "cjson"

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
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local user = generateUuid(1)
local pass = generateUuid(200)

local email, err = db:get("activate:" .. validData['token'])
if "string" ~= type(email) then
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.say("404 HTTP_NOT_FOUND")
    ngx.exit(ngx.status)
end

local login, err = db:get("email:" .. email)
if "string" == type(login) then
    ngx.status = 409
    ngx.say("409 HTTP_CONFLICT")
    ngx.exit(ngx.status)
end

local userData = {
    login   = user,
    pass    = pass,
    email   = email,
    url     = '',
    create  = os.date("%Y-%m-%d %H:%M:%S"),
}

local jsonErrorParse, data = pcall(json.encode, userData)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local ok, err = db:set("user:" .. user, data)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local ok, err = db:set("email:" .. email, user)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local ok, err = db:set("auth:" .. user, pass)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local ok, err = db:expire("auth:" .. user, 2592000)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

ngx.header["X-Accel-Redirect"] = "/send_activate/?action=account&to=" .. email .. "&user=" .. user .. "&pass=" .. pass .. "&host_cdn=" .. ngx.var.host_cdn .. "&host=" .. ngx.var.host_primary
