--- This script requires the following mods:
-- Advanced Peripherals addon for CC:Tweaked
-- Mighty Mail

MIGHTY_MAILBOX = "mighty_mail:mail_box"
MIGHTY_PACKAGE = "mighty_mail:package"

BRACKETS = "[]"
BRACKET_COLOR = "&7&l"
PREFIX = "&lMail"

NOTIFY_TIMER = 300 -- 5 minutes

function notifyOnTimer()
    while true do 
        -- Gets the owner from a chest stored below the mailbox
        local owner = ownerReader.Items[1].tag.owner
        chatBox.sendFormattedToastToPlayer(messageJson, titleJson, owner, PREFIX, BRACKETS, BRACKET_COLOR)
        sleep(NOTIFY_TIMER)
    end
end

function waitForDecrease()
    while true do
        newNumMail = #mailbox.Items 
        if newNumMail < currNumMail then
            return
        end
        currNumMail = newNumMail
    end
end

currNumMail = 0

while true do
    mailReader = peripheral.wrap("top")
    ownerReader = peripheral.wrap("bottom")
    chatBox = peripheral.find("chatBox")

    mailBox = mailReader.getBlockData()
    
    if mailBox.id ~= MIGHTY_MAILBOX then
        print("Block being read is not a mailbox")
    else 
        newNumMail = #mailbox.Items 
        
        if newNumMail > currNumMail and mailbox.Items[newNumMail] ~= MIGHTY_PACKAGE then
            currNumMail = newNumMail
            parallel.waitForAny(notifyOnTimer, waitForDecrease)
        end
    end
end