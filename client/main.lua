Sci.Settings  = Sci.Merge(Config.Defaults, nil)
Sci.Effective = Sci.Merge(Config.Defaults, nil)
Sci.Factor    = 1.0
Sci.Override  = nil
Sci.Zone      = nil

local STATE_KEY = 'SciNpcManager'
local watchers, signature = {}, nil

local NOTIFY = {
	okokNotify = function(res, message, kind, title, duration)
		local map = { success = 'success', error = 'error', warning = 'warning', inform = 'info' }
		return pcall(function() exports[res]:Alert(title, message, duration or 5000, map[kind] or 'info', true) end)
	end,

	['esx_notify'] = function(res, message, kind, title, duration)
		local map = { success = 'success', error = 'error', warning = 'warning', inform = 'info' }
		return pcall(function() exports[res]:Notify(map[kind] or 'info', duration or 5000, message, title) end)
	end,

	['mythic_notify'] = function(res, message, kind)
		return pcall(function() exports[res]:DoHudText(kind or 'inform', message) end)
	end,

	['t-notify'] = function(res, message, kind, title, duration)
		local map = { success = 'success', error = 'error', warning = 'warning', inform = 'info' }
		return pcall(function()
			exports[res]:Alert({ style = map[kind] or 'info', message = message, title = title, duration = duration or 5000 })
		end)
	end,

	ox_lib = function(_, message, kind, title, duration)
		lib.notify({ type = kind or 'inform', title = title, description = message, duration = duration })
		return true
	end,
}

-- okokNotify ships under both okokNotify and okoknotify.
local resolved = {}

local function notifyResource(name)
	if resolved[name] ~= nil then return resolved[name] or nil end

	local wanted = name:lower()
	for i = 0, GetNumResources() - 1 do
		local res = GetResourceByFindIndex(i)
		if res and res:lower() == wanted and GetResourceState(res) == 'started' then
			resolved[name] = res
			return res
		end
	end

	resolved[name] = false
end

AddEventHandler('onClientResourceStart', function() resolved = {} end)
AddEventHandler('onClientResourceStop', function() resolved = {} end)

function SciNotify(message, kind, title, duration)
	title = title or Config.Brand.tag

	for _, name in ipairs(Config.Notify.order) do
		local adapter = NOTIFY[name]
		local res = adapter and (name == 'ox_lib' and name or notifyResource(name))
		if res and adapter(res, message, kind, title, duration) then return end
	end

	NOTIFY.ox_lib(nil, message, kind, title, duration)
end

RegisterNetEvent('Sci_NpcManager:notify', function(message, kind)
	if type(message) == 'string' then SciNotify(message, kind) end
end)

function Sci.Watch(fn)
	watchers[#watchers + 1] = fn
end

local function scheduleOverride()
	if not Config.Schedule.enabled then return nil end

	local hour = GetClockHours()
	for _, slot in ipairs(Config.Schedule.hours) do
		local inside
		if slot.from <= slot.to then
			inside = hour >= slot.from and hour < slot.to
		else
			inside = hour >= slot.from or hour < slot.to
		end
		if inside then return slot.settings end
	end
end

local function zoneOverride(coords)
	local best, bestPriority, name = nil, -math.huge, nil

	for _, zone in ipairs(Config.Zones) do
		local priority = zone.priority or 0
		if priority > bestPriority and #(coords - zone.coords) <= zone.radius then
			best, bestPriority, name = zone.settings, priority, zone.name
		end
	end

	Sci.Zone = name
	return best
end

local function fingerprint(s)
	local parts = {}
	for _, key in ipairs(Sci.Keys.density) do parts[#parts + 1] = ('%.2f'):format(s[key]) end
	for _, key in ipairs(Sci.Keys.toggle) do parts[#parts + 1] = s[key] and '1' or '0' end
	return table.concat(parts, '|')
end

function Sci.Resolve()
	local resolved = Sci.Merge(Sci.Settings, nil)

	if Sci.Factor < 1.0 then
		for _, key in ipairs(Sci.Keys.density) do
			resolved[key] = Sci.Clamp(resolved[key] * Sci.Factor, 0.0, 3.0)
		end
	end

	resolved = Sci.Merge(resolved, scheduleOverride())

	local ped = PlayerPedId()
	if #Config.Zones > 0 and DoesEntityExist(ped) then
		resolved = Sci.Merge(resolved, zoneOverride(GetEntityCoords(ped)))
	end

	Sci.Effective = Sci.Merge(resolved, Sci.Override)

	local current = fingerprint(Sci.Effective)
	if current ~= signature then
		signature = current
		for i = 1, #watchers do watchers[i](Sci.Effective) end
		Sci.Debug('effective settings -> %s', current)
	end
end

local function adopt(payload)
	if type(payload) ~= 'table' or type(payload.settings) ~= 'table' then return end

	Sci.Settings = Sci.Merge(Config.Defaults, payload.settings)
	Sci.Factor = Sci.Clamp(payload.factor, 0.0, 1.0) or 1.0
	Sci.Resolve()
end

AddStateBagChangeHandler(STATE_KEY, 'global', function(_, _, value)
	adopt(value)
end)

exports('GetSettings', function() return Sci.Merge(Sci.Effective, nil) end)

exports('SetOverride', function(patch)
	if type(patch) ~= 'table' then return false end
	Sci.Override = patch
	Sci.Resolve()
	return true
end)

exports('ClearOverride', function()
	Sci.Override = nil
	Sci.Resolve()
	return true
end)

CreateThread(function()
	local adopted = false

	while true do
		if not adopted and GlobalState[STATE_KEY] then
			adopt(GlobalState[STATE_KEY])
			adopted = true
		end

		Sci.Resolve()
		Wait(500)
	end
end)
