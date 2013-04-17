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
	},
	attack = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
	},
	instant_aoe = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.blue,
	},
	reactive = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
	},
	self_buff = function(shared) 
		return {
			type = "SELFBUFF",
			note = "CENTER",
			color = Colors.yellow,
			shared_buffs = shared or {},
		}
	end,
	dot = {
		type = "DEBUFF",
		note = "CENTER",
		color = {1, 0.3, 0},
		subtract_cast_time = true,
	},
	debuff = function(count, shared, show) 
		return { type = "DEBUFF",
			note = count and "LEFT" or "CENTER",
			color = Colors.green,
			stacks = count or 0,
			shared_buffs = shared or {},
			show_stack_count = count,
			show_debuff = show, 
			needs_target = true,
		}
	end,
	melee = function(rage) 
		return {
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			min_rage = rage,
		} 
	end,
	slot_item = function(slot_name)
		return { 
			type = "SLOTITEM",
			note = "RIGHT",
			color = Colors.lightblue,
			slot_id = GetInventorySlotInfo(slot_name),
		}
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
			min_rage = 65,
		},
	},

	["Victory Rush"] = Config.template.attack,
	["Battle Shout"] = {
		Config.template.self_buff({"Horn of Winter", "Roar of Courage", "Trueshot Aura"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.orange,
			max_rage = 70,
		}
	},
	["Commanding Shout"] = {
		Config.template.self_buff({"Power Word: Fortitude", "Blood Pact"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.orange,
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
	},
	["Deadly Calm"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		min_rage = 60
	},
	["Retaliation"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		need_target = false,
	},
	["Recklessness"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		need_target = true,
		need_boss = true,
	},
	["Rampage"] = {
		type = "SELFBUFF",
		note = "LEFT",
		color = Colors.orange,
	},
	["Rend"] = {
		type = "DEBUFF",
		note = "RIGHT",
		color = Colors.red,
		stacks = 0,
		shared_buffs = {}
	},
	["Shield Block"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		need_no_aura = "Shield Block",
	},
	["Shield Barrier"] = {
		type = "SELFBUFF",
		note = "RIGHT",
		color = Colors.orange,
	},
	["Shield Wall"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.blue,
		show_buff = true,
	},
	["Wild Strike"] = {
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.red,
			need_aura = "Bloodsurge",
			show_buff_count = "Bloodsurge",
		},
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = Colors.red,
			min_rage = 80,
		},
	},
	["Demoralizing Shout"] = Config.template.debuff(nil, {"Demoralizing Roar"}, true),
	["Hamstring"] = Config.template.debuff(),
	["Thunder Clap"] = { Config.template.debuff(nil, {"Weakened Blows", "Frost Fever"}), Config.template.instant_aoe },
	["Sunder Armor"] = Config.template.debuff(3, {"Weakened Armor"}),
	["Heroic Strike"] = {
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			min_rage = 80,
			also_lit_on_aura = "Ultimatum",
		},
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			need_aura = "Ultimatum",
		},
	},
	["Cleave"] = Config.template.melee(55),
	["Raging Blow"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		show_buff_count = "Raging Blow!",
	},
	["Dragon Roar"] = Config.template.instant_aoe,
	["Colossus Smash"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.red,
		need_target = true,
		show_debuff = true,
	},
	["Blood Fury"] = { 
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0.5, 0.5, 1 },
		show_buff = true,
	},
	["Berserker Rage"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.orange,
		dim_on_enrage = true,
	},
	["Inner Rage"] = Config.template.reactive,
	["Skull Banner"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
	},
	["Avatar"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
		show_buff = true,
	},
	["Bloodbath"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = Colors.violet,
		show_buff = true,
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
