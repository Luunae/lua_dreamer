local discordia = require"discordia"
local prettyPrint = require"pretty-print"
local client = discordia.Client()
local BOT_TOKEN = os.getenv"BOT_TOKEN"
local commands = {}
local utilities = {}
local emoji = {
	x = ❌
}

function commands.tp(message) commands.teleport(message) end

function commands.teleport(message)
	-- TODO: figure out error handling. Currently will crash on bad input.
	local teleport_destination_channel = message.guild:getChannel(string.sub(message.content, string.find(message.content, "%#") + 1, string.find(message.content, "%>") - 1))
	local entrance_message = message.channel:send("Teleport to `" .. teleport_destination_channel.name .. "` opened on behalf of `" .. message.member.name .. "`...")
	local exit_message = teleport_destination_channel:send("Teleport from `" .. message.channel.name .. "` on behalf of `" .. message.member.name .. "`:\n" .. entrance_message.link)
	data = {
		["content"] = entrance_message.content .. "\n" .. exit_message.link
	}
	entrance_message:update(data)
end

function commands.pwm(message) commands.print_raw_message(message) end

function commands.print_raw_message(message)
	if message.referencedMessage ~= nil then
		print(message.referencedMessage.content)
		message:reply("```\n" .. message.referencedMessage.content .. "\n```")
	end
end

function commands.test_utility(message)
	local command = {}
	for word in string.gmatch(message.content, "%S+") do
		table.insert(command, word)
	end
	if utilities[command[2]] then
		if utilities[command[2]](message) ~= nil then
			utilities.mark_command_success(message)
		end
	end
end

function utilities.create_discord_link(message, opts)
	local channel_mention = message.content:match("<#(%d[0-9]+)>")
	if channel_mention == nil then
		channel_mention = message.channel
	end
	local guild_text_channel = message.guild:getChannel(channel_mention)
	local payload = {}
	local defaults = {
		max_age = 86400,
		max_uses = 0,
		temporary = false,
		unique = false
	}
	
	for k,v in pairs(defaults) do
		payload[k] = v
	end
	
	if opts then
		payload.max_age = opts.max_age or payload.max_age
		payload.max_uses = opts.max_uses or payload.max_uses
		payload.temporary = opts.temporary or payload.temporary 
		payload.unique = opts.unique or payload.unique
	end

	invite = guild_text_channel:createInvite(payload)
	guild_text_channel:send("https://discord.gg/" .. invite.code)
	return invite

end

function utilities.mark_command_invalid(message)
	message:addReaction("❌")
	message:reply{
		content="Not a recognized command.",
		reference = {
			message = message,
			mention = false
		}
	}
end

function utilities.mark_command_success(message) -- Just because this function got called, doesn't mean the thing *actually* succeeded. It just probably did... Hopefully.
	message:addReaction("☑️")
end

client:on("ready", function() print("Logged in as " .. client.user.username) end)
client:on("messageCreate", function(message)
	if message.author.bot then return end
	if string.sub(message.content, 1, 1) == "!" then
		local components = {}
		for word in message.content:gmatch"%g+" do
			if string.sub(word, 1, 1) == "!" then table.insert(components, string.sub(word, 2)) end
			table.insert(components, word)
		end
		local commandname = components[1]
		if commands[commandname] then commands[commandname](message)
		else message.channel:send"Not a recognized command." end
	end
end)
client:run("Bot " .. BOT_TOKEN)