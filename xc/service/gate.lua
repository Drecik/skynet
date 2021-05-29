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
        agent = xc.mgr.loginmgr,
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
        xc.log("diconnect", fd, client.addr)
        clients[fd] = nil
    end
end

local CMD = {}
function CMD.cs_login(client, account_id, session)
    if string.len(session) ~= 0 and client.status == CLIENT_STATUS.INVALID then
        client.status = CLIENT_STATUS.VALID

        local player = xc.newservice("player/player")
        player:bind(account_id, client.fd, skynet.self())
        client.agent = player
    end
    xc.log('[cs_login]', client.addr, session)
    return session
end

function CMD.dispatch(fd, func_name, ...)
    local pack_str, len_str = cmsgpack.packex({0, func_name, {...}})
    socketdriver.send(fd, len_str)
    socketdriver.send(fd, pack_str)
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

        xc.log("message", session_id, func_name)

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
            local pack_str, len_str = cmsgpack.packex({session_id, "", response})
            socketdriver.send(fd, len_str)
            socketdriver.send(fd, pack_str)
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