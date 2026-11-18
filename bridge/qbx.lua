Sci.RegisterAdapter('qbx', {
	priority = 20,  -- above qb: qbx_core ships qb-core alongside it
	detect = function() return GetResourceState('qbx_core') ~= 'missing' end,

	Init = function()
		if GetResourceState('qbx_core') ~= 'started' then return false end
		return (pcall(function() return exports.qbx_core:GetPlayers() end))
	end,

	GetGroups = function(src)
		local ok, perm = pcall(function() return exports.qbx_core:GetPermission(src) end)
		return ok and Sci.GroupList(perm) or {}
	end,
})
