local skynet = require "skynet"
local xc = require "xc.def"
local pack_config = require "pack_config"
local inspect = require "utils.inspect"

local function pack(t)
    for k, d in pairs(t) do
        if type(d) == "table" then
            if d.__class_name then
                t[k] = d:pack()
            else
                pack(d)
            end
        end
    end
end

function xc.pack(...)
    local args = {...}
    pack(args)
    return skynet.pack(table.unpack(args))
end

local function unpack(t)
    for k, d in pairs(t) do
        if type(d) == "table" then
            if d.__class_name then
                local ins = pack_config.createObject(d.__class_name)
                if ins then
                    ins:unpack(d)
                    t[k] = ins
                end
            else
                unpack(d)
            end
        end
    end
end

function xc.register_protocol()
    skynet.register_protocol{
        name = "xc",
        id = skynet.PTYPE_XC,
        unpack = xc.unpack,
        pack = xc.pack
    }
end

function xc.start(class, func)
    skynet.start(function()
        local ins = class:new()
        skynet.dispatch("xc", function(_, _, func, ...)
            local f = ins[func]
            if f then
                skynet.retpack(f(ins, ...))
            else
                xc.log(inspect(ins))
                error("invalid func name: " .. func)
            end
        end)

        if func then
            func(ins)
        end
    end)
end

function xc.call(addr, ...)
    return skynet.call(addr, "xc", ...)
end

function xc.send(addr, ...)
    return skynet.send(addr, "xc", ...)
end

return xc