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
local auth       = require "imega.auth"
local strlib     = require "imega.string"
local json       = require "cjson"

local headers = ngx.req.get_headers()

if strlib.empty(headers["Authorization"]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local matchPiece = ngx.re.match(headers["Authorization"], "Basic\\s(.+)")

if strlib.empty(matchPiece[1]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local credentials = base64.decode(matchPiece[1])
credentials = strlib.split(credentials, ":")

local credentials = {
    login = credentials[1],
    pass  = credentials[2]
}

local validatorCredentials = validation.new{
    login = validation.string.trim:len(36,36),
    pass  = validation.string.trim:len(36,36)
}

local isValid, values = validatorCredentials(credentials)
if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local db = redis:new()
db:set_timeout(1000)
local ok, err = db:connect(ngx.var.redis_ip, ngx.var.redis_port)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end

if not auth.authenticate(db, validData["login"], validData["pass"]) then
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say("403")
    ngx.exit(ngx.status)
end

ngx.req.read_body()
local body = ngx.req.get_body_data()

local jsonErrorParse, data = pcall(json.decode, body)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local validatorItem = validation.new{
    sku_article_barcode   = validation.boolean,
    show_kode_good        = validation.boolean,
    good_discription_file = validation.boolean,
    show_fullname_good    = validation.boolean
}

local isValid, values = validatorItem(data)
if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400")
    ngx.exit(ngx.status)
end

local validParams = values("valid")

local jsonError, jsonData = pcall(json.encode, validParams)
if not jsonError then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500")
    ngx.exit(ngx.status)
end

local ok, err = db:set("settings:" .. validData["login"], jsonData)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    ngx.exit(ngx.status)
end
