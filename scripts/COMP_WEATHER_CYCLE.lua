local mod, config, state = ...

--------------------------------------------------------------------------
local COMP_WEATHER_CYCLE = {
	TypeName = "COMP_WEATHER_CYCLE",
	ParentType = "COMPONENT",
	Properties = {}
}

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:create()
	self._phaseIndex = 0
	self._timer = 0
	self._started = false
	self._waitTime = 0
end

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:init()
	mod:log("Weather Cycle: component initialized")
	self:tryStart()
end

--------------------------------------------------------------------------
-- The map may still be loading when the component is created, so keep looking
-- for the environment system until it exists.
function COMP_WEATHER_CYCLE:tryStart()
	-- Another copy (e.g. one restored from a save) is already driving the weather
	if state.activeCycle ~= nil and state.activeCycle ~= self then
		self._started = true
		self._dormant = true
		mod:log("Weather Cycle: another cycle is active, this copy stays idle")
		return true
	end

	local level = self:getLevel()
	self._environment = level:find("COMP_ENVIRONMENT_SYSTEM")
	self._gameLoop = level:find("COMP_MAIN_GAME_LOOP")

	if self._environment == nil then
		return false
	end

	self._started = true
	state.activeCycle = self
	mod:log("Weather Cycle: started")

	if config.Debug then
		self:probeTimeline()
	end

	self:initSun()
	self:nextPhase()

	if config.Debug then
		mod:msgBox("Weather Cycle: running on this map\nFirst change in " .. math.floor(self._timer) .. "s of game time")
	end
	return true
end

--------------------------------------------------------------------------
-- Debug only: log what the undocumented lighting timeline exposes to Lua,
-- to find out whether weather changes can be blended
-- The game's Lua is sandboxed (no rawget), so only plain table access is used here
local function listMethods(_value)
	if getmetatable == nil then
		return "(getmetatable unavailable) " .. type(_value)
	end
	local names = {}
	local seen = {}
	local mt = getmetatable(_value)
	local depth = 0
	while type(mt) == "table" and depth < 8 do
		local index = mt.__index
		for _, tbl in ipairs({ mt, type(index) == "table" and index or {} }) do
			for k, v in pairs(tbl) do
				if type(k) == "string" and not seen[k] then
					seen[k] = true
					table.insert(names, k)
				end
			end
		end
		if type(index) ~= "table" then break end
		mt = getmetatable(index)
		depth = depth + 1
	end
	table.sort(names)
	return "[" .. type(_value) .. ", metatable " .. type(getmetatable(_value)) .. "] " .. table.concat(names, ", ")
end

function COMP_WEATHER_CYCLE:probeTimeline()
	local ok, err = pcall(function()
		mod:log("Weather Cycle probe: environment methods = " .. listMethods(self._environment))

		local timeline = foundation.findGameObject("Timeline")
		if timeline == nil then
			mod:log("Weather Cycle probe: no 'Timeline' object found")
			return
		end
		timeline:forEachComponent(function(_component)
			mod:log("Weather Cycle probe: Timeline component " .. tostring(_component))
			mod:log("Weather Cycle probe:   methods = " .. listMethods(_component))
		end)
	end)
	if not ok then
		mod:log("Weather Cycle probe failed: " .. tostring(err))
	end
end

--------------------------------------------------------------------------
-- Sun tilt: the sun light lives under Environment/SunContainer. Rotating the container
-- tilts everything under it. Re-applied every frame in case the game resets it.
function COMP_WEATHER_CYCLE:initSun()
	local pitch = config.SunPitchOffset or 0
	local yaw = config.SunYawOffset or 0
	if pitch == 0 and yaw == 0 then
		return
	end

	local ok, err = pcall(function()
		self._sun = foundation.findGameObject("SunContainer")
		if self._sun == nil then
			mod:logWarning("Weather Cycle: SunContainer not found, sun tilt disabled")
			return
		end
		self._sunBase = self._sun:getGlobalOrientation()
		self._sunPitch = math.rad(pitch)
		self._sunYaw = math.rad(yaw)
		self:applySun()
		mod:log("Weather Cycle: sun tilt applied (pitch " .. pitch .. ", yaw " .. yaw .. ")")
	end)
	if not ok then
		mod:logWarning("Weather Cycle: sun tilt failed: " .. tostring(err))
		self._sun = nil
	end
end

function COMP_WEATHER_CYCLE:applySun()
	self._sun:setGlobalOrientation(self._sunBase)
	self._sun:rotateY(self._sunYaw)
	self._sun:rotateX(self._sunPitch)
end

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:getDayDuration()
	if self._gameLoop ~= nil then
		return self._gameLoop:getDayDurationInSeconds()
	end
	return 60
end

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:nextPhase()
	local phases = config.Phases
	self._phaseIndex = (self._phaseIndex % #phases) + 1
	local phase = phases[self._phaseIndex]

	local weatherId = phase.Weather
	if phase.CanRain and math.random() < config.RainChance then
		weatherId = "WEATHER_RAINY"
	end

	self._timer = phase.Days * self:getDayDuration()

	local weather = foundation.findAsset(weatherId)
	if weather == nil then
		mod:logWarning("Weather Cycle: unknown weather " .. tostring(weatherId))
		return
	end

	self._environment:changeCurrentWeather(weather)
	if config.Verbose then
		mod:log("Weather Cycle: " .. weatherId .. " for " .. phase.Days .. " day(s) (" .. math.floor(self._timer) .. "s)")
	end
end

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:update()
	local level = self:getLevel()
	local dt = level:getDeltaTime()
	if config.FollowGameSpeed == false and level:getTimeScale() > 0 then
		dt = level:getUnscaledDeltaTime()
	end

	if not self._started then
		self._waitTime = self._waitTime + self:getLevel():getUnscaledDeltaTime()
		if not self:tryStart() and self._waitTime > 30 then
			mod:logWarning("Weather Cycle: COMP_ENVIRONMENT_SYSTEM not found after 30s, still waiting")
			if config.Debug then
				mod:msgBox("Weather Cycle: ERROR - environment system not found")
			end
			self._waitTime = -1e9
		end
		return
	end

	if self._dormant then
		return
	end

	if self._sun ~= nil then
		self:applySun()
	end

	self._timer = self._timer - dt
	if self._timer <= 0 then
		self:nextPhase()
	end
end

--------------------------------------------------------------------------
function COMP_WEATHER_CYCLE:onFinalize(_isClearingLevel)
	if state.activeCycle == self then
		state.activeCycle = nil
	end
end

--------------------------------------------------------------------------
mod:registerClass(COMP_WEATHER_CYCLE)
