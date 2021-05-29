local xc = require "xc"
local class = require "utils.class"
local imgr = require "mgr.imgr"

local LoginMgr = class.createClass(imgr)

function LoginMgr:ctor()
end

function LoginMgr:cs_login(account_id, ...)
    -- TODO: 检测账号信息，生成session
    xc.log("[login]", ...)
    local session = "1"
    return account_id, session
end

function LoginMgr:onDisconnect()
end

xc.start(LoginMgr)