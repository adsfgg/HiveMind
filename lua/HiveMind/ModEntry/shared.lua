HiveMindGlobals = {}

-- Shared Variables
HiveMindGlobals.version = "0.0.1"
HiveMindGlobals.modName = "HiveMind"

-- Shared Functions
function HiveMindGlobals:SendChatMessage(msg, team, teamType)
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