local Colors = {
	black = { 0, 0, 0 },
	red = { 1, 0.14, 0 },
	blue = { 0.02, 0.45, 1 },
	green = { 0, 1, 0.3 },
	yellow = { 1, 0.9, 0.1 },
	orange = { 0.9, 0.62, 0 },
	lightblue = { 0.3, 0.6, 1 },
	violet = { 1, 0.28, 0.6 },
}

local Config = {}

Config.template = {
	none = {
		type = "NONE",
		note = "CENTER",
		color = Colors.black,
	},
	default = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.blue,
		can_dim = true,
	},
	attack = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		can_dim = true,
	},
	instant_aoe = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.blue,
		can_dim = true,
	},
	reactive = {
		type = "REACTIVE",
		note = "RIGHT",
		color = Colors.red,
		can_dim = true,
	},
	self_buff = function(shared) 
		return {
			type = "SELFBUFF",
			note = "CENTER",
			color = Colors.yellow,
			can_dim = true,
			shared_buffs = shared or {},
		}
	end,
	dot = {
		type = "DEBUFF",
		note = "CENTER",
		color = {1, 0.3, 0},
		can_dim = true,
		subtract_cast_time = true,
	},
	debuff = function(count, shared) 
		return { type = "DEBUFF",
			note = count and "LEFT" or "CENTER",
			color = Colors.green,
			stacks = count or 0,
			can_dim = true,
			shared_debuffs = shared or {},
			show_stack_count = count,
		}
	end,
	melee = function(rage) return {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 1, 1 },
		need_target = true,
		can_dim = true,
		min_rage = rage,
	} end,
	slot_item = function(slot_name)
		return { type = "SLOTITEM",
			note = "RIGHT",
			color = Colors.lightblue,
			slot_id = GetInventorySlotInfo(slot_name) }
	end,
}

Config.gcd_spells = {"Hamstring", "Shadow Bolt"}
Config.enrage_auras = {"Berserker Rage", "Death Wish", "Enrage"}

Config.spells = {
	["Bloodthirst"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		can_dim = true,
	},
	["Whirlwind"] = Config.template.attack,
	["Execute"] = Config.template.reactive,
	["Overpower"] = Config.template.reactive,
	["Mortal Strike"] = {
		Config.template.attack,
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.red,
			need_target = true,
			can_dim = true,
			min_rage = 65,
		},
	},

	["Victory Rush"] = Config.template.attack,
	["Battle Shout"] = {
		Config.template.self_buff({"Horn of Winter", "Roar of Courage"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.orange,
			can_dim = true,
			max_rage = 70,
		}
	},
	["Commanding Shout"] = {
		Config.template.self_buff({"Power Word: Fortitude", "Blood Pact"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.orange,
			can_dim = true,
			max_rage = 70,
		}
	},
	["Devastate"] = Config.template.attack,
	["Revenge"] = Config.template.attack,
	["Shield Slam"] = Config.template.attack,
	["Bladestorm"] = Config.template.attack,
	["Shockwave"] = Config.template.instant_aoe,
	["Concussion Blow"] = Config.template.attack,
	["Sweeping Strikes"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = true
	},
	["Deadly Calm"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = true,
		min_rage = 60
	},
	["Retaliation"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = false,
		need_target = false,
	},
	["Recklessness"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = false,
		need_target = true,
		need_boss = true,
	},
	["Rampage"] = {
		type = "SELFBUFF",
		note = "LEFT",
		color = Colors.orange,
		can_dim = true
	},
	["Rend"] = {
		type = "DEBUFF",
		note = "RIGHT",
		color = Colors.red,
		stacks = 0,
		can_dim = true,
		shared_debuffs = {}
	},
	["Shield Block"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = true,
		need_no_aura = "Shield Block",
	},
	["Shield Barrier"] = {
		type = "SELFBUFF",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = true,
	},
	["Wild Strike"] = {
		{
			type = "REACTIVE",
			note = "RIGHT",
			color = Colors.red,
			can_dim = true,
			need_aura = "Bloodsurge",
		},
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.red,
			can_dim = true,
			min_rage = 80,
		},
	},
	["Demoralizing Shout"] = Config.template.debuff(nil, {"Demoralizing Roar"}),
	["Hamstring"] = Config.template.debuff(),
	["Thunder Clap"] = { Config.template.debuff(nil, {"Weakened Blows", "Frost Fever"}), Config.template.instant_aoe },
	["Sunder Armor"] = Config.template.debuff(3, {"Weakened Armor"}),
	["Heroic Strike"] = {
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			can_dim = true,
			min_rage = 80,
			also_lit_on_aura = "Ultimatum",
		},
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			can_dim = true,
			need_aura = "Ultimatum",
		},
	},
	["Cleave"] = Config.template.melee(55),
	["Raging Blow"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		can_dim = true,
		show_buff_count = "Raging Blow!",
	},
	["Dragon Roar"] = Config.template.instant_aoe,
	["Colossus Smash"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		can_dim = true,
		show_debuff = true,
	},
	["Blood Fury"] = { 
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0.5, 0.5, 1 },
		can_dim = true,
	},
	["Berserker Rage"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		can_dim = true,
		--need_no_enraged = true,
		dim_on_enrage = true,
	},
	["Inner Rage"] = Config.template.reactive,
	["Skull Banner"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
		can_dim = true,
	},
	["Avatar"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
		can_dim = true,
	},
	["Bloodbath"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
		can_dim = true,
	},
	["Disarm"] = Config.template.attack,
	["Demoralizing Banner"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.green,
	},
	["Pummel"] = Config.template.attack,

	["Shadow Bolt"] = Config.template.attack,
	["Immolate"] = Config.template.dot,
	["Corruption"] = Config.template.dot,
	["Bane of Agony"] = Config.template.dot,
	["Conflagrate"] = Config.template.attack,

	["Trinket 1"] = Config.template.slot_item("Trinket0Slot"),
	["Trinket 2"] = Config.template.slot_item("Trinket1Slot"),
}

GuiBarHero.Config = Config
