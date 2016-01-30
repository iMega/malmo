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

local inspect   = require 'inspect'

require "resty.validation.ngx"
local validation = require "resty.validation"
local json   = require 'cjson'
local socket = require 'socket'
local smtp   = require 'socket.smtp'
local ssl    = require 'ssl'
local https  = require 'ssl.https'
local ltn12  = require 'ltn12'

local username = ngx.var.username
local password = ngx.var.password
local server   = ngx.var.server

ngx.req.read_body()
local body = ngx.req.get_body_data()

local jsonErrorParse, data = pcall(json.decode, body)
if not jsonErrorParse then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("4001")
    ngx.exit(ngx.status)
end

local validatorItem = validation.new{
    to = validation.string.trim.email
}

local isValid, values = validatorItem(data)
if not isValid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("4002")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local jsonError, jsonData = pcall(json.encode, validData)
if not jsonError then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("500")
    ngx.exit(ngx.status)
end

function sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            local r, e = sock:connect(host, port)
            if not r then return r, e end
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            return sock:dohandshake()
        end
    }, {
        __index = function(t,n)
            return function(_, ...)
                return sock[n](sock, ...)
            end
        end
    })
end

function sendMail(username, password, server, from, to, subject, body)
    local msg = {
        headers = {
            to      = to,
            subject = subject
        },
        body = body
    }

    local ok, err = smtp.send {
        from     = from,
        rcpt     = to,
        source   = smtp.message(msg),
        user     = username,
        password = password,
        server   = server,
        port     = 465,
        create   = sslCreate
    }
    ngx.say(inspect(err))
    return ok
end
ngx.say("dome")
ngx.say(inspect(sendMail("irvis@imega.ru", "kjk", "smtp.gmail.com", "<irvis@imega.ru>", "<info@imega.ru>", "test", "body test")))

