local inspect = require "utils.inspect"

local function search(k, plist)
    for _, c in ipairs(plist) do
        local v = c[k]
        if v then
            return v
        end
    end
end

local function callCtor(plist, o, args)
    for _, c in ipairs(plist) do
        local ctor = c.ctor
        if ctor then
            ctor(o, args)
        end
    end
end

local Class = {}

function Class.createClass(...)
    local c = {}

    local parents = {...}
    setmetatable(c, {
        __index = function(_, k)
            return search(k, parents)
        end
    })

    c.__index = c

    function c:new(args)
        local o = {}
        setmetatable(o, c)
        callCtor(parents, o, args)
        c.ctor(o, args)
        return o
    end

    return c
end

return Class