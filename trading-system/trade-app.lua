
Protocol = {
    TRADE = "trade",
    GET = "get",
    LIST = "list"
}

Get = {
    TRADES = 0,
    INVENTORY = 1
}

TIMEOUT = 5

Trade = {}

function Trade:new(sendItem, recvItem)
  o.parent = self
  o.sendItem = sendItem
  o.recvItem = recvItem
  return o
end

--- Detects if there is exactly 1 player in a block range and gets the player if there is
-- @return nil if there are too many or too few players. The player name if there is one player
function detectUserInRange(range)
    local playerDetector = peripheral.find("playerDetector")

    if playerDetector == nil then
        error("No player detector found! Please add a player detector")
    end

    local players = playerDetector.getPlayersInRange(range)

    -- Checks if there is not exactly a second player since then it would not be able to determine the user of the trade system
    if players[2] then
        print("There are too many players nearby. We cannot determine who is using the computer right now")
        return nil
    end

    -- If there are no players, someone is probably accessing the computer from too far away
    if not players[1] then
        print("Please move closer to the computer to continue using the trading application")
        return nil
    end

    -- Gets the single player
    return players[1]
end

--- Lists a trade, putting up items to be sent and items wanted in return
-- @param sendItem the item to be sent 
-- @param recvItem the item wanted in return
function listTrade(trade, tradeServer)
    rednet.send(tradeServer, textutils.serialiseJSON(trade), Protocol.LIST)
    id, message = rednet.receive(Protocol.LIST, TIMEOUT)
    -- If the timeout happened
    if not id then
        print("Could not contact trading server...")
    end
end 


-- Trade creation loop
function createTrade()
end

-- Viewing trade loop
function viewTrades(tradeServer)
    rednet.send(tradeServer, Get.TRADES, Protocol.GET)
    id, message = rednet.receive(Protocol.GET, TIMEOUT)
    if not id then
        print("Could not contact trading server...")
    end
end

-- The app loop
function runApp(tradeServer)
    local quit = false
    repeat
        print(
            "Choose an option:\n" ..
            "1. View Trades\n" ..
            "2. List a trade\n" ..
            "3. Buy from trade\n" ..
            "4. Quit\n" ..
            "> "
        )

        choice = read()
        
        if choice == "1" then viewTrades(tradeServer)
        elseif choice == "2" then createTrade()
        elseif choice == "3" then print("Not implemented")
        elseif choice == "4" then quit = true
        else print("Invalid choice") end

    until quit
end

function main() 
    if pocket then 
        print("Please use this on a non-pocket computer with a player detector")
        return
    end

    -- Opens any modems for communications
    peripheral.find("modem", rednet.open)
    rednet.host(Protocol.TRADE, tostring(os.getComputerID()))

    local tradeServer = rednet.lookup(Protocol.TRADE, "tradeServer")

    print(tradeServer)

    runApp(tradeServer)
end


main()