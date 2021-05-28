local skynet = require "skynet"
local xc = require "xc.def"

function xc.config(key)
    return skynet.getenv(key)
end

return xc