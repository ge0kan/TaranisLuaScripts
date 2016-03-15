local inputs = { 
	{"RSSI", SOURCE },
	{"WarnMax", VALUE, 12, 99, 55 },
	{"WarnMin", VALUE, 12, 99, 45 },
	{"WarnRepeat", VALUE, 3, 60, 5 },
 }

local outputs = { 
	"RSSI",
}

local playAfterTelemetryRecovery = false
local silentDelayAfterTelemetryRecovered = 2

local helper = HelperClass()
local timer = TimerClass()
local playRssiWarning = PlayInLoopClass()

local telemetryOk = false
local telemetryChanged = false
local waitTelemetrySilent = false

local function run(rssi, rssiWarningMax, rssiWarningMin, rssiWarningRepeatPeriod)
	if telemetryOk == (rssi == 0) then
		telemetryOk = rssi ~= 0
		telemetryChanged = true
	end
		
	if telemetryChanged and telemetryOk then
		timer:start(silentDelayAfterTelemetryRecovered)
		waitTelemetrySilent = true
		telemetryChanged = false
	end
	
	if telemetryOk then
		if timer:onElapsed() then
			if playAfterTelemetryRecovery then
				helper:playDecimalNumber(rssi, 16)
			end
			waitTelemetrySilent = false
		end
		
		if not waitTelemetrySilent then
			if rssiWarningMin <= rssi and rssi <= rssiWarningMax then 
				playRssiWarning:playNumber(rssi, 16, rssiWarningRepeatPeriod)
			else
				playRssiWarning:resetPlayTimer()
			end
		end
	end

	return rssi * 10.24
end

return { init=init, run=run, output=outputs, input=inputs }