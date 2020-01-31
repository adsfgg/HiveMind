if not Server then return end

Script.Load("lua/HiveMind/Recorder/SaveSend.lua")

class 'HiveMindRecorder'

HiveMindRecorder.playerData = nil
HiveMindRecorder.playerDataIdx = nil

HiveMindRecorder.recording = nil

function HiveMindRecorder:Initialise()
    -- init vars
    self.playerData = {}
    self.playerDataIdx = 0
    self.recording = false

    -- setup event hooks
    Event.Hook("UpdateServer", function(server) self:OnUpdateServer(server) end )
end

-- Process a player move for this update
function HiveMindRecorder:ProcessMove(player, input)
    if not self.recording then return end

    local p_id = player:GetId()
    local player_update = {}

    player_update.commands = input.commands
    player_update.origin = player:GetOrigin()
    player_update.yaw = input.yaw
    player_update.pitch = input.pitch
    player_update.velocity = player:GetVelocity()

    self:UpdatePlayerData(p_id, player_update)
end

function HiveMindRecorder:UpdatePlayerData(p_id, player_update)
    if not self.playerData[self.playerDataIdx] then
        self.playerData[self.playerDataIdx] = {}
    end

    self.playerData[self.playerDataIdx][p_id] = player_update
end

function HiveMindRecorder:OnUpdateServer(server)
    local gameInfo = GetGameInfoEntity()

    if self.recording then
        if gameInfo:GetGameEnded() then
            self:Write()
            self.recording = false
        else
            self.playerDataIdx = self.playerDataIdx + 1
        end
    elseif (gameInfo:GetCountdownActive() or gameInfo:GetGameStarted()) and not Shared.GetCheatsEnabled() then
        HiveMindGlobals:SendChatMessage("Demo recording")
        self.recording = true
    end
end

function HiveMindRecorder:Write()
    local json = {}
    json['player_moves'] = self.playerData

    SaveAndSendRoundData(json)
    HiveMindGlobals:SendChatMessage("Demo uploaded successfully")
end

-- End HiveMindRecorder class

local function CreateHiveMindRecorder()
    local recorder = HiveMindRecorder()
    recorder:Initialise()

    return recorder
end

local hm_recorder
function GetHiveMindRecorder()
    if not hm_recorder then
        hm_recorder = CreateHiveMindRecorder()
    end

    return hm_recorder
end

local old_Player_OnProcessMove = Player.OnProcessMove
function Player:OnProcessMove(input)
    old_Player_OnProcessMove(self, input)

    local recorder = GetHiveMindRecorder()
    recorder:ProcessMove(self, input)
end
