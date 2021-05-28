local skynet = require "skynet"
skynet = require "skynet.manager"
local xc = require "xc.def"
local mailbox = require "service.mailbox"

function xc.newservice(name, ...)
    local addr = skynet.newservice(name, ...)
    return mailbox:new({addr = addr})
end

function xc.exit()
    return skynet.exit()
end

function xc.register(name)
    return skynet.register('.' .. name)
end

return xc