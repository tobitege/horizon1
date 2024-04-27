--@class IOScheduler

--[[
Custom IO scheduler to deal with limited data packet size
and tick rate of screen send/recieve. IOScheduler.defaultData
will send as fast as possible, while IOScheduler.queueData()
will interrupt default send and to send queued data.
--]]

IOScheduler = (function()
    local self = {}

    self.defaultData = nil
    self.currentTask = nil
    self.taskQueue = {}
    function self.queueData(data)
         table.insert(self.taskQueue, data)
    end
    --Send queued data to screen
    function self.send(T)
        output = screen.getScriptOutput()
        screen.clearScriptOutput()
        if output ~= "ack" then
            if output and output ~= "" then
                handleOutput.Read(output)
            end
            coroutine.yield()
            self.send(T)
        else
            screen.setScriptInput(serialize(T))
        end
    end
    --Queue data to send or send self.defaultData
    function self.runQueue()
        if #self.taskQueue == 0 then
            --Send default table
            if self.defaultData ~= nil then
				self.currentTask = coroutine.create(function()
						self.send(self.defaultData)
					end)
            	coroutine.resume(self.currentTask)
            end
        else
            --Iterate over self.taskQueue and send each to screen
            self.currentTask = coroutine.create(function()
                for i=1, #self.taskQueue do
                    local data = self.taskQueue[i]
                    if type(data) == "table" then
                        self.send(data)
                    end
                    table.remove(self.taskQueue,i)
                end
            end)
            coroutine.resume(self.currentTask)
        end
    end

    --Add to system.update()
    function self.update()
		if not screen then system.print("No screen found"); return end
        if self.currentTask then
            if coroutine.status(self.currentTask) ~= "dead" then
                coroutine.resume(self.currentTask)
            else
                self.runQueue()
            end
        else
            self.runQueue()
        end
    end

    return self
end)()

HandleOutput = (function()
    local self = {}
    function self.Read(output)
system.print("handleOutput.Read(): "..output)
		if type(output) ~= "string" or output == "" then
			-- system.print("[E] handleOutput: "..tostring(output));
			return
		end
		local s = deserialize(output)
		if s.dataType == "config" then
			config = s
			local delta = tonumber(config.delta)
			if delta ~= nil then
				config.targetAlt = ship.altitude + delta
				stats.data.target = config.targetAlt
			else
				stats.data.target = config.targetAlt
			end
			self.Execute()
		elseif s.updateReq then
			ioScheduler.queueData(config)
		else
			system.print(tostring(s))
        end
    end

    function self.Execute()
        ship.baseAltitude = helios:closestBody(ship.customTarget):getAltitude(ship.customTarget)

        ship.altitudeHold = config.targetAlt

        if config.estop then
            config.delta = nil
            config.targetAlt = 0
            ship.altitudeHold = 0
            ship.verticalLock = false
            ship.elevatorActive = false
            ship.brake = true
            ship.stateMessage = "EMERGENCY STOP"
            system.print(ship.stateMessage)
            ioScheduler.queueData(config)
        else
            ship.brake = false
        end
        if ship.altitudeHold and ship.altitudeHold ~= 0 then
            ship.elevatorActive = true
            system.print("Alt diff: "..(config.targetAlt - ship.baseAltitude))
            ship.targetDestination = moveWaypointZ(ship.customTarget, config.targetAlt - ship.baseAltitude)
        end
        if config.setBaseReq then
            setBase()
            config.setBaseReq = false
            ioScheduler.queueData(config)
        end
        config.elevation = ship.altitude
        --if config.updateReq then
        --    config.updateReq = false
        --    ioScheduler.queue(config)
        --end
        manualControlSwitch()
    end

    return self
end)()

ioScheduler = IOScheduler
handleOutput = HandleOutput