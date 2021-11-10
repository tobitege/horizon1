--@class STEC
--[[
    Shadow Templar Engine Control
    Version: 1.17

    Setup:
        - Put this file in system.start
        - Replace system.flush with: engines.apply()
        - Replace all controls with the appropriate STEC equivalent:
            - ship.direction.x - left/right
            - ship.direction.y - forward/back
            - ship.direction.z - forward/back
            - ship.rotation.x - pitch
            - ship.rotation.y - roll
            - ship.rotation.z - yaw
        - See comments for additional functionality
]]
planetaryReference = PlanetRef()
galaxyReference = planetaryReference(Atlas())
helios = galaxyReference[0]
kinematics = Kinematics()
local json = require("dkjson")
local jdecode = json.decode

local find = string.find
function getJsonNum (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*(-?[0-9.e-]+)]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)
  return tonumber(valueStr), startIndex, endIndex
end

function round(val, decimal)
  if (decimal) then
    return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
  else
    return math.floor(val + 0.5)
  end
end

function getBrakingInfo()
    local curVelMs = vec3(core.getWorldVelocity()):len()
    local cMass = core.getConstructMass()
    local brakingForce = getJsonNum(unit.getData(), "maxBrake")
    local brakeInfo = {}
    if brakingForce == 0 then
        brakeInfo.time = "BF: 0"
        brakeInfo.dist = 1
        return brakeInfo
    end

    local brakeForce = math.floor(brakingForce)
    local rA = brakeForce / cMass
    local c = 30000000 / 3600
    local c2 = c * c
    local cA = c * math.asin(curVelMs / c)
    local cC = c2 * math.cos(cA / c) / rA
    
    local t = (c - cA) / rA
    local d = cC - c2 * math.cos((rA * t + cA) / c) / rA
      
    local min = math.floor(t / 60)
    t = t - (60 * min)
    local sec = round(t, 0)
        
    local tms = string.format("%02dm:%02ds", min, sec)
     
    local km = round(d / 1000, 2)
    
    brakeInfo.time = tms
    brakeInfo.dist = km
    
    return brakeInfo
end

function STEC(core, control, Cd)
    local self = {}
    self.core = core
    self.control = control
    self.nearestPlanet = helios:closestBody(core.getConstructWorldPos())
    self.world = {
        up = vec3(core.getConstructWorldOrientationUp()),
        down = -vec3(core.getConstructWorldOrientationUp()),
        left = -vec3(core.getConstructWorldOrientationRight()),
        right = vec3(core.getConstructWorldOrientationRight()),
        forward = vec3(core.getConstructWorldOrientationForward()),
        back = -vec3(core.getConstructWorldOrientationForward()),
        velocity = vec3(core.getWorldVelocity()),
        acceleration = vec3(core.getWorldAcceleration()),
        position = vec3(core.getConstructWorldPos()),
        gravity = vec3(core.getWorldGravity()),
        vertical = vec3(core.getWorldVertical()),
        atmosphericDensity = control.getAtmosphereDensity(),
        nearPlanet = unit.getClosestPlanetInfluence() > 0,
        atlasAltitude = self.nearestPlanet:getAltitude(core.getConstructWorldPos()),
        --nearestPlanetGravity = vec3(self.nearestPlanet.getGravity(core.getConstructWorldPos()))

    }
    self.target = {
        prograde = function() return self.world.velocity:normalize() end,
        retrograde = function() return -self.world.velocity:normalize() end,
        radial = function() return self.nearestPlanet:getGravity(core.getConstructWorldPos()):normalize() end,
        antiradial = function() return -self.nearestPlanet:getGravity(core.getConstructWorldPos()):normalize() end,
        normal = function() return self.world.velocity:cross(self.world.right):normalize() end,
        antinormal = function() return self.world.velocity:cross(self.world.left):normalize() end,
    }
    self.planets = {
        sancuary = function() return helios[26]:getGravity(core.getConstructWorldPos()):normalize() end,
        madis = function() return helios[1]:getGravity(core.getConstructWorldPos()):normalize() end,
        thades = function() return helios[3]:getGravity(core.getConstructWorldPos()):normalize() end,
        alioth = function() return helios[2]:getGravity(core.getConstructWorldPos()):normalize() end,
        feli = function() return helios[5]:getGravity(core.getConstructWorldPos()):normalize() end,
        ion = function() return helios[120]:getGravity(core.getConstructWorldPos()):normalize() end,
        jago = function() return helios[9]:getGravity(core.getConstructWorldPos()):normalize() end,
        lacobus = function() return helios[100]:getGravity(core.getConstructWorldPos()):normalize() end,
        sicari = function() return helios[6]:getGravity(core.getConstructWorldPos()):normalize() end,
        sinnen = function() return helios[7]:getGravity(core.getConstructWorldPos()):normalize() end,
        symeon = function() return helios[110]:getGravity(core.getConstructWorldPos()):normalize() end,
        talemai = function() return helios[4]:getGravity(core.getConstructWorldPos()):normalize() end,
        teoma = function() return helios[8]:getGravity(core.getConstructWorldPos()):normalize() end,
    }
    -- Construct id
    self.id = core.getConstructId()
    -- Control Mode - Travel (0) or Cruise (1)
    self.controlMode = unit.getControlMasterModeId()
    -- Alternate Control Mode for remote control
    self.alternateCM = false
    -- Placeholder for throttle value when switching control modes
    self.tempThrottle = 0
    -- Placeholder for cruise value when switching control modes
    self.tempCruise = 0  
    -- Active engine tags
    self.tags = TagManager("all")
    -- Target vector to face if non-0. Can take in a vec3 or function which returns a vec3
    self.targetVector = nil
    -- Whether the target vector should unlock automatically if the ship is rotated by the pilot
    self.targetVectorAutoUnlock = true
    -- Roid AP
    self.targetGoTo = nil
    -- Current altitude
    self.altitude = 0
    -- Current mass of the vessel, in kilograms
    self.mass = self.core.getConstructMass()
    -- Amount of thrust to apply in world space, in Newton. Stacks with {{direction}}
    self.thrust = vec3(0, 0, 0)
    -- Amount of thrust to apply in local space, in percentage of fMax 0-1
    self.direction = vec3(0, 0, 0)
    -- Amount of rotation to apply in local space
    self.rotation = vec3(0, 0, 0)
    -- Speed scale factor for rotations
    self.rotationSpeed = 2
    -- Starting speed for auto-scaling rotation
    self.rotationSpeedMin = 0.01
    -- Maximum speed for auto-scaling rotation
    self.rotationSpeedMax = 5
    -- Step for increasing the rotation speed
    self.rotationStep = 0.03
    -- Breaking speed multiplier
    self.brakingFactor = 10
    -- Amount of angular thrust to apply, in world space
    self.angularThrust = vec3(0, 0, 0)
    -- Whether or not the vessel should attempt to cancel out its current velocity in directions that are not being accelerated towards
    self.inertialDampening = false
    self.IDIntensity = 5
    -- Whether or not the vessel should attempt to completely cancel out its current velocity
    self.brake = false
    -- Whether or not the vessel should attempt to counter gravity influence
    self.counterGravity = true
    -- Whether or not the vessel should attempt to face perpendicular to the gravity vector
    self.followGravity = false
    -- Aggressiveness of the gravity follow adjustment
    self.gravityFollowSpeed = 4
    -- Amount of throttle to apply. 0-1 range
    self.throttle = 1
    -- Maximum thrust which the vessel is capable of producing
    --self.fMax = 0
    -- Altitude which the vessel should attempt to hold
    self.altitudeHold = 0
    -- Speed which the vessel should attempt to maintain
    self.cruiseSpeed = 0
    -- Whether or not to ignore throttle for vertical thrust calculations
    self.ignoreVerticalThrottle = false
    -- Whether or not to ignore throttle for horizontal thrust calculations
    self.ignoreHorizontalThrottle = true
    -- Local velocity
    self.localVelocity = vec3(core.getVelocity())
    -- Roll Degrees
    self.rollDegrees = self.world.vertical:angle_between(self.world.left) / math.pi * 180 - 90
    if self.world.vertical:dot(self.world.up) > 0 then self.rollDegrees = 180 - self.rollDegrees end
    -- Pitch
    self.pitchRatio = self.world.vertical:angle_between(self.world.forward) / math.pi - 0.5
    self.vtolPriority = false
    self.disableVtol = false
    self.disabledTags = ""
    local lastUpdate = system.getTime()
    self.thrustVec = vec3(0,0,0)
    
    self.priorityTags1 = "brake,airfoil,torque,ground"
    self.priorityTags2 = "atmospheric_engine,space_engine"
    self.priorityTags3 = "vertical"
    self.brakeDistance = 0
    self.accelTime = 0
    self.targetDist = 0
    self.inertialMass = 0
    self.maxBrake = jdecode(unit.getData()).maxBrake
    self.debug = nil
    
    function self.updateWorld()
        self.world = {
            up = vec3(core.getConstructWorldOrientationUp()),
            down = -vec3(core.getConstructWorldOrientationUp()),
            left = -vec3(core.getConstructWorldOrientationRight()),
            right = vec3(core.getConstructWorldOrientationRight()),
            forward = vec3(core.getConstructWorldOrientationForward()),
            back = -vec3(core.getConstructWorldOrientationForward()),
            velocity = vec3(core.getWorldVelocity()),
            acceleration = vec3(core.getWorldAcceleration()),
            position = vec3(core.getConstructWorldPos()),
            gravity = vec3(core.getWorldGravity()),
            vertical = vec3(core.getWorldVertical()),
            atmosphericDensity = control.getAtmosphereDensity(),
            nearPlanet = unit.getClosestPlanetInfluence() > 0,
            atlasAltitude = self.nearestPlanet:getAltitude(core.getConstructWorldPos()),
            --nearestPlanetGravity = vec3(self.nearestPlanet.getGravity(core.getConstructWorldPos()))
            
    
        }
        self.nearestPlanet = helios:closestBody(core.getConstructWorldPos())
	   -- Roll Degrees
        self.rollDegrees = self.world.vertical:angle_between(self.world.left) / math.pi * 180 - 90
        if self.world.vertical:dot(self.world.up) > 0 then self.rollDegrees = 180 - self.rollDegrees end
        -- Pitch
        self.pitchRatio = self.world.vertical:angle_between(self.world.forward) / math.pi - 0.5
        
        self.AngularVelocity = vec3(core.getWorldAngularVelocity())
        self.AngularAcceleration = vec3(core.getWorldAngularAcceleration())
        self.AngularAirFriction = vec3(core.getWorldAirFrictionAngularAcceleration())
        
	   self.airFriction = vec3(core.getWorldAirFrictionAcceleration())
        
        self.mass = self.core.getConstructMass()
        self.altitude = self.nearestPlanet:getAltitude(core.getConstructWorldPos())
        self.localVelocity = vec3(core.getVelocity())

        if self.vtolPriority then
            self.priorityTags1 = "brake,airfoil,torque,vertical,lateral,longitudinal,vertical"
            self.priorityTags2 = "atmospheric_engine,space_engine"
            self.priorityTags3 = ""
        else
            self.priorityTags1 = "brake,airfoil,torque,vertical,lateral,longitudinal,"
            self.priorityTags2 = "atmospheric_engine,space_engine"
            self.priorityTags3 = "vertical"
        end


        local tkForward = core.getMaxKinematicsParametersAlongAxis("all", {vec3(0, 1, 0):unpack()})
        local tkUp = core.getMaxKinematicsParametersAlongAxis("all", {vec3(0, 0, 1):unpack()})
        local tkRight = core.getMaxKinematicsParametersAlongAxis("all", {vec3(1, 0, 0):unpack()})
        
        local tkOffset = 0
        if self.world.atmosphericDensity < 0.1 then
            tkOffset = 2
        end
        
        local virtualGravityEngine =
            vec3(
            library.systemResolution3(
                {self.world.right:unpack()},
                {self.world.forward:unpack()},
                {self.world.up:unpack()},
               {(self.world.gravity * self.mass):unpack()}
            )
        )

        self.MaxKinematics = {
            Forward = math.abs(tkForward[1 + tkOffset] + virtualGravityEngine.y),
            Backward = math.abs(tkForward[2 + tkOffset] - virtualGravityEngine.y),
            Up = math.abs(tkUp[1 + tkOffset] + virtualGravityEngine.z),
            Down = math.abs(tkUp[2 + tkOffset] - virtualGravityEngine.z),
            Right = math.abs(tkRight[1 + tkOffset] + virtualGravityEngine.x),
            Left = math.abs(tkRight[2 + tkOffset] - virtualGravityEngine.x)
        }
        self.maxBrake = jdecode(unit.getData()).maxBrake
        local c = 30000000 / 3600
        local v = self.world.velocity:len()
        local y = 1/math.sqrt(1-((v*v)/(c*c)))
        self.inertialMass = self.mass * y

        

    end
    function self.calculateAccelerationForce(acceleration, time)
        return self.mass * (acceleration / time)
    end

    function clamp(n, min, max)
        return math.min(max, math.max(n, min))
    end
    function round(num, numDecimalPlaces)
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end

    function math.sign(v)
        return (v >= 0 and 1) or -1
    end
    function math.round(v, bracket)
        bracket = bracket or 1
        return math.floor(v/bracket + math.sign(v) * 0.5) * bracket
    end


    function self.throttleUp()
        self.throttle = clamp(self.throttle + 0.05, 0, 1)
    end

    function self.throttleDown()
        self.throttle = clamp(self.throttle - 0.05, 0, 1)
    end

    function self.scaleRotation()
        if self.rotationSpeed <= self.rotationSpeedMax then self.rotationSpeed = self.rotationSpeed + self.rotationStep end
    end

    function self.worldToLocal(vector)
        return vec3(
            library.systemResolution3(
                {self.world.right:unpack()},
                {self.world.forward:unpack()},
                {self.world.up:unpack()},
                {vector:unpack()}
            )
        )
    end

    function self.localToRelative(pos, up, right, forward)
        -- this is horrible, can optimize?
        local rightX, rightY, rightZ = right:unpack()
        local forwardX, forwardY, forwardZ = forward:unpack()
        local upX, upY, upZ = up:unpack()
        local rfuX, rfuY, rfuZ = pos:unpack()
        local relX = rfuX * rightX + rfuY * forwardX + rfuZ * upX
        local relY = rfuX * rightY + rfuY * forwardY + rfuZ * upY
        local relZ = rfuX * rightZ + rfuY * forwardZ + rfuZ * upZ
        return vec3(relX, relY, relZ)
    end


    function moveWaypointZ(vector, altitude)
        return (vector - (self.nearestPlanet:getGravity(vector)):normalize() * (altitude))
    end
    function moveWaypointY(altitude, distance)
        local z = moveWaypointZ(self.world.position, altitude - self.altitude)
        return z - (self.world.right:cross(self.nearestPlanet:getGravity(self.world.position)):normalize()) * -distance
    end

    function self.apply()
        local deltaTime = math.max(system.getTime() - lastUpdate, 0.001) --If delta is below 0.001 then something went wrong in game engine.
        self.updateWorld()
        local tmp = self.thrust
        local atmp = self.angularThrust
        --Thrust
        --Lateral
        if self.direction.x > 0 then
            tmp = tmp  + (self.world.right * self.MaxKinematics.Right)
        end
        if self.direction.x < 0 then
            tmp = tmp  + (-self.world.right * self.MaxKinematics.Right)
        end
        --Forward
        if self.direction.y ~= 0 then
            tmp = tmp  + (self.world.forward * self.MaxKinematics.Forward) * self.throttle
        end
        --Vertical
        if self.direction.z > 0 then
            tmp = tmp + self.world.up * self.MaxKinematics.Up
            if not self.ignoreVerticalThrottle then tmp = tmp * self.throttle end
        end
        if self.direction.z < 0 then
            tmp = tmp + -self.world.up * self.MaxKinematics.Down
            if not self.ignoreVerticalThrottle then tmp = tmp * self.throttle end
        end
        --Rotation
        if self.rotation.x ~= 0 then
            self.scaleRotation()
            atmp = atmp + ((self.world.forward:cross(self.world.up) * self.rotation.x) * self.rotationSpeed)
            if self.targetVectorAutoUnlock then
                self.targetVector = nil
                self.followGravity = false
                self.altitudeHold = 0
            end
        end
        if self.rotation.y ~= 0 then
            self.scaleRotation()
            atmp = atmp + ((self.world.up:cross(self.world.right) * self.rotation.y) * self.rotationSpeed)
        end
        if self.rotation.z ~= 0 then
            self.scaleRotation()
            atmp = atmp + ((self.world.forward:cross(self.world.right) * self.rotation.z) * self.rotationSpeed)
            --if self.targetVectorAutoUnlock then
            --    self.targetVector = nil
            --    self.altitudeHold = 0
            --end
        end
        if self.followGravity and self.rotation.x == 0 then
		    local current = self.localVelocity:len() * self.mass
            local scale = nil
            if ship.localVelocity:len() > 1000 then
                scale = self.gravityFollowSpeed * math.min(math.max(current / self.MaxKinematics.Up, 0.1), 1) * 10
            else
                scale = self.gravityFollowSpeed
            end
            --atmp = atmp + (self.world.up:cross(-self.world.vertical) * scale)
            
            atmp = atmp + ((self.world.up:cross(-self.nearestPlanet:getGravity(core.getConstructWorldPos()))) - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2)))
        end

		if self.altitudeHold ~= 0 then
            --local deltaAltitude =  self.altitudeHold - self.altitude
            local waypoint = moveWaypointY(self.altitudeHold, (self.world.velocity:len() * 3) + 50)
            self.targetVector = (waypoint - self.world.position ):normalize()
            atmp = atmp - (self.world.right:cross(self.world.forward:cross(self.world.gravity:normalize())) * self.rotationSpeed * 9) - ((self.AngularVelocity * 3) - (self.AngularAirFriction * 3))
            --tmp = tmp - ((self.nearestPlanet:getGravity(core.getConstructWorldPos()) * self.mass) * deltaAltitude)
        end
        if self.targetVector == nil then self.gotoLock = nil end
        --self.brakeDistance, self.accelTime = kinematics.computeDistanceAndTime(self.world.velocity:len(), 0, self.mass, self.MaxKinematics.Backward,1,self.maxBrake)
        
        if self.gotoLock ~= nil then
            if not self.inertialDampening then self.inertialDampening = true end
            self.direction.y = 0
            local speed = 29999

            local dest = (self.world.position - self.gotoLock):normalize()
            ship.targetVector = -dest
            self.targetDist = (self.world.position - self.gotoLock):len()
      
            local force = tmp:dot(self.world.position - self.gotoLock)

            self.brakeDistance, self.accelTime = kinematics.computeDistanceAndTime((self.world.velocity + self.world.gravity):len(), 0, self.inertialMass, force, 0, self.maxBrake)

            if self.brakeDistance >= (self.targetDist - 2000) or self.targetDist <= 2000 then
                --self.gotoLock = nil
                speed = 2000
            end

            if self.targetDist < 1 then
                self.gotoLock = nil
                self.targetVector = nil
            end

            local fSpeed = utils.clamp(self.targetDist / 3.6,0.3,((math.abs(speed)/3.6))) * self.IDIntensity
            tmp = tmp - (dest * self.mass * fSpeed)
        end
        
        if self.alternateCM then
          local speed = (self.cruiseSpeed / 3.6)
          local dot = self.world.forward:dot(self.airFriction)
          local modifiedVelocity = (speed - dot)
          local desired = self.world.forward * modifiedVelocity
          local delta = (desired - (self.world.velocity - self.world.acceleration))
            
          tmp = tmp + (delta * self.mass)
        end
        if self.inertialDampening then
            local currentShipMomentum = self.localVelocity
            local delta = vec3(0,0,0)
            local moveDirection = self.direction or vec3(0,0,0)

            if moveDirection.x == 0 then delta.x = currentShipMomentum.x end
            if moveDirection.y == 0 then delta.y = currentShipMomentum.y end
            if moveDirection.z == 0 then delta.z = currentShipMomentum.z end

            delta = self.localToRelative(delta, self.world.up, self.world.right, self.world.forward)
            tmp = tmp - (delta * (self.mass * self.IDIntensity))

        end

        if self.brake then
            local velocityLen = self.world.velocity:len()
            tmp =
                -self.world.velocity * self.mass *
                math.max(self.brakingFactor * math.max(1, velocityLen * 0.5), velocityLen * velocityLen)
        end
        if self.targetVector ~= nil then
            local vec = vec3(self.world.forward.x, self.world.forward.y, self.world.forward.z)
            if type(self.targetVector) == "function" then
                vec = self.targetVector()
            elseif type(self.targetVector) == "table" then
                vec = self.targetVector
            end
            atmp = atmp + (self.world.forward:cross(vec) * self.rotationSpeedMax) - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
        end
        -- must be applied last
        if self.counterGravity then
            if self.direction.z >= 0 then
                tmp = tmp - self.nearestPlanet:getGravity(core.getConstructWorldPos()) * self.mass
            end
        end

        atmp = atmp - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
        tmp = tmp / self.mass

        if self.controlMode ~= unit.getControlMasterModeId() then
            self.controlMode = unit.getControlMasterModeId()
            if unit.getControlMasterModeId() == 0 then 
                self.tempCruise = self.cruiseSpeed
                self.cruiseSpeed = 0
                self.throttle = self.tempThrottle
                self.alternateCM = false 
            end
            if unit.getControlMasterModeId() == 1 then 
                self.tempThrottle = self.throttle
                self.throttle = 0
                --system.print("Velocity = "..tostring(math.round(self.world.velocity:len(), 100)))
                self.cruiseSpeed = math.round(self.world.velocity:len() * 3.6, 100)
                self.alternateCM = true
            end
        end
        
        if self.disableVtol then
            self.disabledTags = "vtol"
        else
            self.disabledTags = ""
        end
        
        self.control.setEngineCommand("atmospheric_engine,space_engine,airfoil,brake,torque,vertical,ground",
                                        {tmp:unpack()}, {atmp:unpack()}, false, false,
                                        self.priorityTags1,
                                        self.priorityTags2,
                                        self.priorityTags3)
        self.control.setEngineCommand(self.disabledTags)
        self.thrustVec = self.worldToLocal(tmp)
        atmp = vec3(0, 0, 0)
        tmp = vec3(0, 0, 0)
        lastUpdate = system.getTime()
    end

    return self
end

ship = STEC(core, unit)