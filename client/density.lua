local function budgetFor(multiplier)
	if multiplier <= 0.0 then return 0 end
	if multiplier < 0.4 then return 1 end
	if multiplier < 0.8 then return 2 end
	return 3
end

local function suppress(models, suppressed, isVehicle)
	for _, model in ipairs(models) do
		local hash = type(model) == 'number' and model or joaat(model)
		if isVehicle then
			SetVehicleModelIsSuppressed(hash, suppressed)
		else
			SetPedModelIsSuppressed(hash, suppressed)
		end
	end
end

local function applySticky(s)
	local on = s.enabled

	SetPedPopulationBudget(on and budgetFor(s.peds) or 3)
	SetVehiclePopulationBudget(on and budgetFor(s.vehicles) or 3)

	local cops = not on or s.cops
	SetCreateRandomCops(cops)
	SetCreateRandomCopsNotOnScenarios(cops)
	SetCreateRandomCopsOnScenarios(cops)
	DistantCopCarSirens(cops)

	SetGarbageTrucks(not on or s.garbage)
	SetRandomBoats(not on or s.boats)
	SetRandomTrains(not on or s.trains)

	suppress(Config.WildlifeModels, on and not s.wildlife, false)
	suppress(Config.SuppressedPedModels, on, false)
	suppress(Config.SuppressedVehicleModels, on, true)
end

Sci.Watch(applySticky)

CreateThread(function()
	while true do
		local s = Sci.Effective

		if s.enabled then
			SetPedDensityMultiplierThisFrame(s.peds)
			SetScenarioPedDensityMultiplierThisFrame(s.scenarios, s.scenarios)
			SetVehicleDensityMultiplierThisFrame(s.vehicles)
			SetRandomVehicleDensityMultiplierThisFrame(s.vehicles)
			SetParkedVehicleDensityMultiplierThisFrame(s.parked)
			SetAmbientVehicleRangeMultiplierThisFrame(s.vehicles)
			Wait(0)
		else
			Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then applySticky({ enabled = false }) end
end)
