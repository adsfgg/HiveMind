if not Server then return end

Script.Load("lua/HiveMind/Recorder/GameStateMonitor.lua")
Script.Load("lua/HiveMind/Recorder/SaveSend.lua")
Script.Load("lua/HiveMind/Trackers/TrackerManager.lua")

class 'HiveMindRecorder'

-- JSON Data Variables
local header = {}
local initial_data = {}
local update_data = {}

-- Update Variables
local updates = 0


local gameStateMonitor = nil
local trackerManager = nil

function HiveMindRecorder:Initialize()
    gameStateMonitor = GameStateMonitor()

    trackerManager = TrackerManager()
    trackerManager:Initialize()
end

function HiveMindRecorder:OnCountdownStart()
    self:InitailiseHeaders()
    self:RecordInitialData()
end

function HiveMindRecorder:OnCountdownEnd()
    --
end

function HiveMindRecorder:OnGameStart()
    --
end

function HiveMindRecorder:OnGameEnd()
    self:FinalizeHeaders();

    jsonStructure = {}
    jsonStructure['header'] = header
    jsonStructure['initial_data'] = initial_data
    jsonStructure['update_data'] = update_data

    -- save the data locally then send it to the server.
    SaveAndSendRoundData(jsonStructure)
end 

function HiveMindRecorder:RecordInitialData()
    HiveMindGlobals:PrintDebug("Recording initial data")
    initial_data = {}

    local trackerData = trackerManager:UpdateAllTrackers(true)

    if next(trackerData) ~= nil then
        -- table.insert(update_data, trackerData)
        initial_data = trackerData
    else
        Shared.Message("trackerData is null!")
    end
end

local function BuildModList()
    local modList = {}

    for i = 1, Server.GetNumMods() do
        local id   = Server.GetModId(i)
        local name = Server.GetModTitle(i)
        modList[i] = { id = id, name = name }
    end

    return modList
end

local function BuildServerInfo()
    local serverInfo = {}

    serverInfo['name'] = Server.GetName()
    serverInfo['is_dedicated'] = Server.IsDedicated()
    serverInfo['ip'] = Server.GetIpAddress()
    serverInfo['mods'] = BuildModList()

    return serverInfo
end

function HiveMindRecorder:InitailiseHeaders()
    header = {}
    header['ns2_build_number'] = Shared.GetBuildNumber()
    header['map'] = Shared.GetMapName()
    header['server_info'] = BuildServerInfo()
    header['hivemind_version'] = HiveMindGlobals.version

    -- init these but we need to set their values later in OnGameEnd. We can use these values to check if the data is complete.
    header['average_update_time'] = -1
end

function HiveMindRecorder:GetGametime()
    return math.max( 0, math.floor(Shared.GetTime()) - GetGameInfoEntity():GetStartTime() )
end

function HiveMindRecorder:FinalizeHeaders()
    local winning_team = -1
    local currentState = GetGamerules():GetGameState()

    if currentState == kGameState.Team1Won then
        winning_team = kTeam1Index
    elseif currentState == kGameState.Team2Won then
        winning_team = kTeam2Index
    elseif currentState == kGameState.Draw then
        winning_team = 0
    end

    header['winning_team'] = winning_team
    header['round_length'] = self:GetGametime()
    header['updates'] = updates
end

local function OnUpdateServer()
    if gameStateMonitor:CheckGameState() then
        local trackerData = trackerManager:UpdateAllTrackers(false)

        if next(trackerData) ~= nil then
            --update_data[tostring(updates)] = trackerData
            table.insert(update_data, trackerData)
        end
    end
end

Event.Hook("UpdateServer", OnUpdateServer)