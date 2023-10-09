local discordia = require"discordia"
local prettyPrint = require"pretty-print"
local sql = require"sqlite3"
local client = discordia.Client()
local BOT_TOKEN = os.getenv"BOT_TOKEN"
local commands = {}
local utilities = {}
local sql_commands = {}
local emoji = { x = "❌", check = "☑️" }
local db = sql.open"mydb.sqlite"

function sql_commands.init_guild_db(guild)
	-- local exists = db:exec("SELECT name FROM sqlite_master WHERE type='table' AND name=?", guild.id):nrows() > 0
	-- if not exists then db:exec("CREATE TABLE ? (key TEXT, value TEXT)", guild.id) end
end

function sql_commands.insert_kv_pair(guild, key, value)
	-- Ugh, I need a way to shove a NotImplemented into this so the runtime doesn't have a fucking seizure and kill itself.
	-- assert(false, "not implemented")
	-- db:exec("INSERT INTO ? (key, value) VALUES (?, ?)", guild.id, key, value)
	-- if sql_commands.get_record(guild, key) == value then utilities.mark_command_success end
end

function sql_commands.get_record(guild, key)
	-- return db:exec("SELECT value FROM ? WHERE key=?", guild.id, key)[1].value
end

function sql_commands.update(guild, key, value)
	-- db:exec("UPDATE ? SET value=? WHERE key=?", guild.id, value, key)
	-- if sql_commands.get_record(guild, key) == value then utilities.mark_command_success end
end

function sql_commands.delete(guild, key)
	-- db:exec("DELETE FROM ? WHERE key=?", guild.id, key)
	-- if sql_commands.get_record
end

function commands.tp(message) commands.teleport(message) end

function commands.teleport(message)
	-- TODO: figure out error handling. Currently will crash on bad input.
	local teleport_destination_channel = message.guild:getChannel(string.sub(message.content, string.find(message.content, "%#") + 1, string.find(message.content, "%>") - 1))
	if teleport_destination_channel == nil then
		utilities.mark_command_invalid(message)
		return
	end
	local entrance_message = message.channel:send("Teleport to `" .. teleport_destination_channel.name .. "` opened on behalf of `" .. message.member.name .. "`...")
	local exit_message = teleport_destination_channel:send("Teleport from `" .. message.channel.name .. "` on behalf of `" .. message.member.name .. "`:\n" .. entrance_message.link)
	data = {
		["content"] = entrance_message.content .. "\n" .. exit_message.link
	}
	entrance_message:update(data)
end

function commands.prm(message) commands.print_raw_message(message) end

function commands.print_raw_message(message)
	if message.referencedMessage ~= nil then
		print(message.referencedMessage.content)
		message:reply("```\n" .. message.referencedMessage.content .. "\n```")
	end
end

function commands.server_config(message) assert(false, "not implemented") end

function commands.test_utility(message)
	local command = {}
	for word in string.gmatch(message.content, "%S+") do table.insert(command, word) end
	if utilities[command[2]] then
		if utilities[command[2]](message) ~= nil then utilities.mark_command_success(message) end
	end
end

function utilities.create_discord_link(message, opts)
	local channel_mention = message.content:match"<#(%d[0-9]+)>"
	if channel_mention == nil then channel_mention = message.channel end
	local guild_text_channel = message.guild:getChannel(channel_mention)
	local payload = {}
	local defaults = {
		max_age = 8.64e4,
		max_uses = 0,
		temporary = false,
		unique = false
	}
	for k, v in pairs(defaults) do payload[k] = v end
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

function utilities.mark_command_invalid(message, payload)
	message:addReaction(emoji.x)
	if payload ~= nil then
		message:reply{ content = payload, reference = { message = message, mention = false } }
	end
end

function utilities.mark_command_success(message)
	-- Just because this function got called, doesn't mean the thing *actually* succeeded. It just probably did... Hopefully.
	message:addReaction(emoji.check)
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