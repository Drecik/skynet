local skynet = require "skynet"
local xc = require "xc"
local class = require "utils.class"
local imgr = require "mgr.imgr"

local IdMgr = class.createClass(imgr)

function IdMgr:ctor()
    self.server_id = xc.config("server_id") or 0
    self.last_time = self:time()
    self.index = 0
end

function IdMgr:time()
    return math.floor(skynet.time() * 100)
end

function IdMgr:generateGbId()
    local now = self.time()
    if now ~= self.last_time then
        self.last_time = now
        self.index = 0
    end

    self.index = self.index + 1

    -- server_id .. time .. index
    return tostring(self.server_id) .. tostring(now) .. tostring(self.index)
end

xc.start(IdMgr)