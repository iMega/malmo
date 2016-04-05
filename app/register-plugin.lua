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
local base64     = require "kloss.base64"
local redis      = require "resty.redis"
local curl       = require "lcurl"
local json       = require "cjson"

ngx.req.read_body()
local body = ngx.req.get_body_data()

local jsonErrorParse, data = pcall(json.decode, body)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local validatorItem = validation.new{
    login = validation.string.trim:len(36,36),
    url   = validation:regex("^(https?:\\/\\/)?([\\da-z\\.-]+)(\\.([a-z\\.]{2,6}))?(:\\d+)?([\\/\\w \\.-]*)*$", "si"),
}

local isValid, values = validatorItem({
    login = ngx.var.login,
    url   = data['url'],
})

if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local redis_ip   = ngx.var.redis_ip
local redis_port = ngx.var.redis_port

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(redis_ip, redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local res, err = db:get("auth:" .. validData['login'])
if not res then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local credentials = base64.encode(validData['login'] .. ":" .. res)

local site = curl.easy()
    :setopt_url(validData['url'] .. '/teleport')
    :setopt_httpheader{
        "Authorization: Basic " .. credentials,
    }

local perform = function ()
    site:perform()
end

if not pcall(perform) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local codeResponse = site:getinfo_response_code()

site:close()

if not ngx.HTTP_OK == codeResponse then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST")
    ngx.exit(ngx.status)
end

local userData, err = db:get("user:" .. validData['login'])
if "string" ~= type(userData) then
    ngx.status = ngx.HTTP_NOT_FOUND
    ngx.say("404 HTTP_NOT_FOUND")
    ngx.exit(ngx.status)
end

local jsonErrorParse, data = pcall(json.decode, userData)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

data['url'] = validData['url']

local jsonErrorParse, data = pcall(json.encode, data)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

local ok, err = db:set("user:" .. validData['login'], data)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500 HTTP_INTERNAL_SERVER_ERROR")
    ngx.exit(ngx.status)
end

ngx.status = ngx.HTTP_OK
ngx.say("200 Ok")
ngx.exit(ngx.status)
