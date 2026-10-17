-- Weather Cycle settings
-- Durations are in in-game days (1 day = 60s of game time at normal speed by default).
-- Time is game time, so the cycle pauses when the game is paused and speeds up with fast-forward.

return {
	-- The cycle runs top to bottom, then loops. Remove or reorder entries as you like.
	-- Available weathers: "WEATHER_SUNNY", "WEATHER_DUSK", "WEATHER_NIGHT", "WEATHER_RAINY"
	Phases = {
		{ Weather = "WEATHER_SUNNY", Days = 8.0, CanRain = true },  -- day
		{ Weather = "WEATHER_DUSK",  Days = 3.0 },                  -- sunset
		{ Weather = "WEATHER_NIGHT", Days = 6.0 },                  -- night
		{ Weather = "WEATHER_DUSK",  Days = 3.0 },                  -- twilight / sunrise (the game uses the dusk look for this)
	},

	-- true  = the cycle speeds up / slows down with the game speed (2x game = 2x cycle)
	-- false = the cycle runs at normal (1x) pace no matter the game speed; still stops when paused
	FollowGameSpeed = true,

	-- Experimental: tilt the sun (degrees). 0 = game default.
	-- Pitch raises/lowers the sun, Yaw swings it around the map (changes shadow direction).
	SunPitchOffset = 20,
	SunYawOffset = 0,

	-- Chance (0.0 - 1.0) that a phase with CanRain = true is rainy instead
	RainChance = 0.2,

	-- Write each weather change to the game log
	Verbose = true,

	-- Show in-game popups when the mod loads and when the cycle starts on a map.
	-- Set to false once you've confirmed it works.
	Debug = true,
}
