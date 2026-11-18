Sci.RegisterAdapter('standalone', {
	priority = 0,
	detect = function() return true end,
	Init = function() return true end,
	GetGroups = function() return {} end,
})
