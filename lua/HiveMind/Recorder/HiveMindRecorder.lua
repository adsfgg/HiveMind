if not Server then return end

Script.Load("lua/HiveMind/Recorder/GameStateMonitor.lua");

class 'HiveMindRecorder'

local gameStateMonitor = nil

function HiveMindRecorder:Initialize()
    gameStateMonitor = GameStateMonitor()
end

function HiveMindRecorder:OnCountdownStart()
    HiveMindGlobals:SendChatMessage("Countdown start!")
end

function HiveMindRecorder:OnCountdownEnd()
    HiveMindGlobals:SendChatMessage("Countdown end!")
end

function HiveMindRecorder:OnGameStart()
    HiveMindGlobals:SendChatMessage("Game start!")
end

function HiveMindRecorder:OnGameEnd()
    HiveMindGlobals:SendChatMessage("Game end!")
end

local function OnUpdateServer()
    if gameStateMonitor:CheckGameState() then
        --
    end
end

Event.Hook("UpdateServer", OnUpdateServer)