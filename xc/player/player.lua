local skynet = require "skynet"
local xc = require "xc"
local class = require "utils.class"
local mailbox = require "service.mailbox"

local Player = class.createClass()

function Player:ctor()
    self.mailbox = mailbox:new({addr = skynet.self()})
end

function Player:bind(account_id, client_fd, gate)
    self.account_id = account_id
    self.client_fd = client_fd
    self.gate = gate
    self.client = setmetatable({}, {
        __index = function(_, k)
            return function(...)
                skynet.send(gate, "lua", "dispatch", client_fd, k, ...)
            end
        end
    })
end

function Player:cs_enterGame()
    xc.log('[cs_enterGame]', self.account_id)

    local player_data = xc.mgr.dbmgr.findOne("player", {account_id = self.account_id})
    if not player_data then
        self:onCreate()
    else
        self:unpack(player_data)
    end

    xc.mgr.playermgr.onLogin(self.gbId, self.mailbox)
    return true
end

function Player:onCreate()
    self.gbId = xc.mgr.idmgr.generateGbId()
    xc.mgr.dbmgr.insert("player", self:pack())

    xc.log("on create", self.gbId)
end

function Player:unpack(d)
    self.gbId = d.gbId
    self.account_id = d.account_id
end

function Player:pack()
    return {
        gbId = self.gbId,
        account_id = self.account_id
    }
end

function Player:onDisconnect()
    xc.log("on disconnect", self.gbId)
    xc.mgr.playermgr.onLogout(self.gbId)
end

function Player:kickoff()
    xc.log("kickoff", self.gbId)
    skynet.send(self.gate, "lua", "kickoff", self.client_fd)
end

xc.start(Player)