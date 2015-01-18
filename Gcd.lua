local Gcd = {}
local Gcd_mt = { __index = Gcd }

function Gcd:Release()
	self.frame:UnregisterAllEvents()
	self.frame:SetScript("OnEvent", nil)
end

function Gcd:Create(frame)
	gcd = {}
	setmetatable(gcd, Gcd_mt)
	Gcd:Initialize(frame)
	return gcd
end

function Gcd:Initialize(frame)
	self.slot = GuiBarHero.Utils:FindFirstSpell(GuiBarHero.Config.gcd_spells)
	self.next_gcd = 0
	self.frame = frame
	frame.owner = gcd
	frame:SetScript("OnEvent", Gcd.OnEvent)
	frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

function Gcd:OnEvent()
	self = self.owner
	local start, duration = GetSpellCooldown(self.slot, BOOKTYPE_SPELL)
	if start and duration then
		self.next_gcd = start + duration
	else
		self.next_gcd = 0
	end
end

function Gcd:GetNext()
	return self.next_gcd
end

GuiBarHero.Gcd = Gcd
