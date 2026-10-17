local mod, config, state = ...

-- There is no documented "map loaded" callback, so this piggybacks on the taxation
-- system, which calls init() on every registered taxation function when a map loads
-- (same pattern as the official Taxation example). It never taxes anything; it only
-- spawns an object carrying COMP_WEATHER_CYCLE.

--------------------------------------------------------------------------
local TAXATION_FUNCTION_WEATHER_CYCLE_HOOK = {
	TypeName = "TAXATION_FUNCTION_WEATHER_CYCLE_HOOK",
	ParentType = "TAXATION_FUNCTION_BRACKET",
	Properties = {}
}

--------------------------------------------------------------------------
function TAXATION_FUNCTION_WEATHER_CYCLE_HOOK:init(_instTaxationFunction)
	mod:log("Weather Cycle: level hook fired")

	local level = _instTaxationFunction:getTaxationManager():getLevel()
	-- A cycle saved with the map restarts by itself; only create one if none exists,
	-- otherwise every save/load would add another copy
	if state.activeCycle ~= nil or level:find("COMP_WEATHER_CYCLE") ~= nil then
		mod:log("Weather Cycle: cycle already present on this map")
		return
	end

	level:createObject(function(_object)
		_object:addComponent("COMP_WEATHER_CYCLE")
	end)
end

--------------------------------------------------------------------------
function TAXATION_FUNCTION_WEATHER_CYCLE_HOOK:finalize(_instTaxationFunction)
	event.clear(self)
end

--------------------------------------------------------------------------
function TAXATION_FUNCTION_WEATHER_CYCLE_HOOK:getMaximumAmountToCollect(_taxCollectable)
	return 0
end

--------------------------------------------------------------------------
mod:registerClass(TAXATION_FUNCTION_WEATHER_CYCLE_HOOK)

mod:registerAsset({
	DataType = "TAXATION_FUNCTION_WEATHER_CYCLE_HOOK",
	Id = "WEATHER_CYCLE_TAXATION_HOOK",
	NameKey = "WEATHER_CYCLE_HOOK_NAME",
	DescriptionKey = "WEATHER_CYCLE_HOOK_DESCRIPTION",
	CategoryKey = "WEATHER_CYCLE_HOOK_CATEGORY",
	TaxedNameKey = "WEATHER_CYCLE_HOOK_TAXED",
	TaxationBracketList = {
		{
			DataType = "TAXATION_BRACKET",
			TaxPercentage = 0.0
		}
	}
})

mod:overrideAsset({
	Id = "DEFAULT_TAXATION_SETTINGS",
	AssetTaxationFunctionList = {
		Action = "APPEND",
		"WEATHER_CYCLE_TAXATION_HOOK"
	}
})
