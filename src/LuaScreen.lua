--@class LuaScreen
local rslib = require('rslib')
local utils = require('cpml/utils')
local vec3 = require('cpml/vec3')
local concat = table.concat
local sFormat = string.format
-- Libs and helper functions
local function internalSerialize(v,tC,t) local check = type(v) local intSerial=internalSerialize if check=='table' then t[tC]='{' local tempC=tC+1 if #v==0 then for k,e in pairs(v) do if type(k)~='number' then t[tempC]=k t[tempC+1]='=' tempC=tempC+2 else t[tempC]='[' t[tempC+1]=k t[tempC+2]=']=' tempC=tempC+3 end tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end else for k,e in pairs(v) do tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end end if tempC==(tC+1) then t[tempC]='}' return tempC+1 else t[tempC-1]='}' return tempC end elseif check=='string' then t[tC]=sFormat("%q",v) return tC+1 elseif check=='number' then t[tC]=tostring(v) return tC+1 else t[tC]=v and 'true' or 'false' return tC+1 end end
function serialize(v) local t={} local tC=1 local check = type(v) local intSerial=internalSerialize if check=='table' then t[tC]='{' tC=tC+1 local tempC=tC if #v==0 then for k,e in pairs(v) do if type(k)~='number' then t[tempC]=k t[tempC+1]='=' tempC=tempC+2 else t[tempC]='[' t[tempC+1]=k t[tempC+2]=']=' tempC=tempC+3 end tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end else for k,e in pairs(v) do tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end end if tempC==tC then t[tempC]='}' else t[tempC-1]='}' end elseif check=='string' then t[tC]=sFormat("%q",v) elseif check=='number' then t[tC]=tostring(v) else t[tC]=v and 'true' or 'false' end return concat(t) end
function deserialize(s) local f=load('t='..s) f() return t end
function spairs(a,b)local c={}for d in pairs(a)do c[#c+1]=d end;if b then table.sort(c,function(e,f)return b(a,e,f)end)else table.sort(c)end;local g=0;return function()g=g+1;if c[g]then return c[g],a[c[g]]end end end
function tablelength(T) local count = 0 for _ in pairs(T) do count = count + 1 end return count end
function convertFromHex(a)if a:sub(1,1)=="#"then a=a:sub(2,-1)end;if#a==8 then return tonumber("0x"..a:sub(1,2))/255,tonumber("0x"..a:sub(3,4))/255,tonumber("0x"..a:sub(5,6))/255,tonumber("0x"..a:sub(7,8))/255 elseif#a==6 then return tonumber("0x"..a:sub(1,2))/255,tonumber("0x"..a:sub(3,4))/255,tonumber("0x"..a:sub(5,6))/255,1 elseif#a==3 then return tonumber("0x"..a:sub(1,1))/15,tonumber("0x"..a:sub(2,2))/15,tonumber("0x"..a:sub(3,3))/15,1 else return 1,1,1,1 end end
function mToKm(n,p)
	if n == nil then return "nan" end
    if n >= 1000 then
        local rtn = utils.round((n / 1000),p) or utils.round((n / 1000))
        return  rtn .. " km"
    else
        local rtn = utils.round(n,p) or utils.round(n)
        return rtn .. " m" end end
function massConvert(n,p)
	if n == nil then return "nan" end
    if n >= 1000 and n < 1000000 then
        local rtn = utils.round((n / 1000),p) or utils.round((n / 1000))
        return  rtn .. " t"
    elseif n >= 1000000 then
		local rtn = utils.round((n / 1000000),p) or utils.round((n / 1000000))
		return  rtn .. " kt"
    else
        local rtn = utils.round(n,p) or utils.round(n)
        return rtn .. " kg" end end

local stLogo = loadImage("assets.prod.novaquark.com/31879/70c4eeac-9aad-4fce-952f-db5dac287832.png")
local stCover = loadImage("assets.prod.novaquark.com/27707/a8a9beb8-73de-4cd3-a0fb-d84e11e7a942.png")

font = loadFont('Play-Bold', 22)
fontStats = loadFont('Play-Bold', 18)
font2 = loadFont('Montserrat-Light', 12)
smallFuelFont = loadFont('Montserrat-Light', 7)
font3 = loadFont('Montserrat', 20)
statusFont = loadFont('FiraMono-Bold',16)
eStopFont = loadFont('Play-Bold', 32)
titleFont = loadFont('FiraMono-Bold', 46)

rx, ry = getResolution()
cx, cy = getCursor()

layer0 = createLayer()
layer = createLayer()
statsLayer = createLayer()
altSliderLayer = createLayer()
layer_spash = createLayer()
settingsLayer = createLayer()

click = getCursorPressed()

-- Background
---- x axis
--for i = 0,rx,25 do
--    setNextStrokeColor(layer, 1, 1, 1, 0.2)
--    addLine(layer,i,0,i,ry)
--    addText(layer,font,i,i + 5,15)
--end
---- y axis
--for i = 0,ry,25 do
--    setNextStrokeColor(layer, 1, 1, 1, 0.2)
--    addLine(layer,0,i,rx,i)
--    addText(layer,font,i,5,i - 5)
--end

-- Input Routing
local tmp = nil
local tmpData = nil
local outputMsg = ""
tmp = getInput()

if tmp ~= nil and tmp ~= "" then tmpData = deserialize(tmp) or {}; end
--logMessage("Data Type: "..tmpData.dataType)
if not stats then stats = {} end
if not config then
    config = {}
    config.updateReq = true
    config.shutDown = true
    outputMsg = serialize(config) end
if not fuelAtmo then fuelAtmo = {} end
if not fuelSpace then fuelSpace = {} end
if tmpData ~= nil and type(tmpData) == "table" then
    if tmpData.dataType == "stats" then
        stats = tmpData
    elseif tmpData.dataType == "config" then
        config = tmpData
    elseif tmpData.dataType == "fuelAtmo" then
        fuelAtmo = tmpData
    elseif tmpData.dataType == "fuelSpace" then
        fuelSpace = tmpData
    end
else
    logMessage("tmpData is nil or not a table.")
end

if not bkGround then
    function bkGround()
        local bgHeight = ry/2+160
        local bgWidth = rx/2-60
        -- Buttons Container
        setNextFillColor(layer0, 0.1, 0.1, 0.1, 0.8)
        setNextStrokeColor(layer0, 1, 1, 1, 0.6)
        setNextStrokeWidth(layer0, 2)
        addBoxRounded(layer0,20,ry/6,bgWidth,bgHeight,20)
        -- Stats/fuel Container
        setNextFillColor(layer0, 0.1, 0.1, 0.1, 0.8)
        setNextStrokeColor(layer0, 1, 1, 1, 0.6)
        setNextStrokeWidth(layer0, 2)
        addBoxRounded(layer0,rx - (rx/2-40),ry/6,bgWidth,bgHeight,20)
        addImage(layer0, stLogo, rx - (rx/2-40),ry/6 + 30,rx/2-60,ry/2+100)
    end
end

if not elevAnimation then
    function elevAnimation()
        -- Elevator animation box
        if not stats or not stats.data or not config.floors then return end
		local boxHeight = utils.map(stats.data.elevation or 0,0,config.floors.floor1,ry - 65,100)
		setNextFillColor(altSliderLayer, 0.2, 0.2, 0.2, 1)
		setNextStrokeColor(altSliderLayer, 0.3, 0.0, 0.0, 1)
		setNextStrokeWidth(altSliderLayer, 2)
		addBoxRounded(altSliderLayer,rx/2 - 40,boxHeight,80,30,5)
		setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
		local sx, sy = getTextBounds(font3, mToKm(tonumber(stats.data.elevation)))
		addText(altSliderLayer,font3,mToKm(tonumber(stats.data.elevation)),rx/2 - sx/2,boxHeight + 20,80,30)
		-- Elevator animation line
		addLine(layer,rx/2,100,rx/2,ry - 30)
		addLine(layer,rx/2-20,100,rx/2+20,100)
		addLine(layer,rx/2-20,ry - 30,rx/2+20,ry - 30)
    end
end

if not GenericButton then
    local mt = {}
    mt.__index = mt
    function GenericButton (text1, text2, font, x, y, width, height, color, action, fLayer)
        return setmetatable({
            text1 = text1,
            text2 = text2,
            font = font,
            x = x,
            y = y,
            width = width,
            height = height,
            color = color,
            action = action,
            fLayer = fLayer or layer
        }, mt)
    end
    function mt:draw ()
        local esFont = self.font
        local sx, sy = self.width, self.height --self:getSize()
        local x0 = self.x - sx/2
        local y0 = self.y - sy/2
        local x1 = x0 + sx
        local y1 = y0 + sy
        local r, g, b = 0.7, 0.7, 0.7
        local cr, cg, cb, ca
        if self.color ~= nil then
            cr, cg, cb, ca = convertFromHex(self.color)
        else
            cr, cg, cb, ca = 0.1, 0.1, 0.1, 1
        end
        if cx >= x0 and cx <= x1 and cy >= y0 and cy <= y1 then
            --r, g, b = 1.0, 0.0, 0.1
            cr = cr + 0.1
            cg = cg + 0.1
            cb = cb + 0.1
            if click then
                cr = cr + 0.1
                cg = cg + 0.1
                cb = cb + 0.1
                if click then
                    if type(self.action) == "function" then
                       self.action()
                    end
                end
                --Click action
            end
        end
        --setNextShadow(layer, 64, r, g, b, 0.3)
        setNextFillColor(self.fLayer, cr, cg, cb, ca)
        setNextStrokeColor(self.fLayer, r, g, b, 1)
        setNextStrokeWidth(self.fLayer, 2)
        addBoxRounded(self.fLayer, self.x - sx/2, self.y - sy/2, sx, sy, sy * 0.1)
        if self.text2 ~= "" then
            if config.estop then
                setNextFillColor(self.fLayer, 0.3, 0, 0, 1)
            else
                setNextFillColor(self.fLayer, 1, 1, 1, 1)
            end

            setNextTextAlign(self.fLayer, AlignH_Center, AlignV_Middle)
            addText(self.fLayer, esFont, self.text1, self.x, self.y - 20)
            if config.estop then
                setNextFillColor(self.fLayer, 0.3, 0, 0, 1)
            else
                setNextFillColor(self.fLayer, 1, 1, 1, 1)
            end
            setNextTextAlign(self.fLayer, AlignH_Center, AlignV_Middle)
            addText(self.fLayer, esFont, self.text2, self.x, self.y + 20)
        else
            setNextFillColor(self.fLayer, 1, 1, 1, 1)
            setNextTextAlign(self.fLayer, AlignH_Center, AlignV_Middle)
            addText(self.fLayer, esFont, self.text1, self.x, self.y)
        end
    end

    function mt:getSize ()
        local sx, sy = getTextBounds(esFont, self.text1)
        return sx + 32, sy + 16
    end

    function mt:setPos (x, y)
        self.x, self.y = x, y
    end
end

if not ButtonQuad then
    local mt = {}
    mt.__index = mt
    function ButtonQuad (text, x, y, action, flip, color, fLayer)
        return setmetatable({
            text = text,
            x = x,
            y = y,
            action = action,
            color = color,
            flip = flip,
            fLayer = fLayer or layer
        }, mt)
    end

    function mt:draw ()
        local sx, sy = 180, 40--self:getSize()
        local x0 = self.x - sx/2
        local y0 = self.y - sy/2
        local x1 = x0 + sx
        local y1 = y0 + sy

        local r, g, b = 0.7, 0.7, 0.7
        local cr, cg, cb, ca
        if self.color ~= nil then
            cr, cg, cb, ca = convertFromHex(self.color)
        else
            cr, cg, cb, ca = 0.1, 0.1, 0.1, 1
        end
        if cx >= x0 and cx <= x1 and cy >= y0 and cy <= y1 then
            --r, g, b = 1.0, 0.0, 0.1
            cr = cr + 0.1
            cg = cg + 0.1
            cb = cb + 0.1
            if click then
                cr = cr + 0.1
                cg = cg + 0.1
                cb = cb + 0.1
                if click then
                    if type(self.action) == "function" then
                        self.action()
                    end

                end
                --Click action
            end
        end
        setNextFillColor(self.fLayer, cr, cg, cb, ca)
        setNextStrokeColor(self.fLayer, r, g, b, 1)
        setNextStrokeWidth(self.fLayer, 2)
        --Button Shape
        if not self.flip then
            addQuad(self.fLayer,
                self.x - sx/2, self.y - sy/2, --(x1,y1)
                self.x - sx/2, self.y + sy/2, --(x2,y2)
                self.x + sx/2, self.y + sy/2, --(x3,y3)
                self.x + sx/2 + 30, self.y - sy/2) --(x4,y4)
        else
            addQuad(self.fLayer,
                self.x - sx/2, self.y - sy/2, --(x1,y1)
                self.x - sx/2 - 30, self.y + sy/2, --(x2,y2)
                self.x + sx/2, self.y + sy/2, --(x3,y3)
                self.x + sx/2, self.y - sy/2) --(x4,y4)
        end
        setNextFillColor(self.fLayer, 1, 1, 1, 1)
        setNextTextAlign(self.fLayer, AlignH_Center, AlignV_Middle)
        addText(self.fLayer, font, self.text, self.x, self.y)
    end

    function mt:getSize ()
        local sx, sy = getTextBounds(font, self.text)
        return sx + 32, sy + 16
    end

    function mt:setPos (x, y)
        self.x, self.y = x, y
    end
end

if not FuelGauge then
    local mt = {}
    mt.__index = mt
    function FuelGauge (text, x, y, ft, tm, pct, split, font)
        return setmetatable({
            text = text,
            x = x,
            y = y,
            ft = ft,
            tm = tm,
            pct = pct,
            split = split,
            font = font or font2,
        }, mt)
    end
    function mt:draw ()
        local sx, sy = 200, 17 --self:getSize()
        --container
        if self.split then sx = sx / 2 end
        setNextFillColor(layer, 0.4, 0.4, 0.4, 0.8)
        setNextStrokeColor(layer, 0.2, 0.2, 0.2, 0.8)
        setNextStrokeWidth(layer, 1)
        addBoxRounded(layer, self.x - sx/2, self.y - sy/2, sx, sy, 3)
        setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
        setNextFillColor(layer, 0, 0, 0, 1)
        addText(layer, self.font, self.tm.." ("..self.pct.."%)", self.x, self.y)
        --fill
        local fr,fg,fb
		if self.ft == "atmo" then
            fr = 0.1137
            fg = 0.8196
            fb = 0.9764
		elseif self.ft == "space" then
            fr = 0.9803
            fg = 0.7647
            fb = 0.1176
		end
        setNextFillColor(layer, fr, fg, fb, 0.8)
        local pctFixed = utils.clamp(self.pct,0,100)
        local fWidth = utils.map(pctFixed,0,100,0,sx)
        addBoxRounded(layer, self.x - sx/2, self.y - sy/2, fWidth, sy, 3)
        setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    end
    function mt:setPos (x, y)
        self.x, self.y = x, y
    end
end

if not StatsContainer then
    function StatsContainer()
        setNextFillColor(layer0, 0.3, 0, 0, 0.2)
        setNextStrokeColor(layer0, 0.7, 0.7, 0.7, 1)
        setNextStrokeWidth(layer0, 2)
        addBoxRounded(layer0, rx/1.8, ry/4.5 - 25, 420, 195, 20)
    end
end

if not StatsLine then
    local mt = {}
    mt.__index = mt
    function StatsLine(key,value,x,y,width,height)
        return setmetatable({
            key = key,
            value = value,
            x = x,
            y = y,
            width = width,
            height = height,
        }, mt)
    end

    function mt:draw()
        setNextStrokeColor(layer, 1, 1, 1, 0.2)
        addLine(layer,self.x,self.y,self.x + self.width,self.y)
        setNextStrokeColor(layer, 1, 1, 1, 0.2)
        addLine(layer,self.x + (self.width/2),self.y - 5,self.x + (self.width/2),(self.y - self.height / 4) - 5)

        setNextFillColor(layer, 1, 1, 1, 1)
        setNextTextAlign(layer, AlignH_Right, AlignV_Descender)
        --key
        addText(layer, fontStats, self.key, self.x + (self.width / 2) - 10, self.y)
        setNextFillColor(layer, 1, 1, 1, 1)
        setNextTextAlign(layer, AlignH_Left, AlignV_Descender)
        --value
        addText(layer, fontStats, self.value, self.x + (self.width / 2) + 10, self.y)
    end
end

if not DeviationInd then
    local mt = {}
    mt.__index = mt
    function DeviationInd(x,y,width,height)
        return setmetatable({
            x = x,
            y = y,
            width = width,
            height = height,
        }, mt)
    end

    function mt:draw()
        --Deviation Container
        setNextFillColor(layer, 0.3, 0, 0, 0.2)
        setNextStrokeColor(layer, 0.7, 0.7, 0.7, 1)
        setNextStrokeWidth(layer, 2)

        addBoxRounded(layer, self.x,self.y, self.width, self.height, 20)

        setDefaultFillColor (layer, Shape_Line, 0.1, 0.1, 0.1, 1)
        setDefaultStrokeColor (layer, Shape_Line, 0.7, 0.7, 0.7, 1)
        setDefaultStrokeWidth (layer, Shape_Line, 2)

        --12
        addLine(layer, self.x + (self.width / 2), self.y, self.x + (self.width / 2),self.y+50)
        addLine(layer,self.x + (self.width / 2)-15,self.y+51,self.x + (self.width / 2)+15,self.y+51)
        --9
        addLine(layer, self.x, self.y + (self.height / 2), self.x + 60,self.y + (self.height / 2))
        addLine(layer, self.x + 61,self.y + (self.height / 2)+15,self.x + 61,self.y + (self.height / 2)-15)
        --6
        addLine(layer, self.x + (self.width / 2), self.y + self.height, self.x + (self.width / 2), self.y + self.height - 50)
        addLine(layer, self.x + (self.width / 2) + 15, self.y + self.height - 51, self.x + (self.width / 2) - 15, self.y + self.height - 51)
        --3
        addLine(layer, self.x + self.width, self.y + (self.height / 2), self.x + self.width - 60, self.y + (self.height / 2))
        addLine(layer, self.x + (self.width - 61), self.y + (self.height / 2) + 15, self.x + (self.width - 61), self.y + (self.height / 2) - 15)

        --ship box
        local box_r, box_g, box_b = 0.0, 0.5, 0.1
        local tri_r, tri_g, tri_b = 0.0, 0.5, 0.1

        local box_x = self.x + (self.width / 2) - 25
        local box_y = self.y + (self.height /2) - 25
        local degrees = 0
        if stats.data then
            if stats.data.deviationVec and stats.data.deviationRot then
                --Box color
                box_g = 1.0 - utils.map(utils.clamp(math.abs(stats.data.deviation), 0, 0.3),0,0.3,0,1)
                box_r = 0.0 + utils.map(utils.clamp(math.abs(stats.data.deviation), 0, 0.3),0,0.3,0,1)
                --Box movement
                box_x = box_x + utils.clamp((stats.data.deviationVec.x * 20),-65,65)
                box_y = box_y - utils.clamp((stats.data.deviationVec.y * 20),-58,58)

                --Triangle color
                tri_g = 1.0 - utils.map(utils.clamp(math.abs(stats.data.deviationRot.x), 0, 0.1),0,0.1,0,1)
                tri_r = 0.0 + utils.map(utils.clamp(math.abs(stats.data.deviationRot.x), 0, 0.1),0,0.1,0,1)
                degrees = utils.map(-stats.data.deviationRot.x,-0.270,0.270,-90,90)
            end
        end
        setNextFillColor(statsLayer, box_r, box_g, box_b, 1)
        setNextStrokeColor(statsLayer, 0.7, 0.7, 0.7, 1)
        setNextStrokeWidth(statsLayer, 2)
        setNextRotationDegrees(statsLayer, degrees)
        addBoxRounded(statsLayer, box_x, box_y, 50,50,3)

        setNextFillColor(statsLayer, tri_r, tri_g, tri_b, 1)
        setNextStrokeColor(statsLayer, 0, 0, 0, 1)
        setNextStrokeWidth(statsLayer, 1)
        setNextRotationDegrees(statsLayer, degrees)
        addTriangle(statsLayer,box_x+25,box_y+15, box_x+10,box_y+35, box_x+40,box_y+35)
    end
end

if not settingsBkg then
    function settingsBkg()
        setNextFillColor(settingsLayer, 0.1, 0.1, 0.1, 0.8)
        setNextStrokeColor(settingsLayer, 1, 1, 1, 0.6)
        setNextStrokeWidth(settingsLayer, 2)
        addBoxRounded(settingsLayer,20,ry/6,rx-40,ry/2+160,20)
    end
end

if not rtbSettingsText then
    function rtbSettingsText()
        local title = 'Initial Configuration'
        local sx, sy = getTextBounds(eStopFont, title)
        setNextTextAlign(settingsLayer, AlignH_Center, AlignV_Top)
        addText(settingsLayer, eStopFont, title, rx/2, 150)

        local txtLines = {
            'Before you can use your elevator, you will need to set the base position using the',
            '"Set Base" button below.  The elevator will always return to this point when you press',
            'the "RTB" button, so make sure you have it positioned where it will live permanently.',
            'If you ever move your elevator, you can return to this screen to reset the position',
            'at any time by clicking on the "Set Base" button in the lower left-hand corner.',
            'You can also use the ‘setbase’ Lua command at any time to reset your base location.',
        }
        local spacing = 0

        for i = 1, #txtLines do
            local tsx, tsy = getTextBounds(font, txtLines[i])
            setNextTextAlign(settingsLayer, AlignH_Center, AlignV_Top)
            addText(settingsLayer, font, txtLines[i], rx/2, 200 + spacing)
            spacing = spacing + tsy + 5
        end
    end
end

if not settingsText then
    function settingsText()
        local title = 'Coming Soon™'
        setNextTextAlign(settingsLayer, AlignH_Center, AlignV_Top)
        addText(settingsLayer, eStopFont, title, rx/2, ry/2)
    end
end

function drawFree (elems)
    for _, v in ipairs(elems) do v:draw() end
end

function drawListV (elems, x, y)
    for _, v in ipairs(elems) do
        local sx, sy = v:getSize()
        v:setPos(x, y)
        v:draw()
        y = y + sy + 4
    end
end

function drawState()
    local text = string.format('Elevator State: %s', stats.data.state or 'idle')
    setNextFillColor(layer, 1, 1, 1, 1)
    setNextTextAlign(layer, AlignH_Left, AlignV_Descender)
    addText(layer, statusFont, text, 16, ry - 8)
end

function drawTitle ()
    local font = loadFont('FiraMono-Bold', 46)
    setNextTextAlign(layer, AlignH_Center, AlignV_Top)
    addText(layer, font, config.elevatorName, rx/2, 32)
end

--------------------------------------------------------------------------------

-- BUTTONS
local padding = 10
local mcColor = '#4e025c'
local eStopColor = '#7a0101'
if config.manualControl then mcColor = '#3c00b3' end
if config.estop then eStopColor = '#ff0000' end
local buttons = {
    ButtonQuad('RTB',   135, 135, function() config.targetAlt = config.rtb outputMsg = serialize(config) end,false,'#006603'),
    ButtonQuad('+10m',  135, 185, function()
        if not config.targetAlt or config.targetAlt == 0 then
			config.delta = 10
        else
            config.targetAlt = config.targetAlt + 10
        end
        outputMsg = serialize(config)
		config.delta = nil; end, false,'#0b0578'),
    ButtonQuad('-10m',  135, 235, function()
        if not config.targetAlt or config.targetAlt == 0 then
			config.delta = -10
        else
            config.targetAlt = config.targetAlt - 10
        end
        outputMsg = serialize(config)
		config.delta = nil; end, false,'#0b0578'),
    ButtonQuad('Manual Control', 135, 285,
		function() config.manualControl = not config.manualControl
			config.targetAlt = 0; outputMsg = serialize(config)
			logMessage("Manual Control: "..outputMsg) end,false,mcColor),
    GenericButton('Emergency', 'Stop', eStopFont, 135, 400, 185, 165,
		eStopColor, function() config.estop = not config.estop outputMsg = serialize(config) end),
    GenericButton('Set RTB','',font3,135,515,185,30,'#006960',function() config.setBaseActive = true end),
    GenericButton('Settings','',font3,360,515,185,30,'#006960',function() config.settingsActive = true end),
}

local rtbButtons = {
    ButtonQuad('Set Base',rx/2-112.5, ry-155,
		function() config.setBaseReq = true config.setBaseActive = false outputMsg = serialize(config) end,
		false,'#006603',settingsLayer),
    ButtonQuad('Cancel',rx/2+112.5, ry-155,
		function() config.setBaseActive = false end,
		true,'#450101',settingsLayer),
}

--logMessage(stats.data.target)
local spacing = 0
--Floors
if config.floors ~= nil then
    for k, v in spairs(config.floors) do
        local color = "#450101"
        --logMessage(v.." / "..stats.data.target)
        if tostring(v) == tostring(config.targetAlt) then
            color = "#7a3907"
        end
        local button = ButtonQuad(mToKm(v), 360, 135+spacing, function() config.targetAlt = v; outputMsg = serialize(config) end,true,color)
        table.insert(buttons,button)
        spacing = spacing + 50
    end
end

-- STATS
local statYPos = ry/4.5 + 5
local statSpacing = 22
local statsDraw = {}

if stats.data then
	--StatsLine(key,value,x,y,width,height)
	table.insert(statsDraw,StatsLine('Elevation',mToKm(stats.data.elevation, 0.001),585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Velocity',utils.round((stats.data.velocity * 3.6), 0.01)..' km/h',585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Mass',massConvert(stats.data.mass,0.01),585,statYPos,  385,50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Gravity',utils.round(stats.data.gravity,0.001)..' m/s²',585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Target Altitude',mToKm(stats.data.target),585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Target Distance',mToKm(stats.data.target_dist,0.001),585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Brake Distance',mToKm(stats.data.brake_dist),585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
	table.insert(statsDraw,StatsLine('Deviation',utils.round(stats.data.deviation,0.00001)..' m',585,statYPos, 385, 50)) statYPos = statYPos + statSpacing
end

local fgAtmo = {}
local fgSpace = {}
local topY = 130
if fuelAtmo.tanks ~= nil and #fuelAtmo.tanks > 0 then
    local aSpacing = 200

    if #fuelAtmo.tanks <= 11 then
        for k,v in pairs(fuelAtmo.tanks) do
            local fg = FuelGauge("", rx/1.8+100, topY + aSpacing, "atmo", v.tm, v.pct,false)
            table.insert( fgAtmo, fg )
            aSpacing = aSpacing + 22
        end
    else
        local lSpacing = aSpacing
        local rSpacing = aSpacing
        for i = 1, #fuelAtmo.tanks, 1 do
            if i <= 10 then
                local fg = FuelGauge("", rx/1.8 + 50, topY + lSpacing, "atmo", fuelAtmo.tanks[i].tm, fuelAtmo.tanks[i].pct,true,smallFuelFont)
                table.insert( fgAtmo, fg )
                lSpacing = lSpacing + 22
            else
                local fg = FuelGauge("", rx/1.8 + 155, topY + rSpacing, "atmo", fuelAtmo.tanks[i].tm, fuelAtmo.tanks[i].pct,true,smallFuelFont)
                table.insert( fgAtmo, fg )
                rSpacing = rSpacing + 22
            end
        end
    end
end
if fuelSpace.tanks ~= nil and #fuelSpace.tanks > 0 then
    local aSpacing = 200
    if #fuelSpace.tanks < 10 then
		local sSpacing = 200
		for k,v in spairs(fuelSpace.tanks) do
			local fg = FuelGauge("", rx/1.8+315, topY + sSpacing, "space", v.tm, v.pct)
			table.insert( fgSpace, fg )
			sSpacing = sSpacing + 22
		end
    else
        local lSpacing = aSpacing
        local rSpacing = aSpacing
        for i = 1, #fuelSpace.tanks, 1 do
            if i <= 10 then
                local fg = FuelGauge("", rx/1.8 + 265, 115 + lSpacing, "space", fuelSpace.tanks[i].tm, fuelSpace.tanks[i].pct,true,smallFuelFont)
                table.insert( fgSpace, fg )
                lSpacing = lSpacing + 22
            else
                local fg = FuelGauge("", rx/1.8 + 370, 115 + rSpacing, "space", fuelSpace.tanks[i].tm, fuelSpace.tanks[i].pct,true,smallFuelFont)
                table.insert( fgSpace, fg )
                rSpacing = rSpacing + 22
            end
        end
    end
end
if config.shutDown then
    config.setBaseActive = false
    config.settingsActive = false
    addImage(layer_spash, stCover, 0,0,rx,ry)
end
if config.elevatorName then
    setNextTextAlign(layer, AlignH_Center, AlignV_Top)
    addText(layer, titleFont, config.elevatorName, rx/2, 26)
end
if not config.settingsActive and not config.setBaseActive and not config.shutDown then
    bkGround()
    elevAnimation()
    drawFree(buttons)
    drawFree(fgAtmo)
    drawFree(fgSpace)
    if stats.data ~= nil then
        StatsContainer()
        if statsDraw ~= nil then drawFree(statsDraw) end
        drawState()
        DeviationInd(265, 318, 185, 165):draw()
        --if stats.data.deviationRot then logMessage(tostring(vec3(stats.data.deviationRot))) end
    end

    --rslib.drawRenderCost()
elseif config.setBaseActive then
    --SetBase page
    settingsBkg()
    rtbSettingsText()
    drawFree(rtbButtons)
elseif config.settingsActive then
    settingsBkg()
    settingsText()
    GenericButton('Back','',font3,rx/2,ry/2+100,185,30,'#006960',function() config.settingsActive = false end, settingsLayer):draw()
    --settings page
end

requestAnimationFrame(1)
if outputMsg == "" then
    outputMsg = "ack"
end
setOutput(outputMsg)