if not Server then return end

Script.Load("lua/HiveMind/Recorder/GameStateMonitor.lua")
Script.Load("lua/HiveMind/Recorder/SaveSend.lua")
Script.Load("lua/HiveMind/Trackers/TrackerManager.lua")

local currentHiveMindRecorder = nil

class 'HiveMindRecorder'

-- JSON Data Variables
HiveMindRecorder.header = {}
HiveMindRecorder.initial_data = {}
HiveMindRecorder.update_data = {}

-- Update Variables
HiveMindRecorder.updates = 0


HiveMindRecorder.gameStateMonitor = nil
HiveMindRecorder.trackerManager = nil

function HiveMindRecorder:Initialize()
    self.trackerManager = TrackerManager():Initialize()
    self.gameStateMonitor = GameStateMonitor():Initialize(self)

    currentHiveMindRecorder = self

    return self
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
    jsonStructure['header'] = self.header
    jsonStructure['initial_data'] = self.initial_data
    jsonStructure['update_data'] = self.update_data

    -- save the data locally then send it to the server.
    SaveAndSendRoundData(jsonStructure)
end 

function HiveMindRecorder:RecordInitialData()
    HiveMindGlobals:PrintDebug("Recording initial data")
    self.initial_data = {}

    local trackerData = self.trackerManager:UpdateAllTrackers(true)

    if next(trackerData) ~= nil then
        self.initial_data = trackerData
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
    self.header = {}
    self.header['ns2_build_number'] = Shared.GetBuildNumber()
    self.header['map'] = Shared.GetMapName()
    self.header['server_info'] = BuildServerInfo()
    self.header['hivemind_version'] = HiveMindGlobals.version

    -- init these but we need to set their values later in OnGameEnd. We can use these values to check if the data is complete.
    self.header['average_update_time'] = -1
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

    self.header['winning_team'] = winning_team
    self.header['round_length'] = self:GetGametime()
    self.header['updates'] = self.updates
end

function HiveMindRecorder:OnUpdateServer()
    if self.gameStateMonitor:CheckGameState() then
        local trackerData = self.trackerManager:UpdateAllTrackers(false)

        if next(trackerData) ~= nil then
            --update_data[tostring(updates)] = trackerData
            table.insert(self.update_data, trackerData)
        else
            table.insert(self.update_data, {})
        end
    end
end

Event.Hook("UpdateServer", function() currentHiveMindRecorder:OnUpdateServer() end)