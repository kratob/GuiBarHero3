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
		}
	},
}


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
	self.main_frame = self:CreateMainFrame()
	self.main_frame:RefreshBars()
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
	self.main_frame:RefreshBars()
end

function GuiBarHero:Show()
	self.db.char.shown = true
	self.main_frame:Show()
end

function GuiBarHero:Hide()
	self.db.char.shown = false
	self.main_frame:Hide()
end

