local EPS = { time = 0.1 }

local DEBUG = { bars_created = 0, textures_created = 0 }

local LAYOUT = { 
	main = { border = 4, alpha = 0.8 },
	bar = { height = 16, width = 410, skip = 7, max = 20, dim_alpha = 0.4, speed = 30 }, 
	icon = { height = 20, width = 20, dist = 1, vdist = 4, skip = 8, alpha = 0.7 },
	large_icon = { height = 30, width = 30, dist = 4, skip = 8, max = 11, alpha = 1, dim_alpha = 0.2 },
	profile = { height = 20, width = 30, dist = 2, skip = 8, max = 10, font = "Fonts\\FRIZQT__.TTF", font_size = 14, current_color = {1, 1, 1, 1}, color = {.7, .7, .7, .5} },
	chord = { height = 8, width = 64, alpha = .7, path = "Interface\\AddOns\\GuiBarHero\\Textures\\Horizontal" },
	right_note = { height = 16, width = 16, offset = 0, path = "Interface\\AddOns\\GuiBarHero\\Textures\\Rightarrow" },
	left_note = { height = 16, width = 16, offset = -16, path = "Interface\\AddOns\\GuiBarHero\\Textures\\Leftarrow" },
	center_note = { height = 16, width = 16, offset = -8, path = "Interface\\AddOns\\GuiBarHero\\Textures\\Circle" },
	bridge = { x = 20, width = 5, offset = -2.5, color = {1,1,1,.4} }
}

local TEMPLATE = {
	none = {
		type = "NONE",
		note = "CENTER",
		color = { 0, 0, 0 },
	},
	default = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0, 0, 1 },
		can_dim = true,
	},
	attack = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 0, 0 },
		need_target = true,
		can_dim = true,
	},
	instant_aoe = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0, 0, 1 },
		can_dim = true,
	},
	reactive = {
		type = "REACTIVE",
		note = "RIGHT",
		color = { 1, 0, 0 },
		can_dim = true,
	},
	self_buff = function(shared) 
		return {
			type = "SELFBUFF",
			note = "CENTER",
			color = { 1, 1, 0 },
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
			color = { 0, 1, 0 },
			stacks = count or 0,
			can_dim = true,
			shared_debuffs = shared or {},
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
			color = { 0.5, 0.5, 1 },
			slot_id = GetInventorySlotInfo(slot_name) }
	end,
}

local GCD_SPELLS = {"Hamstring", "Shadow Bolt"}
local ENRAGE_AURAS = {"Berserker Rage", "Death Wish", "Enrage"}

local SPELLS = {
	["Bloodthirst"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 0, 0 },
		need_target = true,
		can_dim = true,
	},
	["Whirlwind"] = TEMPLATE.attack,
	["Execute"] = TEMPLATE.reactive,
	["Overpower"] = TEMPLATE.reactive,
	["Mortal Strike"] = {
		TEMPLATE.attack,
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 0, 0 },
			need_target = true,
			can_dim = true,
			min_rage = 65,
		},
	},

	["Victory Rush"] = TEMPLATE.attack,
	["Battle Shout"] = {
		TEMPLATE.self_buff({"Horn of Winter", "Roar of Courage"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, .5, 0 },
			can_dim = true,
			max_rage = 70,
		}
	},
	["Commanding Shout"] = {
		TEMPLATE.self_buff({"Power Word: Fortitude", "Blood Pact"}),
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, .5, 0 },
			can_dim = true,
			max_rage = 70,
		}
	},
	["Devastate"] = TEMPLATE.attack,
	["Revenge"] = TEMPLATE.attack,
	["Shield Slam"] = TEMPLATE.attack,
	["Bladestorm"] = TEMPLATE.attack,
	["Shockwave"] = TEMPLATE.instant_aoe,
	["Concussion Blow"] = TEMPLATE.attack,
	["Sweeping Strikes"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = true
	},
	["Deadly Calm"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = true
	},
	["Retaliation"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = false,
		need_target = false,
	},
	["Recklessness"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = false,
		need_target = true,
		need_boss = true,
	},
	["Rampage"] = {
		type = "SELFBUFF",
		note = "LEFT",
		color = { 1, .5, 0 },
		can_dim = true
	},
	["Rend"] = {
		type = "DEBUFF",
		note = "RIGHT",
		color = { 1, 0, 0 },
		stacks = 0,
		can_dim = true,
		shared_debuffs = {}
	},
	["Shield Block"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = true,
		need_no_aura = "Shield Block",
	},
	["Wild Strike"] = {
		{
			type = "REACTIVE",
			note = "RIGHT",
			color = { 1, 0, 0 },
			can_dim = true,
			need_aura = "Bloodsurge",
		},
		TEMPLATE.attack
	},
	["Demoralizing Shout"] = TEMPLATE.debuff(nil, {"Demoralizing Roar"}),
	["Hamstring"] = TEMPLATE.debuff(),
	["Thunder Clap"] = { TEMPLATE.debuff(nil, {"Weakened Blows", "Frost Fever"}), TEMPLATE.instant_aoe },
	["Sunder Armor"] = TEMPLATE.debuff(5),
	["Heroic Strike"] = {
		{
			type = "COOLDOWN",
			note = "RIGHT",
			color = { 1, 1, 1 },
			need_target = true,
			can_dim = true,
			min_rage = 70,
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
	["Cleave"] = TEMPLATE.melee(55),
	["Raging Blow"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 0, 0 },
		need_target = true,
		can_dim = true,
		need_enraged = true,
	},
	["Dragon Roar"] = TEMPLATE.instant_aoe,
	["Colossus Smash"] = TEMPLATE.attack,
	["Blood Fury"] = { 
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0.5, 0.5, 1 },
		can_dim = true,
	},
	["Berserker Rage"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, .5, 0 },
		can_dim = true,
		need_no_enraged = true,
	},
	["Inner Rage"] = TEMPLATE.reactive,
	["Skull Banner"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 0, 1 },
		can_dim = true,
	},
	["Avatar"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 1, 0, 1 },
		can_dim = true,
	},
	["Disarm"] = TEMPLATE.attack,
	["Demoralizing Banner"] = {
		type = "COOLDOWN",
		note = "RIGHT",
		color = { 0, 1, 0 },
	},
	["Pummel"] = TEMPLATE.attack,

	["Shadow Bolt"] = TEMPLATE.attack,
	["Immolate"] = TEMPLATE.dot,
	["Corruption"] = TEMPLATE.dot,
	["Bane of Agony"] = TEMPLATE.dot,
	["Conflagrate"] = TEMPLATE.attack,

	["Trinket 1"] = TEMPLATE.slot_item("Trinket0Slot"),
	["Trinket 2"] = TEMPLATE.slot_item("Trinket1Slot"),
}

local OPTIONS = {
	type = 'group',
	args = {
		show = {
			type = 'execute',
			name = 'show',
			desc = 'Show GuiBars.',
			func = function()
				GuiBarHero:Show()
			end
		},
		hide = {
			type = 'execute',
			name = 'hide',
			desc = 'Hide GuiBars.',
			func = function()
				GuiBarHero:Hide()
			end
		},
		debug = {
			type = 'execute',
			name = 'debug',
			desc = 'Show debug information.',
			func = function()
				GuiBarHero:Print("" .. DEBUG.bars_created .. " bars and " .. DEBUG.textures_created .. " textures created.")
			end
		},
		bar = {
			type = 'input',
			name = 'bar',
			desc = 'Add a new GuiBar.',
			get = false,
			set = function(value)
				local _, _, nr, spell_name = string.find(value, '(%d*)%s*(.*)')
				if spell_name == "" then spell_name = nil end
				nr = tonumber(nr)
				if nr then
					GuiBarHero:InsertBar(nr, spell_name)
				end
			end,
			usage = '<bar number> <spell name>'
		},
		icon = {
			type = 'input',
			name = 'icon',
			desc = 'Add a new GuiIcon.',
			get = false,
			set = function(value)
				local _, _, nr, spell_name = string.find(value, '(%d*)%s*(.*)')
				nr = tonumber(nr)
				if nr then
					GuiBarHero:InsertBar(nr, spell_name, true)
				end
			end,
			usage = '<bar number> <spell name>'
		},
		icons = {
			type = 'toggle',
			name = 'icons',
			desc = 'Will the single icons be displayed on top of the main frame?',
			get = function()
				return GuiBarHero.db.char.icons_on_top
			end,
			set = function(v)
				GuiBarHero.db.char.icons_on_top = not not v
				GuiBarHero:RefreshBars()
			end,
		}
	}
}

local MainFrame = {}
local MainFrame_mt = { __index = MainFrame }

local Bar = {}
local Bar_mt = { __index = Bar }



GuiBarHero = LibStub("AceAddon-3.0"):NewAddon("GuiBarHero3", "AceConsole-3.0", "AceEvent-3.0")
LibStub("AceConfig-3.0"):RegisterOptionsTable("GuiBarHero3", OPTIONS, {"guibarhero", "gbh"})

local DB_DEFAULTS = { 
	char = {
		profiles = { { bars = {}, icons = {} } },
		current_profile = 1,
		shown = true,
		icons_on_top = false,
	},
}


function GuiBarHero:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GuiBarHero3DB", DB_DEFAULTS)
end

function GuiBarHero:OnEnable()
	self:Print("GuiBarHero enabled.")
	self.main_frame = MainFrame:Create()
	self:RefreshBars()
	if self.db.char.shown then 
		self:Show()
	else
		self:Hide()
	end
	self:RegisterEvent("SPELLS_CHANGED", "OnSpellsChanged")
end

function GuiBarHero:OnDisable()
end

function GuiBarHero:OnSpellsChanged()
	self:RefreshBars()
end

function GuiBarHero:GetNumSpellBookItems()
	local t = GetNumSpellTabs()
	local n
	while true do
		local name, texture, offset, numSpells = GetSpellTabInfo(t)
		if not name then
			break
		end
		n = offset + numSpells
		t = t + 1
	end
	return n
end

function GuiBarHero:Show()
	self.db.char.shown = true
	self.main_frame:Show()
end

function GuiBarHero:Hide()
	self.db.char.shown = false
	self.main_frame:Hide()
end

function GuiBarHero:SetCurrentProfile(nr)
	if nr > 0 and nr <= LAYOUT.profile.max then
		self.db.char.current_profile = nr
		if not self.db.char.profiles[nr] then
			self.db.char.profiles[nr] = { bars = {}, icons = {} }
		end
		self:RefreshBars()
	end
end

function GuiBarHero:RefreshBars()
	self.main_frame.profile_frame:ClearAllPoints()
	self.main_frame.icon_frame:ClearAllPoints()
	if self.db.char.icons_on_top then
		self.main_frame.profile_frame:SetPoint("BOTTOMLEFT", LAYOUT.main.border, - LAYOUT.profile.dist - LAYOUT.profile.height)
		self.main_frame.icon_frame:SetPoint("TOPLEFT", LAYOUT.main.border, LAYOUT.large_icon.dist + LAYOUT.large_icon.height)
	else
		self.main_frame.icon_frame:SetPoint("BOTTOMLEFT", LAYOUT.main.border, - LAYOUT.large_icon.dist - LAYOUT.large_icon.height)
		self.main_frame.profile_frame:SetPoint("TOPLEFT", LAYOUT.main.border, LAYOUT.profile.dist + LAYOUT.profile.height)
	end
	local profile = self.db.char.current_profile
	for i = 1, LAYOUT.profile.max do
		self.main_frame.profile_buttons[i]:SetTextColor(unpack(LAYOUT.profile.color))
	end
	self.main_frame.profile_buttons[profile]:SetTextColor(unpack(LAYOUT.profile.current_color))
	self.main_frame:SetBars(self.db.char.profiles[profile].bars)
	self.main_frame:SetBars(self.db.char.profiles[profile].icons, true)
end

function GuiBarHero:InsertBar(nr, spell_name, icon)
	local max, db
	local profile = self.db.char.current_profile
	if icon then
		max = LAYOUT.large_icon.max
		db = GuiBarHero.db.char.profiles[profile].icons
	else
		db = GuiBarHero.db.char.profiles[profile].bars
		max = #db + (spell_name and 1 or 0)
	end
	if nr > 0 and nr <= max and (icon or #db < LAYOUT.bar.max) then
		local slot, full_name 
		if spell_name and spell_name ~= "" then slot, full_name = GuiBarHero:FindSpell(spell_name) end
		if full_name then 
			if db[nr] and db[nr].name == full_name then
				db[nr].alt = (db[nr].alt or 1) + 1
			else
				if icon then
					db[nr] = { name = full_name };
				else
					table.insert(db, nr, { name = full_name })
				end
			end
		else
			if icon then
				db[nr] = nil
			else
				table.remove(db, nr)
			end
		end
		GuiBarHero:RefreshBars()
	end
end

function GuiBarHero:GetBarSpellName(nr, icons)
	local profile = self.db.char.current_profile
	local db = icons and self.db.char.profiles[profile].icons or self.db.char.profiles[profile].bars
	return db[nr] and db[nr].name
end

function GuiBarHero:FindSpell(name)
	name = string.lower(name)
	if name == "trinket 1" then 
		return "Trinket 1", "Trinket 1"
	elseif name == "trinket 2" then
		return "Trinket 2", "Trinket 2"
	end
	local slot_id = 1
	for slot_id = 1, GuiBarHero:GetNumSpellBookItems() do
		local full_name = GetSpellBookItemName(slot_id, BOOKTYPE_SPELL)
		if not full_name then return nil end
		if string.lower(full_name) == name then
			return slot_id, full_name
		end
	end
	return nil
end


function MainFrame:Create()
	main_frame = {}
	setmetatable(main_frame, MainFrame_mt)

	local frame = CreateFrame("Frame", "MainFrame", UIParent)
	frame.owner = main_frame
	frame:SetWidth(LAYOUT.bar.width + 2 * LAYOUT.main.border)
	frame:SetHeight(2 * LAYOUT.main.border + 2 * LAYOUT.bar.skip + LAYOUT.bar.height)
	local pos = GuiBarHero.db.char.pos
	if pos then
		frame:SetPoint(pos.rel_1, UIParent, pos.rel_2, pos.x, pos.y)
	else
		frame:SetPoint("TOPLEFT", UIParent, "CENTER", - LAYOUT.bar.width / 2 - LAYOUT.main.border, 0)
	end
	frame:SetClampedToScreen(1)
	frame:EnableMouse(1)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = {left = LAYOUT.main.border, right = 4, top = 4, bottom = 4}
	})
	frame:SetBackdropColor(0,0,0,LAYOUT.main.alpha)
	main_frame.frame = frame

	local left_frame = CreateFrame("Frame", "LeftIconFrame", frame)
	left_frame.owner = main_frame
	left_frame:SetWidth(LAYOUT.icon.width)
	left_frame:SetPoint("TOPLEFT", - LAYOUT.icon.dist - LAYOUT.icon.width,
							- LAYOUT.main.border - LAYOUT.bar.skip + (LAYOUT.icon.height - LAYOUT.bar.height)/2) 
	left_frame:SetPoint("BOTTOMLEFT", - LAYOUT.icon.dist - LAYOUT.icon.width,
							LAYOUT.main.border + LAYOUT.bar.skip - (LAYOUT.icon.height - LAYOUT.bar.height)/2)
	left_frame:EnableMouse(1)
	left_frame:SetScript("OnMouseDown", MainFrame.BarClick)
	main_frame.left_frame = left_frame

	local icon_frame = CreateFrame("Frame", "IconFrame", frame)
	icon_frame.owner = main_frame
	icon_frame:SetHeight(LAYOUT.large_icon.height)
	icon_frame:SetWidth(LAYOUT.large_icon.max * (LAYOUT.large_icon.width + LAYOUT.large_icon.skip) - LAYOUT.large_icon.skip)
	icon_frame:EnableMouse(1)
	icon_frame.icons = true
	icon_frame:SetScript("OnMouseDown", MainFrame.BarClick)
	icon_frame:Show()
	main_frame.icon_frame = icon_frame

	local profile_frame = CreateFrame("Frame", "ProfileFrame", frame)
	profile_frame.owner = main_frame
	profile_frame:SetHeight(LAYOUT.profile.height)
	profile_frame:SetWidth(LAYOUT.profile.max * (LAYOUT.profile.width + LAYOUT.profile.skip) - LAYOUT.profile.skip)
	profile_frame:EnableMouse(1)
	profile_frame.profiles = true
	profile_frame:SetScript("OnMouseDown", MainFrame.BarClick)
	self.profile_buttons = {}
	for i = 1, LAYOUT.profile.max do
		local fs = profile_frame:CreateFontString("FontString", "HIGHLIGHT")
		fs:SetFont(LAYOUT.profile.font, LAYOUT.profile.font_size)
		fs:SetText("" .. i)
		fs:SetPoint("CENTER", profile_frame, "BOTTOMLEFT", (i-1)* (LAYOUT.profile.width + LAYOUT.profile.skip) + LAYOUT.profile.width / 2, LAYOUT.profile.height / 2)
		fs:Show()
		self.profile_buttons[i] = fs
	end
	profile_frame:Show()
	main_frame.profile_frame = profile_frame

	local bridge_frame = CreateFrame("Frame", "BridgeFrame", frame)
	bridge_frame:SetFrameLevel(5)
	bridge_frame:SetWidth(LAYOUT.bridge.width)
	bridge_frame:SetPoint("TOPLEFT", LAYOUT.bridge.x + LAYOUT.bridge.offset + LAYOUT.main.border, -LAYOUT.main.border + 1)
	bridge_frame:SetPoint("BOTTOMLEFT", LAYOUT.bridge.x + LAYOUT.bridge.offset + LAYOUT.main.border, LAYOUT.main.border - 1)
	local tex = bridge_frame:CreateTexture("bridge", OVERLAY)
	DEBUG.textures_created = DEBUG.textures_created + 1
	tex:SetTexture(unpack(LAYOUT.bridge.color))
	tex:SetAllPoints()

	local gcd_frame = CreateFrame("Frame", "BridgeFrame", frame)
	gcd_frame:SetFrameLevel(5)
	gcd_frame:SetWidth(3)
	local tex = gcd_frame:CreateTexture("gcd", OVERLAY)
	DEBUG.textures_created = DEBUG.textures_created + 1
	tex:SetTexture(unpack(LAYOUT.bridge.color))
	tex:SetAllPoints()
	gcd_frame.tex = tex
	main_frame.next_gcd = 0
	main_frame.gcd_frame = gcd_frame
	for _, gcd_spell in ipairs(GCD_SPELLS) do
		local spell = GuiBarHero:FindSpell(gcd_spell)
		if spell then
			main_frame.gcd_slot = spell
			break
		end
	end

	main_frame.current_bars = {}
	main_frame.current_icons = {}
	main_frame.bar_pool = {}
	main_frame.icon_pool = {}

	frame:SetScript("OnUpdate", main_frame.OnUpdate)
	frame:SetScript("OnMouseDown", main_frame.OnMouseDown)
	frame:SetScript("OnEvent", main_frame.OnCooldown)
	frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	return main_frame
end

function MainFrame:BarClick(button)
	local x, y = GetCursorPosition()
	local rel_x = (x / self:GetEffectiveScale() - self:GetLeft()) / self:GetWidth()
	local rel_y = (y / self:GetEffectiveScale() - self:GetBottom()) / self:GetHeight()
	local profiles = self.profiles
	local icons = self.icons
	self = self.owner
	local nr
	if icons then
		nr = math.ceil(rel_x * LAYOUT.large_icon.max)
		insert_nr = nr
	elseif profiles then
		nr = math.ceil(rel_x * LAYOUT.profile.max)
	else
		nr = math.ceil((1-rel_y) * (#self.current_bars))
		insert_nr = math.ceil((1-rel_y) * (#self.current_bars) + 0.5)
	end
	local info_type, id, link = GetCursorInfo()
	if profiles then
		if button == "LeftButton" then
			GuiBarHero:SetCurrentProfile(nr)
		end
	else
		if info_type then
			local name
			if info_type == "spell" then
				name = GetSpellBookItemName(id, BOOKTYPE_SPELL)
			elseif info_type == "item" then
				if link == GetInventoryItemLink("player", GetInventorySlotInfo("Trinket0Slot")) then
					name = "Trinket 1"
				elseif link == GetInventoryItemLink("player", GetInventorySlotInfo("Trinket1Slot")) then
					name = "Trinket 2"
				end
				if name then
					ClearCursor()
				end
			end
			if name then
				GuiBarHero:InsertBar(insert_nr, name, icons)
			end
		elseif button == "RightButton" and IsShiftKeyDown() then
			GuiBarHero:InsertBar(nr, nil, icons)
		elseif button == "LeftButton" and IsShiftKeyDown() then
			local name = GuiBarHero:GetBarSpellName(nr, icons)
			if name then
				local slot = GuiBarHero:FindSpell(GuiBarHero:GetBarSpellName(nr, icons))
				_, spell_id = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
				PickupSpell(spell_id)
			end
		end
	end
end

function MainFrame:SetBars(bars, icons)
	local current_bars = icons and self.current_icons or self.current_bars
	local last = 1
	for i = 1, LAYOUT.bar.max do
--		if (bars[i] and bars[i].name) ~= (current_bars[i] and current_bars[i].spell_name) then
			if current_bars[i] then
				self:ReleaseBar(current_bars[i])
				current_bars[i] = nil
			end
			if bars[i] then
				local slot, name = GuiBarHero:FindSpell(bars[i].name)
				if name then 
					local new_bar = self:AquireBar(icons)
					if icons then
						new_bar:SetIconPosition((i - 1) * (LAYOUT.large_icon.width + LAYOUT.large_icon.skip), 0, LAYOUT.large_icon.width, LAYOUT.large_icon.height)
					else
						new_bar:SetPosition(LAYOUT.main.border, 
							(1 - i) * (LAYOUT.bar.height + LAYOUT.bar.skip) - LAYOUT.main.border - LAYOUT.bar.skip,
							LAYOUT.bar.width, LAYOUT.bar.height)
						new_bar:SetIconPosition(-LAYOUT.icon.width - LAYOUT.icon.dist, 
							(1 - i) * (LAYOUT.bar.height + LAYOUT.bar.skip) - LAYOUT.main.border - 
							LAYOUT.bar.skip + (LAYOUT.icon.height - LAYOUT.bar.height)/2, 
							LAYOUT.icon.width, LAYOUT.icon.height)
					end
					new_bar:SetSpeed(LAYOUT.bar.speed)
					new_bar:SetSpell(slot, name, bars[i].alt)
					new_bar:Show()
					current_bars[i] = new_bar
				end
			end
		--end
		if bars[i] then last = i end
	end
	if not icons then
		self.frame:SetHeight(last * (LAYOUT.bar.height + LAYOUT.bar.skip) + LAYOUT.bar.skip + 2 * LAYOUT.main.border)
	end
end

function MainFrame:OnCooldown()
	self = self.owner
	local start, duration = GetSpellCooldown(self.gcd_slot, BOOKTYPE_SPELL)
	self.next_gcd = start + duration
end


function MainFrame:OnUpdate()
	self = self.owner
	local gcd_away = (self.next_gcd - GetTime()) 
	local alpha = 1 + gcd_away
	if alpha > 1 then 
		alpha = 1
	end
	if alpha > 0 then
		self.gcd_frame.tex:SetVertexColor(1, 1, 1, alpha)
		self.gcd_frame:Show()
		self.gcd_frame:SetPoint("TOPLEFT", LAYOUT.bridge.x + LAYOUT.main.border + gcd_away * LAYOUT.bar.speed - 1.5, -LAYOUT.main.border + 1)
		self.gcd_frame:SetPoint("BOTTOMLEFT", LAYOUT.bridge.x + LAYOUT.main.border + gcd_away * LAYOUT.bar.speed - 1.5, LAYOUT.main.border - 1)
	else
		self.gcd_frame:Hide()
	end
	for _,bar in pairs(self.current_bars) do
		bar:Draw()
	end
	for _,bar in pairs(self.current_icons) do
		bar:Draw()
	end
end

function MainFrame:OnMouseDown(button)
	if button == "LeftButton" then
		if (not self:IsMovable()) and IsAltKeyDown() then
			self:SetMovable(1)
			self:StartMoving()
		else
			self:SetMovable(0)
			self:StopMovingOrSizing()
			local l_rel_1, _, l_rel_2, l_x, l_y = self:GetPoint(1)
			GuiBarHero.db.char.pos = { rel_1 = l_rel_1, rel_2 = l_rel_2, x = l_x, y = l_y }
		end
	end
end

function MainFrame:AquireBar(icon_only)
	if icon_only then
		local bar = table.remove(self.icon_pool)
		if not bar then
			DEBUG.bars_created = DEBUG.bars_created + 1
			bar = Bar:Create(self.icon_frame, true)
		end
		return bar
	else
		local bar = table.remove(self.bar_pool)
		if not bar then
			DEBUG.bars_created = DEBUG.bars_created + 1
			bar = Bar:Create(self.frame)
		end
		return bar
	end
end

function MainFrame:ReleaseBar(bar)
	bar:Hide()
	bar.frame:UnregisterAllEvents()
	bar.frame:SetScript("OnEvent", nil)
	bar.icon_frame:SetScript("OnEvent", nil)
	if bar.icon_only then
		table.insert(self.icon_pool, bar)
	else
		table.insert(self.bar_pool, bar)
	end
end

function MainFrame:Show()
	self.frame:Show()
end

function MainFrame:Hide()
	self.frame:Hide()
end


function Bar:Create(parent, icon_only)
	local bar = {} 
	setmetatable(bar, Bar_mt)

	bar.icon_only = icon_only

	local frame = CreateFrame("Frame", "Bar", parent)
	frame.owner = bar
	bar.frame = frame
	local icon_frame = CreateFrame("Frame", "Icon", parent)
	icon_frame.owner = bar
	icon_frame:SetScript("OnEvent", Bar.UpdateIcon)
	icon_frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	bar.icon_frame = icon_frame
	
	bar.tex_pool = {}
	bar.note_tex = nil
	local tex = icon_frame:CreateTexture("GuiBarTex")
	DEBUG.textures_created = DEBUG.textures_created + 1
	tex:Hide()
	tex:SetAllPoints()
	tex:SetBlendMode("BLEND")
	tex:SetDrawLayer("ARTWORK")
	tex:SetVertexColor(1,1,1,LAYOUT.icon.alpha)
	bar.icon_tex = tex

	bar.note_type = LAYOUT.center_note
	bar.next_note = 0
	bar.spell_info = TEMPLATE.none
	bar.GUID = UnitGUID("player")

	self.speed = 1000
	bar:SetPosition(0,0,0,0)
	bar:Hide()

	return bar
end

function Bar:AquireTex()
	local tex = table.remove(self.tex_pool)
	if not tex then
		DEBUG.textures_created = DEBUG.textures_created + 1
		tex = self.frame:CreateTexture("GuiBarTex")
		tex:Hide()
	end
	return tex
end

function Bar:ReleaseTex(tex)
	tex:Hide()
	table.insert(self.tex_pool, tex)
end


function Bar:CreateTextures()
	if not self.icon_only then
		self.chord_width = math.ceil(LAYOUT.chord.width * self.height / LAYOUT.chord.height)
		if not self.chord_tex then
			local tex = self:AquireTex()
			tex:SetTexture(LAYOUT.chord.path, true)
			tex:SetBlendMode("BLEND")
			local r,g,b = unpack(self.spell_info.color)
			tex:SetDrawLayer("ARTWORK")
			tex:SetVertexColor(r, g, b, LAYOUT.chord.alpha)
			self.chord_tex = tex
		end
		self.chord_tex:SetHeight(self.height)

		local scale = self.height / self.note_type.height
		self.note_offset = self.note_type.offset * scale
		self.note_width = self.note_type.width * scale

		if not self.note_tex then
			self.note_tex = self:AquireTex()
		end

		tex = self.note_tex
		tex:SetTexture(self.note_type.path, true)
		tex:SetBlendMode("ADD")
		tex:SetVertexColor(unpack(self.spell_info.color))
		tex:SetDrawLayer("OVERLAY")
		tex:SetHeight(self.height)
		tex:SetWidth(self.note_width)
	end

	self:UpdateIcon()
end

function Bar:UpdateIcon(_, unit)
	local update_spells = true
	if self.owner then --called by an event handler
		self = self.owner
		if unit ~= "player" then return end
		update_spells = false
	end
	if not self.spell_info then return end
	if self.spell_info.type == "SLOTITEM" then
		self.icon_tex:SetTexture(GetInventoryItemTexture("player", self.spell_info.slot_id))
		self.icon_tex:Show()
	elseif update_spells then
		if self.slot_id then
			self.icon_tex:SetTexture(GetSpellTexture(self.slot_id, BOOKTYPE_SPELL))
			self.icon_tex:Show()
		else
			self.icon_tex:Hide()
		end
	end
end

function Bar:SetPosition(x, y, width, height)
	self.frame:SetPoint("TOPLEFT", x, y)
	self.frame:SetWidth(width)
	self.frame:SetHeight(height)
	self.height = height
	self.width = width
	self:CreateTextures()
end

function Bar:SetIconPosition(x, y, width, height)
	self.icon_frame:SetWidth(width)
	self.icon_frame:SetHeight(height)
	self.icon_frame:SetPoint("TOPLEFT", x, y)
end

function Bar:SetSpeed(speed)
	self.speed = speed
	self:CreateTextures()
end

function Bar:SetSpell(slot_id, spell_name, alt)
	local spell_info = spell_name and SPELLS[spell_name] or TEMPLATE.default
	if not spell_info.type then 
		spell_info = spell_info[((alt or 1) - 1) % #spell_info + 1]
	end
	self.spell_name = spell_name
	self.spell_info = spell_info
	self.slot_id = slot_id
	self.casting = nil
	self.next_note = 0
	local handler
	local events
	if spell_info.type == "COOLDOWN" then
		handler = Bar.UpdateCooldown
		events = Bar.update_cooldown_events
	elseif spell_info.type == "SELFBUFF" then
		handler = Bar.UpdateSelfbuff
		events = Bar.update_selfbuff_events
	elseif spell_info.type == "DEBUFF" then
		handler = Bar.UpdateDebuff
		events = Bar.update_debuff_events
	elseif spell_info.type == "SLOTITEM" then
		handler = Bar.UpdateSlotItem
		events = Bar.update_slot_item_events
	elseif spell_info.type == "MELEE" then
		handler = Bar.UpdateMelee
		events = Bar.update_melee_events
	elseif spell_info.type == "REACTIVE" then
		self.icon_lit = 0
	end
	if handler then
		self.frame:SetScript("OnEvent", handler)
		for _, event in pairs(events) do
			self.frame:RegisterEvent(event)
		end
		handler(self.frame)
	end

	if spell_info.note == "LEFT" then
		self.note_type = LAYOUT.left_note
	elseif spell_info.note == "RIGHT" then
		self.note_type = LAYOUT.right_note
	else
		self.note_type = LAYOUT.center_note
	end
	self:CreateTextures()
	self:Show()
end

Bar.update_selfbuff_events = { "UNIT_AURA" }

function Bar:UpdateSelfbuff(event_type, unit)
	self = self.owner
	if unit and unit ~= "player" then return end
	local name, found, expires, latest_expire
	found, _, _, _, _, _, latest_expire = UnitBuff("player", self.spell_name)

	if self.spell_info.shared_buffs then
		for _, shared_buff in ipairs(self.spell_info.shared_buffs) do
			name, _, _, _, _, _, expires = UnitBuff("player", shared_buff)
			if name then
				found = true
				if expires and ((not latest_expire) or (expires > latest_expire)) then
					latest_expire = expires
				end
			end
		end
	end

	if (not found) then
		if not tonumber(self.next_note) or self.next_note > GetTime() + EPS.time then
			self.next_note = 0
			self.icon_lit = 0
		end
	elseif latest_expire then
		self.next_note = latest_expire 
		self.icon_lit = self.next_note
	else
		self.next_note = "?"
		self.icon_lit = nil
	end
end

Bar.update_debuff_events = { "UNIT_AURA", "PLAYER_TARGET_CHANGED", "SPELL_UPDATE_COOLDOWN" }

function Bar:UpdateDebuff(event, unit)
	self = self.owner
	if event == "UNIT_AURA" and unit ~= "target" then return end
	if (not UnitExists("target")) or UnitIsDead("target") or UnitIsFriend("player", "target") then
		self.next_note = nil
		self.icon_lit = nil
		return
	end
	local name, count, expires
	local latest_expire = 0
	local found = false
	name, _, _, count, _, _, expires = UnitDebuff("target", self.spell_name)
	if (name and ((not self.spell_info.stacks) or (not count) or count >= self.spell_info.stacks)) then
		found = true
		if expires then
			latest_expire = expires
		end
	end
	if self.spell_info.shared_debuffs then
		for _, shared_debuff in ipairs(self.spell_info.shared_debuffs) do
			name, _, _, _, _, _, expires = UnitDebuff("target", shared_debuff)
			if name then
				found = true
				if expires and expires > latest_expire then
					latest_expire = expires
				end
			end
		end
	end

	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)
	if (duration > 1.5 or (duration > 0 and self.next_note > start + duration + EPS.time)) and start + duration > latest_expire then
		latest_expire = start + duration
		found = true
	end

	if found then
		if self.spell_info.subtract_cast_time then
			local _, _, _, _, _, _, castTime = GetSpellInfo(self.spell_name)
			latest_expire = latest_expire - castTime / 1000
		end
		if latest_expire > 0 then
			if (not tonumber(self.next_note) or self.next_note < latest_expire) then
				self.next_note = latest_expire
				self.icon_lit = self.next_note
			end
		else
			self.next_note = "?"
			self.icon_lit = nil
		end
	end

	if (not found) and (not tonumber(self.next_note) or self.next_note > GetTime() + EPS.time) then
		self.next_note = 0
		self.icon_lit = 0
	end
end

Bar.update_cooldown_events = { "SPELL_UPDATE_COOLDOWN", "PLAYER_TARGET_CHANGED", "CURRENT_SPELL_CAST_CHANGED", "ACTIONBAR_UPDATE_STATE" }

function Bar:UpdateCooldown()
	self = self.owner
	if self.spell_info.need_target and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitIsFriend("player", "target")) then
		self.next_note = nil
		self.icon_lit = nil
		return
	end
	if self.spell_info.need_boss and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitClassification("target") ~= "worldboss") then
		self.next_note = nil
		self.icon_lit = nil
		return
	end
	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)
	if not duration then
		self.next_note = nil
		self.icon_lit = nil
		return
	end
	if not self.next_note then self.next_note = 0 end
	if duration > 1.5 then
		self.next_note = start + duration
	elseif duration > 0 and self.next_note > start + duration + EPS.time then
		self.next_note = start + duration
	end
	local spell, _, _, _, _, endTime = UnitCastingInfo("player")
	if endTime and endTime > self.next_note * 1000 then
		self.next_note = endTime / 1000
	end
	self.icon_lit = self.next_note
end

Bar.update_slot_item_events = { "BAG_UPDATE_COOLDOWN", "UNIT_INVENTORY_CHANGED" }

function Bar:UpdateSlotItem(event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
	self = self.owner
	local start, duration, enable = GetInventoryItemCooldown("player", self.spell_info.slot_id)
	if enable == 1 then
		if duration > 0 then
			self.next_note = start + duration
			self.icon_lit = start + duration
		else
			self.icon_lit = 0
		end
	else
		self.next_note = nil
		self.icon_lit = nil
	end
end

Bar.update_melee_events = { "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_FAILED_QUIET",
	"UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_TARGET_CHANGED" }

function Bar:UpdateMelee(event, unit, spell)
	self = self.owner
	self.next_note = nil
	if not self.casting then 
		self.icon_lit = 0
	end
	if (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED_QUIET" or
		event == "UNIT_SPELLCAST_INTERRUPTED") and unit == "player" and spell == self.casting then
		self.icon_lit = 0
		self.casting = nil
	end
	if (self.spell_info.need_target and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitIsFriend("player", "target"))) or
		(self.spell_info.need_boss and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitClassification("target") ~= "worldboss")) then
		self.icon_lit = nil
	end
end

function Bar:Swing(this_swing, next_swing, special)
	if (not self.last_swing) or math.abs(this_swing - self.last_swing) > EPS.swing then
		self.last_swing = this_swing
	end
	self.last_swing_exact = this_swing
	self.next_swing = next_swing
end

function Bar:UpdateNextSwing(next_swing)
	if (not self.next_swing) or math.abs(next_swing - self.next_swing) > EPS.swing then
		self.next_swing = next_swing
	end
end

function Bar:StopSwing()
	self.last_swing = nil
	self.last_swing_exact = nil
	self.next_swing = nil
end

function Bar:Draw()
	local time = GetTime()
	local dimmed = false
	local hidden = false
	local bar_end = nil
	if self.spell_info.can_dim and ((not IsUsableSpell(self.spell_name)) or (SpellHasRange(self.spell_name) and IsSpellInRange(self.spell_name, "target") == 0)) then
		dimmed = true
	end
	if self.spell_info.min_rage and UnitMana("player") < self.spell_info.min_rage then
		dimmed = true
	end
	if self.spell_info.max_rage and UnitMana("player") > self.spell_info.max_rage then
		dimmed = true
	end
	if self.spell_info.need_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.need_aura)
		if name then
			bar_end = expires
		else
			dimmed = true
			hidden = true
		end
	end
	if self.spell_info.also_lit_on_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.also_lit_on_aura)
		if name then
			bar_end = expires
			dimmed = false
			hidden = false
		end
	end
	if self.spell_info.need_enraged then
		bar_end = 0
		for _, aura in ipairs(ENRAGE_AURAS) do
			name, _, _, _, _, _, expires = UnitBuff("player", aura)
			if name and bar_end < expires then
				bar_end = expires
			end
		end
	end
	if self.spell_info.need_no_enraged then
		for _, aura in ipairs(ENRAGE_AURAS) do
			name, _, _, _, _, _, expires = UnitBuff("player", aura)
			if name and self.next_note < expires then
				self.next_note = expires
			end
		end
	end
	if self.spell_info.need_no_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.need_no_aura)
		if name and self.next_note < expires then
			self.next_note = expires
		end
	end
	if self.icon_only then
		dimmed = dimmed or (not self.icon_lit) or self.icon_lit > time or hidden
		self.icon_tex:SetVertexColor(1, 1, 1, dimmed and LAYOUT.large_icon.dim_alpha or LAYOUT.large_icon.alpha )
	else
		if (not self.next_note) or hidden or (bar_end and (bar_end < self.next_note)) then
			self:DrawEmpty()
		elseif self.next_note == "?" then
			self:DrawUnknown()
		else
			local x = (self.next_note - time) * self.speed + LAYOUT.bridge.x
			local x2 = nil
			if bar_end then
				x2 = (bar_end - time) * self.speed + LAYOUT.bridge.x
			end
			self:DrawChord(x > 0 and x or 0, x2, dimmed)
			self:DrawNote(x, false, dimmed)
		end
	end
end

function Bar:DrawEmpty()
	if self.chord_tex then
		self.chord_tex:Hide()
	end
	if self.note_tex then
		self.note_tex:Hide()
	end
end

function Bar:DrawUnknown()
	self:DrawEmpty()
end

function Bar:DrawChord(start, stop, dimmed)
	local r,g,b = unpack(self.spell_info.color)
	local alpha = LAYOUT.chord.alpha
	if dimmed then alpha = alpha * LAYOUT.bar.dim_alpha end
	local w = self.chord_width
	local offset = (GetTime() * self.speed) % w
	if (not stop) or stop > self.width then
		stop = self.width
	end
	local visible_width = stop - start
	local tex = self.chord_tex
	if visible_width > 0 then
		tex:SetPoint("TOPLEFT", start, 0)
		tex:SetWidth(visible_width)
		tex:SetTexCoord((start + offset) / w, (stop + offset) / w, 0, 1)
		tex:SetVertexColor(r,g,b,alpha)
		tex:Show()
	else
		tex:Hide()
	end
end

function Bar:DrawNote(note, dimmed)
	local r,g,b = unpack(self.spell_info.color)
	local alpha = 1
	if dimmed then alpha = LAYOUT.bar.dim_alpha end
	local offset = note + self.note_offset
	local qleft, qright, tex
	tex = self.note_tex
	if offset < 0 then
		qleft = - offset / self.note_width
		tex:SetPoint("TOPLEFT", 0, 0)
	else
		qleft = 0
		tex:SetPoint("TOPLEFT", offset, 0)
	end
	if offset + self.note_width > self.width then
		qright = 1 - (offset + self.note_width - self.width) / self.note_width
	else
		qright = 1
	end
	if qleft >= qright then
		tex:Hide()
	else
		tex:SetTexCoord(qleft, qright, 0, 1)
		tex:SetWidth((qright - qleft) * self.note_width)
		tex:SetVertexColor(r,g,b,alpha)
		tex:Show()
	end
end

function Bar:Hide()
	self.frame:Hide()
	self.icon_frame:Hide()
end

function Bar:Show()
	if not self.icon_only then self.frame:Show() end
	self.icon_frame:Show()
end
