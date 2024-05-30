-- Helper function to set all sides on
function setAllSides(value) 
    for _, side in ipairs(rs.getSides()) do
        redstone.setOutput(side, value)
    end
end

-- This function will never end, but it is used in parallel.waitForAny
function awaitMessages() 
    -- Starts waiting for messages to be sent over
    print("Waiting for messages")
    while true do
        -- Recieves the id (unused) and the message
        local _, message = rednet.receive("alarm")
        print("\nGot message")
        if message == "1" then
            setAllSides(true) 
        elseif message == "0" then 
            setAllSides(false)
        elseif message ~= nil then
            print(string.format("Invalid message: %s", message))
        else 
            write(".")
        end
    end
end

-- returns when the quit key is pressed 
function awaitForceQuitKey()
    local key = nil
    repeat
        local event, key, is_held = os.pullEvent("key")
    until key == keys.q
end

-- Opens any modems for communications
peripheral.find("modem", rednet.open)

rednet.host("alarm", "alarm-server")

-- Waits for awaitMessages to exit, but runs both in parallel
parallel.waitForAny(awaitForceQuitKey, awaitMessages)
