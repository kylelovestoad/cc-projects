-- Opens any modems for communication
peripheral.find("modem", rednet.open)

-- same hostname for all machines running this since we don't really care about name
rednet.host("alarm", "alarm-client")

repeat
    -- Repeatedly prompts users until they quit
    print("'q' to quit. To set alarm off or on type '0' or '1': ")
    local input = read()
    -- Discard anything that isn't a 0 or 1. 
    -- Serverside still checks for this but it's good for the client to do this too
    if input == "0" or input == "1" then
        rednet.broadcast(input, "alarm")
    elseif input ~= "q" then
        print("Invalid message, try again")
    end
until input == "q"