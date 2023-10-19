local discordia = require"discordia"
local Date = require"discordia/libs/utils/Date"
local prettyPrint = require"pretty-print"
local sql = require"sqlite3"
local client = discordia.Client()
local BOT_TOKEN = os.getenv"BOT_TOKEN"
local commands = {}
local utilities = {}
local sql_commands = {}
local emoji = { x = "❌", check = "☑️" }
local db = sql.open"mydb.sqlite"
local UTC_OFFSET = -7 * 3.6e3
local DISCORD_CHARACTER_LIMIT = 2e3

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

function commands.teleport(message)
	-- TODO: figure out error handling. Currently will crash on bad input.
	local teleport_destination_channel = message.guild:getChannel(string.sub(message.content, string.find(message.content, "%#") + 1, string.find(message.content, "%>") - 1))
	if teleport_destination_channel == nil then
		utilities.mark_command_invalid(message)
		return
	end
	local entrance_message = message.channel:send("Teleport to `" .. teleport_destination_channel.name .. "` opened on behalf of `" .. message.member.name .. "`...")
	local exit_message = teleport_destination_channel:send("Teleport from `" .. message.channel.name .. "` on behalf of `" .. message.member.name .. "`:\n" .. entrance_message.link)
	local data = {
		["content"] = entrance_message.content .. "\n" .. exit_message.link
	}
	entrance_message:update(data)
end

function commands.tp(message) commands.teleport(message) end

function commands.print_raw_message(message)
	if message.referencedMessage ~= nil then
		print(message.referencedMessage.content)
		message:reply("```\n" .. message.referencedMessage.content .. "\n```")
	end
end

function commands.prm(message) commands.print_raw_message(message) end

function commands.server_config(message) assert(false, "not implemented") end

function commands.test_utility(message)
	local command = {}
	for word in string.gmatch(message.content, "%S+") do table.insert(command, word) end
	if utilities[command[2]] then utilities[command[2]](message) end
end

function utilities.can_user_see_message(user, message)
	local guild_object = message.guild
	if guild_object == nil then return false end
	local member_in_guild = guild_object:getMember(user.id)
	if not member_in_guild then
		print"404 in utilities.can_user_see_message"
		return false
	end
	local can_read_messages = member_in_guild:hasPermission(message.channel, "readMessages")
	if not can_read_messages then return false end
	return true
end

function utilities.compose_quote(message)
	if string.len(message.content) == 0 then return end
	-- This is wrong, I need to figure out shenanigans to allow quoting of attachments.
	local created_timestamp = math.floor(message.createdAt + UTC_OFFSET)
	local author = ""
	if message.member == nil then author = message.author.name
	else author = message.member.name end
	local channel = message.channel.mentionString
	local edit_timestamp = ""
	if message.editedTimestamp ~= nil then
		edit_timestamp = "\n\nEdited at: <t:" .. math.floor(Date.fromISO(message.editedTimestamp):toSeconds() + UTC_OFFSET) .. ">"
	end
	local quote = "__" .. author .. "__ in **" .. channel .. "** at <t:" .. created_timestamp .. ">:\n> " .. message.content:gsub("\n", "\n> ") .. edit_timestamp
	return quote
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
	local invite = guild_text_channel:createInvite(payload)
	guild_text_channel:send("https://discord.gg/" .. invite.code)
	return invite
end

function utilities.get_discord_messages_from_string(text)
	return string.gmatch(text, "https://discord%.com/channels/(%d+)/(%d+)/(%d+)")
end

function utilities.get_message_from_ids(server_id, channel_id, message_id)
	local server = client:getGuild(server_id)
	if server == nil then return end
	local channel = server:getChannel(channel_id)
	if channel == nil then return end
	local message = channel:getMessage(message_id)
	if message == nil then return end
	return message
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

function utilities.message_contains_discord_links(message)
	local table_links = false
	for server_id, channel_id, message_id in utilities.get_discord_messages_from_string(message.content) do
		if table_links == false then table_links = {} end
		table.insert(table_links, { server_id, channel_id, message_id })
	end
	return table_links
end

function utilities.unroll_quotes(message)
	-- First I want my list of discord links
	local list_of_links = utilities.message_contains_discord_links(message)
	if list_of_links == {} then return end
	local quote = "**Quoting Message(s) on behalf of** " .. message.author.name .. " (id:" .. message.author.id .. ")"
	local no_access_error = ":x: User does not have access to this message."
	local list_of_messages_author_can_see = {}
	-- Next I want to discard any that the message author doesn't share the server and channel with.
	for k, v in pairs(list_of_links) do
		local message_to_check = utilities.get_message_from_ids(v[1], v[2], v[3])
		if message_to_check ~= nil then
			if utilities.can_user_see_message(message.author, message_to_check) then
				table.insert(list_of_messages_author_can_see, message_to_check)
			else table.insert(list_of_messages_author_can_see, false) end
		end
	end
	for k, v in pairs(list_of_messages_author_can_see) do
		if v then
			local single_message = utilities.compose_quote(v)
			if string.len(quote) + string.len(single_message) + 2 < DISCORD_CHARACTER_LIMIT then quote = quote .. "\n\n" .. single_message
			else
				message:reply(quote)
				quote = "Continuing Quotes:\n" .. single_message
			end
		else
			if string.len(quote) + string.len(no_access_error) + 2 < DISCORD_CHARACTER_LIMIT then quote = quote .. "\n\n" .. no_access_error
			else
				message:reply(quote)
				quote = "Continuing Quotes:\n" .. no_access_error
			end
		end
	end
	message:reply(quote)
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
		else
			message.channel:send("Not a recognized command, " .. message.author.name)
		end
	end
	if utilities.message_contains_discord_links then utilities.unroll_quotes(message) end
	-- Probably needs some config, but I can shoehorn that in when I get the db up.
end)
client:on("reactionAddUncached", function(channel, messageId, hash, userId)
	local message = channel:getMessage(messageId)
	if message.author.id == client.user.id then
		if hash ~= "❌" then return
		else
			local first_newline = string.find(message.content, "\n")
			local first_line = string.sub(message.content, 1, first_newline)
			local substituted_string = first_line:match":(%d+)%)"
			if substituted_string == nil then return end
			local member = message.guild:getMember(substituted_string)
			if member == nil then return end
			local reactor = message.guild:getMember(userId)
			if reactor == nil then return end
			if member.id == userId then message:delete()
			else
				if member:hasPermission"manageMessages" then message:delete() end
			end
		end
	end
end)
client:on("reactionAdd", function(reaction, userId)
	local message = reaction.message
	if message.author.id == client.user.id then
		if reaction.emojiName ~= "❌" then return
		else
			local first_newline = string.find(message.content, "\n")
			local first_line = string.sub(message.content, 1, first_newline)
			local substituted_string = first_line:match":(%d+)%)"
			local member = message.guild:getMember(substituted_string)
			if member == nil then return end
			if member.id == userId then message:delete()
			else
				if member:hasPermission"manageMessages" then message:delete() end
			end
		end
	end
end)
client:run("Bot " .. BOT_TOKEN)