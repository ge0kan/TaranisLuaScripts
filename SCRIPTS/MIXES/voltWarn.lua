local inputs = { 
	{"PlaySwitch", SOURCE},
	{"RSSI", SOURCE },
	{"Batt", SOURCE },
	{"CellNumber", VALUE, 1, 12, 4 },
	{"WarnVolt", VALUE, 300, 420, 345 },
	{"CritVolt", VALUE, 300, 420, 335 },
	{"WarnRepeatTm", VALUE, 3, 60, 20 },
	{"CritRepeatTm", VALUE, 3, 60, 4 },
 }

local outputs = { 
	"Cell",
}

local maxVoltage = 4.2
local errorLowVoltage = 2.5
local playAfterTelemetryRecovery = true
local silentDelayAfterTelemetryRecovered = 2


local helper = HelperClass()
local timer = TimerClass()
local playVoltageWarning = PlayInLoopClass()
local playVoltageCritical = PlayInLoopClass()
local playVoltageManual = PlayInLoopClass()
local playRssiWarning = PlayInLoopClass()

local function getCellStatus(cellVoltage, maxVoltage, warningVoltage, criticalVoltage, errorLowVoltage)
	local cellStatus = 0

	if cellVoltage > maxVoltage then
		cellStatus = -2 -- error, voltage is too high, incorrect number of cells (to low)
	elseif cellVoltage > warningVoltage and cellVoltage <= maxVoltage then
		cellStatus = 0 -- do nothing, voltage is in normal working range
	elseif cellVoltage > criticalVoltage and cellVoltage <= warningVoltage then
		cellStatus = 1 -- warning, low voltage
	elseif cellVoltage > errorLowVoltage and cellVoltage <= criticalVoltage then
		cellStatus = 2 -- critical worning, critical low voltage
	elseif cellVoltage <= errorLowVoltage then
		cellStatus = -1 -- error, voltage is too low, incorrect number of cells (to high) or damage battery
	end
	
	return cellStatus
end

local telemetryOk = false
local telemetryChanged = false
local waitTelemetrySilent = false

local function run(playTelemetrySwitch, rssi, battVoltage, cellNumber, warningVoltage, criticalVoltage, warningRepeatPeriod, criticalRepeatPeriod)
	if telemetryOk == (rssi == 0) then
		telemetryOk = rssi ~= 0
		telemetryChanged = true
	end
	
	local cellVoltage = battVoltage / cellNumber
	
	if telemetryChanged and telemetryOk then
		timer:restart(silentDelayAfterTelemetryRecovered)
		waitTelemetrySilent = true
		telemetryChanged = false
	end
	
	if telemetryOk then
	
		if timer:onElapsed() then
			if playAfterTelemetryRecovery then
				helper:playDecimalNumber(cellVoltage, 1)
			end
			waitTelemetrySilent = false
		end
	
		if not waitTelemetrySilent then 
			if playTelemetrySwitch == 0 then
				playVoltageManual:playNumber(cellVoltage, 1, criticalRepeatPeriod)
			else
				playVoltageManual:resetPlayTimer()
				warningVoltage = warningVoltage / 100;
				criticalVoltage = criticalVoltage / 100;
				local cellStatus = getCellStatus(cellVoltage, maxVoltage, warningVoltage, criticalVoltage, errorLowVoltage)

				if cellStatus == 1 then
					playVoltageWarning:playNumber(cellVoltage, 1, warningRepeatPeriod)
				end
				if cellStatus == 2 or cellStatus == -1 or cellStatus == -2 then
					playVoltageCritical:playNumber(cellVoltage, 1, criticalRepeatPeriod)
				else
					playVoltageCritical:resetPlayTimer()
				end
				
				if playTelemetrySwitch == 1024 then
					playRssiWarning:playNumber(rssi, 16, criticalRepeatPeriod)
				else
					playRssiWarning:resetPlayTimer()
				end
				
			end
		end
	end

	return cellVoltage * 10.24
end

return { init=init, run=run, output=outputs, input=inputs }