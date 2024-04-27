--@class FuelTankHelper
-- system.print("ContainerOpt. "..ContainerOptimization)
fuelTanks = {}
FuelMass = {}
FuelTime = {}
fuelTypes = {
  atmo = {
    density = 4.000,
  },
  space = {
    density = 6.000,
  },
  rocket = {
    density = 0.800,
  },
}
local function calcAtmoVolume(baseCap)
	if fuelTankHandlingAtmo > 0 then
		return baseCap + (baseCap * (fuelTankHandlingAtmo * 0.2))
	end
	return baseCap
end
local function calcSpaceVolume(baseCap)
	if fuelTankHandlingSpace > 0 then
		return baseCap + (baseCap * (fuelTankHandlingSpace * 0.2))
	end
	return baseCap
end
local function calcMaxMass(cap, type)
	local maxMass = cap * fuelTypes[type].density
	local adjustedMaxMass = maxMass
	if ContainerOptimization > 0 then adjustedMaxMass = maxMass - (maxMass * ContainerOptimization * 0.05) end
	if FuelTankOptimization > 0 then adjustedMaxMass = adjustedMaxMass - (maxMass * FuelTankOptimization * 0.05) end
	return adjustedMaxMass
end
function normalizeHp(type,hp)
	local adjHp = 0
	if type == "atmo" then
		if hp >= 50 and hp < 163 then adjHp = 50
		elseif hp >= 163 and hp < 1315 then adjHp = 163
		elseif hp >= 1315 and hp < 10461 then adjHp = 1315
		elseif hp >= 10461 then adjHp = 10461 end
	elseif type == "space" then
		if hp >= 50 and hp < 187 then adjHp = 50
		elseif hp >= 187 and hp < 1496 then adjHp = 187
		elseif hp >= 1496 and hp < 15933 then adjHp = 1496
		elseif hp >= 15933 then adjHp = 15933 end
	elseif type == "rocket" then
		if hp >= 366 and hp < 736 then adjHp = 366
		elseif hp >= 736 and hp < 6231 then adjHp = 736
		elseif hp >= 6231 and hp < 68824 then adjHp = 6231
		elseif hp >= 68824 then adjHp = 68824 end
	end
	return adjHp
end
function normalizeHpAtmo(hp)
end
function normalizeHpSpace(hp)
  -- 187
  -- 1496
  -- 15933
end
function normalizeHpRocket(hp)
  -- 366
  -- 736
  -- 6231
  -- 68824
end
fuelTankSpecsByMaxHP = {
  -- Atmo Tanks
  atmo = {
    _50 = {
      type = "atmo",
      size = "XS",
      capacity = function() return calcAtmoVolume(100) end,
      baseWeight = 35.030,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(100),"atmo") end,
    },
    _163 = {
      type = "atmo",
      size = "S",
      capacity = function() return calcAtmoVolume(400) end,
      baseWeight = 182.670,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(400),"atmo") end,
    },
    _1315 = {
      type = "atmo",
      size = "M",
      capacity = function() return calcAtmoVolume(1600) end,
      baseWeight = 988.670,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(1600),"atmo") end,
    },
    _10461 = {
      type = "atmo",
      size = "L",
      capacity = function() return calcAtmoVolume(12800) end,
      baseWeight = 5480.000,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(12800),"atmo") end,
    },
  },

  -- Space Tanks
  space = {
    _50 = {
      type = "space",
      size = "XS",
      capacity = function() return calcAtmoVolume(100) end,
      baseWeight = 35.030,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(100),"space") end,
    },
    _187 = {
      type = "space",
      size = "S",
      capacity = function() return calcSpaceVolume(400) end,
      baseWeight = 182.670,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(400),"space") end,
    },
    _1496 = {
      type = "space",
      size = "M",
      capacity = function() return calcSpaceVolume(1600) end,
      baseWeight = 988.670,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(1600),"space") end,
    },
    _15933 = {
      type = "space",
      size = "L",
      capacity = function() return calcSpaceVolume(12800) end,
      baseWeight = 5480.000,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(12800),"space") end,
    },
  },

  -- Rocket Tanks
  rocket = {
    _366 = {
      type = "rocket",
      size = "XS",
      capacity = function() return 400 end,
      baseWeight = 173.420,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(400),"rocket") end,
    },
    _736 = {
      type = "rocket",
      size = "S",
      capacity = function() return 800 end,
      baseWeight = 886.720,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(800),"rocket") end,
    },
    _6231 = {
      type = "rocket",
      size = "M",
      capacity = function() return 6400 end,
      baseWeight = 4720.000,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(6400),"rocket") end,
    },
    _68824 = {
      type = "rocket",
      size = "L",
      capacity = function() return 50000 end,
      baseWeight = 25740.000,
      maxWeight = function() return calcMaxMass(calcAtmoVolume(50000),"rocket") end,
    },
  },
}

local function isINF(value)
  return value == math.huge or value == -math.huge
end

local function isNAN(value)
  return value ~= value
end

function disp_time(time)
  if isINF(time) or isNAN(time) then return "-:-" end
  local days = math.floor(time/86400)
  local hours = math.floor(math.fmod(time, 86400)/3600)
  local minutes = math.floor(math.fmod(time,3600)/60)
  local seconds = math.floor(math.fmod(time,60))
  if time >= 86400 then
      return string.format("%dd:%02dh",days,hours)
  elseif time < 86400 and time > 3600 then
      return string.format("%02dh:%02dm:%02ds",hours,minutes,seconds)
  elseif time < 3600 and time > 60 then
      return string.format("%02dm:%02ds",minutes,seconds)
  else
      return string.format("%02ds",seconds)
  end
end

local unpack = table.unpack

function fuelUsed(period)
	local t = {}
	function sum(a, ...)
		if a then
            return a-sum(...)
        else
            return 0
        end
	end
	function average(n)
		if #t == period then table.remove(t, 1) end
		if n ~= 0 and n ~= nil then t[#t + 1] = n end
		return sum(unpack(t))
	end
	return average
end

function getFuelSituation()
  local tanks = {
    atmo = {},
    space = {},
    rocket = {},
  }

  for id, specs in pairs(fuelTanks) do
    table.insert(tanks[specs.type], {
      name = core.getElementNameById(id),
      level = getFuelTankLevel(id),
      time = getFuelTime(id),
      specs = specs,
    })
  end
  return tanks
end

function getFuelTankSpecs(fuelTankType, fuelTankId)
  local maxHP = math.floor(core.getElementMaxHitPointsById(fuelTankId))
--   system.print(fuelTankType.." ... "..maxHP)
  return fuelTankSpecsByMaxHP[fuelTankType]['_' .. normalizeHp(fuelTankType,maxHP)]
end

function getFuelTankLiters(fuelTankId)
  local fuelTankSpecs = fuelTanks[fuelTankId]
  local massTotal = core.getElementMassById(fuelTankId)
  local massContents = massTotal - fuelTankSpecs.baseWeight
  return massContents
end
--vanillaMaxVolume = vanillaMaxVolume - (vanillaMaxVolume * ContainerOptimization * 0.05)
function getFuelTankLevel(fuelTankId)
  local fuelTankSpecs = fuelTanks[fuelTankId]
  local adjustedMaxMass = fuelTankSpecs.maxWeight()
  return getFuelTankLiters(fuelTankId) / adjustedMaxMass
end

function getFuelTime(fuelTankId)
  local fuelTankSpecs = fuelTanks[fuelTankId]
  local lastUpdate = FuelTime[fuelTankId] or system.getArkTime()
  local deltaTime = math.max(system.getArkTime() - lastUpdate, 0.001)
  local massTotal = core.getElementMassById(fuelTankId)
  local minMass = fuelTankSpecs.baseWeight
  local fuelUsed = FuelMass[fuelTankId](massTotal)
  local fuelTime = (deltaTime / fuelUsed) * (massTotal - minMass)
  local fuelTimeFormatted = disp_time(fuelTime)
  FuelTime[fuelTankId] = system.getArkTime()
  return fuelTimeFormatted
end

function getFuelTanks()
  local elementIds = core.getElementIdList()
  for k, elementId in pairs(elementIds) do
    local elementType = core.getElementDisplayNameById(elementId)
    -- Fuel tank configuration routine
    if elementType == "Atmospheric Fuel Tank" then
      --system.print(elementType.."_"..elementId)
      local tank = getFuelTankSpecs("atmo", elementId)
      fuelTanks[elementId] = tank
      FuelMass[elementId] = fuelUsed(2)
    elseif elementType == "Space Fuel Tank" then
      fuelTanks[elementId] = getFuelTankSpecs("space", elementId)
      FuelMass[elementId] = fuelUsed(2)
    elseif elementType == "Rocket Fuel Tank" then
      fuelTanks[elementId] = getFuelTankSpecs("rocket", elementId)
      FuelMass[elementId] = fuelUsed(2)
    end
  end

--   for _, v in ipairs(fuelTankSpecsByMaxHP) do
--     --system.print("Fuel Tank: "..v)
--     for k,t in ipairs(v) do
--       for x,y in pairs(t) do
--         --system.print("Capacity: "..y.capacity())
--       end
--     end
--   end
end

getFuelTanks()