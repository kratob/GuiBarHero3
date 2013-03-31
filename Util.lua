local Utils = {}

function Utils:GetNumSpellBookItems()
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

GuiBarHero.Utils = Utils
