if not Server then return end

-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

class 'HiveMindPlayback'

HiveMindPlayback.LibDeflate = GetLibDeflate()
HiveMindPlayback.B64 = GetBase64()
HiveMindPlayback.data = {}
HiveMindPlayback.playing = false

function HiveMindPlayback:Initialise(demo_id)
    HiveMindGlobals:PrintDebug("Initialise HiveMindPlayback")
    assert(demo_id ~= nil, "No demo id given")

    self.data = self:LoadData(demo_id)
    self.playing = false

    Event.Hook("ClientConnect", function(client) self:OnClientConnect(client) end)

    return self
end

function HiveMindPlayback:OnClientConnect(client)
    local player = client:GetControllingPlayer()

    assert(player)

    -- Force the connecting local player to spectate
    if client:GetIsLocalClient() then
        HiveMindGlobals:PrintDebug("Local player connected, forcing to spectate")
        GetGamerules():JoinTeam(player, kSpectatorIndex)
        HiveMindGlobals:PrintDebug("Starting demo")
        HiveMindGlobals:SendChatMessage("Playing demo")
        self.playing = true
    end
end

function HiveMindPlayback:LoadData(demo_id)
    local dataFile = assert(io.open("config://HiveMind/" .. demo_id .. ".demo", "r"))

    local data = dataFile:read()
    data = self.B64.decode(data)
    data = self.LibDeflate:DecompressZlib(data)
    data = json.decode(data)

    assert(data ~= nil, "Failed to load demo")
    return data
end
