Sci.Bridge = { REQUIRED = { 'Init', 'GetGroups' } }
Sci.Adapters = {}

function Sci.RegisterAdapter(name, def)
	def.name = name
	def.priority = def.priority or 0
	Sci.Adapters[name] = def
end

function Sci.GroupList(value)
	if type(value) == 'string' then return { value } end
	if type(value) ~= 'table' then return {} end

	local out = {}
	for key, flag in pairs(value) do
		if type(key) == 'number' then out[#out + 1] = tostring(flag)
		elseif flag then out[#out + 1] = tostring(key) end
	end
	return out
end

-- vmp_license mints a license that GetPlayerIdentifiers() does not include.
function Sci.MintedLicense(src)
	if GetResourceState('vmp_license') ~= 'started' then return nil end
	local ok, license = pcall(function() return exports.vmp_license:GetLicense(src) end)
	if ok and type(license) == 'string' and license ~= '' then return license end
end
