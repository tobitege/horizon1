--@class ElevatorScreen
ElevatorScreen = (function ()
	local self = {}

	function self.updateStats()
		stats.data.elevation = ship.altitude
		stats.data.target = config.targetAlt
		stats.data.velocity = ship.world.velocity:len()
		stats.data.mass = ship.mass
		stats.data.gravity = ship.world.gravity:len()
		stats.data.target_dist = math.abs(ship.altitude - (ship.altitudeHold or 0))
		stats.data.brake_dist = ship.brakeDistance
		stats.data.deviation = ship.deviation
		stats.data.deviationVec = ship.worldToLocal(ship.deviationVec)
		stats.data.deviationRot = ship.worldToLocal(ship.deviationRot)
		stats.data.state = ship.stateMessage
		stats.data.delta = nil
	end
	self.updateStats()
	function self.updateScreenFuel()
		fuelAtmo.tanks = {}
		fuelSpace.tanks = {}

		for _, tank in pairs(SHUD.fuel.atmo) do
			table.insert(fuelAtmo.tanks,fuelTank(tank.time,math.ceil(100 * tank.level)))
		end
		for _, tank in pairs(SHUD.fuel.space) do
			table.insert(fuelSpace.tanks,fuelTank(tank.time,math.ceil(100 * tank.level)))
		end
		--for _, tank in pairs(SHUD.fuel.rocket) do fuelHtmlRocket = fuelHtmlRocket .. mkTankHtml("rocket", tank) end
		ioScheduler.queueData(fuelAtmo)
		ioScheduler.queueData(fuelSpace)
	end
	if screen then screen.clearScriptOutput() else system.print("No screen!") end

    return self
end)()
