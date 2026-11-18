local QB

Sci.RegisterAdapter('qb', {
	priority = 10,
	detect = function() return GetResourceState('qb-core') ~= 'missing' end,

	Init = function()
		local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
		if not ok or type(obj) ~= 'table' then return false end
		QB = obj
		return true
	end,

	GetGroups = function(src)
		if not QB or not QB.Functions.GetPermission then return {} end
		local ok, perm = pcall(QB.Functions.GetPermission, src)
		return ok and Sci.GroupList(perm) or {}
	end,
})
