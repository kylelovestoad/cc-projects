CHAT_MARKER = "> "

-- This function will never end, but it is used in parallel.waitForAny
function awaitMessages() 
    -- Starts waiting for messages to be sent over
    while true do
        -- Wait for chat
        local id, message = rednet.receive("chat")
        print()
        print(id .. ": " .. message)
        write(CHAT_MARKER)
    end
end

function chat()
    while true do
        write(CHAT_MARKER)
        local input = read()
        rednet.broadcast(input, "chat")
    end
end

-- force quit key is leftCtrl 
function awaitForceQuitKey()
    local key = nil
    repeat
        local event, key, is_held = os.pullEvent("key")
    until key == keys.leftCtrl
end

-- Setup to clear out existing messages to display the TUI
term.clear()
term.setCursorPos(1,1)

-- Opens any modems for communication
peripheral.find("modem", rednet.open)

local hostname = tostring(os.getComputerID())
rednet.host("chat", hostname)

print("Welcome to Glaxx Chat!")

-- Waits for awaitForceQuitKey to exit, but runs both in parallel
parallel.waitForAny(awaitForceQuitKey, awaitMessages, chat)
print()
