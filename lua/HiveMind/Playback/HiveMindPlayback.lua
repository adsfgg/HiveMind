if not Server then return end

-- Trackers
Script.Load("lua/HiveMind/Trackers/TrackerManager.lua")
-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

local currentHiveMindPlayback = nil

class 'HiveMindPlayback'

HiveMindPlayback.trackerManager = nil

HiveMindPlayback.LibDeflate = GetLibDeflate()
HiveMindPlayback.B64 = GetBase64()
HiveMindPlayback.data = {}

function HiveMindPlayback:Initialize(demo_id)
    assert(demo_id ~= nil, "No demo id given")

    self.trackerManager = TrackerManager()
    self.trackerManager:Initialize()

    self.data = self:LoadData(demo_id)

    Event.Hook("ClientConnect", function(client) self:OnClientConnect(client) end)

    HiveMindGlobals:PrintDebug("Waiting for client to connect...")

    currentHiveMindPlayback = self
    return self
end

function HiveMindPlayback:OnClientConnect(client)
    local player = client:GetControllingPlayer()

    assert(player)

    -- Force the connecting local player to spectate
    HiveMindGlobals:PrintDebug("Client connecting...")
    if client:GetIsLocalClient() then
        HiveMindGlobals:PrintDebug("Client is local, moving to spectate")
        GetGamerules():JoinTeam(player, kSpectatorIndex)
    else
        HiveMindGlobals:PrintDebug("Client is not local, ignoring")
    end
end

function HiveMindPlayback:LoadData(demo_id)
    HiveMindGlobals:PrintDebug("Attempting to open demo file")
    local dataFile = assert(io.open("config://HiveMind/" .. demo_id .. ".demo", "r"))

    HiveMindGlobals:PrintDebug("Attempting to decode data")

    local data = dataFile:read()
    data = self.B64.decode(data)
    data = self.LibDeflate:DecompressZlib(data)
    data = json.decode(data)

    assert(data ~= nil, "Failed to load demo")
    HiveMindGlobals:PrintDebug("Demo data loaded successfully")
    return data
end