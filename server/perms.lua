local SHOWN_KINDS = { 'license', 'vmp', 'fivem', 'discord', 'steam' }

-- A prefixed owner only matches that identifier kind.
local exact, bare = {}, {}
for _, raw in ipairs(Config.Owners) do
	local id = tostring(raw):match('^%s*(.-)%s*$'):lower()
	if id:find(':', 1, true) then exact[id] = true elseif id ~= '' then bare[id] = true end
end

local function identifiers(src)
	local ids = GetPlayerIdentifiers(src) or {}
	ids[#ids + 1] = Sci.MintedLicense(src)
	return ids
end

function Sci.IsOwner(src)
	for _, id in ipairs(identifiers(src)) do
		id = id:lower()
		if exact[id] or bare[id:match(':(.+)$') or id] then return true end
	end
	return false
end

local function shownIdentifier(ids)
	for _, kind in ipairs(SHOWN_KINDS) do
		for _, id in ipairs(ids) do
			if id:sub(1, #kind + 1) == kind .. ':' then return id end
		end
	end
	return 'no-identifier'
end

function Sci.Describe(src)
	src = tonumber(src) or 0
	if src == 0 then return 'console' end
	return ('%s [%d] (%s)'):format(GetPlayerName(src) or 'unknown', src, shownIdentifier(identifiers(src)))
end

local providers = {
	sci_admin = function(src, node)
		local wanted = Config.Permissions.sciAdmin[node]
		local res = Config.Permissions.adminResource or 'Sci_Adminmenu'
		if not wanted or GetResourceState(res) ~= 'started' then return nil end

		local ok, allowed = pcall(function()
			if wanted == true then return exports[res]:isPlayerAdmin(src) end
			return exports[res]:isPlayerAllowed(src, wanted)
		end)
		if not ok then return nil end

		-- A running admin menu's no is final.
		return allowed == true
	end,

	ace = function(src, node)
		local ace = Config.Permissions.ace[node]
		return ace and IsPlayerAceAllowed(tostring(src), ace) or nil
	end,

	group = function(src, node)
		local wanted = Config.Permissions.groups[node]
		if not wanted then return nil end

		for _, group in ipairs(Sci.Bridge.GetGroups(src)) do
			for _, name in ipairs(wanted) do
				if group:lower() == name:lower() then return true end
			end
		end
		return nil
	end,

	custom = function(src, node)
		local ok, answer = pcall(Config.Permissions.custom, src, node)
		if ok then return answer end
		return nil
	end,
}

function SciPerm(src, node)
	src = tonumber(src) or 0
	if src == 0 then return true end
	if Sci.IsOwner(src) then return true end

	for _, name in ipairs(Config.Permissions.providers) do
		local provider = providers[name]
		local answer = provider and provider(src, node)
		if answer == true then return true end
		if answer == false then return false end
	end

	return false
end
