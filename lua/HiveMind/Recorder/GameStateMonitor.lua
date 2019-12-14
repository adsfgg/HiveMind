--[[
    Class to monitor the GameState.
]]

class 'GameStateMonitor'

local lastState

function GameStateMonitor:CheckGameState()
    local currentState = GetGamerules():GetGameState()
    if not lastState then
        lastState = currentState
        return false
    end

    if lastState ~= kGameState.Started then
        self:CheckForGameStart(currentState)
    end

    self:CheckForGameEnd(currentState)

    lastState = currentState

    return currentState == kGameState.Started
end

function GameStateMonitor:CheckForGameStart(currentState)
    if lastState ~= currentState then
        if currentState == kGameState.Countdown then
            self:OnCountdownStart()
        elseif currentState == kGameState.Started then
            self:OnGameStart()
        end
    end
end

function GameStateMonitor:CheckForGameEnd(currentState)
    if lastState ~= currentState then
        if currentState == kGameState.Team1Won or currentState == kGameState.Team2Won or currentState == kGameState.Draw then
            self:OnGameEnd()
            return true
        end
    end
    return false
end

function GameStateMonitor:OnCountdownStart()
    HiveMindRecorder:OnCountdownStart()
end

function GameStateMonitor:OnGameStart()
    HiveMindRecorder:OnGameStart()
end

function GameStateMonitor:OnGameEnd()
    HiveMindRecorder:OnGameEnd()
end
