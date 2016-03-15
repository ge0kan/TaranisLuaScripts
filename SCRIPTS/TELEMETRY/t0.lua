	--[[
	--]]
local rssiName = "RSSI"
local batteryVoltageName = "Batt"
local cellNumber = 4
local cellVoltageDelta = 0.3





-- help methods and vars ---------------------------------------------------------------------------
local PreviousTime = {}
local startPlayTime = {}

local function getTelemetryId(name)
	field = getFieldInfo(name)
	if field then 
		return field.id 
	end
	return -1
end

local function playDecimalNumber(value, unit)
	if unit == nil then 
		unit = 0
	end
	playNumber(value * 10, unit, PREC1)
end

local function playRepeatValue(value, unit, period, key)
	local minCycleDuration = 2
	local timeNow = getTime()

	if ((PreviousTime[key] == nil) or (timeNow - PreviousTime[key]) > period * 100) and 
		((startPlayTime[key] == nil) or (timeNow - startPlayTime[key]) > minCycleDuration * 100) then
	    PreviousTime[key] = timeNow
		startPlayTime[key] = timeNow
		playDecimalNumber(value, unit)
	end
end

local function resetPlayValuePeriod(key)
	PreviousTime[key] = 0
end

local function formatFloat(value, digitsAfterPoint)
	local ratio = 10 ^ digitsAfterPoint
	return math.floor((value) * ratio + 0.5) / ratio 
end
-- end help methods and vars ------------------------------------------------------------------------

local batteryVoltageId
local batteryVoltage
local rssiId
local rssi
local telemetryLost = true
local cellVoltage = 0
local cellVoltagePrevious = 0
local newTelemetrySession = true
local cellVoltageLast = 0
local newBatteryEvent = false
local telemetryStateChangeEvent = false

local function init() -- init is called once when model is loaded
	rssiId = getTelemetryId(rssiName)
	batteryVoltageId = getTelemetryId(batteryVoltageName)
end

local function background() -- background is called periodically when screen is not visible
	rssi = getValue(rssiId)
	
	if telemetryLost ~= (rssi == 0) then
		telemetryLost = rssi == 0
		telemetryStateChangeEvent = true
	end

	batteryVoltage = getValue(batteryVoltageId)
	
	cellVoltagePrevious = cellVoltage
	cellVoltage = batteryVoltage / cellNumber
	if cellVoltage == 0 and cellVoltagePrevious > 0 then
		cellVoltageLast = cellVoltagePrevious
	end
	
	if cellVoltagePrevious == 0 and cellVoltage > 0 and cellVoltageLast > 0 then
		newTelemetrySession = true
	end
	
	if newTelemetrySession and ((cellVoltage > 0 and math.abs(cellVoltage - cellVoltageLast) > cellVoltageDelta)) then
		newBatteryEvent = true
		newTelemetrySession = false
	end
	
	model.setGlobalVariable(0, 0, 0)
	if newBatteryEvent then
		newBatteryEvent = false;
		--playNumber(cellNumber, 0) -- cells
		--playFile("oops.wav") -- new battery installed
		playTone(1000, 200, 100)
		playTone(1000, 200, 100)
		
		playTone(1000, 200, 100)
		playTone(1000, 200, 100)
		--playDecimalNumber(cellVoltage, 1)
		
		model.setGlobalVariable(0, 0, 1)
	end
		
	if telemetryStateChangeEvent then
		telemetryStateChangeEvent = false
		if telemetryLost then
			--playTone(300, 100, 100)
		else
			--playTone(800, 100, 100)
		end
	end
end

local function run(event) -- run is called periodically when screen is visible
	background() -- run typically calls background to start
    lcd.clear()
	
	lcd.drawText(15, 25, "korvin8 telemetry screen 3", MIDSIZE)
	lcd.drawText(20, 40, "cell:")
	lcd.drawText(50, 40, formatFloat(cellVoltage, 2))
	lcd.drawText(70, 40, "last")
	lcd.drawText(100, 40, formatFloat(cellVoltageLast, 2))



	lcd.drawText(20, 50, "RSSI:")
	lcd.drawText(50, 50, rssi)
	lcd.drawRectangle(0, 0, 212, 64, GREY_DEFAULT)
	if telemetryLost then
		lcd.drawText(70, 50, "telemetryLost")
	end
	
	if event == EVT_EXIT_BREAK then
        lastKey = "EVT_EXIT_BREAK"
        killEvents(event)
      elseif event == EVT_MENU_BREAK then
        lastKey = "EVT_MENU_BREAK"
        killEvents(event)
      elseif event == EVT_PAGE_BREAK then
        lastKey = "EVT_PAGE_BREAK"
         killEvents(event)
      elseif event == EVT_PAGE_LONG then
        lastKey = "EVT_PAGE_LONG"
        killEvents(event)
      elseif event == EVT_ENTER_BREAK then
        lastKey = "EVT_ENTER_BREAK"
        killEvents(event)
      elseif event == EVT_ENTER_LONG then
        lastKey = "EVT_ENTER_LONG"
        killEvents(event)
      elseif event == EVT_PLUS_BREAK then
        lastKey = "EVT_PLUS_BREAK"
        killEvents(event)
      elseif event == EVT_MINUS_BREAK then
        lastKey = "EVT_MINUS_BREAK"
        killEvents(event)
      elseif event == EVT_PLUS_RPT then
        lastKey = "EVT_PLUS_RPT"
        killEvents(event)
      elseif event == EVT_MINUS_RPT then
        lastKey = "EVT_MINUS_RPT"
        killEvents(event)
      elseif event == EVT_PLUS_FIRST then
        lastKey = "EVT_PLUS_FIRST"
        killEvents(event)
      elseif event == EVT_MINUS_FIRST then
        lastKey = "EVT_MINUS_FIRST"
        killEvents(event)
      end
      lcd.clear()
      lcd.drawText(10, 20, "idx : ", 0)
      lcd.drawText(lcd.getLastPos(), 20, lastKey, 0)
	
	return 0
end
















return { run=run, background=background, init=init  }