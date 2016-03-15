-- HelperClass --------------------------------------------------------------------------------------------------
HelperClass = {}
HelperClass.__index = HelperClass

setmetatable(HelperClass, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function HelperClass.new()
	local self = setmetatable({}, HelperClass)
	return self
end

function HelperClass:playDecimalNumber(value, unit)
	playNumber(value * 10, unit, PREC1)
end

function HelperClass:formatFloat(value, digitsAfterPoint)
	local ratio = 10 ^ digitsAfterPoint
	return math.floor(value * ratio + 0.5) / ratio 
end

function HelperClass:getFieldId(name)
	field = getFieldInfo(name)
	if field then 
		return field.id 
	end
	return -1
end

function HelperClass:getValueByName(name)
	return getValue(HelperClass:getFieldId(name))
end
-- HelperClass --------------------------------------------------------------------------------------------------

-- PlayInLoopClass --------------------------------------------------------------------------------------------------
PlayInLoopClass = {}
PlayInLoopClass.__index = PlayInLoopClass

setmetatable(PlayInLoopClass, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function PlayInLoopClass.new()
	local self = setmetatable({}, PlayInLoopClass)
	
	self.previousTime = nil
	self.startPlayTime = nil
	self.minCycleDuration = 2
	self.helper = HelperClass()
	
	return self
end

function PlayInLoopClass:playNumber(value, unit, period)
	local timeNow = getTime()

	if ((self.previousTime == nil) or (timeNow - self.previousTime) > period * 100) and 
		((self.startPlayTime == nil) or (timeNow - self.startPlayTime) > self.minCycleDuration * 100) then
	    self.previousTime = timeNow
		self.startPlayTime = timeNow
		self.helper:playDecimalNumber(value, unit)
	end
end

function PlayInLoopClass:resetPlayTimer()
	self.previousTime = nil
end
-- PlayInLoopClass --------------------------------------------------------------------------------------------------

-- TelemetryMonitorClass --------------------------------------------------------------------------------------------------
TelemetryMonitorClass = {}
TelemetryMonitorClass.__index = TelemetryMonitorClass

setmetatable(TelemetryMonitorClass, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TelemetryMonitorClass.new(delta, dropBoundary)
	local self = setmetatable({}, TelemetryMonitorClass)
	
	self.delta = delta
	self.dropBoundary = dropBoundary
	self.value = 0 
	self.previousValue = 0
	self.lastValue = 0
	self.newSession = true
	
	return self
end

function TelemetryMonitorClass:onValueChangeAfterDrop(telemetryValue)
	local isChange = false
	
	self.previousValue = self.value
	self.value = telemetryValue
	if self.value <= self.dropBoundary and self.previousValue > self.dropBoundary then
		self.lastValue = self.previousValue
	end
	
	if self.previousValue <= self.dropBoundary and 
	self.value > self.dropBoundary and 
	self.lastValue > self.dropBoundary then
		self.newSession = true
	end
	
	if self.newSession and 
	(self.value > self.dropBoundary and math.abs(self.value - self.lastValue) >= self.delta) then
		isChange = true
		self.newSession = false
	end
	
	return isChange
end
-- TelemetryMonitorClass --------------------------------------------------------------------------------------------------

-- TimerClass --------------------------------------------------------------------------------------------------
TimerClass = {}
TimerClass.__index = TimerClass

setmetatable(TimerClass, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TimerClass.new()
	local self = setmetatable({}, TimerClass)
	
	self.period = nil
	self.previousTime = nil
	
	return self
end

function TimerClass:start(period)
	self.period = period
	if self.previousTime == nil then
		self.previousTime = getTime()
	end
end

function TimerClass:restart(period)
	self.period = period
	self.previousTime = getTime()
end

function TimerClass:stop()
	self.previousTime = nil
end

function TimerClass:onElapsed()
	local isLoop = false
	if self.previousTime ~= nil and (getTime() - self.previousTime) >= self.period * 100 then
		self.previousTime = nil
		isLoop = true
	end
	return isLoop
end

-- TimerClass --------------------------------------------------------------------------------------------------

local inputs = { 
	{"Value", SOURCE },
 }

local outputs = { 
	"Val",
}
local function run(value)
	return value * 10.24
end

return { run=run, output=outputs, input=inputs }