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
local strlib     = require "imega.string"

local headers = ngx.req.get_headers()

if strlib.empty(headers["Authorization"]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST");
    ngx.exit(ngx.status)
end

local matchPiece = ngx.re.match(headers["Authorization"], "Basic\\s(.+)")

if strlib.empty(matchPiece[1]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("400 HTTP_BAD_REQUEST");
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
    ngx.say("400 HTTP_BAD_REQUEST");
    ngx.exit(ngx.status)
end

local validData = values("valid")

if '9915e49a-4de1-41aa-9d7d-c9a687ec048d' ~= validData['login'] then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("401 HTTP_UNAUTHORIZED");
    ngx.exit(ngx.status)
end

if '8c279a62-88de-4d86-9b65-527c81ae767a' ~= validData['pass'] then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("401 HTTP_UNAUTHORIZED");
    ngx.exit(ngx.status)
end

ngx.status = ngx.HTTP_OK
ngx.say("200 Ok");
ngx.exit(ngx.status)
