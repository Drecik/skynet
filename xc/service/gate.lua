local skynet = require "skynet"
local xc = require "xc"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local cmsgpack = require "cmsgpack"

local handler = {}
local clients = {}

local CLIENT_STATUS = {
    INVALID = 1,
    VALID = 2,
}

function handler.connect(fd, addr)
    xc.log("new connection", fd, addr)
    clients[fd] = {
        addr = addr,
        status = CLIENT_STATUS.INVALID,
        agent = xc.newservice("service/login", fd, skynet.self()),
        recv_limit = {}
    }

    skynet.timeout(300, function()
        local client = clients[fd]
        if client and client.status == CLIENT_STATUS.INVALID then
            gateserver.closeclient(fd)
            handler.disconnect(fd)
        end
    end)

    gateserver.openclient(fd)
end

function handler.disconnect(fd)
    local client = clients[fd]
    if client then
        if client.agent:onDisconnect() then
            client.agent:exit()
        end
        xc.info("diconnect", fd, client.addr)
        clients[fd] = nil
    end
end

local CMD = {}
function CMD.cs_login(client, session)
    if string.len(session) ~= 0 then
        client.status = CLIENT_STATUS.VALID
    end
    return session
end

function CMD.cs_enterGame(client, ret, player)
    if ret then
        client.agent:exit()
        client.agent = player

        xc.log("[cs_enterGame]", client.addr, player.addr)
    end
    return ret
end

function CMD.dispatch(fd, func_name, ...)
    local packStr, lenStr = cmsgpack.packex({0, func_name, {...}})
    socketdriver.send(fd, lenStr)
    socketdriver.send(fd, packStr)
end

function CMD.kickoff(fd)
    xc.log("kickoff", fd)
    gateserver.closeclient(fd)
    handler.disconnect(fd)
end

function handler.message(fd, msg, sz)
    local client = clients[fd]
    if client and client.agent then
        local str = netpack.tostring(msg, sz)
        local data = cmsgpack.unpack(str)
        local session_id, func_name = data[1], data[2]

        if string.sub(func_name, 1, 3) ~= "cs_" then
            xc.warn("invalid func_name", func_name, client.addr)
            return
        end

        local last_recv_time = client.recv_limit[func_name] or 0
        local now = skynet.now()
        if last_recv_time + 10 > now then
            xc.warn("recv limit", client.addr)
            return
        end
        client.recv_limit[func_name] = now

        local f = CMD[func_name]
        local response = {}
        if f then
            response = {f(client, client.agent[func_name](table.unpack(data[3])))}
        else
            response = {client.agent[func_name](table.unpack(data[3]))}
        end

        if #response > 0 then
            local packStr, lenStr = cmsgpack.packex({session_id, "", response})
            socketdriver.send(fd, lenStr)
            socketdriver.send(fd, packStr)
        end
    end
end

function handler.command(cmd, _, ...)
    local f = CMD[cmd]
    if f then
        f(...)
    end
end

xc.register_protocol()
gateserver.start(handler)