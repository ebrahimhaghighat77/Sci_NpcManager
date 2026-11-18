local protectedModels, protectedPeds = {}, {}
local lastSweep, lastPrune = 0, 0

for _, model in ipairs(Config.ProtectedModels) do
	protectedModels[type(model) == 'number' and model or joaat(model)] = true
end

local function inProtectedZone(coords)
	for _, zone in ipairs(Config.ProtectedZones) do
		if #(coords - zone.coords) <= zone.radius then return true end
	end
	return false
end

local function flagged(entity)
	local ok, value = pcall(function() return Entity(entity).state.sciNpcProtected end)
	return ok and value == true
end

local function pedProtected(ped, s)
	local me = PlayerPedId()

	if ped == me or IsPedAPlayer(ped) or protectedPeds[ped] or IsEntityAMissionEntity(ped) then return true end
	if protectedModels[GetEntityModel(ped)] or IsEntityAttachedToEntity(ped, me) or flagged(ped) then return true end
	if inProtectedZone(GetEntityCoords(ped)) then return true end

	if Config.Purge.keepDead and IsPedDeadOrDying(ped, true) then return true end
	if Config.Purge.keepInVeh and IsPedInAnyVehicle(ped, false) then return true end

	if GetPedType(ped) == 28 then return Config.Purge.keepAnimals or s.wildlife end

	return false
end

local function vehicleProtected(vehicle, mine)
	if vehicle == mine or IsEntityAMissionEntity(vehicle) or flagged(vehicle) then return true end
	if inProtectedZone(GetEntityCoords(vehicle)) then return true end

	for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
		local occupant = GetPedInVehicleSeat(vehicle, seat)
		if occupant ~= 0 and IsPedAPlayer(occupant) then return true end
	end
	return false
end

local function delete(entity)
	if NetworkGetEntityIsNetworked(entity) then
		NetworkRequestControlOfEntity(entity)
		if not NetworkHasControlOfEntity(entity) then return false end
	end

	SetEntityAsMissionEntity(entity, true, true)
	DeleteEntity(entity)
	return not DoesEntityExist(entity)
end

local function inRange(entity, origin, radius)
	return radius <= 0.0 or #(GetEntityCoords(entity) - origin) <= radius
end

function Sci.Sweep(s)
	local origin = GetEntityCoords(PlayerPedId())
	local radius = Config.Purge.radius or 0.0
	local peds, cars = 0, 0

	if s.purge then
		for _, ped in ipairs(GetGamePool('CPed')) do
			if DoesEntityExist(ped) and not pedProtected(ped, s) and inRange(ped, origin, radius) and delete(ped) then
				peds = peds + 1
			end
		end
	end

	if s.purgeCars then
		local mine = GetVehiclePedIsIn(PlayerPedId(), false)
		for _, vehicle in ipairs(GetGamePool('CVehicle')) do
			if DoesEntityExist(vehicle) and not vehicleProtected(vehicle, mine) and inRange(vehicle, origin, radius)
				and delete(vehicle) then
				cars = cars + 1
			end
		end
	end

	lastSweep = GetGameTimer()
	return peds, cars
end

local function forced()
	return Sci.Merge(Sci.Effective, { purge = true, purgeCars = true })
end

RegisterNetEvent('Sci_NpcManager:purgeNow', function()
	local peds, cars = Sci.Sweep(forced())
	Sci.Debug('manual sweep removed %d peds and %d vehicles', peds, cars)
end)

CreateThread(function()
	while true do
		local s = Sci.Effective
		local sweeping = s.enabled and (s.purge or s.purgeCars)

		if sweeping then Sci.Sweep(s) end

		if GetGameTimer() - lastPrune > 30000 then
			lastPrune = GetGameTimer()
			for entity in pairs(protectedPeds) do
				if not DoesEntityExist(entity) then protectedPeds[entity] = nil end
			end
		end

		Wait(sweeping and Config.Purge.interval or 1000)
	end
end)

exports('ProtectPed', function(entity)
	if not entity or not DoesEntityExist(entity) then return false end
	protectedPeds[entity] = true
	return true
end)

exports('UnprotectPed', function(entity)
	protectedPeds[entity] = nil
	return true
end)

exports('Sweep', function() return Sci.Sweep(forced()) end)
exports('LastSweep', function() return lastSweep end)
