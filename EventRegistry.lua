local EventRegistry = {}
local EventRegistry_mt = { __index = EventRegistry }

function EventRegistry:Create(frame)
	local event_registry = {}
	setmetatable(event_registry, EventRegistry_mt)
	event_registry:Initialize(frame)
	return event_registry
end

function EventRegistry:Initialize(frame)
	self.frame = CreateFrame("Frame", "EventRegistry", frame)
	self.frame.owner = self
	self.frame:SetScript("OnEvent", EventRegistry.OnEvent)
	self.registry = {}
	self.events_by_unit = {}
end

function EventRegistry:OnEvent(event, unit)
	self = self.owner
	if unit and unit ~= "player" and unit ~= "target" then return end
	local escaped_unit = unit or "nil"
	if not self.events_by_unit[unit] then
		self.events_by_unit[escaped_unit] = {}
	end
	self.events_by_unit[escaped_unit][event] = true
end

function EventRegistry:Run()
	for unit, events in pairs(self.events_by_unit) do
		local unescaped_unit = unit == "nil" and nil or unit
		for event, _ in pairs(events) do
			for entry, _ in pairs(self.registry[event] or {}) do
				entry.callback(entry.spell, event, unescaped_unit)
			end
		end
	end
	self.events_by_unit = {}
end

function EventRegistry:Register(event, spell, callback)
	if not self.registry[event] then
		self.registry[event] = {}
		self.frame:RegisterEvent(event)
	end
	entry = { callback = callback, spell = spell }
	self.registry[event][entry] = true
end

function EventRegistry:Unregister(spell)
	for event, spells in pairs(self.registry) do
		for entry, _ in pairs(spells) do
			if entry.spell == spell then
				spells[entry] = nil
			end
		end
	end
end

GuiBarHero.EventRegistry = EventRegistry
