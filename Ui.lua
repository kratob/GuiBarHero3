local LAYOUT = { 
	main = { border = 4, alpha = 0.8 },
	bar = { height = 16, width = 410, skip = 7, max = 20, dim_alpha = 0.4, speed = 30 }, 
	icon = { height = 20, width = 20, dist = 1, vdist = 4, skip = 8, alpha = 0.7, text_color={1,1,1} },
	large_icon = { height = 30, width = 30, dist = 4, skip = 8, max = 11, alpha = 1, dim_alpha = 0.2 },
	profile = { height = 20, width = 30, dist = 2, skip = 8, max = 10, font = "Fonts\\FRIZQT__.TTF", font_size = 14, current_color = {1, 1, 1, 1}, color = {.7, .7, .7, .5} },
	chord = { height = 8, width = 64, alpha = .7, path = "Interface\\AddOns\\GuiBarHero3\\Textures\\Glow" },
	right_note = { height = 16, width = 16, offset = 0, path = "Interface\\AddOns\\GuiBarHero3\\Textures\\Rightarrow" },
	left_note = { height = 16, width = 16, offset = -16, path = "Interface\\AddOns\\GuiBarHero3\\Textures\\Leftarrow" },
	center_note = { height = 16, width = 16, offset = -8, path = "Interface\\AddOns\\GuiBarHero3\\Textures\\Circle" },
	bridge = { x = 20, width = 5, offset = -2.5, color = {1,1,1,.4} }
}


local MainFrame = {}
local MainFrame_mt = { __index = MainFrame }

local Bar = {}
local Bar_mt = { __index = Bar }


--------------------
-- UI initialization

function MainFrame:Create()
	main_frame = {}
	setmetatable(main_frame, MainFrame_mt)
	main_frame:Initialize()

	return main_frame
end

function MainFrame:Initialize()
	self:CreateFrame()
	self:CreateLeftIconFrame()
	self:CreateIconFrame()
	self:CreateProfileFrame()
	self:CreateBridgeFrame()
	self:CreateGcdFrame()

	self.current_bars = {}
	self.current_icons = {}

	self.event_registry = GuiBarHero.EventRegistry:Create(self.frame)
end

function MainFrame:CreateFrame()
	local frame = CreateFrame("Frame", "MainFrame", UIParent)
	frame.owner = self
	frame:SetWidth(LAYOUT.bar.width + 2 * LAYOUT.main.border)
	frame:SetHeight(2 * LAYOUT.main.border + 2 * LAYOUT.bar.skip + LAYOUT.bar.height)
	local pos = GuiBarHero.settings:GetPosition()
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
	self.frame = frame

	frame:SetScript("OnUpdate", main_frame.OnUpdate)
	frame:SetScript("OnMouseDown", main_frame.OnMouseDown)
end

function MainFrame:CreateLeftIconFrame()
	local left_icon_frame = CreateFrame("Frame", "LeftIconFrame", self.frame)
	left_icon_frame.owner = self
	left_icon_frame:SetWidth(LAYOUT.icon.width)
	left_icon_frame:SetPoint("TOPLEFT", - LAYOUT.icon.dist - LAYOUT.icon.width,
							- LAYOUT.main.border - LAYOUT.bar.skip + (LAYOUT.icon.height - LAYOUT.bar.height)/2) 
	left_icon_frame:SetPoint("BOTTOMLEFT", - LAYOUT.icon.dist - LAYOUT.icon.width,
							LAYOUT.main.border + LAYOUT.bar.skip - (LAYOUT.icon.height - LAYOUT.bar.height)/2)
	left_icon_frame:EnableMouse(1)
	left_icon_frame:SetScript("OnMouseDown", MainFrame.BarClick)
	self.left_icon_frame = left_icon_frame
end

function MainFrame:CreateIconFrame()
	local icon_frame = CreateFrame("Frame", "IconFrame", self.frame)
	icon_frame.owner = self
	icon_frame:SetHeight(LAYOUT.large_icon.height)
	icon_frame:SetWidth(LAYOUT.large_icon.max * (LAYOUT.large_icon.width + LAYOUT.large_icon.skip) - LAYOUT.large_icon.skip)
	icon_frame:EnableMouse(1)
	icon_frame.icons = true
	icon_frame:SetScript("OnMouseDown", MainFrame.IconClick)
	icon_frame:Show()
	main_frame.icon_frame = icon_frame
end

function MainFrame:CreateProfileFrame()
	local profile_frame = CreateFrame("Frame", "ProfileFrame", self.frame)
	profile_frame.owner = self
	profile_frame:SetHeight(LAYOUT.profile.height)
	profile_frame:SetWidth(LAYOUT.profile.max * (LAYOUT.profile.width + LAYOUT.profile.skip) - LAYOUT.profile.skip)
	profile_frame:EnableMouse(1)
	profile_frame.profiles = true
	profile_frame:SetScript("OnMouseDown", MainFrame.ProfileClick)
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
	self.profile_frame = profile_frame
end

function MainFrame:CreateBridgeFrame()
	local bridge_frame = CreateFrame("Frame", "BridgeFrame", self.frame)
	bridge_frame:SetFrameLevel(5)
	bridge_frame:SetWidth(LAYOUT.bridge.width)
	bridge_frame:SetPoint("TOPLEFT", LAYOUT.bridge.x + LAYOUT.bridge.offset + LAYOUT.main.border, -LAYOUT.main.border + 1)
	bridge_frame:SetPoint("BOTTOMLEFT", LAYOUT.bridge.x + LAYOUT.bridge.offset + LAYOUT.main.border, LAYOUT.main.border - 1)
	local tex = bridge_frame:CreateTexture("bridge", OVERLAY)
	tex:SetTexture(unpack(LAYOUT.bridge.color))
	tex:SetAllPoints()
end

function MainFrame:CreateGcdFrame()
	local gcd_frame = CreateFrame("Frame", "GcdFrame", self.frame)
	gcd_frame:SetFrameLevel(5)
	gcd_frame:SetWidth(3)
	local tex = gcd_frame:CreateTexture("gcd", OVERLAY)
	tex:SetTexture(unpack(LAYOUT.bridge.color))
	tex:SetAllPoints()
	gcd_frame.tex = tex
	main_frame.gcd_frame = gcd_frame
end


-----------------
-- Mouse handlers

function MainFrame:GetRelativeCursorPosition(frame)
	local x, y = GetCursorPosition()
	local rel_x = (x / frame:GetEffectiveScale() - frame:GetLeft()) / frame:GetWidth()
	local rel_y = (y / frame:GetEffectiveScale() - frame:GetBottom()) / frame:GetHeight()
	return rel_x, rel_y
end

function MainFrame:IconClick(button)
	local rel_x = self.owner:GetRelativeCursorPosition(self)
	self = self.owner
	local nr = math.ceil(rel_x * LAYOUT.large_icon.max)
	self:SpellClick(button, nr, nr, true)
end

function MainFrame:ProfileClick(button)
	local rel_x = self.owner:GetRelativeCursorPosition(self)
	self = self.owner
	local nr = math.ceil(rel_x * LAYOUT.profile.max)
	if button == "LeftButton" and nr > 0 and nr <= LAYOUT.profile.max then
		GuiBarHero.settings:SetCurrentProfile(nr)
		self:RefreshBars()
	end
end

function MainFrame:BarClick(button)
	local _, rel_y = self.owner:GetRelativeCursorPosition(self)
	self = self.owner
	nr = math.ceil((1-rel_y) * (#self.current_bars))
	insert_nr = math.ceil((1-rel_y) * (#self.current_bars) + 0.5)
	self:SpellClick(button, nr, insert_nr, false)
end

function MainFrame:SpellClick(button, nr, insert_nr, icons)
	local info_type, _, _ = GetCursorInfo()
	if info_type then
		self:SpellDropped(insert_nr, icons)
	elseif button == "RightButton" and IsShiftKeyDown() then
		if icons then
			GuiBarHero.settings:RemoveIcon(nr)
		else
			GuiBarHero.settings:RemoveBar(nr)
		end
		self:RefreshBars()
	elseif button == "LeftButton" and IsShiftKeyDown() then
		self:PickupSpell(nr, icons)
	end
end

function MainFrame:SpellDropped(nr, icons)
	local info_type, id, link = GetCursorInfo()
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
		if icons then
			GuiBarHero.settings:SetIcon(nr, name)
		else
			GuiBarHero.settings:InsertBar(nr, name)
		end
		self:RefreshBars()
	end
end

function MainFrame:PickupSpell(nr, icons)
	local name 
	if icons then
		name = GuiBarHero.settings:GetIconSpellName(nr)
	else
		name = GuiBarHero.settings:GetBarSpellName(nr)
	end
	if name then
		local slot = GuiBarHero.Utils:FindSpell(name)
		if slot then
			local _, spell_id = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
			PickupSpell(spell_id)
		end
	end
end

function MainFrame:OnMouseDown(button)
	if button == "LeftButton" then
		if (not self.moving) and IsAltKeyDown() then
			self.moving = true
			self:SetMovable(1)
			self:StartMoving()
		else
			self.moving = false
			self:SetMovable(0)
			self:StopMovingOrSizing()
			local l_rel_1, _, l_rel_2, l_x, l_y = self:GetPoint(1)
			GuiBarHero.settings:SetPosition({ rel_1 = l_rel_1, rel_2 = l_rel_2, x = l_x, y = l_y })
		end
	end
end


-----------------------
-- Manage UI components

function MainFrame:Show()
	self.frame:Show()
end

function MainFrame:Hide()
	self.frame:Hide()
end

function MainFrame:RefreshBars()
	self:RefreshProfileFrame()
	self:RefreshIconFrame()
	if self.gcd then
		self.gcd:Release()
	end
	self.gcd = GuiBarHero.Gcd:Create(self.gcd_frame)
	self:SetBars(GuiBarHero.settings:GetBars())
	self:SetBars(GuiBarHero.settings:GetIcons(), true)
end

function MainFrame:RefreshProfileFrame()
	self.profile_frame:ClearAllPoints()
	self.profile_frame:SetPoint("BOTTOMLEFT", LAYOUT.main.border, - LAYOUT.profile.dist - LAYOUT.profile.height)
	for i = 1, LAYOUT.profile.max do
		self.profile_buttons[i]:SetTextColor(unpack(LAYOUT.profile.color))
	end
	self.profile_buttons[GuiBarHero.settings:GetCurrentProfile()]:SetTextColor(unpack(LAYOUT.profile.current_color))
end

function MainFrame:RefreshIconFrame()
	self.icon_frame:ClearAllPoints()
	self.icon_frame:SetPoint("TOPLEFT", LAYOUT.main.border, LAYOUT.large_icon.dist + LAYOUT.large_icon.height)
end

function MainFrame:SetBars(spells, icons)
	local current_bars, frame
	if icons then
		current_bars = self.current_icons
		frame = self.icon_frame
	else
		current_bars = self.current_bars
		frame = self.frame
	end
	local last = 1
	for i = 1, LAYOUT.bar.max do
		if current_bars[i] then
			current_bars[i]:Release()
			current_bars[i] = nil
		end
		if spells[i] then
			local slot, name = GuiBarHero.Utils:FindSpell(spells[i].name)
			if name then 
				local new_bar = Bar:Aquire(frame, icons, self.event_registry)
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
				new_bar:SetSpell(spells[i])
				new_bar:Show()
				current_bars[i] = new_bar
			end
		end
		if spells[i] then last = i end
	end
	if not icons then
		self.frame:SetHeight(last * (LAYOUT.bar.height + LAYOUT.bar.skip) + LAYOUT.bar.skip + 2 * LAYOUT.main.border)
	end
end


------------
-- Rendering

function MainFrame:OnUpdate()
	self = self.owner
	self.event_registry:Run()
	self:DrawGcd()
	for _, bar in pairs(self.current_bars) do
		bar:Draw()
	end
	for _, bar in pairs(self.current_icons) do
		bar:Draw()
	end
end

function MainFrame:DrawGcd()
	local gcd_away = (self.gcd:GetNext() - GetTime()) 
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
end


-------
-- Bars

function Bar:Aquire(frame, icon_only, event_registry)
	local pool
	if icon_only then
		self.icon_pool = self.icon_pool or {}
		pool = self.icon_pool
	else
		self.bar_pool = self.bar_pool or {}
		pool = self.bar_pool
	end
	local bar = table.remove(pool)
	if not bar then
		bar = Bar:Create(frame, icon_only, event_registry)
	end
	return bar
end

function Bar:Release()
	self:Hide()
	if self.spell then
		self.spell:Release()
	end
	if self.icon_only then
		table.insert(self.icon_pool, bar)
	else
		table.insert(self.bar_pool, bar)
	end
end

function Bar:Create(parent, icon_only, event_registry)
	local bar = {} 
	setmetatable(bar, Bar_mt)
	bar:Initialize(parent, icon_only, event_registry)

	return bar
end

function Bar:Initialize(parent, icon_only, event_registry)
	self.event_registry = event_registry
	self.icon_only = icon_only
	self.note_type = LAYOUT.center_note
	self.next_note = 0
	self.spell_info = GuiBarHero.Config.template.none
	self.GUID = UnitGUID("player")

	self:CreateFrames(parent)
	self:CreateIconTexture()
	if not self.icon_only then
		self:CreateBarTextures()
	end
	self:CreateFont()

	self:SetPosition(0, 0, 0, 0)
	self:Hide()
end

function Bar:CreateFrames(parent)
	local frame = CreateFrame("Frame", "Bar", parent)
	frame.owner = self
	self.frame = frame

	local icon_frame = CreateFrame("Frame", "Icon", parent)
	icon_frame.owner = self
	icon_frame:SetScript("OnEvent", Bar.UpdateIcon)
	icon_frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self.icon_frame = icon_frame
end

function Bar:CreateIconTexture()
	self.tex_pool = {}
	self.note_tex = nil
	local tex = self.icon_frame:CreateTexture("GuiBarTex")
	tex:Hide()
	tex:SetAllPoints()
	tex:SetBlendMode("BLEND")
	tex:SetDrawLayer("ARTWORK")
	tex:SetVertexColor(1, 1, 1, LAYOUT.icon.alpha)
	self.icon_tex = tex
end

function Bar:CreateBarTextures()
	local tex = self.frame:CreateTexture("Chord")
	tex:SetTexture(LAYOUT.chord.path, true)
	tex:SetBlendMode("BLEND")
	tex:SetDrawLayer("ARTWORK")
	self.chord_tex = tex

	tex = self.frame:CreateTexture("Chord dimmed")
	tex:SetTexture(LAYOUT.chord.path, true)
	tex:SetBlendMode("BLEND")
	tex:SetDrawLayer("ARTWORK")
	self.dimmed_chord_tex = tex

	self.note_tex = self.frame:CreateTexture("Note")
end

function Bar:CreateFont()
	local fs = self.icon_frame:CreateFontString("FontString")
	fs:SetFont(LAYOUT.profile.font, LAYOUT.profile.font_size)
	fs:SetTextColor(unpack(LAYOUT.icon.text_color))
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	fs:SetPoint("CENTER", self.icon_frame, "CENTER", 0, 0)
	fs:Hide()
	self.icon_text = fs
end

function Bar:RefreshBar()
	local r,g,b = unpack(self.spell_info.color)
	self.chord_width = math.ceil(LAYOUT.chord.width * self.height / LAYOUT.chord.height)
	self.chord_tex:SetHeight(self.height)
	self.chord_tex:SetVertexColor(r, g, b, LAYOUT.chord.alpha)
	self.dimmed_chord_tex:SetHeight(self.height)
	self.dimmed_chord_tex:SetVertexColor(r, g, b, LAYOUT.chord.alpha * LAYOUT.bar.dim_alpha)

	local scale = self.height / self.note_type.height
	self.note_offset = self.note_type.offset * scale
	self.note_width = self.note_type.width * scale

	tex = self.note_tex
	tex:SetTexture(self.note_type.path, true)
	tex:SetBlendMode("ADD")
	tex:SetVertexColor(unpack(self.spell_info.color))
	tex:SetDrawLayer("OVERLAY")
	tex:SetHeight(self.height)
	tex:SetWidth(self.note_width)
end

function Bar:RefreshIcon(_, unit)
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
		local slot_id = self.spell:GetSlotId()
		if slot_id then
			self.icon_tex:SetTexture(GetSpellTexture(slot_id, BOOKTYPE_SPELL))
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
end

function Bar:SetIconPosition(x, y, width, height)
	self.icon_frame:SetWidth(width)
	self.icon_frame:SetHeight(height)
	self.icon_frame:SetPoint("TOPLEFT", x, y)
	self.icon_text:Hide()
end

function Bar:SetSpell(spell)
	self.spell = GuiBarHero.Spell:Create(spell.name, spell.alt, self.event_registry)
	self.spell_info = self.spell:GetInfo()
	local note_type = self.spell_info.note
	if note_type == "LEFT" then
		self.note_type = LAYOUT.left_note
	elseif note_type == "RIGHT" then
		self.note_type = LAYOUT.right_note
	else
		self.note_type = LAYOUT.center_note
	end

	if not self.icon_only then
		self:RefreshBar()
	end
	self:RefreshIcon()
end

function Bar:Draw()
	local time = GetTime()
	local dim_start, dim_end, hidden, bar_start, bar_end, icon_text = self.spell:GetStatus()
	if self.icon_only then
		local dimmed = (not bar_start) or (dim_start and dim_start <= time) or (dim_end and dim_end > time) or bar_start > time or hidden
		self.icon_tex:SetVertexColor(1, 1, 1, dimmed and LAYOUT.large_icon.dim_alpha or LAYOUT.large_icon.alpha )
	else
		if (not bar_start) or hidden or (bar_end and (bar_end < bar_start)) then
			self:DrawEmpty(false)
			self:DrawEmpty(true)
		else
			local note_x = (bar_start - time) * LAYOUT.bar.speed + LAYOUT.bridge.x
			local x = note_x
			if x <= 0 then
				x = 0
			end
			local x2 = self.width
			local x_dim_start = dim_start and (dim_start - time) * LAYOUT.bar.speed + LAYOUT.bridge.x
			local x_dim_end = dim_end and (dim_end - time) * LAYOUT.bar.speed + LAYOUT.bridge.x
			if bar_end then
				x2 = (bar_end - time) * LAYOUT.bar.speed + LAYOUT.bridge.x
				if x2 > self.width then
					x2 = self.width
				end
			end
			if x_dim_start and x_dim_start > x and x_dim_start < x2 then
				-- second half dimmed
				self:DrawChord(x, x_dim_start, false)
				self:DrawChord(x_dim_start, x2, true)
				self:DrawNote(note_x, false)
			elseif x_dim_end and x_dim_end > x and x_dim_end < x2 then
				-- first half dimmed
				self:DrawChord(x, x_dim_end, true)
				self:DrawChord(x_dim_end, x2, false)
				self:DrawNote(note_x, true)
			elseif (x_dim_start and x_dim_start <= x) or (x_dim_end and x_dim_end >= x2) then
				-- totally dimmed
				self:DrawChord(x, x2, true)
				self:DrawEmpty(false)
				self:DrawNote(note_x, true)
			else
				-- not dimmed at all
				self:DrawChord(x, x2, false)
				self:DrawEmpty(true)
				self:DrawNote(note_x, false)
			end
		end
	end
	if icon_text then
		self.icon_text:SetText(icon_text)
		self.icon_text:Show()
	else
		self.icon_text:Hide()
	end
end

function Bar:DrawEmpty(dimmed)
	if dimmed then
		if self.dimmed_chord_tex then
			self.dimmed_chord_tex:Hide()
		end
	else
		if self.chord_tex then
			self.chord_tex:Hide()
		end
		if self.note_tex then
			self.note_tex:Hide()
		end
	end
end

function Bar:DrawChord(start, stop, dimmed)
	local w = self.chord_width
	local offset = (GetTime() * LAYOUT.bar.speed) % w
	local visible_width = stop - start
	local tex = nil
	if dimmed then
		tex = self.dimmed_chord_tex
	else
		tex = self.chord_tex
	end
	if visible_width > 0 then
		tex:SetPoint("TOPLEFT", start, 0)
		tex:SetWidth(visible_width)
		tex:SetTexCoord((start + offset) / w, (stop + offset) / w, 0, 1)
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
		qright = 0.95 - (offset + self.note_width - self.width) / self.note_width
	else
		qright = 0.95
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

GuiBarHero.MainFrame = MainFrame
