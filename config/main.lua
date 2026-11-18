Config = Config or {}

Config.Debug = false

Config.Brand = {
	tag   = 'Sci NPC',       -- notification title; its capitals become the logo monogram
	name  = 'SciDev',
	title = 'NPC Manager',
	logo  = 'img/logo.png',  -- relative to html/, or an https:// URL; '' shows the monogram
}

-- Omitted keys keep the values in html/styles.css.
Config.Theme = {
	accent     = '#2b8fff',
	accentDeep = '#0a63e6',
	accentSoft = nil,  -- nil derives it from accent
	panelFrom  = 'rgb(22, 32, 47)',
	panelTo    = 'rgb(12, 18, 28)',
	cardFrom   = 'rgba(255, 255, 255, 0.045)',
	cardTo     = 'rgba(255, 255, 255, 0.02)',
	stroke     = 'rgba(255, 255, 255, 0.09)',
	strokeSoft = 'rgba(255, 255, 255, 0.06)',
	text       = '#eaf1f8',
	textDim    = '#9db2c9',
	textFaint  = '#5f7893',
	ok         = '#31d17e',
	warn       = '#f5b13d',
	bad        = '#ff5c6c',
	scrim      = 'rgba(4, 8, 14, 0.35)',  -- 'transparent' disables it
	radius      = 18,
	radiusSmall = 11,
	font = "'Segoe UI', 'Inter', system-ui, -apple-system, sans-serif",
}

Config.Command = 'scinpc'
Config.OpenKey = ''  -- e.g. 'F7'; '' registers no keybind

Config.Notify = {
	order = { 'okokNotify', 'esx_notify', 'mythic_notify', 't-notify', 'ox_lib' },  -- first running one wins
}

Config.SaveState = true  -- keep panel changes in settings.json across restarts

-- Densities run 0.0 - 3.0; 1.0 is stock GTA.
Config.Defaults = {
	enabled   = true,
	peds      = 1.0,
	scenarios = 1.0,
	vehicles  = 1.0,
	parked    = 1.0,
	cops      = true,
	garbage   = true,
	boats     = true,
	trains    = true,
	wildlife  = true,
	purge     = false,  -- keep deleting ambient peds already out
	purgeCars = false,  -- same for ambient traffic
}

Config.Presets = {
	{
		id = 'empty', label = 'Empty city', desc = 'Nothing spawns and what is already out is swept.',
		settings = { enabled = true, peds = 0.0, scenarios = 0.0, vehicles = 0.0, parked = 0.0, cops = false,
			garbage = false, boats = false, trains = false, wildlife = false, purge = true, purgeCars = true },
	},
	{
		id = 'nopeds', label = 'No pedestrians', desc = 'Streets empty of people, traffic keeps flowing.',
		settings = { enabled = true, peds = 0.0, scenarios = 0.0, vehicles = 1.0, parked = 1.0, cops = false,
			garbage = true, boats = true, trains = true, wildlife = true, purge = true, purgeCars = false },
	},
	{
		id = 'low', label = 'Quiet', desc = 'About a third of the usual crowd. Easy on low-end PCs.',
		settings = { enabled = true, peds = 0.3, scenarios = 0.3, vehicles = 0.35, parked = 0.5, cops = false,
			garbage = false, boats = true, trains = true, wildlife = true, purge = false, purgeCars = false },
	},
	{
		id = 'normal', label = 'Vanilla', desc = 'Stock GTA population.',
		settings = { enabled = true, peds = 1.0, scenarios = 1.0, vehicles = 1.0, parked = 1.0, cops = true,
			garbage = true, boats = true, trains = true, wildlife = true, purge = false, purgeCars = false },
	},
	{
		id = 'busy', label = 'Busy', desc = 'Crowded pavements and heavy traffic.',
		settings = { enabled = true, peds = 1.6, scenarios = 1.6, vehicles = 1.5, parked = 1.4, cops = true,
			garbage = true, boats = true, trains = true, wildlife = true, purge = false, purgeCars = false },
	},
}

Config.Purge = {
	interval    = 1500,   -- ms between sweeps
	radius      = 0.0,    -- 0 sweeps everything the client has streamed in
	keepAnimals = false,  -- spare animals even while wildlife is off
	keepInVeh   = true,   -- spare drivers and passengers
	keepDead    = true,
}

Config.ProtectedModels = {
	'mp_m_shopkeep_01', 's_m_y_ammucity_01', 's_m_m_ammucountry', 's_f_y_scrubs_01',
	's_m_m_doctor_01', 'ig_barry', 'csb_burgerdrug',
}

Config.ProtectedZones = {
	-- { name = 'Pillbox', coords = vec3(298.6, -584.4, 43.2), radius = 25.0 },
}

Config.SuppressedPedModels = {
	-- 'a_m_y_methhead_01',
}

Config.SuppressedVehicleModels = {
	-- 'taco', 'trash',
}

Config.WildlifeModels = {
	'a_c_deer', 'a_c_coyote', 'a_c_mtlion', 'a_c_boar', 'a_c_rabbit_01', 'a_c_cormorant', 'a_c_crow',
	'a_c_seagull', 'a_c_pigeon', 'a_c_hen', 'a_c_chickenhawk', 'a_c_rat', 'a_c_chop', 'a_c_husky',
	'a_c_shepherd', 'a_c_retriever', 'a_c_poodle', 'a_c_pug', 'a_c_westy', 'a_c_cat_01',
}

Config.Zones = {
	-- { name = 'Airport', coords = vec3(-1037.0, -2737.0, 20.0), radius = 300.0, priority = 1, settings = { peds = 0.2 } },
}

Config.Schedule = {
	enabled = false,
	hours = {  -- in-game hours; `to` is exclusive and may wrap past midnight
		{ from = 2,  to = 6,  settings = { peds = 0.25, vehicles = 0.3 } },
		{ from = 7,  to = 10, settings = { peds = 1.2,  vehicles = 1.3 } },
		{ from = 17, to = 20, settings = { peds = 1.2,  vehicles = 1.3 } },
	},
}
