local skynet = require "skynet"

local Mailbox = {}
function Mailbox:ctor(args)
    self.addr = args and args.addr or 0
end

Mailbox.__index = function(t, k)
    if k == "pack" then
        return function()
            return {
                __class_name = t.__class_name,
                addr = t.addr
            }
        end
    elseif k == "unpack" then
        return function(m, data)
            if m ~= t then
                data = m
            end
            t.addr = data.addr
        end
    elseif k == "exit" then
        return function()
            skynet.kill(t.addr)
        end
    else
        return function(m, ...)
            if m == t then
                return skynet.call(t.addr, "xc", k, ...)
            else
                return skynet.call(t.addr, "xc", k, m, ...)
            end
        end
    end
end

function Mailbox:new(args)
    local o = {}
    setmetatable(o, self)
    Mailbox.ctor(o, args)
    o.__class_name = "mailbox"
    return o
end

return Mailbox