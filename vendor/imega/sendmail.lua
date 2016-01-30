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


local function sslCreate()
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

local function sendMail(username, password, server, from, to, subject, body)
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
        server   = smtp.gmail.com,
        port     = 465,
        create   = sslCreate
    }

    return ok
end

return {
    send = auth,
    getToken     = getToken,
    checkToken   = checkToken,
    getLogin     = getLogin
}
