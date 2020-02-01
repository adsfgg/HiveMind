local DEBUG = true

HiveMindGlobals = {}

-- Shared Variables
HiveMindGlobals.version = "0.0.1"
HiveMindGlobals.modName = "HiveMind"
HiveMindGlobals.type = "Main"
HiveMindGlobals.callbacks = {}

-- Shared Functions
function HiveMindGlobals:SendChatMessage(msg, team, teamType)
    assert(msg ~= nil)
    
    if team == nil then
        team = kTeamReadyRoom
    end

    if teamType == nil then
        teamType = kNeutralTeamType
    end

    Server.SendNetworkMessage("Chat", BuildChatMessage(false, self.modName, -1, team, teamType, msg), true)
    Shared.Message("Chat All - " .. self.modName .. ": " .. msg)
    Server.AddChatToHistory(msg, self.modName, 0, team, false)
end

function HiveMindGlobals:Print(msg)
    assert(msg ~= null, "Message cannot be null")
    assert(type(msg) == "string", "Message must be of type string")

    Shared.Message(self.modName .. " - (" .. self:GetType() .. "): " .. msg)
end

function HiveMindGlobals:PrintWarn(msg)
    msg = "WARNING - " .. msg
    self:Print(msg)
end

function HiveMindGlobals:PrintDebug(msg)
    if DEBUG then
        msg = "DEBUG - " .. msg
        self:Print(msg)
    end
end

function HiveMindGlobals:SetType(type)
    self.type = type
end

function HiveMindGlobals:GetType()
    return self.type
end

function HiveMindGlobals:GetDebugMode()
    return DEBUG
end

function HiveMindGlobals:IsIdEntity(playerId)
    return playerId:sub(1,1) == "E"
end

function HiveMindGlobals:IsIdSteam(playerId)
    return playerId:sub(1,1) == "S"
end

function HiveMindGlobals:PlayerIdMatches(player, playerId)
    if self:IsIdEntity(playerId) then
        return playerId == "E" .. player:GetId()
    elseif self:IsIdSteam(playerId) then
        return playerId == "S" .. player:GetSteamId()
    end

    return false
end

function HiveMindGlobals:CreatePlayerId(player)
    local playerId = player:GetSteamId()

    if playerId == 0 then
        if not player:GetIsVirtual() then
            HiveMindGlobals:PrintWarn("Failed to get steamid for non virtual player, falling back to entity-id")
        end

        playerId = "E" .. player:GetId()
    else
        playerId = "S" .. playerId
    end

    return playerId
end

function HiveMindGlobals:GetPlayerData(player, playerMovesData)
    if playerMovesData then
        for playerId,playerData in pairs(playerMovesData) do
            if self:PlayerIdMatches(player, playerId) then
                return playerId, playerData
            end
        end
    end

    return nil, nil
end

HiveMindGlobals:PrintDebug("Debug mode is enabled!")