SYSTEM_NAME = "&6&lTrading System"
BRACKETS = "[]"
BRACKET_COLOR = "&e"

CommandPart = {
    PREFIX = "$",   
    TRADE = "trade",
    ADD = "add",
    LIST = "list",
    HELP = "help",
    REMOVE = "remove",
}

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

    local json = textutils.serialiseJSON(message)
    chatBox.sendFormattedMessageToPlayer(json, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
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

function addItemToTrade(player, inv, chatBox, manager, commandArgs)
    slot = tonumber(commandArgs[3])
    count = tonumber(commandArgs[4])

    tradeItem = findItemInSlot(inv, slot)

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

        local json = textutils.serialiseJSON(message)

        chatBox.sendFormattedMessageToPlayer(json, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        manager.removeItemFromPlayer("up", tradeItem)

    else
        chatBox.sendMessageToPlayer("The inventory slot you provided was empty", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        return 
    end

    sendReferenceToHelp(player, chatBox)
end  

function runCommand(manager, chatBox, readers, commandArgs)
    player = manager.getOwner()
    
    if commandArgs[1] ~= CommandPart.TRADE then
        sendReferenceToHelp(player, chatBox)
        return
    end

    local inv = manager.getItems()

    if commandArgs[2] == "create" then
        startTradeSelectMenu(player, inv, chatBox)
        return
    end
    
    if commandArgs[2] == "add" then
        addItemToTrade(player, inv, chatBox, manager, commandArgs)
        return
    end

    
end


-- Find inventory managers for each player. We need the {} to make it into a table
local inventoryManagers = { peripheral.find("inventoryManager") }
-- TODO work with blockReaders
local readers = { peripheral.find("blockReader") }
local chatBox = peripheral.find("chatBox")

while true do
    -- This will only give command args if the chat is a command "starts with $"
    local player, commandArgs = awaitCommand()
    
    -- If it is a command, get the running player's inventory and run it
    if commandArgs then

        local inventoryManager = getInventoryManagerForPlayer(player, inventoryManagers)

        -- Could not find the player's assigned inventory manager
        if not inventoryManager then
            chatBox.sendMessageToPlayer("You are not registered within the trading system, please ask kylelovestoad to add you", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
        end

        runCommand(inventoryManager, chatBox, readers, commandArgs)
    end
    -- Do nothing if it is not a command since we should not respond
end
