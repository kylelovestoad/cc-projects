function mapItemsToDisplayItems(tbl) 
    local displayTable = {}
    for i,item in ipairs(tbl) do
        displayTable[i] = { name = item.displayName, count = item.count}
    end
    return displayTable
end

-- Split a string to become a list
local function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
       table.insert(result, each)
    end
    return result
end

--- Awaits a command and returns the arguments
function awaitCommand()
    local event, username, message, uuid, isHidden = os.pullEvent("chat")
    if isHidden then
        -- trims the dollar sign since all hidden commands have that
        removedDollar = message:gsub("^%$", "")
        return username, split(removedDollar, " ")
    else 
        return nil 
    end
end

function getInventoryManagerForPlayer(player, managers)
    for _, manager in pairs(managers) do
        if manager.getOwner() == player then
            return manager
        end
    end
    return nil
end

function runCommand(manager, chatBox, commandArgs)
    player = manager.getOwner()
    if not player then
        chatBox.sendMessageToPlayer("You are not registered within the trading system, please ask kylelovestoad to add you", player)
        return
    end

    if commandArgs[1] == "inv" then
        chatBox.sendMessageToPlayer("Test!", player)
    end
end

inventoryManagers = { peripheral.find("inventoryManager") }
chatBox = peripheral.find("chatBox")

while true do
    -- This will only give command args if the chat is a command "starts with $"
    username, commandArgs = awaitCommand()
    inventoryManager = getInventoryManagerForPlayer(username, inventoryManagers)
    if commandArgs then
        runCommand(inventoryManager, chatBox, commandArgs)
    end
end
