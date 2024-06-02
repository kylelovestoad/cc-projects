SYSTEM_NAME = "&6&lTrading System"
BRACKETS = "[]"
BRACKET_COLOR = "&e"


-- function 

function selectCountIfNecessary(item)
    if item.count == 1 then
        return "$"
    else

    end
end

function formatItems(items)
    formattedItems = {}
    for index,item in ipairs(items) do
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
                tag = nbt
            }
        },
        clickEvent = {
            action = "run_command"
            value = selectCountIfNecessary(item)
        },
        extra = {{
            text = " x" .. item.count .. "\n",
            color = "white",
            bold = true
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
        removedDollar = message:gsub("^%$", "")
        return username, split(removedDollar, " ")
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

function runCommand(manager, chatBox, commandArgs)
    player = manager.getOwner()
    
    if commandArgs[1] ~= "trade" then
        return
    end

    if commandArgs[2] == "create" then
        local inv = manager.getItems()
        message = {
            {
                text = "\nYour inventory:\n",
                color = "yellow",
                bold = true,
                extra = formatItems(inv)
            }
        }
        

        local json = textutils.serialiseJSON(message)
        chatBox.sendFormattedMessageToPlayer(json, player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
    else
        chatBox.sendMessageToPlayer("Type $trade help for help", player, SYSTEM_NAME, BRACKETS, BRACKET_COLOR)
    end
end



-- Find inventory managers for each player. We need the {} to make it into a table
local inventoryManagers = { peripheral.find("inventoryManager") }
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
        else 
            runCommand(inventoryManager, chatBox, commandArgs)
        end
    end
    -- Do nothing if it is not a command since we should not respond
end
