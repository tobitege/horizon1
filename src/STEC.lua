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
local atlas = require('atlas')
planetaryReference = PlanetRef()
galaxyReference = planetaryReference(atlas)
helios = galaxyReference[0]
kinematics = Kinematics()
local jdecode = json.decode
local maxBrake = jdecode(unit.getWidgetData()).maxBrake

function STEC(core, control, Cd)
    local self = {}
    self.core = core
    self.construct = construct
    self.control = control
    self.nearestPlanet = helios:closestBody(construct.getWorldPosition())
    self.world = {
        up = vec3(construct.getWorldOrientationUp()),
        down = -vec3(construct.getWorldOrientationUp()),
        left = -vec3(construct.getWorldOrientationRight()),
        right = vec3(construct.getWorldOrientationRight()),
        forward = vec3(construct.getWorldOrientationForward()),
        back = -vec3(construct.getWorldOrientationForward()),
        velocity = vec3(construct.getWorldVelocity()),
        acceleration = vec3(construct.getWorldAcceleration()),
        position = vec3(construct.getWorldPosition()),
        gravity = vec3(core.getWorldGravity()),
        vertical = vec3(core.getWorldVertical()),
        atmosphericDensity = control.getAtmosphereDensity(),
        nearPlanet = unit.getClosestPlanetInfluence() > 0,
        atlasAltitude = self.nearestPlanet:getAltitude(construct.getWorldPosition())
    }
    self.target = {
        prograde = function() return self.world.velocity:normalize() end,
        retrograde = function() return -self.world.velocity:normalize() end,
        radial = function() return self.world.gravity:normalize() end,
        antiradial = function() return -self.world.gravity:normalize() end,
        normal = function() return self.world.velocity:normalize():cross(self.world.gravity:normalize()):normalize() end,
        antinormal = function() return self.world.velocity:normalize():cross(-self.world.gravity:normalize()):normalize() end,
    }

    self.rot = vec3(0,0,0)
    self.deviationRot = vec3(0,0,0)
    -- Construct id
    self.id = construct.getId()
    -- Control Mode - Travel (0) or Cruise (1)
    self.controlMode = unit.getControlMode()
    -- Alternate Control Mode for remote control
    self.alternateCM = false
    -- Active engine tags
    self.tags = TagManager("all,brake")
    -- Target vector to face if non-0. Can take in a vec3 or function which returns a vec3
    self.targetDestination = nil
    self.targetdestination = nil
    self.customTarget = vec3(0,0,0)
    self.baseAltitude = 0
    self.verticalLock = false
    self.lockVector = vec3(0,0,0)
    self.lockPos = vec3(0,0,0)
    self.altHoldPreset1 = 0
    self.altHoldPreset2 = 0
    self.altHoldPreset3 = 0
    self.altHoldPreset4 = 0
    self.deviation = 0
    self.deviationVec = vec3(0,0,0)
    self.stateMessage = ""
    self.pocket = false
    self.autoShutdown = false
    self.dockingClamps = false
    self.elevatorDestination = vec3(0,0,0)
    self.IDIntensity = 5
    self.deviationThreshold = 0.05
    self.playerId = player.getId()
    self.targetVectorVertical = nil
    self.breadCrumbDist = 1000
    self.deviated = false
    self.breadCrumbs = {}
    self.hoverHeight = 10
    -- Whether the target vector should unlock automatically if the ship is rotated by the pilot
    self.targetVectorAutoUnlock = true
    -- Current altitude
    self.altitude = 0
    -- Current mass of the vessel, in kilograms
    self.mass = self.construct.getMass()
    -- Amount of thrust to apply in world space, in Newton. Stacks with {{direction}}
    self.thrust = vec3(0, 0, 0)
    -- Amount of thrust to apply in local space, in percentage of fMax 0-1
    self.direction = vec3(0, 0, 0)
    -- Amount of rotation to apply in local space
    self.rotation = vec3(0, 0, 0)
    -- Speed scale factor for rotations
    self.rotationSpeed = 2
    -- Minimum rotation speed for auto-scale
    self.rotationSpeedzMin = 0.01
    -- Rotation Speed on x axis
    self.rotationSpeedz = 0.01
    -- Max rotation speed for auto-scale
    self.maxRotationSpeedz = 3
    -- Auto-scale rotation Setup
    self.rotationStep = 0.03
    -- Breaking speed multiplier
    self.brakingFactor = 10
    -- Amount of angular thrust to apply, in world space
    self.angularThrust = vec3(0, 0, 0)
    -- Whether or not the vessel should attempt to cancel out its current velocity in directions that are not being accelerated towards
    self.inertialDampening = false
    -- Desired state of intertialDampening
    self.inertialDampeningDesired = false
    -- Whether or not the vessel should attempt to completely cancel out its current velocity
    self.brake = false
    -- Whether or not the vessel should attempt to counter gravity influence
    self.counterGravity = true
    -- Whether or not the vessel should attempt to face perpendicular to the gravity vector
    self.followGravity = false
    -- Aggressiveness of the gravity follow adjustment
    self.gravityFollowSpeed = 6
    -- Speed (in km/h) in which to limit the velocity of the ship
    self.speedLimiter = 2000
    -- Variable speed limit based on delta distance in altitude hold mode
    self.variableSpeedLimit = 2000
    -- Toggle speed limiter on/off
    self.speedLimiterToggle = true
    -- Vertical Speed Limit (Atmo)
    self.verticalSpeedLimitAtmo = 750
    -- Vertical Speed Limit (Space)
    self.verticalSpeedLimitSpace = 2000
    -- Final approach speed
    self.approachSpeed = 200
    -- Amount of throttle to apply. 0-1 range
    self.throttle = 1
    -- Maximum thrust which the vessel is capable of producing
    self.fMax = 0
    self.vMax = 0
    self.hMax = 0
    -- Toggle altitude hold on/off
    self.elevatorActive = false
    -- Altitude which the vessel should attempt to hold
    self.altitudeHold = 0
    -- Atmosphere density Threshold
    self.atmosphereThreshold = 0
    -- Speed which the vessel should attempt to maintain
    self.cruiseSpeed = 0
    -- Whether or not to ignore throttle for vertical thrust calculations
    self.ignoreVerticalThrottle = false
    -- Local velocity
    self.localVelocity = vec3(construct.getVelocity())
    self.brakeDistance = 0
    self.accelTime = nil
    -- Roll Degrees
    self.rollDegrees = self.world.vertical:angle_between(self.world.left) / math.pi * 180 - 90
    self.viewY = 0
    self.viewX = 0
    if self.world.vertical:dot(self.world.up) > 0 then self.rollDegrees = 180 - self.rollDegrees end
    -- Pitch
    self.pitchRatio = self.world.vertical:angle_between(self.world.forward) / math.pi - 0.5
    --Vertical Cruise Toggle (for elevator stuff)
    self.verticalCruise = false
    --Vertical Cruise Speed (for elevator stuff)
    self.verticalCruiseSpeed = 0
    self.priorityTags1 = "brake,airfoil,torque,vertical,lateral,longitudinal"
    self.priorityTags2 = "atmospheric_engine,space_engine"
    self.priorityTags3 = ""

    local lastUpdate = system.getArkTime()

    function self.updateWorld()
        self.world = {
            up = vec3(construct.getWorldOrientationUp()),
            down = -vec3(construct.getWorldOrientationUp()),
            left = -vec3(construct.getWorldOrientationRight()),
            right = vec3(construct.getWorldOrientationRight()),
            forward = vec3(construct.getWorldOrientationForward()),
            back = -vec3(construct.getWorldOrientationForward()),
            velocity = vec3(construct.getWorldVelocity()),
            acceleration = vec3(construct.getWorldAcceleration()),
            position = vec3(construct.getWorldPosition()),
            gravity = vec3(core.getWorldGravity()),
            vertical = vec3(core.getWorldVertical()),
            atmosphericDensity = control.getAtmosphereDensity(),
            nearPlanet = unit.getClosestPlanetInfluence() > 0,
            atlasAltitude = self.nearestPlanet:getAltitude(construct.getWorldPosition())
        }
        self.nearestPlanet = helios:closestBody(construct.getWorldPosition())
	   -- Roll Degrees
        self.rollDegrees = self.world.vertical:angle_between(self.world.left) / math.pi * 180 - 90
        if self.world.vertical:dot(self.world.up) > 0 then self.rollDegrees = 180 - self.rollDegrees end
        -- Pitch
        self.pitchRatio = self.world.vertical:angle_between(self.world.forward) / math.pi - 0.5

        self.AngularVelocity = vec3(construct.getWorldAngularVelocity())
        self.AngularAcceleration = vec3(construct.getWorldAngularAcceleration())
        self.AngularAirFriction = vec3(construct.getMaxThrustAlongAxis())

	    self.airFriction = vec3(construct.getWorldAirFrictionAcceleration())

        local atmoRadius = helios:closestBody(construct.getWorldPosition()).atmosphereRadius
        local planetRadius = helios:closestBody(construct.getWorldPosition()).radius

        self.atmosphereThreshold = atmoRadius - planetRadius
        --system.print("Planet Radius: "..helios:closestBody(construct.getWorldPosition()).radius)
        --system.print("atmosphereThreshold = " .. self.atmosphereThreshold)
	    self.airFriction = vec3(construct.getWorldAirFrictionAcceleration())

        self.mass = self.construct.getMass()
        --self.altitude = self.core.getAltitude()
        self.altitude = helios:closestBody(construct.getWorldPosition()):getAltitude(construct.getWorldPosition())
        self.localVelocity = vec3(construct.getVelocity())
        self.maxBrake = jdecode(unit.getWidgetData()).maxBrake
        local fMax = construct.getMaxThrustAlongAxis("all", {vec3(0,1,0):unpack()})
        local vMax = construct.getMaxThrustAlongAxis("all", {vec3(0,0,1):unpack()})
        --system.print("vMax[1]: "..round2(vMax[1],0))
        --system.print("vMax[2]: "..round2(vMax[2],0))
        --system.print("vMax[3]: "..round2(vMax[3],0))
        --system.print("vMax[4]: "..round2(vMax[4],0))
        if self.world.atmosphericDensity > 0.1 then
            self.fMax = math.max(fMax[1], -fMax[2])
        else
            self.fMax = math.max(fMax[3], -fMax[4])
        end
        if self.world.atmosphericDensity > 0.1 then
            self.vMax = math.max(vMax[1], -vMax[2])
        else
            self.vMax = math.min(vMax[3], -vMax[4])
        end
        local hMax = construct.getMaxThrustAlongAxis("all", {vec3(1,0,0):unpack()})
        if self.world.atmosphericDensity > 0.1 then
            self.hMax = math.max(hMax[1], -hMax[2])
        else
            self.hMax = math.max(hMax[3], -hMax[4])
        end
        --system.print(self.world.velocity:dot(-self.world.gravity:normalize()))
        local gravN = self.mass * core.getGravityIntensity()
        local correctedThrust = self.vMax
        local correctedBrake = self.maxBrake
        local sign = 1

        if self.maxBrake ~= nil and core.getGravityIntensity() >= 1 then
            if self.world.velocity:dot(-self.world.gravity:normalize()) < 1 then
                sign = -1
            end
            gravN = gravN * sign
            correctedThrust = self.vMax + gravN
            correctedBrake = self.maxBrake + gravN
        end
        self.brakeDistance, self.accelTime = kinematics.computeDistanceAndTime(self.world.velocity:len(), 0, self.mass, correctedThrust,20,correctedBrake)
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
    function self.throttleUp()
        self.throttle = clamp(self.throttle + 0.05, 0, 1)
    end

    function self.throttleDown()
        self.throttle = clamp(self.throttle - 0.05, 0, 1)
    end

    function moveWaypointZ(vector, altitude)
        return (vector - (ship.nearestPlanet:getGravity(vector)):normalize() * (altitude))
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

    function MsToKmh(ms)
        return ms * 3.6
    end
    function KmhToMs(kmh)
        return kmh / 3.6
    end

    function self.apply()
        local deltaTime = math.max(system.getArkTime() - lastUpdate, 0.001) --If delta is below 0.001 then something went wrong in game engine.
        self.updateWorld()
        local tmp = self.thrust
        local atmp = self.angularThrust
        -- local gravityCorrection = false
        local fMax = construct.getMaxThrustAlongAxis("all", {vec3(0,1,0):unpack()})
        -- local vMaxUp = construct.getMaxThrustAlongAxis("all", {vec3(0,0,1):unpack()})
        -- local vMaxDown = construct.getMaxThrustAlongAxis("all", {vec3(0,0,-1):unpack()})
        -- local hMax = construct.getMaxThrustAlongAxis("all", {vec3(1,0,0):unpack()})
        if not self.elevatorActive then self.inertialDampening = self.inertialDampeningDesired end

        if self.direction.x ~= 0 then
            local dot = (1 - self.world.up:dot(-self.world.gravity:normalize())) * (self.mass * 0.000095) -- Magic number is magic
            local gravCorrection = -self.world.vertical * dot

            if self.direction.x < 0 and math.abs(round2(self.hMax,0)) < 500 then
                -- gravityCorrection = true
                tmp = tmp + ((((self.world.right * self.direction.x) + gravCorrection):normalize() * self.fMax) * self.throttle)
            elseif self.direction.x > 0 and math.abs(round2(self.hMax,0)) < 500 then
                -- gravityCorrection = true
                tmp = tmp + ((((self.world.right * self.direction.x) + gravCorrection):normalize() * self.fMax) * self.throttle)
            else
                tmp = tmp + (((self.world.right * self.direction.x) * self.fMax) * self.throttle) -- OG code
            end
        end

        if self.direction.y ~= 0 then

            --tmp = tmp + (((self.world.forward * self.direction.y) * self.fMax) * self.throttle)
            --tmp = tmp + (((self.world.gravity:normalize():cross(-self.world.right) * self.direction.y) * self.fMax) * self.throttle)
            local dot  = (1 - self.world.up:dot(-self.world.gravity:normalize())) * (self.mass * 0.000095)
            local gravCorrection = -self.world.vertical * dot
            --system.print(math.abs(round2(fMax[2],0)))
            if self.direction.y < 0 and math.abs(round2(fMax[2],0)) == 0 then
                -- gravityCorrection = true
                tmp = tmp + ((((self.world.forward * self.direction.y) + gravCorrection):normalize() * self.fMax) * self.throttle)
            else
                tmp = tmp + (((self.world.forward * self.direction.y) * self.fMax) * self.throttle)
            end

        end
        if self.direction.z ~= 0 then
            local a = ((self.world.up * self.direction.z) * self.fMax)
            if not self.ignoreVerticalThrottle then a = a * self.throttle end
            tmp = tmp + a
        end
        if self.rotation.x ~= 0 then
            atmp = atmp + ((self.world.forward:cross(self.world.up) * self.rotation.x) * self.rotationSpeed)
            if self.targetVectorAutoUnlock then
                self.targetVector = nil
            end
        end
        if self.rotation.y ~= 0 then
            atmp = atmp + ((self.world.up:cross(self.world.right) * self.rotation.y) * self.rotationSpeed)
        end
        if self.rotation.z ~= 0 then
            if self.rotationSpeedz <= self.maxRotationSpeedz then self.rotationSpeedz = self.rotationSpeedz + self.rotationStep end
            --system.print("Rotation Speed: "..self.rotationSpeedz)
            atmp = atmp + ((self.world.forward:cross(self.world.right) * self.rotation.z) * clamp(self.rotationSpeedz, 0.01, self.maxRotationSpeedz))
            if self.targetVectorAutoUnlock then
                self.targetVector = nil
            end
        end
        if self.followGravity and self.rotation.x == 0 then

          --system.print(tostring(self.direction))
		    local current = self.localVelocity:len() * self.mass
            local scale = nil
            --if ship.localVelocity:len() > 10 then
            --    scale = self.gravityFollowSpeed * math.min(math.max(current / self.fMax, 0.1), 1) * 10
            --else
            --    scale = self.gravityFollowSpeed
            --end
            local gFollow = (self.world.up:cross(-self.nearestPlanet:getGravity(construct.getWorldPosition())))
            local scale = 1
            if self.pocket then
                if self.direction.x < 0  then
                    scale = 0.25
                    gFollow = gFollow + ship.world.right:cross(-self.nearestPlanet:getGravity(construct.getWorldPosition()) * 0.25)
                elseif self.direction.x > 0  then
                    scale = 0.25
                    gFollow = gFollow - ship.world.right:cross(-self.nearestPlanet:getGravity(construct.getWorldPosition()) * 0.25)
                elseif self.direction.y < 0  then
                    gFollow = gFollow + ship.world.forward:cross(-self.nearestPlanet:getGravity(construct.getWorldPosition()) * 0.25)
                end
            end
            gFollow = gFollow * scale
            atmp = atmp + gFollow
        end

        self.deviationVec = (moveWaypointZ(self.customTarget, self.altitude - self.baseAltitude) - self.world.position)
        self.deviationRot = self.world.forward:cross(self.rot)
        self.deviation = self.deviationVec:len()

        if self.elevatorActive then
            if not self.inertialDampening then self.inertialDampening = true end
            if not self.counterGravity then self.counterGravity = true end
            self.targetVector = self.rot
            if self.world.velocity:len() > (2000 / 3.6) then deviation = 0 end

            local deltaAltitude =  self.altitudeHold - self.altitude
            local brakeBuffer = 1000

            local speed = 0
            --local self.breadCrumbDist = 500
            local distance = (self.world.position - self.targetDestination):len()

            local realDistance = helios:closestBody(self.targetDestination):getAltitude(self.targetDestination) - self.altitude
            local destination = vec3(0,0,0)
            local verticalSpeedLimit


            local dampen = 1

            --if self.world.velocity:len() < 55.555 then

            --end

            if self.altitude <= (self.atmosphereThreshold + self.brakeDistance) or self.altitude <= self.brakeDistance then
                verticalSpeedLimit = self.verticalSpeedLimitAtmo
            else
                verticalSpeedLimit = self.verticalSpeedLimitSpace
            end
            if  (self.brakeDistance + brakeBuffer) >= math.abs(deltaAltitude) then
                verticalSpeedLimit = self.approachSpeed
            end

            --system.print("self.deviation: "..self.deviation)


            local deviationThreshold = self.deviationThreshold
            if self.deviated or self.world.velocity:len() < 1 then deviationThreshold = 0.05 end
            --system.print("Deviation threshold: "..deviationThreshold)
            if self.deviation > (deviationThreshold + self.world.velocity:len() * 10^-2) then
            --if self.deviation > deviationThreshold then
                destination = moveWaypointZ(self.customTarget, (self.altitude - self.baseAltitude))
                self.deviated = true
                speed = self.deviation * self.IDIntensity
                self.stateMessage = "Correcting Deviation"
            else
                self.deviated = false
                destination = self.targetDestination
            end

            if math.abs(deltaAltitude) > self.brakeDistance and math.abs(deltaAltitude) > 500 and not self.deviated then
                self.stateMessage = "Traveling"
                speed = round2((clamp(deltaAltitude, -verticalSpeedLimit, verticalSpeedLimit)), 1)
            elseif not self.deviated then
                self.stateMessage = "Final approach"
                speed = self.approachSpeed
                if self.brakeDistance * 1.5 >= math.abs(distance) then speed = 5 end
            end
            --system.print("realDistance: "..realDistance)
            local breadCrumb
            --local breadCrumbDist = utils.clamp(math.abs(self.world.velocity:len()),10,self.breadCrumbDist - (self.deviation * 100))

            --system.print(breadCrumbDist)
            if realDistance > self.breadCrumbDist and not self.deviated then
                breadCrumb = moveWaypointZ(self.customTarget, (self.altitude - self.baseAltitude) + self.breadCrumbDist)
                destination = breadCrumb
                --local waypointString = ship.nearestPlanet:convertToMapPosition(destination)
			    --system.print(tostring(waypointString))
            elseif realDistance < -self.breadCrumbDist and not self.deviated then
                breadCrumb = moveWaypointZ(self.customTarget, (self.altitude - self.baseAltitude) - self.breadCrumbDist)
                destination = breadCrumb
                --local waypointString = ship.nearestPlanet:convertToMapPosition(destination)
			    --system.print(tostring(waypointString))
            end

            self.elevatorDestination = (self.world.position - destination):normalize()
            --system.print("TEST: "..round2((distance * distance),4))

            tmp = tmp - self.elevatorDestination * self.mass * utils.clamp(distance * 3.6,0.3,((math.abs(speed)/3.6) * self.IDIntensity))
            --if breadCrumb ~= nil then system.print("Breadcrumb distance: "..(self.world.position - breadCrumb):len()) end
            if distance < 0.01 and not manualControl then
                self.elevatorActive = false self.targetVector = nil
                self.stateMessage = "Idle"
                self.dockingClamps = true
            elseif distance < 2 and self.world.velocity:len() == 0 and not manualControl then
                self.elevatorActive = false self.targetVector = nil
                self.stateMessage = "Idle"
                self.dockingClamps = true
            else
                self.dockingClamps = false
            end

	    else
            --self.stateMessage = "Idle"
            self.destination = vec3(0,0,0)
        end
        if self.inertialDampening then
            local currentShipMomentum = self.localVelocity
            local delta = vec3(0,0,0)
            local moveDirection = self.direction or vec3(0,0,0)

            if moveDirection.x == 0 then delta.x = currentShipMomentum.x end
            if moveDirection.y == 0 then delta.y = currentShipMomentum.y end
            if moveDirection.z == 0 then delta.z = currentShipMomentum.z end

            delta = self.localToRelative(delta, self.world.up, self.world.right, self.world.forward)
            --system.print(tostring(delta))
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
            atmp = atmp + (self.world.forward:cross(vec) * (self.rotationSpeed / 4))  - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
        end

        if self.targetVectorVertical ~= nil then
            local vec = vec3(self.world.up.x, self.world.up.y, self.world.up.z)
            if type(self.targetVector) == "function" then
                vec = self.targetVector()
            elseif type(self.targetVector) == "table" then
                vec = self.targetVector
            end
            if (self.world.up - self.targetVectorVertical):len() < 0 then
                atmp = atmp + (-self.world.up:cross(vec) * (self.rotationSpeed / 4))  - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
            else
                atmp = atmp + (self.world.up:cross(vec) * (self.rotationSpeed / 4))  - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
            end

        end

        -- must be applied last
        if self.counterGravity then
            --tmp = tmp - self.nearestPlanet:getGravity(construct.getWorldPosition()) * self.mass
            tmp = tmp - self.world.gravity * self.mass
        end

        if self.verticalLock then
            local localPos = (self.world.position + self.world.up) - self.lockPos
            local intersectionPos = self.lockVector * self.lockVector:dot(localPos)
            local intersectionVec = intersectionPos - localPos
            local thrustForce = intersectionVec * (self.mass * 0.3)-- * deltaTime
            --system.print("thrustForce: " .. tostring(thrustForce))
            tmp = tmp + thrustForce * self.mass
         end

        atmp = atmp - ((self.AngularVelocity * 2) - (self.AngularAirFriction * 2))
        tmp = tmp / self.mass

        if self.controlMode ~= unit.getControlMode() then
            self.controlMode = unit.getControlMode()
            if unit.getControlMode() == 0 then self.alternateCM = false end
            if unit.getControlMode() == 1 then self.alternateCM = true end
        end


        --self.control.setEngineCommand(tostring(self.tags), {tmp:unpack()}, {atmp:unpack()})
        self.control.setEngineCommand("atmospheric_engine,space_engine,airfoil,brake,torque,vertical,lateral,longitudinal",
                                        {tmp:unpack()}, {atmp:unpack()}, false, false,
                                        self.priorityTags1,
                                        self.priorityTags2,
                                        self.priorityTags3)

        atmp = vec3(0, 0, 0)
        tmp = vec3(0, 0, 0)
        self.elevatorDestination = vec3(0,0,0)
        lastUpdate = system.getArkTime()
    end

    return self
end

ship = STEC(core, unit)
