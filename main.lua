local discordia = require('discordia')
local prettyPrint = require('pretty-print')
local client = discordia.Client()

local BOT_TOKEN = os.getenv("BOT_TOKEN")

local commands = {}
local utilities = {}

function commands.tp( message )
    commands.teleport( message )
end

function commands.teleport( message )
    local teleport_destination_channel = message.guild:getChannel(string.sub(message.content, string.find(message.content, "%#")+1, string.find(message.content, "%>")-1))
    local entrance_message = message.channel:send("Teleporting to " .. teleport_destination_channel.name .. " on behalf of " .. message.author.username .. "...")
    local exit_message = teleport_destination_channel:send("Teleport from " .. message.channel.name .. " on behalf of " .. message.author.username .. ".\n" .. entrance_message.content .. ":\n" .. message.channel.mentionString)
    data = {["content"] = entrance_message.content .. "\n" .. exit_message.channel.mentionString}
    entrance_message:update(data)
end

function utilities.create_discord_link( ... )
end

client:on('ready', function()
    print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(message)
    if message.author.bot then return end
    if string.sub(message.content, 1, 1) == "!" then
        local components = {}
        for word in message.content:gmatch("%g+") do
            if string.sub(word, 1, 1) == "!" then
                table.insert(components, string.sub(word, 2))
            end
            table.insert(components, word)
        end
        local commandname = components[1]
        if commands[commandname] then
            commands[commandname](message)
        else
            message.channel:send("Not a recognized command.")
        end
    end
end)

client:run("Bot " .. BOT_TOKEN)