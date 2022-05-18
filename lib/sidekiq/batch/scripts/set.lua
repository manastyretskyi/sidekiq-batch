local keys = redis.call("SCAN", 0, "MATCH", "BID-*", "COUNT", 10000)[2]
local batches = {}

for key, value in pairs(keys) do
  if not string.find(value, "^BID-.*-failed$") and not string.find(value, "^BID-.*-jids$") and not string.find(value, "^BID-.*-callbacks-complete$") and not string.find(value, "^BID-.*-callbacks-success$") and not string.find(value, "^BID-.*-success$") and not string.find(value, "^BID-.*-complete$") then
    local jid = string.gsub(value, "^BID.", "")

    table.insert(batches, jid)
  end
end

return batches
