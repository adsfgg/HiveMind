if not Server then return end

-- Trackers
Script.Load("lua/HiveMind/Trackers/TrackerManager.lua")
-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

class 'HiveMindPlayback'

local trackerManager = nil

local LibDeflate = GetLibDeflate()
local B64 = GetBase64()

function HiveMindPlayback:Initialize(demo_id)
    assert(demo_id ~= nil, "No demo id given")

    trackerManager = TrackerManager()
    trackerManager:Initialize()

    self:LoadData(demo_id)
    HiveMindGlobals:PrintDebug("Waiting to play demo")
end

function HiveMindPlayback:LoadData(demo_id)
    HiveMindGlobals:PrintDebug("Attempting to open demo file")
    local dataFile = assert(io.open("config://HiveMind/" .. demo_id .. ".demo", "r"))

    HiveMindGlobals:PrintDebug("Attempting to decode data")

    local data = dataFile:read()
    data = B64.decode(data)
    data = LibDeflate:DecompressZlib(data)
    data = json.decode(data)

    assert(data ~= nil, "Failed to load demo")
    HiveMindGlobals:PrintDebug("Demo data loaded successfully")
end