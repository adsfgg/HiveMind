local DEBUG = true

HiveMindGlobals = {}

-- Shared Variables
HiveMindGlobals.version = "0.0.1"
HiveMindGlobals.modName = "HiveMind"

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

    Shared.Message(self.modName .. " - " .. msg)
end

function HiveMindGlobals:PrintDebug(msg)
    if DEBUG then
        msg = "DEBUG - " .. msg
        self:Print(msg)
    end
end

function HiveMindGlobals:GetDebugMode()
    return DEBUG
end