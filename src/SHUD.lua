--@class SHUD
vec2 = require('cpml/vec2')
mat4 = require("cpml/mat4")
local json = require("dkjson") -- For AGG
local format = string.format



if next(manualSwitches) ~= nil then
    for _, sw in ipairs(manualSwitches) do
      system.print("Deactivate!")
      sw.deactivate()
    end
  end

function SpeedConvert(value)
    if not value or value == 0 then return {0,"00","km/h"} end
    if value > 5000 then
        local ending = tonumber(tostring(round2(value/55.55, 2)):match("%.(%d+)"))
        ending = string.format("%02d",ending)
        return {round2(value/55.55),ending,"su/h"}
    end
    local ending = tonumber(tostring(round2(value/3.6, 2)):match("%.(%d+)"))
    ending = string.format("%02d",ending)
    return {round2(value*3.6),ending,"km/h"}
end

function CruiseControl(value)
    local appliedCruise = 0


    if ship.cruiseSpeed < 500 then appliedCruise = value * 10
    elseif ship.cruiseSpeed >= 500 and ship.cruiseSpeed <= 1999 then appliedCruise = value * 50
    elseif ship.cruiseSpeed >= 2000 and ship.cruiseSpeed <= 9999 then appliedCruise = value * 100
    elseif ship.cruiseSpeed >= 10000 then appliedCruise = value * 1000 end


    ship.cruiseSpeed = utils.clamp(ship.cruiseSpeed + appliedCruise,-29990,29990)
end

function getControlMode()
    if ship.alternateCM then
        return "Cruise"
    else
        return "Travel"
    end
end

altHoldAdjustment = 0.1
altAdjustment = 3

function altHoldAdjustmentSetting()
    return altHoldAdjustment * (10^altAdjustment)
end


function setAltHoldAdjustment()

end


function SHUDMenuItem(content, action, update)
    local self = {}
    self.Enabled = true
    self.Active = false
    self.Content = content
    self.Class = ""
    self.Action = action or function(system, unit, self) end
    self.Update = update or function(system, unit, self) end

    function self.Disable()
        self.Enabled = false
        return self
    end

    function self.Enable()
        self.True = false
        return self
    end

    function self.Lock()
        SHUD.ScrollLock = true
        self.Active = true
        self.Class = "locked"
        return self
    end

    function self.Unlock()
        SHUD.ScrollLock = false
        self.Active = false
        self.Class = ""
        return self
    end

    return self
end



SHUD =
(function()
    local self = {}
    self.Enabled = false
    self.FreezeUpdate = false
    self.IntroPassed = false

    self.FOV = system.getCameraHorizontalFov()
    self.ScreenW = system.getScreenWidth()
    self.ScreenH = system.getScreenHeight()
    self.Resolution = vec2(self.ScreenW, self.ScreenH)

    self.SvgMinX = -round((self.ScreenW / 4) / 2,0)
    self.SvgMinY = -round((self.ScreenH / 4) / 2,0)
    self.SvgWidth = round(self.ScreenW / 4,0)
    self.SvgHeight = round(self.ScreenH / 4,0)

    function scaleViewBounds(input)
        local rMin = -0.5
        local rMax = 0.5
        local tMin = -90
        local tMax = 90
        return -(((input - rMin) / (rMax - rMin)) * (tMax - tMin) + tMin)
    end

    shipPitch = scaleViewBounds(ship.pitchRatio)

    self.SHUDFuelHtml = ""

    self.Markers = {}

    self.MarkerBuffer = {}

    function self.worldToScreen(pos)
        local P = mat4():perspective(self.FOV, self.ScreenW/self.ScreenH, 0.1, 100000)
        local adjustedPos = ship.world.position - vec3(unit.getMasterPlayerRelativePosition())
        local V = mat4():look_at(adjustedPos, adjustedPos + ship.world.forward, ship.world.up)

        local pos = V * P * { pos.x, pos.y, pos.z, 1 }

        pos[1] = pos[1] / pos[4] * 0.5 + 0.5
        pos[2] = pos[2] / pos[4] * 0.5 + 0.5

        pos[1] = pos[1] * 100
        pos[2] = pos[2] * 100

        return vec3(pos[1], pos[2], pos[3])
    end

    local SMI = SHUDMenuItem
    local DD = DynamicDocument

    function self.UpdateMarkers()
        self.MarkerBuffer = {}
        for i=1,#self.Markers do
            local m = self.Markers[i]
            local marker = {}
            local p = vec3(0,0,0)
            if type(m.Position) == "function" then marker.pos = m.Position() p = m.Position() else marker.pos = m.Position p = m.Position end
            marker.pos = self.worldToScreen(marker.pos)
            marker.class = m.Class
            marker.content = '&nbsp;'
            if m.Name then marker.content = [[<div class="name">]] .. m.Name .. [[</div>]] end
            if m.ShowDistance then marker.content = marker.content .. [[<div class="distance">]] .. round2((ship.world.position - p):len()) .. [[m</div>]] end
            if marker.pos.z > 0 then self.MarkerBuffer[#self.MarkerBuffer + 1] = marker end
        end
    end

    local function esc(x)
        return (x:gsub("%%", "%%%%"))
    end




    function self.MakeBooleanIndicator(varName)
        local tmpl = [[<span class="right">
            <i dd-if="varName == true">✓&nbsp;</i>
            <i dd-if="varName == false">✘&nbsp;</i>
        </span>]]
        return tmpl:gsub("varName", esc(varName))
    end

    function self.MakeSliderIndicator(varName, suffix)
        suffix = suffix or ""
        local tmpl = [[<span class="right">{{varName}}{{suffix}}<i>&udarr;&nbsp;</i></span>]]
        return tmpl:gsub("varName", esc(varName)):gsub("{{suffix}}", esc(suffix))
    end

    function self.GenerateMenuLink(text, link)
        return SMI(text..self.MenuIcon,  function() self.SelectMenu(link) end)
    end

    self.MenuIcon = [[<span class="right"><i>&gt;&nbsp;</i></span>]]
    self.BackButton = SMI([[<i>&lt;&nbsp;</i>&nbsp;]].."Back", function() SHUD.Menu = SHUD.MenuList.prev SHUD.CurrentIndex = 1 end)
    self.Menu = {
            SMI(DD([[<span>Throttle<span>]]..self.MakeSliderIndicator("round2(ship.throttle * 100)", "%")),
                function(_, _, w) if w.Active then w.Unlock() else w.Lock() end end,
                function(system, _ , w) ship.throttle = utils.clamp(ship.throttle + (system.getMouseWheel() * 0.05),-1,1) end),

            self.GenerateMenuLink("Stability Assist", "stability"),
            self.GenerateMenuLink("Altitude Hold", "altHold"),
            self.GenerateMenuLink("Ship Stats", "shipStats"),
            SMI([[<i>&#9432;&nbsp;</i><span>&nbsp;Hotkeys</span>]]..self.MenuIcon, function() self.SelectMenu("hotkeys") end)
    }
    self.MenuList = {}
    self.MenuList.flightMode = {}
    self.MenuList.shipStats = {
        SMI(DD([[<span>Core ID:</span><span class="right">{{ship.id}}</span>]])).Disable(),
        SMI(DD([[<span>Mass:</span><span class="right">{{round2(ship.mass/1000,2)}} Ton</span>]])).Disable(),
        SMI(DD([[<span>FMax:</span><span class="right">{{round2(ship.fMax/1000,2)}} KN</span>]])).Disable(),
        SMI(DD([[<span>Pos X:</span><span class="right">{{round2(ship.world.position.x)}}</span>]])).Disable(),
        SMI(DD([[<span>Pos Y:</span><span class="right">{{round2(ship.world.position.y)}}</span>]])).Disable(),
        SMI(DD([[<span>Pos Z:</span><span class="right">{{round2(ship.world.position.z)}}</span>]])).Disable(),
    }

    self.MenuList.stability = {
        SMI(DD("<span>Gravity Suppression<span>" .. self.MakeBooleanIndicator("ship.counterGravity")), function() ship.counterGravity = not ship.counterGravity end),
        SMI(DD("<span>Gravity Follow</span>" .. self.MakeBooleanIndicator("ship.followGravity")), function() ship.followGravity = not ship.followGravity end),
        SMI(DD("<span>Inertial Dampening<span>" .. self.MakeBooleanIndicator("ship.inertialDampening")), function() ship.inertialDampeningDesired = not ship.inertialDampeningDesired end),
        SMI(DD([[<span>Hover Height<span>]]..self.MakeSliderIndicator("ship.hoverHeight", "m")),
               function(_, _, w) if w.Active then w.Unlock() else w.Lock() end end,
               function(system, _ , w) ship.hoverHeight = utils.clamp(ship.hoverHeight + (system.getMouseWheel()),0,35) end),
    }
    function self.updateTargetDest()
        ship.targetDestination = moveWaypointZ(ship.customTarget, utils.clamp(ship.altitudeHold + (system.getMouseWheel() * altHoldAdjustmentSetting()),0,2000000) - ship.baseAltitude)
        ship.altitudeHold = utils.clamp(ship.altitudeHold + (system.getMouseWheel() * altHoldAdjustmentSetting()),0,2000000)
    end
    self.MenuList.altHold = {
        SMI(DD("<span>Altitude Hold<span>" .. self.MakeBooleanIndicator("ship.elevatorActive")), function() ship.elevatorActive = not ship.elevatorActive end),
        SMI(DD([[<span>Multiplier<span>]]..self.MakeSliderIndicator("round2(altHoldAdjustmentSetting(),3)", "")),
               function(_, _, w) if w.Active then w.Unlock() else w.Lock() end end,
               function(system, _ , w) altAdjustment = utils.clamp(altAdjustment + (system.getMouseWheel()),-1,4) end),
        SMI(DD([[<span>Alt Setpoint<span>]]..self.MakeSliderIndicator("round2(ship.altitudeHold,3)", "m")),
               function(_, _, w) if w.Active then w.Unlock() else w.Lock() end end,
               function(system, _ , w) self.updateTargetDest() end),
        SMI(DD([[<span>Preset 1:</span><span class="right">]].. mToKm(ship.altHoldPreset1).."</span>"), function() ship.altitudeHold = ship.altHoldPreset1 ship.elevatorActive = true end),
        SMI(DD([[<span>Preset 2:</span><span class="right">]].. mToKm(ship.altHoldPreset2).."</span>"), function() ship.altitudeHold = ship.altHoldPreset2 ship.elevatorActive = true end),
        SMI(DD([[<span>Preset 3:</span><span class="right">]].. mToKm(ship.altHoldPreset3).."</span>"), function() ship.altitudeHold = ship.altHoldPreset3 ship.elevatorActive = true end),
        SMI(DD([[<span>Preset 4:</span><span class="right">]].. mToKm(ship.altHoldPreset4).."</span>"), function() ship.altitudeHold = ship.altHoldPreset4 ship.elevatorActive = true end),
        SMI(DD([[<span>Altitude:</span><span class="right">{{round2(ship.altitude,4)}}</span>]])).Disable(),
    }

    self.MenuList.hotkeys = {}

    local fa = "<style>" .. CSS_SHUD .. "</style>"
    self.fuel = nil
    function getFuelRenderedHtml()
        local fuelHtmlAtmo = ""
        local fuelHtmlSpace = ""
        local fuelHtmlRocket = ""

        self.fuel = getFuelSituation()
        local fuelHtml = ""

        local mkTankHtml = (function (type, tank)
            local tankLevel = 100 * tank.level
            local tankLiters = tank.level * tank.specs.capacity()
            return '<div class="fuel-meter fuel-type-' .. type .. '"><hr class="fuel-level" style="width:' .. tankLevel .. '%%;" />' .. tank.time .. ' (' .. math.floor(tankLevel) .. '%%, ' .. math.floor(tankLiters) .. 'L)</div>'
        end)

        for _, tank in pairs(self.fuel.atmo) do fuelHtml = fuelHtml .. mkTankHtml("atmo", tank) end
        for _, tank in pairs(self.fuel.space) do fuelHtml = fuelHtml .. mkTankHtml("space", tank) end
        for _, tank in pairs(self.fuel.rocket) do fuelHtml = fuelHtml .. mkTankHtml("rocket", tank) end

        self.SHUDFuelHtml = fuelHtml
    end

    opacity = 1.0
    local template = DD(fa..[[
    <div id="horizon" style="opacity: {{opacity}};">
        <svg dd-if="enableARReticle" class="shadow" height="100%" width="100%" viewBox="{{SHUD.SvgMinX}} {{SHUD.SvgMinY}} {{SHUD.SvgWidth}} {{SHUD.SvgHeight}}">
            <g transform="translate({{ship.viewX}},{{ -ship.viewY }}) scale(0.7)">
                <line class="st0" x1="-0.5" y1="-91.5" x2="-0.5" y2="-11.5"/>
                <line class="st0" x1="116" y1="-0.5" x2="19" y2="-0.5"/>
                <line class="st0" x1="-0.5" y1="10.25" x2="-0.5" y2="90.25"/>
                <line class="st0" x1="-20" y1="-0.5" x2="-117" y2="-0.5"/>
                <line class="st1" x1="-0.5" y1="-4" x2="-0.5" y2="3"/>
                <line class="st1" x1="3" y1="-0.5" x2="-4" y2="-0.5"/>
                <path class="st0" d="M-10,16.34c-5.12-3.4-8.5-9.23-8.5-15.84c0-6.56,3.32-12.34,8.38-15.76"/>
                <path class="st0" d="M10-15.96c5.68,3.29,9.5,9.43,9.5,16.46c0,7.03-3.82,13.17-9.5,16.46"/>
                <g transform="rotate({{ shipPitch }} 0,0)">
                    <path class="st0" d="M-53.99-10.22c3.98-17.83,19.5-38.76,42.99-43.7"/>
                    <path class="st0" d="M-11,51.99C-32.68,47.76-49.76,30.68-53.99,9"/>
                    <path class="st0" d="M52.99,9C48.69,31.01,31.15,48.28,9,52.17"/>
                    <path class="st0" d="M9-54.14c21.87,3.98,39.92,21.42,44.09,43.78"/>
                    <line class="st0" x1="-53.5" y1="-10.5" x2="-94.5" y2="-10.5"/>
                    <line class="st0" x1="-54" y1="9.5" x2="-95" y2="9.5"/>
                    <polyline class="st2" points="53,9.5 84.49,9.5 94,9.5 84.5,13.5 84.5,9.5 "/>
                    <polyline class="st2" points="53,-10.5 84.49,-10.5 94,-10.5 84.5,-14.5 84.5,-10.5 "/>
                </g dd-if="ship.world.nearPlanet">
            </g>


        </svg>
        <div id="speedometerBar">&nbsp;</div>
           <div id="speedometer">
               <span class="display">
               	<span class="major">{{SpeedConvert(ship.world.velocity:len())[1]}}</span>
               	<span class="minor">{{SpeedConvert(ship.world.velocity:len())[2]}}</span>
               	<span class="unit">{{SpeedConvert(ship.world.velocity:len())[3]}}</span>
               </span>
               <span class="accel">
               	<span class="major">{{round2(ship.world.acceleration:len(), 1)}}</span>
               	<span class="unit">m/s</span>
               </span>
               <span class="vertical">
               	{{round2(ship.world.velocity:dot(-ship.world.gravity:normalize()), 1)}}
               </span>
               <span class="alt">
               	{{round2(ship.altitude)}}m
               </span>

               <span class="misc">ATM {{round2(ship.world.atmosphericDensity, 2)}} | G {{round2(ship.world.gravity:len(), 2)}}m/s</span>
               <span dd-if="not ship.alternateCM" class="throttle">Throttle {{round2(ship.throttle * 100)}}%</span>
		     <span dd-if="ship.alternateCM" class="throttle">Cruise {{round2(ship.cruiseSpeed)}} km/h</span>
            </div>

            <div id="horizon-menu">
                {{_SHUDBUFFER}}
            </div>

            </div>
            <div id="fuelTanks">
            {{ SHUD.SHUDFuelHtml }}

            </div>

    </div>

    ]])
    local itemTemplate = [[<div class="item {{class}}">{{content}}</div>]]
    function self.SelectMenu(menuName)
        if not SHUD.MenuList[menuName] then error("[SHUD] Undefined menu: " .. menuName) end
        SHUD.MenuList.prev = SHUD.Menu
        SHUD.Menu = SHUD.MenuList[menuName]
        SHUD.CurrentIndex = 1
        if SHUD.Menu[#SHUD.Menu] ~= SHUD.BackButton then table.insert(SHUD.Menu, SHUD.BackButton) end
    end

    function self.Select()
        if not self.Enabled then return end
        if #self.Menu < 1 then
            return
        end
        self.Menu[self.CurrentIndex].Action(self.system, self.unit, self.Menu[self.CurrentIndex])
    end

    function self.Render()
        local buffer = ""
        if self.Enabled then
            for i = 1, #self.Menu do
                local item = self.Menu[i]
                if item.Active then item.Update(self.system, self.unit, item) end
                local lb = itemTemplate
                local cls = ""
                local content = item.Content
                if content.Read then
                    content = content.Read()
                end
                content = esc(content)
                if self.CurrentIndex == i then
                    cls = "active"
                end
                if not item.Enabled then cls = cls .. " disabled" end
                lb = lb:gsub("{{class}}", cls .. " " .. item.Class)
                lb = lb:gsub("{{content}}", content)
                buffer = buffer .. lb
            end
            _ENV["_SHUDBUFFER"] = esc(buffer)
        else
            ship.frozen = player.isFrozen()
            _ENV["_SHUDBUFFER"] = DD([[<div class="item helpText">Press ]] .. "[" .. self.system.getActionKeyName("speedup") .. "]" .. [[ to  toggle menu</div>
				<div class="item helpText"><span>Character Movement:</span>]].. self.MakeBooleanIndicator("ship.frozen") .. [[</div>
				<div class="item helpText"><span>Vertical Lock:</span>]].. self.MakeBooleanIndicator("ship.verticalLock") .. [[</div>
				<div class="item helpText"><span>Inertial Dampening:</span>]].. self.MakeBooleanIndicator("ship.inertialDampening") .. [[</div>
				<div class="item helpText"><span>Gravity Follow:</span>]].. self.MakeBooleanIndicator("ship.followGravity") .. [[</div>
				<div class="item helpText"><span>Gravity Supression:</span>]].. self.MakeBooleanIndicator("ship.counterGravity") .. [[</div>
            ]]).Read()
        end
        if not self.FreezeUpdate then self.system.setScreen(template.Read()) end
    end

    function self.Update()
        if useGEAS then
            unit.activateGroundEngineAltitudeStabilization(ship.hoverHeight)
        end
        if player.isFrozen() or self.Enabled then
            opacity = 1
        else
            opacity = 0.5
        end
        if not self.ScrollLock and self.Enabled then
            local wheel = system.getMouseWheel()
            if wheel ~= 0 then
                self.CurrentIndex = self.CurrentIndex - wheel
                if self.CurrentIndex > #self.Menu then self.CurrentIndex = 1
                elseif self.CurrentIndex < 1 then self.CurrentIndex = #self.Menu end
            end
        elseif not self.Enabled then
            if player.isFrozen() and unit.isRemoteControlled() == 1 then
                ship.throttle = utils.clamp(ship.throttle + (system.getMouseWheel() * 0.05),-1,1)
			end
        	self.UpdateMarkers()
		end
	end

    function self.Init(system, unit, keybinds)
        self.system = system
        self.unit = unit
        self.CurrentIndex = 1
        self.ScrollLock = false
        system.showScreen(1)
        unit.hideWidget()
        local keys = keybinds.GetNamedKeybinds()
        self.MenuList.hotkeys = {}
        for i=1,#keys do
            local key = keys[i]
            table.insert(self.MenuList.hotkeys, SMI([[<span>]]..key.Name..[[</span><span class="right">]]..self.system.getActionKeyName(key.Key)..[[</span>]]).Disable())
        end

        self.MenuList.flightMode = {}
        for k,v in pairs(keybindPresets) do
            table.insert(self.MenuList.flightMode,
            SMI(string.upper(k), function()
                self.Init(self.system, self.unit, v)
                keybindPreset = k
                keybindPresets[keybindPreset].Init()
            end))
        end

        keybinds.Init()
    end

    return self
end)()
