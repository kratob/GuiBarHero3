local EPS = { time = 0.1 }

local Spell = {}
local Spell_mt = { __index = Spell }

function Spell:Release()
	self.frame:UnregisterAllEvents()
	self.frame:SetScript("OnEvent", nil)
end

function Spell:Create(spell_name, alternative, frame)
	local spell = {}
	setmetatable(spell, Spell_mt)
	spell:Initialize(spell_name, alternative, frame)
	return spell
end

function Spell:Initialize(spell_name, alternative, frame)
	self.frame = frame
	frame.owner_spell = self

	local slot_id, spell_name = GuiBarHero.Utils:FindSpell(spell_name)
	local spell_info = spell_name and GuiBarHero.Config.spells[spell_name] or GuiBarHero.Config.template.default
	if not spell_info.type then 
		spell_info = spell_info[((alternative or 1) - 1) % #spell_info + 1]
	end
	self.spell_info = spell_info
	self.spell_name = spell_name
	self.slot_id = slot_id
	self.casting = nil
	self.next_note = 0
	local handler
	local events
	if spell_info.type == "COOLDOWN" then
		handler = Spell.UpdateCooldown
		events = Spell.update_cooldown_events
	elseif spell_info.type == "SELFBUFF" then
		handler = Spell.UpdateSelfbuff
		events = Spell.update_selfbuff_events
	elseif spell_info.type == "DEBUFF" then
		handler = Spell.UpdateDebuff
		events = Spell.update_debuff_events
	elseif spell_info.type == "SLOTITEM" then
		handler = Spell.UpdateSlotItem
		events = Spell.update_slot_item_events
	elseif spell_info.type == "MELEE" then
		handler = Spell.UpdateMelee
		events = Spell.update_melee_events
	end
	if handler then
		frame:SetScript("OnEvent", handler)
		for _, event in pairs(events) do
			frame:RegisterEvent(event)
		end
		handler(frame)
	end
end

Spell.update_selfbuff_events = { "UNIT_AURA" }

function Spell:UpdateSelfbuff(event_type, unit)
	self = self.owner_spell
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
		end
	elseif latest_expire then
		self.next_note = latest_expire 
	else
		self.next_note = "?"
	end
end

Spell.update_debuff_events = { "UNIT_AURA", "PLAYER_TARGET_CHANGED", "SPELL_UPDATE_COOLDOWN" }

function Spell:DebuffEnd(only_self)
	if (not UnitExists("target")) or UnitIsDead("target") or UnitIsFriend("player", "target") then
		self.next_note = nil
		return
	end
	local name, count, expires
	local total_count = 0
	local latest_expire = 0
	local found = false
	name, _, _, count, _, _, expires, caster = UnitDebuff("target", self.spell_name)
	if (name and (not only_self or caster == "player")) then
		total_count = total_count + count
		if ((not self.spell_info.stacks) or (not count) or count >= self.spell_info.stacks) then
			found = true
			if expires and expires > latest_expire then
				latest_expire = expires
			end
		end
	end
	if self.spell_info.shared_debuffs then
		for _, shared_debuff in ipairs(self.spell_info.shared_debuffs) do
			name, _, _, count, _, _, expires, caster = UnitDebuff("target", shared_debuff)
			if (name and (not only_self or caster == "player")) then
				total_count = total_count + count
                if ((not self.spell_info.stacks) or (not count) or count >= self.spell_info.stacks) then
					found = true
					if expires and expires > latest_expire then
						latest_expire = expires
					end
				end
			end
		end
	end
	if found then
		return latest_expire, total_count
	else
		return nil, total_count
	end
end

function Spell:UpdateDebuff(event, unit)
	self = self.owner_spell
	if event == "UNIT_AURA" and unit ~= "target" then return end
	if (not UnitExists("target")) or UnitIsDead("target") or UnitIsFriend("player", "target") then
		self.next_note = nil
		return
	end
	local latest_expire, count = self:DebuffEnd()
	local found = latest_expire
	latest_expire = (latest_expire or 0)

	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)
	if duration and (duration > 1.5 or (duration > 0 and self.next_note and self.next_note > start + duration + EPS.time)) and start + duration > latest_expire then
		latest_expire = start + duration
		found = true
	end

	if latest_expire then
		if self.spell_info.subtract_cast_time then
			local _, _, _, _, _, _, castTime = GetSpellInfo(self.spell_name)
			latest_expire = latest_expire - castTime / 1000
		end
		if latest_expire > 0 then
			if (not tonumber(self.next_note) or self.next_note < latest_expire) then
				self.next_note = latest_expire
			end
		else
			self.next_note = nil
		end
	end

	if (not found) and (not tonumber(self.next_note) or self.next_note > GetTime() + EPS.time) then
		self.next_note = 0
	end

	if self.spell_info.show_stack_count and count and not found then
		self.icon_text = "" .. count
	else
		self.icon_text = nil
	end
end

Spell.update_cooldown_events = { "SPELL_UPDATE_COOLDOWN", "PLAYER_TARGET_CHANGED", "CURRENT_SPELL_CAST_CHANGED", "ACTIONBAR_UPDATE_STATE" }

function Spell:UpdateCooldown()
	self = self.owner_spell
	if self.spell_info.need_target and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitIsFriend("player", "target")) then
		self.next_note = nil
		self.icon_text = nil
		return
	end
	if self.spell_info.need_boss and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitClassification("target") ~= "worldboss") then
		self.next_note = nil
		return
	end
	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)
	if not duration then
		self.next_note = nil
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

	self.icon_text = nil
	if self.spell_info.show_buff_count then
		found, _, _, count = UnitBuff("player", self.spell_info.show_buff_count)
		if found then
			self.icon_text = "" .. count
		end
	end
end

Spell.update_slot_item_events = { "BAG_UPDATE_COOLDOWN", "UNIT_INVENTORY_CHANGED" }

function Spell:UpdateSlotItem(event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
	self = self.owner_spell
	local start, duration, enable = GetInventoryItemCooldown("player", self.spell_info.slot_id)
	if enable == 1 then
		if duration > 0 then
			self.next_note = start + duration
		else
			self.next_note = 0
		end
	else
		self.next_note = nil
	end
end

Spell.update_melee_events = { "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_FAILED_QUIET",
	"UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_TARGET_CHANGED" }

function Spell:UpdateMelee(event, unit, spell)
	self = self.owner_spell
	self.next_note = nil
	if (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED_QUIET" or
		event == "UNIT_SPELLCAST_INTERRUPTED") and unit == "player" and spell == self.casting then
		self.casting = nil
	end
	if (self.spell_info.need_target and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitIsFriend("player", "target"))) or
		(self.spell_info.need_boss and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitClassification("target") ~= "worldboss")) then
	end
end

function Spell:Swing(this_swing, next_swing, special)
	if (not self.last_swing) or math.abs(this_swing - self.last_swing) > EPS.swing then
		self.last_swing = this_swing
	end
	self.last_swing_exact = this_swing
	self.next_swing = next_swing
end

function Spell:UpdateNextSwing(next_swing)
	if (not self.next_swing) or math.abs(next_swing - self.next_swing) > EPS.swing then
		self.next_swing = next_swing
	end
end

function Spell:StopSwing()
	self.last_swing = nil
	self.last_swing_exact = nil
	self.next_swing = nil
end

function Spell:GetStatus()
	local time = GetTime()
	local dimmed = false
	local hidden = false
	local bar_end = nil
	local bar_start = self.next_note
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
	if self.spell_info.show_debuff then
		local expires = self:DebuffEnd(true)
		if expires then
			bar_end = expires
			bar_start = 0
			if self.next_note > time then
				dimmed = true
			end
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
		for _, aura in ipairs(GuiBarHero.Config.enrage_auras) do
			name, _, _, _, _, _, expires = UnitBuff("player", aura)
			if name and bar_start < expires then
				bar_start = expires
			end
		end
	end
	if self.spell_info.dim_on_enrage then
		for _, aura in ipairs(GuiBarHero.Config.enrage_auras) do
			name, _, _, _, _, _, expires = UnitBuff("player", aura)
			if name and bar_start < expires then
				dimmed = true
			end
		end
	end
	if self.spell_info.need_no_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.need_no_aura)
		if name and bar_start < expires then
			bar_start = expires
		end
	end
	return dimmed, hidden, bar_start, bar_end, self.icon_text
end

function Spell:GetInfo()
	return self.spell_info
end

function Spell:GetSlotId()
	return self.slot_id
end

GuiBarHero.Spell = Spell
