local inputs = { 
	{"ArmSwitch", SOURCE }, 
	{"Throttle", SOURCE },
	{"RSSI", SOURCE },
	{"ThrArmPos", VALUE, - 10, 10, -10 }, -- -10 == -10*102.4 == -1024
	{"ThrArmRange", VALUE, 0, 128, 10 }, -- minVal == -1024-(10/2) == -1029 -- maxVal == -1024+(10/2) == 1019
	{"SwchArmVal", VALUE, - 1, 1, 0 },
	{"OffDelay5s", VALUE, 0, 128, 2 }, -- 2 == 2*5sec == 10 sec
 }

local outputs = { 
	"Arm", -- 0 - diarmed, 1 - armed
	"Warn",-- 1 - warning, 0 - ok
	"Log", -- 1 logging, not logging
}

local isArmed = 0
local isLogging = 0
local isThrottleWarning = 0
local timer = TimerClass()

local function run(armingSwitch, throttle, rssi, throttleArmPosition, armRange, switchArmValue, offDelay)
	throttleMax = throttleArmPosition * 102.4 + armRange / 2;
	throttleMin = throttleArmPosition * 102.4 - armRange / 2;
	switchArmValue = switchArmValue * 1024
	offDelay = offDelay * 5
	
	if isArmed == 0 then
		if armingSwitch == switchArmValue then
			if throttleMin <= throttle and throttle <= throttleMax  then
				isThrottleWarning = 0
				isArmed = 1
			elseif isThrottleWarning == 0 then
				isThrottleWarning = 1
			end
		elseif isThrottleWarning == 1 then
			isThrottleWarning = 0
		end
	elseif armingSwitch ~= switchArmValue then
		isArmed = 0
	end
	
	if rssi > 0 or isArmed == 1 then
		isLogging = 1
		timer:stop()
	elseif isLogging == 1 then
		timer:start(offDelay)
		if timer:onElapsed() then
			isLogging = 0
		end
	end
	
	return isArmed * 10.24, isThrottleWarning * 10.24, isLogging * 10.24
end

return { init=init, run=run, output=outputs, input=inputs }