local skynet = require "skynet"
local xc = require "xc"
local class = require "utils.class"
local mailbox = require "service.mailbox"

local Player = class.createClass()

local client_fd, gate = ...
function Player:ctor()
    self.client = setmetatable({}, {
        __index = function(_, k)
            return function(...)
                skynet.send(gate, "lua", "dispatch", client_fd, k, ...)
            end
        end
    })

    self.mailbox = mailbox:new({addr = skynet.self()})
end

function Player:onCreate(account_id)
    self.gbId = xc.mgr.idmgr.generateGbId()
    self.account_id = account_id

    xc.mgr.dbmgr.insert("player", self.pack())

    xc.log("on create", self.gbId)
end

function Player:load(data)
    self:unpack(data)

    xc.log("load succ", self.gbId)
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

function Player:onEnterGame()
    xc.log("on enter", self.gbId)
    xc.mgr.playermgr.onLogin(self.gbId, self.mailbox)
    return true
end

function Player:onDisconnect()
    xc.log("on disconnect", self.gbId)
    xc.mgr.playermgr.onLogout(self.gbId)
    return true
end

function Player:kickoff()
    xc.log("kickoff", self.gbId)
    skynet.send(gate, "lua", "kickoff", client_fd)
end

function Player:cs_kickoff()
    self:kickoff()
end

return xc.start(Player)