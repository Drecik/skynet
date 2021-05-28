local mailbox = require "service.mailbox"

local class_config = {
    mailbox = function() return mailbox:new() end
}

local config = {}
function config.createObject(class_name)
    local f = class_config[class_name]
    if f then
        return f()
    end
end

return config