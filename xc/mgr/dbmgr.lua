local skynet = require "skynet"
local xc = require "xc"
local mongo = require "skynet.db.mongo"
local class = require "utils.class"
local imgr = require "mgr.imgr"

local DBMgr = class.createClass(imgr)

local mgr_name = ...
function DBMgr:ctor()
    xc.register(mgr_name)
end

function DBMgr:init()
    self.host = xc.config("db_host")
    self.port = xc.config("db_port")
    self.db_name = xc.config("db_name")

    self.client = mongo.client({
        host = self.host,
        port = self.port
    })

    if not self.client then
        xc.error("connect to mongo failed", self.host, self.port, self.db_name)
        return false
    end

    self.db = self.client:getDB(self.db_name)
    if not self.db then
        xc.error("connect to mongo failed", self.host, self.port, self.db_name)
    end

    xc.log("connect to mongo succ", self.host, self.port, self.db_name)
    return true
end

function DBMgr:insert(collection, doc)
    return self.db:getCollection(collection):insert(doc)
end

function DBMgr:batchInsert(collection, docs)
    return self.db:getCollection(collection):batch_insert(docs)
end

function DBMgr:delete(collection, selector, max_delete_count)
    max_delete_count = max_delete_count or 0
    self.db:getCollection(collection):delete(selector, max_delete_count)
end

function DBMgr:drop(collection)
    return self.db:runCommand("drop", collection)
end

function DBMgr:findOne(collection, query, selector)
    return self.db:getCollection(collection):findOne(query, selector)
end

function DBMgr:findAll(collection, query, selector, limit)
    local result = {}
    local cursor = self.db:getCollection(collection):find(query, selector)
    if limit then
        cursor:limit(cursor)
    end
    while cursor:hasNext() do
        local doc = cursor:next()
        table.insert(result, doc)
    end
    cursor:close()

    return result
end

function DBMgr:update(collection, query, update, upsert, multi)
    self.db:getCollection(collection):update(query, update, upsert, multi)
end

xc.start(DBMgr)