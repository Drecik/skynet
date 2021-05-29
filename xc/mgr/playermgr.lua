local xc = require "xc"
local class = require "utils.class"
local imgr = require "mgr.imgr"

local PlayerMgr = class.createClass(imgr)

function PlayerMgr:ctor()
    self.players = {}
    self.online_cnt = 0
end

function PlayerMgr:onLogin(gbId, mailbox)
    xc.log("on login", gbId)
    assert(self.players[gbId] == nil, "already login: " .. gbId)
    self.online_cnt = self.online_cnt + 1
    self.players[gbId] = mailbox
end

function PlayerMgr:onLogout(gbId)
    xc.log("on logout", gbId)
    assert(self.players[gbId], "invalid player")
    self.online_cnt = self.online_cnt - 1
    self.players[gbId] = nil
end

xc.start(PlayerMgr)