if not Server then return end

-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

class 'HiveMindPlayback'

HiveMindPlayback.trackerManager = nil

HiveMindPlayback.LibDeflate = GetLibDeflate()
HiveMindPlayback.B64 = GetBase64()
HiveMindPlayback.data = {}

HiveMindPlayback.playbackStarted = false
HiveMindPlayback.timeToStart = 0

HiveMindPlayback.currentUpdate = 1

function HiveMindPlayback:Initialize(demo_id)
    assert(demo_id ~= nil, "No demo id given")

    self.data = self:LoadData(demo_id)

    Event.Hook("ClientConnect", function(client) self:OnClientConnect(client) end)
    Event.Hook("UpdateServer", function(server) self:OnUpdateServer(server) end)

    return self
end

function HiveMindPlayback:OnClientConnect(client)
    local player = client:GetControllingPlayer()

    assert(player)

    -- Force the connecting local player to spectate
    if client:GetIsLocalClient() then
        GetGamerules():JoinTeam(player, kSpectatorIndex)
        HiveMindGlobals:SendChatMessage("Starting demo in 10 seconds")

        self.timeToStart = Shared.GetTime() + 10
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

function HiveMindPlayback:OnUpdateServer(server)
end
