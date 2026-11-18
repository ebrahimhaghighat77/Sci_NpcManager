local RESOURCE   = GetCurrentResourceName()
local STATE_FILE = 'settings.json'
local STATE_KEY  = 'SciNpcManager'
local NODE       = 'npc.manage'

Sci.Settings = Sci.Merge(Config.Defaults, nil)
Sci.Factor   = 1.0

local cooldowns, strikes = {}, {}

function Sci.Notify(src, message, kind)
	if not src or src == 0 then return Sci.Log('%s', message) end
	TriggerClientEvent('Sci_NpcManager:notify', src, message, kind)
end

function Sci.Webhook(title, description, src)
	local url = Config.Webhook.url
	if type(url) ~= 'string' or url == '' then return end

	local fields = {}
	if src and src ~= 0 then
		fields[1] = { name = 'Player', value = Sci.Describe(src), inline = true }
	end

	PerformHttpRequest(url, function() end, 'POST', json.encode({
		username = Config.Webhook.username or Config.Brand.tag,
		embeds = { {
			title = title, description = description, color = Config.Webhook.colour, fields = fields,
			footer = { text = Config.Brand.title }, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		} },
	}), { ['Content-Type'] = 'application/json' })
end

function SciAntiCheat(src, reason)
	if not src or src == 0 then return end

	if Config.AntiCheat.logAll then Sci.Error('anti-cheat: %s - %s', Sci.Describe(src), reason) end
	Sci.Webhook('Anti-cheat', reason, src)

	if not Config.AntiCheat.enabled then return end

	local res = Config.AntiCheat.banResource
	if res and res ~= '' and GetResourceState(res) == 'started' then
		local ok = pcall(function() exports[res][Config.AntiCheat.banExport](exports[res], src, reason) end)
		if ok then return end
	end

	if Config.AntiCheat.dropOnFail then
		DropPlayer(src, ('[%s] %s'):format(Config.Brand.tag, reason))
	end
end

function Sci.Strike(src, reason)
	local now = GetGameTimer()
	local bucket = strikes[src]

	if not bucket or now - bucket.first > Config.AntiCheat.windowMs then
		bucket = { first = now, count = 0 }
		strikes[src] = bucket
	end

	bucket.count = bucket.count + 1
	if bucket.count >= Config.AntiCheat.strikes then
		strikes[src] = nil
		SciAntiCheat(src, reason)
	end
end

-- os.clock is CPU time and barely moves on an idle server.
function Sci.Cooldown(src, key, ms)
	local now = GetGameTimer()
	local bucket = cooldowns[src] or {}
	cooldowns[src] = bucket

	if bucket[key] and now - bucket[key] < ms then return false end
	bucket[key] = now
	return true
end

local function loadState()
	if not Config.SaveState then return end

	local raw = LoadResourceFile(RESOURCE, STATE_FILE)
	if not raw or raw == '' then return end

	local ok, decoded = pcall(json.decode, raw)
	if ok and type(decoded) == 'table' then
		Sci.Settings = Sci.Merge(Config.Defaults, decoded)
	else
		Sci.Warn('%s is unreadable, using Config.Defaults', STATE_FILE)
	end
end

local function saveState()
	if Config.SaveState then
		SaveResourceFile(RESOURCE, STATE_FILE, json.encode(Sci.Settings, { indent = true }), -1)
	end
end

function Sci.Publish()
	GlobalState:set(STATE_KEY, { settings = Sci.Settings, factor = Sci.Factor }, true)
end

local function recalcAutoScale()
	local factor, best = 1.0, -1

	if Config.AutoScale.enabled then
		local players = #GetPlayers()
		for _, tier in ipairs(Config.AutoScale.tiers) do
			if players >= tier.players and tier.players > best then
				best, factor = tier.players, Sci.Clamp(tier.factor, 0.0, 1.0) or 1.0
			end
		end
	end

	if factor ~= Sci.Factor then
		Sci.Factor = factor
		Sci.Publish()
	end
end

function Sci.Apply(patch, actor, src)
	Sci.Settings = Sci.Merge(Sci.Settings, patch)
	saveState()
	Sci.Publish()

	if actor then
		Sci.Log('%s changed settings -> %s', actor, json.encode(Sci.Settings))
		Sci.Webhook('Settings changed', ('```%s```'):format(json.encode(Sci.Settings)), src)
	end
end

function Sci.ApplyPreset(id, actor, src)
	local preset = Sci.FindPreset(tostring(id or ''):lower())
	if not preset then return false end

	Sci.Apply(preset.settings, actor, src)
	return true
end

function Sci.PurgeNow(actor, src)
	TriggerClientEvent('Sci_NpcManager:purgeNow', -1)

	if actor then
		Sci.Log('%s triggered a sweep', actor)
		Sci.Webhook('Manual sweep', 'Every client was asked to sweep once.', src)
	end
end

function Sci.Payload()
	local presets = {}
	for i, preset in ipairs(Config.Presets) do
		presets[i] = { id = preset.id, label = preset.label, desc = preset.desc, settings = preset.settings }
	end

	return {
		brand    = Config.Brand,
		theme    = Config.Theme,
		settings = Sci.Settings,
		factor   = Sci.Factor,
		presets  = presets,
		players  = #GetPlayers(),
		schedule = Config.Schedule.enabled,
		zones    = #Config.Zones,
	}
end

-- ox_lib re-packs multiple returns into a table, so a nil err would leave a hole.
local function action(name, ms, handler)
	lib.callback.register('Sci_NpcManager:' .. name, function(src, data)
		if not Sci.Cooldown(src, name, ms) then return { err = 'too_fast' } end

		if not SciPerm(src, NODE) then
			if name ~= 'open' then Sci.Strike(src, ('panel %s without permission'):format(name)) end
			return { err = 'no_permission' }
		end

		return handler(src, data)
	end)
end

action('open', 500, function()
	return { ok = true, data = Sci.Payload() }
end)

action('apply', 200, function(src, patch)
	if type(patch) ~= 'table' then return { err = 'bad_request' } end
	Sci.Apply(patch, Sci.Describe(src), src)
	return { ok = true, data = Sci.Payload() }
end)

action('preset', 500, function(src, data)
	if not Sci.ApplyPreset(type(data) == 'table' and data.id, Sci.Describe(src), src) then
		return { err = 'unknown_preset' }
	end
	return { ok = true, data = Sci.Payload() }
end)

action('purge', 1000, function(src)
	Sci.PurgeNow(Sci.Describe(src), src)
	return { ok = true, data = Sci.Payload() }
end)

exports('GetSettings', function() return Sci.Merge(Sci.Settings, nil) end)
exports('GetFactor', function() return Sci.Factor end)
exports('SetSettings', function(patch) Sci.Apply(patch, 'export') return Sci.Merge(Sci.Settings, nil) end)
exports('SetPreset', function(id) return Sci.ApplyPreset(id, 'export') end)
exports('SetEnabled', function(enabled) Sci.Apply({ enabled = enabled == true }, 'export') end)
exports('PurgeNow', function() Sci.PurgeNow('export') end)

AddEventHandler('playerJoining', function()
	SetTimeout(1000, recalcAutoScale)
end)

AddEventHandler('playerDropped', function()
	cooldowns[source], strikes[source] = nil, nil
	SetTimeout(1000, recalcAutoScale)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource ~= RESOURCE then return end

	loadState()
	recalcAutoScale()
	Sci.Publish()
	Sci.Log('ready - peds %.2f, vehicles %.2f, master %s',
		Sci.Settings.peds, Sci.Settings.vehicles, Sci.Settings.enabled and 'on' or 'off')
end)

CreateThread(function()
	while true do
		Wait(60000)
		recalcAutoScale()
	end
end)
