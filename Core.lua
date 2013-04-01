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


function GuiBarHero:OnInitialize()
	self.settings = self.Settings:Create()
end

function GuiBarHero:OnEnable()
	self.main_frame = self.MainFrame:Create()
	self.main_frame:RefreshBars()
	if self.settings:GetShown() then 
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
	self.settings:SetShown(true)
	self.main_frame:Show()
end

function GuiBarHero:Hide()
	self.settings:SetShown(false)
	self.main_frame:Hide()
end

