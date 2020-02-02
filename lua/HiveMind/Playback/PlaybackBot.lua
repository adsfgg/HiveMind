class 'PlaybackBot' (Bot)

PlaybackBot.playerId = nil

function PlaybackBot:Initialize(playerId, forceTeam, active, tablePosition)
    self.playerId = playerId
    Bot.Initialize(self, forceTeam, active, tablePosition)
end

function PlaybackBot:GetPlayerId()
    return self.playerId
end

function PlaybackBot:_LazilyInitBrain()
end

function PlaybackBot:GenerateMove()
    
    local move = Move()
    local playback = GetHiveMindPlayback()
    
    if playback.playing then
        
        local nextMove = playback:GetNextMove(self)
        if nextMove then
            move.commands = nextMove.commands
            move.yaw = nextMove.yaw
            move.pitch = nextMove.pitch
            
            local player = self:GetPlayer()
            player:SetOrigin(nextMove.origin)
            player:SetVelocity(nextMove.velocity)
            player:SetViewAngles(nextMove.viewAngles)
            player:SetName(nextMove.name)
        else
            HiveMindGlobals:PrintWarn(self.playerId .. ": Skipping next move")
        end
        
    end
    
    return move
    
end