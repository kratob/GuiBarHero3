local EPS = { time = 0.2 }

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
	self.bar_start = 0
	self.bar_end = nil

	self:AttachHandler()
end

function Spell:AttachHandler()
	local handler
	local events
	if self.spell_info.type == "COOLDOWN" then
		handler = Spell.UpdateCooldown
		events = Spell.update_cooldown_events
	elseif self.spell_info.type == "SELFBUFF" then
		handler = Spell.UpdateSelfbuff
		events = Spell.update_selfbuff_events
	elseif self.spell_info.type == "DEBUFF" then
		handler = Spell.UpdateDebuff
		events = Spell.update_debuff_events
	elseif self.spell_info.type == "SLOTITEM" then
		handler = Spell.UpdateSlotItem
		events = Spell.update_slot_item_events
	end
	if handler then
		self.frame:SetScript("OnEvent", handler)
		for _, event in pairs(events) do
			self.frame:RegisterEvent(event)
		end
		handler(self.frame)
	end
end

Spell.update_selfbuff_events = { "UNIT_AURA" }

function Spell:UpdateSelfbuff(event_type, unit)
	self = self.owner_spell
	if unit and unit ~= "player" then return end

	self:UpdateBuff(self.GetBuff)
end

Spell.update_debuff_events = { "UNIT_AURA", "PLAYER_TARGET_CHANGED", "SPELL_UPDATE_COOLDOWN" }

function Spell:UpdateDebuff(event, unit)
	self = self.owner_spell
	if event == "UNIT_AURA" and unit ~= "target" then return end
	if (not UnitExists("target")) or UnitIsDead("target") or UnitIsFriend("player", "target") then
		self.bar_start = nil
		self.bar_end = nil
		self.icon_text = nil
		return
	end

	self:UpdateBuff(self.GetDebuff)
end

function Spell:GetBuff(name)
    return UnitBuff("player", name)
end

function Spell:GetDebuff(name)
    return UnitDebuff("target", name)
end

function Spell:UpdateBuff(get_buff)
	local latest_expire, count = self:BuffEnd(get_buff)
	local found = latest_expire
	local last_bar_start = self.bar_start or 0
	if not found then
		self.bar_start = nil
		self.bar_end = nil
	end

	latest_expire = (latest_expire or 0)

	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)
	if duration and (duration > 1.5 or (duration > 0 and self.bar_start and self.bar_start > start + duration + EPS.time)) and start + duration > latest_expire then
		latest_expire = start + duration
		found = true
	end

	if latest_expire then
		if self.spell_info.subtract_cast_time then
			local _, _, _, _, _, _, castTime = GetSpellInfo(self.spell_name)
			latest_expire = latest_expire - castTime / 1000
		end
		if latest_expire > 0 then
			if (not self.bar_start or self.bar_start < latest_expire) then
				self.bar_start = latest_expire
			end
		else
			self.bar_start = nil
		end
	end

	if (not found) and (not self.bar_start or self.bar_start > GetTime() + EPS.time) then
		self.bar_start = 0
	end

	self:ShowBuffOrDebuff(last_bar_start)

	if self.spell_info.show_stack_count and count and not found then
		self.icon_text = "" .. count
	else
		self.icon_text = nil
	end
end

function Spell:BuffEnd(get_buff, only_self)
	local name, count, expires
	local total_count = 0
	local latest_expire = 0
	local found = false
	name, _, _, count, _, _, expires, caster = get_buff("target", self.spell_name)
	if (name and (not only_self or caster == "player")) then
		total_count = total_count + count
		if ((not self.spell_info.stacks) or (not count) or count >= self.spell_info.stacks) then
			found = true
			if expires and expires > latest_expire then
				latest_expire = expires
			end
		end
	end
	if self.spell_info.shared_buffs then
		for _, shared_debuff in ipairs(self.spell_info.shared_buffs) do
			name, _, _, count, _, _, expires, caster = get_buff("target", shared_debuff)
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


Spell.update_cooldown_events = { "SPELL_UPDATE_COOLDOWN", "PLAYER_TARGET_CHANGED", "CURRENT_SPELL_CAST_CHANGED", "ACTIONBAR_UPDATE_STATE", "UNIT_AURA" }

function Spell:UpdateCooldown(event, unit)
	self = self.owner_spell
	if event == "UNIT_AURA" and unit ~= "target" and unit ~= "player" then return end

	local last_bar_start = self.bar_start or 0
	self.bar_start = nil
	self.bar_end = nil
	self.icon_text = nil

	if not self:ValidTarget() then return end

	local start, duration = GetSpellCooldown(self.slot_id, BOOKTYPE_SPELL)

	if duration and duration > 0 then
		end_time = start + duration
		if duration > 1.5 or (not last_bar_start) or last_bar_start > end_time + EPS.time  then
			self.bar_start = end_time
		else
			self.bar_start = last_bar_start
		end
	else
		if last_bar_start < GetTime() + EPS.time then
			self.bar_start = last_bar_start
		else
			self.bar_start = 0
		end
	end

	local spell, _, _, _, _, endTime = UnitCastingInfo("player")
	if endTime and endTime > self.bar_start * 1000 then
		self.bar_start = endTime / 1000
	end

	if self.spell_info.need_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.need_aura)
		if name then
			self.bar_end = expires
		else
			self.bar_start = nil
			self.bar_end = nil
		end
	end

	if self.spell_info.also_lit_on_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.also_lit_on_aura)
		if name then
			self.bar_start = 0
			self.bar_end = expires
		end
	end

	if self.spell_info.need_no_aura then
		name, _, _, _, _, _, expires = UnitBuff("player", self.spell_info.need_no_aura)
		if name and self.bar_start < expires then
			self.bar_start = expires
		end
	end

	self.icon_text = nil
	if self.spell_info.show_buff_count then
		found, _, _, count = UnitBuff("player", self.spell_info.show_buff_count)
		if found then
			self.icon_text = "" .. count
		end
	end

	self:ShowBuffOrDebuff(last_bar_start)
end

function Spell:ShowBuffOrDebuff(last_bar_start)
	if self.spell_info.show_debuff or self.spell_info.show_buff then
		local expires
		if self.spell_info.show_debuff then
			expires = self:BuffEnd(self.GetDebuff, true)
		else
			expires = self:BuffEnd(self.GetBuff)
		end
		if expires then
			self.bar_start = nil
			self.bar_end = expires
		elseif last_bar_start > GetTime() - EPS.time then
			self.bar_start = last_bar_start
		end
	end
end

function Spell:ValidTarget()
	if self.spell_info.need_target and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitIsFriend("player", "target")) then
		return false
	end
	if self.spell_info.need_boss and ((not UnitExists("target")) or 
		UnitIsDead("target") or UnitClassification("target") ~= "worldboss") then
		return false
	end
	return true
end

Spell.update_slot_item_events = { "BAG_UPDATE_COOLDOWN", "UNIT_INVENTORY_CHANGED", "UNIT_AURA" }

function Spell:UpdateSlotItem(event, unit)
	if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_AURA") and unit ~= "player" then return end
	self = self.owner_spell
	local last_bar_start = self.bar_start or 0
	self.bar_end = nil
	local start, duration, enable = GetInventoryItemCooldown("player", self.spell_info.slot_id)
	if enable == 1 then
		if duration > 0 then
			local expires, buff_texture
			local item_id = GetInventoryItemID("player", self.spell_info.slot_id)
			local name, _, _, _, _, _, _, _, _, item_texture = GetItemInfo(item_id)
			_, _, _, _, _, _, expires = UnitBuff("player", name)
			if not expires then
				-- attempt to guess by texture
				for i = 1, 40 do
					_, _, buff_texture, _, _, _, expires = UnitBuff("player", i)
					if (not buff_texture) or buff_texture == item_texture then
						break
					end
				end
			end

			if expires and expires > 0 then
				self.bar_start = nil
				self.bar_end = expires
			else
				self.bar_start = start + duration
			end
		elseif last_bar_start > GetTime() + EPS.time then
			self.bar_start = 0
		else
			self.bar_start = last_bar_start
		end
	else
		self.bar_start = nil
	end
end

function Spell:GetStatus()
	local hidden = false
	local bar_start = self.bar_start
	local bar_end = self.bar_end

	local dimmed = self:IsDimmed(bar_start)

	if bar_end and not bar_start then
		bar_start = 0
		dimmed = true
	end

	return dimmed, hidden, bar_start, bar_end, self.icon_text
end

function Spell:IsDimmed(bar_start)
	local dimmed = false

	if (self.slot_id and (not IsUsableSpell(self.spell_name)) or (SpellHasRange(self.spell_name) and IsSpellInRange(self.spell_name, "target") == 0)) then
		dimmed = true
	end

	if self.spell_info.min_rage and UnitMana("player") < self.spell_info.min_rage then
		dimmed = true
	end

	if self.spell_info.max_rage and UnitMana("player") > self.spell_info.max_rage then
		dimmed = true
	end

	if self.spell_info.dim_on_enrage and bar_start then
		local enrage_end = self:EnrageEnd()
		if enrage_end and enrage_end > bar_start then
			dimmed = true
		end
	end

	return dimmed
end

function Spell:EnrageEnd()
	local found
	local latest_expires = 0
	for _, aura in ipairs(GuiBarHero.Config.enrage_auras) do
		name, _, _, _, _, _, expires = UnitBuff("player", aura)
		if name and expires > latest_expires then
			found = true
			latest_expires = expires
		end
	end
	return found and latest_expires
end

function Spell:GetInfo()
	return self.spell_info
end

function Spell:GetSlotId()
	return self.slot_id
end

GuiBarHero.Spell = Spell
