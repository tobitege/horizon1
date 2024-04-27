--@class AR_HUD

json = require('dkjson')
quat = require('cpml/quat')
vec3 = require('cpml/vec3')
const = require('cpml/constants')
vec2 = require('cpml/vec2')
utils = require('cpml/utils')
mat4 = require("cpml/mat4")


mouseDeltaSum = vec2(0,0)

local function signum(number)
	if number > 0 then
	   return 1
	elseif number < 0 then
	   return -1
	else
	   return 0
	end
 end
function scaleViewBoundsY(viewY)
	local rMin = 0
	local rMax = 1250 / mouseSensitivity
	local tMin = -(system.getScreenHeight() / 2)
	local tMax = system.getScreenHeight() / 2
	return ((viewY - rMin) / (rMax - rMin)) * (tMax - tMin) + tMin
end
function scaleViewBoundsX(viewX)
    local rMin = 1
    local rMax = -1
	if signum(forwardX.x) == -1  and signum(forwardX.y) == -1 then
		rMin = -1
		rMax = 1
	elseif signum(forwardX.x) == 1  and signum(forwardX.y) == -1 then
		rMin = -1
		rMax = 1
	end
    local tMin = -(system.getScreenHeight() / 2)
    local tMax = system.getScreenHeight() / 2
    return ((viewX - rMin) / (rMax - rMin)) * (tMax - tMin) + tMin
end
function scaleViewBound(rMin,rMax,tMin,tMax,input)
    return ((input - rMin) / (rMax - rMin)) * (tMax - tMin) + tMin
end

function deltaSum(sum, delta)
   local deltaX = 0
   local deltaY = 0

   if (sum.y + delta.y) <= 0 then deltaY = 0
   elseif (sum.y + delta.y) >= (1250 / mouseSensitivity) then deltaY = (1250 / mouseSensitivity)
   else deltaY = sum.y + delta.y
   end

   return vec2(deltaX,deltaY)
end

function updateAR()
	local mouseDelta = vec2(system.getMouseDeltaX(),system.getMouseDeltaY())
	mouseDeltaSum = deltaSum(mouseDeltaSum,mouseDelta)
	playerQ = 1-- quat(unit.getMasterPlayerRelativeOrientation())
	forwardX = (playerQ * vec3(core.getConstructOrientationForward()))
	ship.viewY = scaleViewBoundsY(mouseDeltaSum.y)
	ship.viewX = scaleViewBoundsX(forwardX.x)
    --system.print("x: "..ship.viewX..", y: "..ship.viewY)
end
