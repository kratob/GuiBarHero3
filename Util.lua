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

function Utils:FindSpell(name)
	name = string.lower(name)
	if name == "trinket 1" then 
		return nil, "Trinket 1"
	elseif name == "trinket 2" then
		return nil, "Trinket 2"
	end
	local slot_id = 1
	for slot_id = 1, self:GetNumSpellBookItems() do
		local full_name = GetSpellBookItemName(slot_id, BOOKTYPE_SPELL)
		if not full_name then return nil end
		if string.lower(full_name) == name then
			return slot_id, full_name
		end
	end
	return nil
end

function Utils:FindFirstSpell(spells)
	for _, spell in ipairs(spells) do
		local slot, name = Utils:FindSpell(spell)
		if slot then
			return slot, name
		end
	end
end

GuiBarHero.Utils = Utils
