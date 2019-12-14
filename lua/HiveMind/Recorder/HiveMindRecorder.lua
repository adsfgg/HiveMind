if not Server then return end

Script.Load("lua/HiveMind/Recorder/GameStateMonitor.lua")
Script.Load("lua/HiveMind/Recorder/SaveSend.lua")

class 'HiveMindRecorder'

-- JSON Data Variables
local headers = {}
local initial_data = {}
local update_data = {}

-- Update Variables
local updates = 0


local gameStateMonitor = nil

function HiveMindRecorder:Initialize()
    gameStateMonitor = GameStateMonitor()
end

function HiveMindRecorder:OnCountdownStart()
    HiveMindGlobals:SendChatMessage("Countdown start!")
    self:InitailiseHeaders()
end

function HiveMindRecorder:OnCountdownEnd()
    HiveMindGlobals:SendChatMessage("Countdown end!")
end

function HiveMindRecorder:OnGameStart()
    HiveMindGlobals:SendChatMessage("Game start!")
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

function HiveMindRecorder:OnGameEnd()
    HiveMindGlobals:SendChatMessage("Game end!")
    self:FinalizeHeaders();

    jsonStructure = {}
    jsonStructure['headers'] = headers
    jsonStructure['initial_data'] = initial_data
    jsonStructure['update_data'] = update_data

    -- save the data locally then send it to the server.
    SaveAndSendRoundData(jsonStructure)
end 

local function OnUpdateServer()
    if gameStateMonitor:CheckGameState() then
        --
    end
end

Event.Hook("UpdateServer", OnUpdateServer)