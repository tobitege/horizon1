--@require ExportedVariables

--@require PlanetRef
--@require KinematicsMin
--@require SimpleSlotDetectorMin
--@require Serializer
--@require EventDelegateMin
--@require TaskManagerMin
--@require DynamicDocumentMin
--@require DUTTYMin
--@require CSS_SHUD
--@require FuelTankHelper
--@require TagManagerMin
--@require KeybindControllerMin
--@require IOScheduler
--@require STEC
--@require AR_HUDMin
--@require SHUD
--@require STEC_Config
--@require ElevatorScreen
--@timer SHUDRender
--@timer FuelStatus
--@timer DockingTrigger
--@class Main

_G.BuildUnit = {}
local Unit = _G.BuildUnit
_G.BuildSystem = {}
local System = _G.BuildSystem
_G.BuildScreen = {}
local buildScreen = _G.BuildScreen
local elevatorScreen = nil

function Unit.onStart()
	--Events.Flush.Add(mouse.apply)
	Events.Flush.Add(ship.apply)
	Events.Update.Add(SHUD.Update)
	getFuelRenderedHtml()
	system.print("Screen: "..tostring(screen))
	if screen ~= nil then
		manualControlSwitch()
		system.print("Altitude: "..helios:closestBody(construct.getWorldPosition()):getAltitude(construct.getWorldPosition()))
		ship.altitudeHold = helios:closestBody(construct.getWorldPosition()):getAltitude(construct.getWorldPosition())
		ship.baseAltitude = helios:closestBody(ship.customTarget):getAltitude(ship.customTarget)
		--ship.elevatorActive = true
	end
	--if next(manualSwitches) ~= nil then manualSwitches[1].activate() end
	if screen == nil then
		ship.verticalLock = false
		ship.intertialDampening = true
		ship.elevatorActive = false
		config.manualControl = not config.manualControl
		manualControlSwitch()
	end
	if screen ~= nil then elevatorScreen = ElevatorScreen end
	system.print("ElevatorScreen: "..tostring(elevatorScreen))
	local sName = ""
	local coreMass = core.getMass()
	if emitter ~= nil then
		system.print("Emitter Range: "..emitter.getRange())
	end
	if activateFFonStart then
		if next(manualSwitches) ~= nil then
			for _, sw in ipairs(manualSwitches) do
				sw.activate()
			end
		end
	end

	shipName = construct.getName()
	system.print(player.getId())
	unit.setTimer("SHUDRender", 0.02)
	unit.setTimer("FuelStatus", 3)
	unit.setTimer("DockingTrigger", 1)
	if laser ~= nil then laser.deactivate() end

	system.print([[Horizon 1.0.1.13]])
	if showDockingWidget then
		parentingPanelId = system.createWidgetPanel("Docking")
		parentingWidgetId = system.createWidget(parentingPanelId,"parenting")
		system.addDataToWidget(unit.getWidgetDataId(),parentingWidgetId)
	end

	if setBaseOnStart then setBase() end
	--StepOne.Start()
	--ioScheduler.queueData(config)
end

function Unit.onStop()
	if next(manualSwitches) ~= nil then
		for _, sw in ipairs(manualSwitches) do
			sw.deactivate()
		end
	end
	config.shutDown = true
	if screen then screen.setScriptInput(serialize(config)) end
	system.showScreen(false)
	if laser ~= nil then laser.deactivate() end

	for _, sw in ipairs(forceFields) do
		sw.deactivate()
	end
end

function manualControlSwitch()
	if not config.manualControl then
		SHUD.Init(system, unit, keybindPresets["screenui"])
		system.showScreen(false)
		player.freeze(false)
		ship.frozen = true
		ship.stateMessage = "Idle"
	else
		SHUD.Init(system, unit, keybindPresets["keyboard"])
		system.showScreen(true)
		player.freeze(true)
		ship.frozen = false
		ship.stateMessage = "Manual Control"
	end
end

local emitterOn = false
local tmpClamp = ship.dockingClamps

function Unit.onTimer(timer)
	if timer == "SHUDRender" then
		if screen == nil then
			if SHUD then SHUD.Render() end
		elseif config.manualControl then
			if SHUD then SHUD.Render() end
			if enableARReticle then updateAR() end
		else

		end
	end
	if timer == "FuelStatus" then
		getFuelRenderedHtml()
		if elevatorScreen then elevatorScreen.updateScreenFuel() end
		--ioScheduler.queueData(config)
	end
	if timer == "DockingTrigger" then
		if telemeter ~= nil then telDistance = telemeter.raycast().distance end
		if ship.dockingClamps then
			if laser ~= nil then laser.activate() end
			if telemeter ~= nil and telDistance > 0 and telDistance < 1 then
				if ship.autoShutdown and not config.manualControl then system.print(ship.altitude) unit.exit() end
			end
		end
	end
end

function System.onActionStart(action)
	keybindPresets[keybindPreset].Call(action, "down")
end

function System.onActionStop(action)
	keybindPresets[keybindPreset].Call(action, "up")
end

function System.onInputText(action)
	if DUTTY then DUTTY.input(action) end
end

function System.onActionLoop(action)
end

function System.onUpdate()
	--system.print("Cust Target: "..tostring(vec3(ship.customTarget)).." | alt: "..ship.altitude.." | baseAlt: "..ship.baseAltitude.." | worldPos: "..tostring(vec3(ship.world.position)).." | ")
	--self.deviationVec = (moveWaypointZ(self.customTarget, self.altitude - self.baseAltitude) - self.world.position)
	if elevatorScreen then elevatorScreen.updateStats() end
	ioScheduler.update()
	if Events then Events.Update() end
	if TaskManager then TaskManager.Update() end
end

function System.onFlush()
	if Events then Events.Flush() end
end

function buildScreen.onMouseDown(x,y,slot)
	--system.print("Mouse X: "..x..", Mouse Y: "..y)
end
function toggleVerticalLock()
	--ship.verticalLock = true
    ship.lockVector = vec3(construct.getWorldOrientationUp())
    ship.lockPos = vec3(construct.getWorldPosition()) + (vec3(construct.getWorldOrientationUp()))
end
function createBreadcrumbTrail(endAlt)
	--Create a set of waypoints starting from the current position to the destination spaced 1km apart
	local startPosition = moveWaypointZ(ship.customTarget, ship.world.atlasAltitude - ship.baseAltitude)
	local endPosition = moveWaypointZ(ship.customTarget, endAlt)
	local distance = (startPosition - endAlt):len()
	if distance < 1000 then return end
	for i = 1, round2(distance / 1000,0), 1 do
		if ship.nearestPlanet:getAltitude(startPosition) < ship.nearestPlanet:getAltitude(endPosition) then
			table.insert(ship.breadCrumbs, moveWaypointZ(startPosition, 1000 * i))
		else
			table.insert(ship.breadCrumbs, moveWaypointZ(startPosition, -1000 * i))
		end
	end
end

--local btrail = createBreadcrumbTrail(3)
--system.print("Breadcrumbs:")
--for _, sw in ipairs(ship.breadCrumbs) do
--	system.print("POS: "..tostring(sw))
--end
function buildScreen.onMouseUp(x,y,slot)
--ship.baseAltitude = helios:closestBody(ship.customTarget):getAltitude(ship.customTarget)
--	if settingsActive then
--		if mousex >= 0.1515 and mousex <= 0.4934 and mousey >= 0.5504 and mousey <= 0.7107 then --Setbase button
--			setBase()
--			settingsActive = false
--		end
--		if mousex >= 0.5097 and mousex <= 0.8511 and mousey >= 0.5504 and mousey <= 0.7134 then --Cancel button
--			settingsActive = false
--		end
--		if mousex >= 0.0277 and mousex <= 0.0868 and mousey >= 0.8515 and mousey <= 0.9484 then --Settings button
--			settingsActive = false
--		end

--		if mousex >= 0.0277 and mousex <= 0.0868 and mousey >= 0.8515 and mousey <= 0.9484 then --Settings button
--			settingsActive = true
--		end
--	end
end