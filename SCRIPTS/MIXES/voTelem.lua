local inputs = { 
	{"CellNumber", VALUE, 1, 12, 4 },
	{"WarnVolt", VALUE, 300, 420, 345 },
	{"CritVolt", VALUE, 300, 420, 335 },
	{"WarnVoltagePeriod", VALUE, 3, 60, 20 },
	{"CritVoltagePeriod", VALUE, 3, 60, 4 },
	{"WarnMax", VALUE, 12, 99, 55 },
	{"WarnMin", VALUE, 12, 99, 45 },
	{"WarnRSSIPeriod", VALUE, 3, 60, 5 },
 }

local outputs = { 
	"Cell",
	"RSSI"
}

local batteryName = "Batt"
local rssiName = "RSSI"
local manualPlaySwitchName = "sb"
local manualPlaySwitchVoltageValue = 0
local manualPlaySwitchRssiValue = 1024
local errorMaxVoltage = 4.2
local errorLowVoltage = 2.5
local playVoltageAfterTelemetryRecovery = true
local playRssiAfterTelemetryRecovery = false
local silentDelayAfterTelemetryRecovered = 2
local manualRssiPeriod = 4
local manualVoltagePeriod = 4

-----------------------------------------------------------------------------------------------------------------------------------------------------

local function getCellStatus(cellVoltage, errorMaxVoltage, warningVoltage, criticalVoltage, errorLowVoltage)
	local cellStatus = 0
	if cellVoltage > errorMaxVoltage then
		cellStatus = -2 -- error, voltage is too high, incorrect number of cells (to low)
	elseif cellVoltage > warningVoltage and cellVoltage <= errorMaxVoltage then
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

local batteryId
local rssiId

local helper = HelperClass()
local timer = TimerClass()
local playVoltageWarning = PlayInLoopClass()
local playVoltageCritical = PlayInLoopClass()
local playVoltageManual = PlayInLoopClass()
local playRssiWarning = PlayInLoopClass()
local playRssiManual = PlayInLoopClass()

local telemetryOk = false
local telemetryChanged = false
local waitTelemetrySilent = false

local function init()
	batteryId = helper:getFieldId(batteryName)
	rssiId = helper:getFieldId(rssiName)
end

local function run(cellNumber, warningVoltage, criticalVoltage, warningVoltagePeriod, criticalVoltagePeriod, warningRssiMax, warningRssiMin, warningRssiPeriod)
	local battery = getValue(batteryId)
	local rssi = getValue(rssiId)
	local manualPlaySwitch = getValue(manualPlaySwitchName)

	if telemetryOk == (rssi == 0) then
		telemetryOk = rssi ~= 0
		telemetryChanged = true
	end
	
	if telemetryChanged and telemetryOk then
		timer:restart(silentDelayAfterTelemetryRecovered)
		waitTelemetrySilent = true
		telemetryChanged = false
	end
	
	local cellVoltage = battery / cellNumber
	
	if telemetryOk then
		if timer:onElapsed() then
			if playVoltageAfterTelemetryRecovery then
				helper:playDecimalNumber(cellVoltage, 1)
			end
			if playRssiAfterTelemetryRecovery then
				helper:playDecimalNumber(rssi, 16)
			end
			waitTelemetrySilent = false
		end
	
		if not waitTelemetrySilent then 
			if manualPlaySwitch == manualPlaySwitchVoltageValue then
				playVoltageManual:playNumber(cellVoltage, 1, manualVoltagePeriod)
			else
				playVoltageManual:resetPlayTimer()
				
				warningVoltage = warningVoltage / 100;
				criticalVoltage = criticalVoltage / 100;
				
				local cellStatus = getCellStatus(cellVoltage, errorMaxVoltage, warningVoltage, criticalVoltage, errorLowVoltage)

				if cellStatus == 1 then
					playVoltageWarning:playNumber(cellVoltage, 1, warningVoltagePeriod)
				end
				if cellStatus == 2 or cellStatus == -1 or cellStatus == -2 then
					playVoltageCritical:playNumber(cellVoltage, 1, criticalVoltagePeriod)
				else
					playVoltageCritical:resetPlayTimer()
				end
					
				if warningRssiMin <= rssi and rssi <= warningRssiMax then 
					playRssiWarning:playNumber(rssi, 16, warningRssiPeriod)
				end
				
				if manualPlaySwitch == manualPlaySwitchRssiValue then
					playRssiManual:playNumber(rssi, 16, manualRssiPeriod)
				else
					playRssiManual:resetPlayTimer()
				end
				
			end
		end
	end

	return cellVoltage * 10.24, rssi * 10.24
end

return { init=init, run=run, output=outputs, input=inputs }