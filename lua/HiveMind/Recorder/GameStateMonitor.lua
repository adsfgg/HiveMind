--[[
    Class to monitor the GameState.
]]

class 'GameStateMonitor'

GameStateMonitor.lastState = nil
GameStateMonitor.countdownStarted = false
GameStateMonitor.recorder = nil

function GameStateMonitor:Initialize(recorder)
    assert(recorder ~= nil)

    self.recorder = recorder
end

function GameStateMonitor:CheckGameState()
    local currentState = GetGamerules():GetGameState()
    if not self.lastState then
        self.lastState = currentState
        return false
    end

    if self.lastState ~= kGameState.Started then
        self:CheckForGameStart(currentState)
    end

    self:CheckForGameEnd(currentState)

    self.lastState = currentState

    return currentState == kGameState.Started
end

function GameStateMonitor:CheckForGameStart(currentState)
    if self.lastState ~= currentState then
        if currentState == kGameState.Countdown then
            self:OnCountdownStart()
        elseif currentState == kGameState.Started then
            self:OnGameStart()
        end
    end
end

function GameStateMonitor:CheckForGameEnd(currentState)
    if self.lastState ~= currentState then
        if currentState == kGameState.Team1Won or currentState == kGameState.Team2Won or currentState == kGameState.Draw then
            self:OnGameEnd()
            return true
        end
    end
    return false
end

function GameStateMonitor:OnCountdownStart()
    self.recorder:OnCountdownStart()
    self.countdownStarted = true
end

function GameStateMonitor:OnGameStart()
    if self.countdownStarted then
        self.countdownStarted = false
        self.recorder:OnCountdownEnd()
    end
    self.recorder:OnGameStart()
end

function GameStateMonitor:OnGameEnd()
    self.recorder:OnGameEnd()
end
