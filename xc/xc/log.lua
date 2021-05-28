local skynet = require "skynet"
local xc = require "xc.def"

local function getFileInfo()
    local info = debug.getinfo(3)
    return '[' .. info.short_src .. ':' .. info.currentline .. ']'
end

function xc.log(...)
    return skynet.error('[info]', getFileInfo(), ...)
end

function xc.error(...)
    return skynet.error('[error]', getFileInfo(), ...)
end

function xc.warn(...)
    return skynet.error('[warn]', getFileInfo(), ...)
end

local debug = skynet.getenv('debug')
function xc.debug(...)
    if debug then
        return skynet.error('[debug]', getFileInfo(), ...)
    end
end

return xc