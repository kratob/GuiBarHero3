local Settings = {}
local Settings_mt = { __index = Settings }

function Settings:Create()
	settings = {}
	setmetatable(settings, Settings_mt)
	settings:Initialize()
	return settings
end


function Settings:Defaults() 
	return { 
		char = {
			profiles = { { bars = {}, icons = {} } },
			current_profile = 1,
			shown = true,
		},
	}
end

function Settings:Initialize()
	self.database = LibStub("AceDB-3.0"):New("GuiBarHero3DB", self:Defaults()).char
end

function Settings:GetPosition()
	return self.database.position
end

function Settings:SetPosition(position)
	self.database.position = position
end

function Settings:CurrentProfile()
	return self.database.profiles[self.database.current_profile] or { bars = {}, icons = {} }
end

function Settings:GetCurrentProfile()
	return self.database.current_profile
end

function Settings:SetCurrentProfile(nr)
	self.database.current_profile = nr
end

function Settings:GetShown()
	return self.database.shown
end

function Settings:SetShown(shown)
	self.database.shown = shown
end

function Settings:GetBars()
	return self:CurrentProfile().bars
end

function Settings:GetIcons()
	return self:CurrentProfile().icons
end

function Settings:InsertBar(nr, spell_name)
	local bars = self:GetBars()
	local slot, full_name = GuiBarHero.Utils:FindSpell(spell_name)
	if full_name and nr > 0 and nr <= #bars + 1 then
		if bars[nr] and bars[nr].name == full_name then
			bars[nr].alt = (bars[nr].alt or 1) + 1
		else
			table.insert(bars, nr, { name = full_name })
		end
	end
end

function Settings:RemoveBar(nr)
	local bars = self:GetBars()
	if nr > 0 and nr <= #bars then
		table.remove(bars, nr)
	end
end

function Settings:SetIcon(nr, spell_name)
	local icons = self:GetIcons()
	local slot, full_name = GuiBarHero.Utils:FindSpell(spell_name)
	if full_name and nr > 0 then
		if icons[nr] and icons[nr].name == full_name then
			icons[nr].alt = (icons[nr].alt or 1) + 1
		else
			icons[nr] = { name = full_name }
		end
	end
end

function Settings:RemoveIcon(nr)
	local icons = self:GetIcons()
	if nr > 0 then
		icons[nr] = nil
	end
end

function Settings:GetBarSpellName(nr)
	local bars = self:GetBars()
	return bars[nr] and bars[nr].name
end

function Settings:GetIconSpellName(nr)
	local icons = self:GetIcons()
	return icons[nr] and icons[nr].name
end

GuiBarHero.Settings = Settings
