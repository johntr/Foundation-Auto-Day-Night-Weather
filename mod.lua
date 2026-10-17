local weatherCycleMod = foundation.createMod();

-- User settings (phase lengths, rain chance)
local config = weatherCycleMod:dofile("config.lua")

-- Log only: a message box here pops up mid-load, which seems to stop the cycle starting
weatherCycleMod:log("Weather Cycle: mod loaded")

-- Shared between the component and the hook so only one cycle runs per map
local state = { activeCycle = nil }

-- Component that drives the cycle
weatherCycleMod:dofile("scripts/COMP_WEATHER_CYCLE.lua", config, state)

-- Starts the component when a map loads
weatherCycleMod:dofile("scripts/level_hook.lua", config, state)
