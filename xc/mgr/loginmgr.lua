local xc = require "xc"
local class = require "utils.class"
local imgr = require "mgr.imgr"

local LoginMgr = class.createClass(imgr)

local mgr_name = ...
function LoginMgr:ctor()
    xc.register(mgr_name)
end

function LoginMgr:login(...)
    -- TODO: 检测账号信息，生成session
    return "1"
end

function LoginMgr:verify(account_id, session)
    return true
end

xc.start(LoginMgr)