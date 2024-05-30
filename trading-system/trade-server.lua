Protocol = {
    TRADE = "trade",
    GET = "get",
    LIST = "list"
}

function mapItemsToDisplayItems(tbl) 
    local displayTable = {}
    for i,item in ipairs(tbl) do
        displayTable[i] = { name = item.displayName, count = item.count}
    end
    return displayTable
end

-- Need to open modem to use rednet
peripheral.find("modem", rednet.open)

-- Initialize the protocols the server uses, one for each operation
rednet.host(Protocol.TRADE, "tradeServer")
rednet.host(Protocol.GET, "tradeServer")
rednet.host(Protocol.LIST, "tradeServer")

id, message = rednet.receive(Protocol.GET)

print(id .. ": " .. message)

inventoryManager = peripheral.find("inventoryManager")

displayItems = mapItemsToDisplayItems(inventoryManager.getItems())

-- print items
for i,item in ipairs(displayItems) do
    print(item.displayName .. " " .. item.count)
end


