local DEADLINE_MS = 15000

local donor = Sci.Adapters.standalone
local adapter = donor

for _, def in pairs(Sci.Adapters) do
	local ok, found = pcall(def.detect)
	if ok and found and def.priority > adapter.priority then adapter = def end
end

local filled = {}

for _, fn in ipairs(Sci.Bridge.REQUIRED) do
	if type(adapter[fn]) == 'function' then
		Sci.Bridge[fn] = adapter[fn]
	else
		Sci.Bridge[fn] = donor[fn]
		filled[#filled + 1] = fn
	end
end

Sci.Bridge.Name = adapter.name

if #filled > 0 then
	Sci.Warn('bridge %s: filled from standalone - %s', adapter.name, table.concat(filled, ', '))
end

CreateThread(function()
	local deadline = GetGameTimer() + DEADLINE_MS

	while GetGameTimer() < deadline do
		local ok, ready = pcall(Sci.Bridge.Init)
		if ok and ready then
			Sci.Log('bridge: %s', adapter.name)
			return
		end
		Wait(500)
	end

	Sci.Warn('bridge %s did not start within %ds, using standalone', adapter.name, DEADLINE_MS / 1000)

	for _, fn in ipairs(Sci.Bridge.REQUIRED) do Sci.Bridge[fn] = donor[fn] end
	Sci.Bridge.Name = 'standalone'
end)
