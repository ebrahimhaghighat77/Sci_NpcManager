local open = false

local function openPanel(payload)
	if open or type(payload) ~= 'table' then return end
	open = true
	SetNuiFocus(true, true)
	SendNUIMessage({ type = 'openPanel', data = payload })
end

local function closePanel()
	if not open then return end
	open = false
	SetNuiFocus(false, false)
	SendNUIMessage({ type = 'closePanel' })
end

RegisterNetEvent('Sci_NpcManager:openPanel', openPanel)

local function proxy(endpoint)
	RegisterNUICallback(endpoint, function(data, cb)
		cb(lib.callback.await('Sci_NpcManager:' .. endpoint, false, data) or { err = 'no_response' })
	end)
end

proxy('apply')
proxy('preset')
proxy('purge')

RegisterNUICallback('close', function(_, cb)
	closePanel()
	cb({ ok = true })
end)

CreateThread(function()
	while true do
		if open then
			local peds = 0
			for _, ped in ipairs(GetGamePool('CPed')) do
				if not IsPedAPlayer(ped) then peds = peds + 1 end
			end

			SendNUIMessage({
				type = 'stats',
				data = { peds = peds, vehicles = #GetGamePool('CVehicle'), zone = Sci.Zone, hour = GetClockHours() },
			})
		end
		Wait(1000)
	end
end)

AddEventHandler('esx:onPlayerDeath', closePanel)
AddEventHandler('gameEventTriggered', function(event)
	if open and event == 'CEventNetworkEntityDamage' and IsPedDeadOrDying(PlayerPedId(), true) then closePanel() end
end)

AddEventHandler('onResourceStop', function(resource)
	if open and resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)

if Config.OpenKey ~= '' then
	RegisterCommand('+scinpc_panel', function()
		local reply = lib.callback.await('Sci_NpcManager:open', false)
		if reply and reply.ok then openPanel(reply.data) end
	end, false)
	RegisterCommand('-scinpc_panel', function() end, false)
	RegisterKeyMapping('+scinpc_panel', 'Open the NPC manager panel', 'keyboard', Config.OpenKey)
end
