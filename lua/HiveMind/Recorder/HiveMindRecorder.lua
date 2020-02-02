if not Server then return end

Script.Load("lua/HiveMind/Recorder/SaveSend.lua")

class 'HiveMindRecorder'

-- Player Data
-- playerData{
--     playerId {
--          update_num {
--              data;
--          }
--      }
-- }
HiveMindRecorder.playerData = nil
HiveMindRecorder.playerDataIdx = nil
HiveMindRecorder.fullPlayerData = nil

-- Header Data
HiveMindRecorder.headerData = nil

HiveMindRecorder.recording = nil
HiveMindRecorder.totalUpdates = 0

function HiveMindRecorder:Initialise()
    HiveMindGlobals:PrintDebug("Initialise HiveMindRecorder")

    -- init vars
    self:InitRecordingData()

    -- setup event hooks
    Event.Hook("UpdateServer", function(server) self:OnUpdateServer(server) end )
end

-- Process a player move for this update
function HiveMindRecorder:ProcessMove(player, input)
    if not self.recording then return end

    local playerId = HiveMindGlobals:CreatePlayerId(player)

    local playerUpdate      = {}
    local origin            = player:GetOrigin()
    local velocity          = player:GetVelocity()
    local name              = player:GetName()

    playerUpdate.commands   = input.commands
    playerUpdate.origin_x   = origin.x
    playerUpdate.origin_y   = origin.y
    playerUpdate.origin_z   = origin.z
    playerUpdate.yaw        = input.yaw
    playerUpdate.pitch      = input.pitch
    playerUpdate.velocity_x = velocity.x
    playerUpdate.velocity_y = velocity.y
    playerUpdate.velocity_z = velocity.z
    playerUpdate.name       = name

    self:UpdatePlayerData(playerId, playerUpdate)
end

function HiveMindRecorder:UpdatePlayerData(playerId, playerUpdate)
    if not self.playerData[self.playerDataIdx] then
        self.playerData[self.playerDataIdx] = {}
    end

    if self.fullPlayerData[playerId] then
        playerUpdate = self:GetPlayerDataChanges(self.fullPlayerData[playerId], playerUpdate)
        self:ApplyPlayerDataChanges(playerUpdate, playerId)
    else
        self.fullPlayerData[playerId] = playerUpdate
    end

    self.playerData[self.playerDataIdx][playerId] = playerUpdate
end

function HiveMindRecorder:GetPlayerDataChanges(fullData, playerUpdate)
    local changes = {}

    for i,v in pairs(playerUpdate) do
        if fullData[i] ~= v then
            changes[i] = v
        end
    end

    return changes
end

function HiveMindRecorder:ApplyPlayerDataChanges(playerChanges, playerId)
    for i,v in pairs(playerChanges) do
        self.fullPlayerData[playerId][i] = v
    end
end

function HiveMindRecorder:InitRecordingData()
    HiveMindGlobals:PrintDebug("Initialising data for recording")
    self.playerData     = {}
    self.playerDataIdx  = 1
    self.fullPlayerData = {}
    self.headerData     = {}
    self.recording      = false
    self.totalUpdates   = 0
end

function HiveMindRecorder:PopulateHeaderData()
    HiveMindGlobals:PrintDebug("Populating header data")
    local headerData = {}

    headerData['totalUpdates'] = self.totalUpdates

    self.headerData = headerData
end

function HiveMindRecorder:OnUpdateServer(server)
    local gameInfo = GetGameInfoEntity()

    if self.recording then
        if gameInfo:GetGameEnded() then
            HiveMindGlobals:PrintDebug("Game ended, writing buffers")
            self:PopulateHeaderData()
            self:Write()
            self.recording = false
        else
            self.totalUpdates   = self.totalUpdates + 1
            self.playerDataIdx  = self.playerDataIdx + 1
        end
    elseif (gameInfo:GetCountdownActive() or gameInfo:GetGameStarted()) and (not Shared.GetCheatsEnabled() or HiveMindGlobals:GetDebugMode()) then
        HiveMindGlobals:PrintDebug("Starting recording")
        self:InitRecordingData()
        HiveMindGlobals:SendChatMessage("Demo recording")
        self.recording = true
    end
end

function HiveMindRecorder:Write()
    HiveMindGlobals:PrintDebug("Populating JSON table")

    local json = {}
    json['player_moves']    = self.playerData
    json['header']          = self.headerData

    HiveMindGlobals:PrintDebug("Attempting to save and send")
    SaveAndSendRoundData(json)

    HiveMindGlobals:SendChatMessage("Demo uploaded successfully")
end

-- End HiveMindRecorder class

local old_Player_OnProcessMove = Player.OnProcessMove
function Player:OnProcessMove(input)
    old_Player_OnProcessMove(self, input)

    local recorder = GetHiveMindRecorder()
    recorder:ProcessMove(self, input)
end
