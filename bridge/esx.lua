local ESX

Sci.RegisterAdapter('esx', {
	priority = 30,
	detect = function() return GetResourceState('es_extended') ~= 'missing' end,

	Init = function()
		local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
		if not ok or type(obj) ~= 'table' then return false end
		ESX = obj
		return true
	end,

	GetGroups = function(src)
		local xPlayer = ESX and ESX.GetPlayerFromId(src)
		if not xPlayer or not xPlayer.getGroup then return {} end
		local ok, group = pcall(xPlayer.getGroup)
		return ok and Sci.GroupList(group) or {}
	end,
})
