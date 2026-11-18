local CMD = Config.Command
local NODE = 'npc.manage'

local densityAlias = {
	peds = 'peds', ped = 'peds', scenarios = 'scenarios', scenario = 'scenarios',
	vehicles = 'vehicles', traffic = 'vehicles', parked = 'parked',
}

local toggleAlias = {
	cops = 'cops', police = 'cops', garbage = 'garbage', boats = 'boats', trains = 'trains',
	wildlife = 'wildlife', animals = 'wildlife', purge = 'purge', purgecars = 'purgeCars',
}

local BOOL = { on = true, ['true'] = true, ['1'] = true, off = false, ['false'] = false, ['0'] = false }

local function presetIds()
	local ids = {}
	for i, preset in ipairs(Config.Presets) do ids[i] = preset.id end
	return table.concat(ids, ', ')
end

local function usage(src)
	for _, line in ipairs({
		('/%s - open the panel'):format(CMD),
		('/%s on | off - master switch'):format(CMD),
		('/%s peds | scenarios | vehicles | parked | all <0-3> - density'):format(CMD),
		('/%s cops | garbage | boats | trains | wildlife [on|off]'):format(CMD),
		('/%s purge | purgecars [on|off] - keep sweeping what already spawned'):format(CMD),
		('/%s preset <%s>'):format(CMD, presetIds()),
		('/%s clear | reset | status'):format(CMD),
	}) do Sci.Notify(src, line) end
end

local function status(src)
	local s = Sci.Settings
	local function onOff(v) return v and 'on' or 'off' end

	Sci.Notify(src, ('master %s | peds %.2f | scenarios %.2f | vehicles %.2f | parked %.2f | auto-scale %.2f')
		:format(onOff(s.enabled), s.peds, s.scenarios, s.vehicles, s.parked, Sci.Factor))
	Sci.Notify(src, ('cops %s | garbage %s | boats %s | trains %s | wildlife %s | sweep %s/%s')
		:format(onOff(s.cops), onOff(s.garbage), onOff(s.boats), onOff(s.trains), onOff(s.wildlife),
			onOff(s.purge), onOff(s.purgeCars)))
end

RegisterCommand(CMD, function(src, args)
	src = tonumber(src) or 0
	if not SciPerm(src, NODE) then return end

	local sub = (args[1] or ''):lower()
	local actor = Sci.Describe(src)

	if sub == '' then
		if src == 0 then return usage(src) end
		return TriggerClientEvent('Sci_NpcManager:openPanel', src, Sci.Payload())
	end

	if sub == 'help' then return usage(src) end
	if sub == 'status' then return status(src) end

	if sub == 'on' or sub == 'off' then
		Sci.Apply({ enabled = sub == 'on' }, actor, src)
		return Sci.Notify(src, ('Population control %s.'):format(sub == 'on' and 'enabled' or 'disabled'), 'success')
	end

	if sub == 'reset' then
		Sci.Settings = Sci.Merge(Config.Defaults, nil)
		Sci.Apply(nil, actor, src)
		return Sci.Notify(src, 'Settings restored to Config.Defaults.', 'success')
	end

	if sub == 'clear' then
		Sci.PurgeNow(actor, src)
		return Sci.Notify(src, 'Sweep sent to every client.', 'success')
	end

	if sub == 'preset' then
		if Sci.ApplyPreset(args[2], actor, src) then
			return Sci.Notify(src, ('Preset "%s" applied.'):format(args[2]:lower()), 'success')
		end
		return Sci.Notify(src, ('Unknown preset. Try: %s'):format(presetIds()), 'error')
	end

	local key = densityAlias[sub]
	if key or sub == 'all' then
		local value = Sci.Clamp(args[2], 0.0, 3.0)
		if not value then return Sci.Notify(src, 'Give a number between 0.0 and 3.0.', 'error') end

		local patch = key and { [key] = value } or { peds = value, scenarios = value, vehicles = value, parked = value }
		Sci.Apply(patch, actor, src)
		return Sci.Notify(src, ('%s set to %.2f.'):format(key or 'All densities', value), 'success')
	end

	key = toggleAlias[sub]
	if key then
		local value = BOOL[(args[2] or ''):lower()]
		if value == nil then value = not Sci.Settings[key] end

		Sci.Apply({ [key] = value }, actor, src)
		return Sci.Notify(src, ('%s %s.'):format(key, value and 'on' or 'off'), 'success')
	end

	Sci.Notify(src, ('Unknown option "%s". Try /%s help'):format(sub, CMD), 'error')
end, false)

AddEventHandler('playerJoining', function()
	local src = source
	if GetResourceState('chat') ~= 'started' and GetResourceState('Sci_ChatSystem') ~= 'started' then return end

	SetTimeout(3000, function()
		TriggerClientEvent('chat:addSuggestion', src, '/' .. CMD, 'Ambient NPC and traffic density', {
			{ name = 'option', help = 'on/off, peds, vehicles, preset, clear, status, help' },
			{ name = 'value', help = '0.0 - 3.0, on/off, or a preset id' },
		})
	end)
end)
