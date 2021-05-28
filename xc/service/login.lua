local skynet = require "skynet"
local xc = require "xc"
local class = require "utils.class"
local inspect = require "utils.inspect"

local Login = class.createClass()

local client_fd, gate = ...
function Login:ctor()
end

function Login:cs_login(...)
    xc.log('[cs_login]', ...)
    return xc.mgr.loginmgr.login(...)
end

function Login:cs_enterGame(account_id, session)
    xc.log('[cs_enterGame]', account_id, session)
    local ret = xc.mgr.loginmgr.verify(account_id, session)
    if not ret then
        return ret
    end

    local player_data = xc.mgr.dbmgr.findOne("player", {account_id = account_id})
    local player = xc.newservice("player/player", client_fd, gate)
    if not player_data then
        player:onCreate(account_id)
    else
        player:load(player_data)
    end

    ret = player:onEnterGame()
    xc.log('[cs_enterGame]', ret)
    if not ret then
        player:exit()
        return false
    end

    return true, player
end

function Login:onDisconnect()
    xc.log("on disconnect")
    return true
end

xc.start(Login)