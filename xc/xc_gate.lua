local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local cmsgpack =  require "cmsgpack"

local handler = {}

local clients = {}

function handler.connect(fd, addr)
    skynet.error("new connect:", fd, addr)
    clients[fd] = {
        addr = addr,
        agent = nil
    }

    gateserver.openclient(fd)
end

function handler.disconnect(fd)
    local client = clients[fd]
    if client and client.agent then
        skynet.call(client.agent, "lua", "disconnect")
    end

    skynet.error("disconnect")
end

function handler.message(fd, msg, sz)
    local str = netpack.tostring(msg, sz)
    local data = cmsgpack.unpack(str)
    local sessionId, funcName = data[1], data[2]
    str = table.unpack(data[3])
    skynet.error("recv message from fd", sessionId, funcName, str)

    local pack_str, len_str = cmsgpack.packex({sessionId, funcName, table.pack(string.upper(str))})
    socketdriver.send(fd, len_str)
    socketdriver.send(fd, pack_str)
end

gateserver.start(handler)