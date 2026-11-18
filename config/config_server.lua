Config = Config or {}

-- Any identifier kind, prefix optional: 'license:abc', 'vmp:12345', 'discord:123' or 'abc'.
Config.Owners = {
}

Config.Permissions = {
	providers = { 'sci_admin', 'ace', 'group', 'custom' },  -- in order; first yes wins, a no stops

	adminResource = 'Sci_Adminmenu',
	sciAdmin = { ['npc.manage'] = 'npc.manage' },  -- admin menu node, or true for any admin on duty
	ace      = { ['npc.manage'] = 'sci_npc.admin' },
	groups   = { ['npc.manage'] = { 'admin', 'superadmin', 'owner', 'god', 'mod' } },

	custom = function(src, node) return nil end,  -- true or false decides, nil passes
}

Config.AntiCheat = {
	enabled     = true,
	strikes     = 5,      -- denied panel calls inside windowMs before acting
	windowMs    = 20000,
	banResource = 'Sci_Adminmenu',
	banExport   = 'bancheater',
	dropOnFail  = true,   -- drop the player when no ban resource answers
	logAll      = true,
}

Config.Webhook = {
	url      = '',
	username = nil,  -- nil uses Config.Brand.tag
	colour   = 3050731,
}

Config.AutoScale = {
	enabled = false,
	tiers = {
		{ players = 32, factor = 0.75 },
		{ players = 48, factor = 0.55 },
		{ players = 64, factor = 0.35 },
	},
}
