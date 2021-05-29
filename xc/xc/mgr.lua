local xc = require "xc.def"
local mailbox = require "service.mailbox"

local mgr_mailboxes = {}
local function mgr_mailbox(name)
    local mb = mgr_mailboxes[name]
    if mb then
        return mb
    end
    mb = mailbox:new({addr = '.' .. name})
    mgr_mailboxes[name] = mb
    return mb
end

xc.mgr = setmetatable({}, {
    __index = function(_, k)
        return mgr_mailbox(k)
    end
})

return xc