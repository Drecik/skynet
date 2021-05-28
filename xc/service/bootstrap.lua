local skynet = require "skynet"
local xc = require "xc"
local class = require "utils.class"

local Bootstrap = class.createClass()

local mgr_names = {
    "loginmgr",
    "dbmgr",
    "idmgr",
    "playermgr"
}

function Bootstrap:ctor()
    self.mgrs = {}
end

function Bootstrap:init()
    for _, name in ipairs(mgr_names) do
        self.mgrs[name] = xc.newservice("mgr/" .. name, name)
    end

    for name, mgr in pairs(self.mgrs) do
        if not mgr:init() then
            xc.error("init mgr: " .. name .. " failed!!")
        else
            xc.log("init mgr: " .. name .. " succ...")
        end
    end

    for name, mgr in pairs(self.mgrs) do
        if not mgr:start() then
            xc.error("start mgr: " .. name .. " failed!!")
        else
            xc.log("start mgr: " .. name .. " succ...")
        end
    end

    local gate_mailbox = xc.newservice("service/gate")
    skynet.call(gate_mailbox.addr, "lua", "open", {
        port = 9999,
        maxclient = 10,
        nodelay = true
    })

    xc.exit()
end

xc.start(Bootstrap, function(ins)
    ins:init()
end)