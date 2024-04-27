--@class Serializer
local concat = table.concat
local sFormat = string.format
local function internalSerialize(v,tC,t) local check = type(v) local intSerial=internalSerialize if check=='table' then t[tC]='{' local tempC=tC+1 if #v==0 then for k,e in pairs(v) do if type(k)~='number' then t[tempC]=k t[tempC+1]='=' tempC=tempC+2 else t[tempC]='[' t[tempC+1]=k t[tempC+2]=']=' tempC=tempC+3 end tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end else for k,e in pairs(v) do tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end end if tempC==(tC+1) then t[tempC]='}' return tempC+1 else t[tempC-1]='}' return tempC end elseif check=='string' then t[tC]=sFormat("%q",v) return tC+1 elseif check=='number' then t[tC]=tostring(v) return tC+1 else t[tC]=v and 'true' or 'false' return tC+1 end end
function serialize(v) local t={} local tC=1 local check = type(v) local intSerial=internalSerialize if check=='table' then t[tC]='{' tC=tC+1 local tempC=tC if #v==0 then for k,e in pairs(v) do if type(k)~='number' then t[tempC]=k t[tempC+1]='=' tempC=tempC+2 else t[tempC]='[' t[tempC+1]=k t[tempC+2]=']=' tempC=tempC+3 end tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end else for k,e in pairs(v) do tempC=intSerial(e,tempC,t) t[tempC]=',' tempC=tempC+1 end end if tempC==tC then t[tempC]='}' else t[tempC-1]='}' end elseif check=='string' then t[tC]=sFormat("%q",v) elseif check=='number' then t[tC]=tostring(v) else t[tC]=v and 'true' or 'false' end return concat(t) end
function deserialize(s) local f=load('t='..s) f() return t end
function tryDeserialize(s) local f=load('t='..s) if f then f() return true, t else return false end end
function mToKm(n)
    if n == nil then return "nan" end
    if n >= 1000 then
        return round2((n / 1000),2) .. " km"
    end
    return round2(n,2) .. " m"
end
function round2(num, numDecimalPlaces)
    if num ~= nil then
    	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num)) or 0
    end
	return 0
end

config = {
    dataType = "config",
    floors = {
        floor1 = 0,
        floor2 = 0,
        floor3 = 0,
        floor4 = 0,
    },
    elevatorName = construct.getName(),
    rtb = 0,
    targetAlt = 0,
    estop = false,
    settingsActive = false,
    setBaseActive = false,
    setBaseReq = false,
    manualControl = false,
    destination = nil,
    shutDown = false,
    updateReq = false,
}

stats = {
	dataType = "stats",
	data = {
		elevation = 0,
		target = config.targetAlt,
		velocity = 0,
		mass = 0,
		gravity = 0,
		target_dist = 0,
		brake_dist = 0,
		deviation = 0,
		deviationVec = vec3(0,0,0),
		deviationRot = vec3(0,0,0),
		state = "Idle",
		delta = 0
	}
}
fuelAtmo = {
    dataType = "fuelAtmo",
    tanks = {}
}

fuelSpace = {
    dataType = "fuelSpace",
    tanks = {}
}

function fuelTank(tm,pct)
    local mt = {}
    mt.__index = mt
    return setmetatable({
            tm = tm,
            pct = pct
        },mt)
end