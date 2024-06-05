SYSTEM_NAME = "&6&lTrading System"
BRACKETS = "[]"
BRACKET_COLOR = "&e"
DATABASE_DIR = "./db"
QUEUED_DB_FILE = DATABASE_DIR .. "/queued"
LISTED_DB_FILE = DATABASE_DIR .. "/listed"


CommandPart = {
    PREFIX = "$",   
    TRADE = "trade",
    ADD = "add",
    LIST = "list",
    HELP = "help",
    REMOVE = "remove",
}

-- The marker slot for trade chests. in-game this is 0 but lua is 1 based
MARKER_SLOT = 1

function commandStringOf(...)
    local args = {...}
    return CommandPart.PREFIX .. CommandPart.TRADE .. " " .. table.concat(args, " ")
end

function formatItems(items)
    formattedItems = {}
    for index, item in ipairs(items) do
        table.insert(formattedItems, formatItem(item))
    end
    return formattedItems
end

function formatItem(item)
    -- hacky fix to prevent crashes with sophisticated backpacks. 
    -- It seems like the containers hold too much nbt and overload the client when hovering over backpacks
    -- There isn't really a seemingly easy fix right now unless I find out what is causing the crash
    if string.match(item.name, ":.*backpack.*") then  
        -- backpacks have a contentsUuid 
        item.nbt.contentsUuid = nil
    end
    local nbt = textutils.serialiseJSON(item.nbt) 

    return
    { 
        text = item.displayName,
        color = "aqua",
        bold = false,
        hoverEvent = {
            action = "show_item",
            contents = {
                id = item.name,
                count = item.count,
                tag = nbt,
            }
        },
        clickEvent = {
            action = "suggest_command",
            value = commandStringOf(CommandPart.ADD, item.slot, item.count),
        },
        extra = {{
            text = " x" .. item.count .. "\n",
            color = "white",
            bold = true,
        }}
    }
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
        removedPrefix = message:gsub("^%" .. CommandPart.PREFIX, "")
        return username, split(removedPrefix, " ")
    else 
        return username, nil 
    end
end

function getInventoryManagerForPlayer(player, managers)
    for _, manager in pairs(managers) do
        if player == manager.getOwner() then
            return manager
        end
    end
    return nil
end

function startTradeSelectMenu(player, inv, chatBox)
    -- Creates the selection menu for items in your inventory
    local listCommand = commandStringOf(CommandPart.LIST)

    local message = { 
        { 
            text = "\nChoose items to trade, then run ",
            color = "green",
            bold = false,
        },
        {
            text = listCommand .. "\n",
            color = "yellow",
            bold = false,
            clickEvent = {
                action = "suggest_command",
                value = listCommand,
            },
        },
        {
            text = "Your inventory:\n",
            color = "yellow",
            bold = true,
            extra = formatItems(inv),
        }
    }

    local item = textutils.serialiseJSON(message)
    chatBox.sendFormattedMessageToPlayer(item, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
end

-- gets the inventory inside the chest used for trading
function getTradeChestInventory(player, readers)
    for _, reader in ipairs(readers) do
        blockData = reader.getBlockData()
        local itemsList = nil
        -- For vanilla chests
        if blockData.Items then
            items = blockData.Items
        -- For sophisticated storage chests
        elseif blockData.storageWrapper then
            items = blockData.storageWrapper.contents.inventory.Items
        else
            return nil
        end

        if items[MARKER_SLOT].id == "advancedperipherals:memory_card" and items[MARKER_SLOT].tag.owner == player then
            -- This only works since the marker will always be the first element. If MARKER_SLOT is set to anything but 1 this won't work!!
            table.remove(items, MARKER_SLOT)
            return items
        end
    end

    return nil
end


function findItemInSlot(inv, slot)
    for _,item in ipairs(inv) do
        if item.slot == slot then
            return item
        end
    end
    return nil
end

function sendReferenceToHelp(player, chatBox)
    chatBox.sendMessageToPlayer("Type " .. commandStringOf(CommandPart.HELP) .. " for help", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
end

function getSavedItemsFromFile(file, items)
    if not fs.exists(file) then
        return
    end

    for line in io.lines(file) do
        -- First we get the item from the database
        item = textutils.unserialiseJSON(line)
    
        -- Finally we use the player attribute from the item to determine which player section the item goes to
        table.insert(items[item.player], item)
    end
end

function addTableToFile(file, tbl, inMemStorage)
    h = fs.open(file, "a")
    h.write(textutils.serialiseJSON(tbl) .. "\n")
    table.insert(inMemStorage, tbl)
    h.close()
end

function removeTableFromFile(file, id, inMemStorage)
    h = fs.open(file, "w")
    itemLine = h.seek("set", id)
    -- remove the line where the item is by overwriting it
    h.write("")
    table.remove(inMemStorage, id)
    h.close()
end

function addItemToTrade(player, tradeItem, chatBox, manager, slot, count)

    if tradeItem ~= nil then
        if count > tradeItem.count then
            chatBox.sendMessageToPlayer("You cannot trade more than you have in the inventory slot. If you are trying to trade more than a stack of items, add each stack individually", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
            return
        end

        if count <= 0 then 
            chatBox.sendMessageToPlayer("You must trade more than 0 items", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
            return
        end

        local removeCommand = commandStringOf(CommandPart.REMOVE)

        local message = {
            {
                text = "Item successfully added to our trading system! If you would like to remove the item, run ",
                color = "green",
                bold = false,
            },
            {
                text = removeCommand,
                color = "yellow",
                bold = false,
                clickEvent = {
                    action = "suggest_command",
                    value = removeCommand,
                },
            }
        }

        local item = textutils.serialiseJSON(message)

        chatBox.sendFormattedMessageToPlayer(item, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        manager.removeItemFromPlayer("up", tradeItem)
    else
        chatBox.sendMessageToPlayer("The inventory slot you provided was empty", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        return 
    end

    sendReferenceToHelp(player, chatBox)
end  

function runCommand(manager, chatBox, readers, trades, commandArgs)
    player = manager.getOwner()
    
    if commandArgs[1] ~= CommandPart.TRADE then
        return
    end

    local inv = manager.getItems()

    if commandArgs[2] == "create" then
        startTradeSelectMenu(player, inv, chatBox)
        return
    end
    
    if commandArgs[2] == "add" then
        slot = tonumber(commandArgs[3])
        count = tonumber(commandArgs[4])
        -- If slot and count are present, then try to add the item
        if slot and count then
            tradeItem = findItemInSlot(inv, slot)
            -- The database needs to know the player for easy display
            tradeItem.player = player
            -- Set the full count to the new count (The count that is being subtracted from your inventory)
            tradeItem.count = count
            addItemToTrade(player, tradeItem, chatBox, manager, slot, count)
            -- Adds the item to the queuedItems persistent storage
            addTableToFile(QUEUED_DB_FILE, tradeItem, trades.queuedTradeItems)
        else
            -- If one is not there the command is invalid so redirect to help command
            sendReferenceToHelp(player, chatBox)
        end
        return
    end

    if commandArgs[2] == "list" then

        queued = trades.queuedTradeItems[player]
        addTableToFile(LISTED_DB_FILE, queued, trades.listedTrades[player])

        for i,tradeItem in ipairs(queued) do
            removeTableFromFile(QUEUED_DB_FILE, i, queued)
        end

        return
    end

    if commandArgs[2] == "view" then
        tradeChestInv = getTradeChestInventory(player, readers)
        print(textutils.serialiseJSON(tradeChestInv))
        if tradeChestInv then 
            formattedItems = {}
            for index, item in ipairs(tradeChestInv) do
                -- print(item.id)
                -- print(item.Count)
                -- print(item.Slot)
                
            

                -- table.insert(formattedItems, message)
            end
            -- local item = textutils.serialiseJSON(formattedItems)
            -- chatBox.sendFormattedMessageToPlayer(item, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        end

        return
    end

    sendReferenceToHelp(player, chatBox)
end

-- create our database dir if it doesn't exist
if fs.exists(DATABASE_DIR) then
    -- If the database dir name exists but it is not a directory, then delete it and make a new directory
    if not fs.isDir(DATABASE_DIR) then
        fs.delete(DATABASE_DIR)
        fs.makeDir(DATABASE_DIR)
    end
else 
    fs.makeDir(DATABASE_DIR)
end

local trades = {}
trades.queuedTradeItems = {}
trades.listedTrades = {}
-- Find inventory managers for each player. We need the {} to make it into a table
inventoryManagers = { peripheral.find("inventoryManager") }

for _,manager in pairs(inventoryManagers) do
    owner = manager.getOwner()
    if owner ~= nil then
        trades.queuedTradeItems[owner] = {}
        trades.listedTrades[owner] = {}
    end
end

getSavedItemsFromFile(QUEUED_DB_FILE, trades.queuedTradeItems)
getSavedItemsFromFile(LISTED_DB_FILE, trades.listedTrades)

print(textutils.serializeJSON(trades.queuedTradeItems))
print(textutils.serializeJSON(trades.listedTrades))

while true do
    -- This will only give command args if the chat is a command "starts with $"
    local player, commandArgs = awaitCommand()
    

    -- Create the readers to read the trading containers
    local readers = { peripheral.find("blockReader") }
    local chatBox = peripheral.find("chatBox")


    -- If it is a command, get the running player's inventory and run it
    if commandArgs then

        local inventoryManager = getInventoryManagerForPlayer(player, inventoryManagers)

        -- Could not find the player's assigned inventory manager
        if not inventoryManager then
            chatBox.sendMessageToPlayer("You are not registered within the trading system, please ask kylelovestoad to add you", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        end

        runCommand(inventoryManager, chatBox, readers, trades, commandArgs)
    end
    -- Do nothing if it is not a command since we should not respond
end
