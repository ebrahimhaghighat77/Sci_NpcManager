Sci = Sci or {}

local TAG = '[Sci_NpcManager]^7 '

function Sci.Log(fmt, ...) print('^5' .. TAG .. fmt:format(...)) end
function Sci.Warn(fmt, ...) print('^3' .. TAG .. fmt:format(...)) end
function Sci.Error(fmt, ...) print('^1' .. TAG .. fmt:format(...)) end

function Sci.Debug(fmt, ...)
	if Config and Config.Debug then Sci.Log('(debug) ' .. fmt, ...) end
end

Sci.Keys = {
	density = { 'peds', 'scenarios', 'vehicles', 'parked' },
	toggle  = { 'enabled', 'cops', 'garbage', 'boats', 'trains', 'wildlife', 'purge', 'purgeCars' },
}

function Sci.Clamp(value, min, max)
	value = tonumber(value)
	if not value or value ~= value then return nil end
	if value < min then return min end
	if value > max then return max end
	return math.floor(value * 100 + 0.5) / 100
end

function Sci.Merge(base, patch)
	local out = {}
	for key, value in pairs(base) do out[key] = value end
	if type(patch) ~= 'table' then return out end

	for _, key in ipairs(Sci.Keys.density) do
		local value = patch[key] ~= nil and Sci.Clamp(patch[key], 0.0, 3.0)
		if value then out[key] = value end
	end

	for _, key in ipairs(Sci.Keys.toggle) do
		if patch[key] ~= nil then out[key] = patch[key] == true end
	end

	return out
end

function Sci.FindPreset(id)
	for _, preset in ipairs(Config.Presets) do
		if preset.id == id then return preset end
	end
end
