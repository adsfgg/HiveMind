if not Server then return end

-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

class 'HiveMindPlayback'

HiveMindPlayback.trackerManager = nil

HiveMindPlayback.LibDeflate = GetLibDeflate()
HiveMindPlayback.B64 = GetBase64()
HiveMindPlayback.data = {}
HiveMindPlayback.playing = false

HiveMindPlayback.playbackStarted = false
HiveMindPlayback.timeToStart = 0

HiveMindPlayback.currentUpdate = 1
HiveMindPlayback.totalUpdates = 0

HiveMindPlayback.knownPlayerIds = {}

function HiveMindPlayback:Initialize(demo_id)
    HiveMindGlobals:PrintDebug("Initialise HiveMindPlayback")
    assert(demo_id ~= nil, "No demo id given")

    self.data = self:LoadData(demo_id)
    self.playing = false
    self.currentUpdate = 1
    self.knownPlayerIds = {}
    self.totalUpdates = self.data['header']['totalUpdates']
    HiveMindGlobals:PrintDebug("About to start demo. Total updates: " .. self.totalUpdates)

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

function HiveMindPlayback:OnUpdateDemo()
    local playerData = self.data['player_moves'][''..self.currentUpdate]
    
    for playerId, data in pairs(playerData) do
        local player

        if not self.knownPlayerIds[playerId] then
            HiveMindGlobals:PrintDebug("Adding new virtual client for playerId: " .. playerId)
            player = Server.AddVirtualClient()

            -- hack for now 
            HiveMindGlobals:PrintDebug("Forcing new player to marines")
            teamJoinSuccess, player = GetGamerules():JoinTeam(player, 1)

            self.knownPlayerIds[playerId] = true
        end
    end
end

function HiveMindPlayback:ProcessPlayerMove(player, input)
    if not self.playback or player:IsLocalPlayer() then
        return
    end

    local playerId, playerData = HiveMindGlobals:GetPlayerData(player, self.data['player_moves'][self.currentUpdate])

    if not playerData then
        return
    end

    newPlayer = self:UpdatePlayerData(data, input, player)

    -- if the player id is an entity id and the ids have changed 
    if HiveMindGlobals:IsIdEntity(playerId) and not HiveMindGlobals:PlayerIdMatches(player, playerId) then
        -- unset the old id
        self.knownPlayerIds[playerId] = nil

        -- create a new one and update knownPlayerIds table
        playerId = "E" .. player:GetId()
        self.knownPlayerIds[playerId] = true
    end
end

function HiveMindPlayback:UpdatePlayerData(data, input, player)
    local playerOrigin      = player:GetOrigin()
    local playerVelocity    = player:GetVelocity()

    local commands          = data['commands']
    local yaw               = data['yaw']
    local pitch             = data['pitch']
    
    -- re-create origin
    local origin_x          = data['origin_x'] or playerOrigin.x
    local origin_y          = data['origin_y'] or playerOrigin.y
    local origin_z          = data['origin_z'] or playerOrigin.z
    local origin            = Vector(origin_x, origin_y, origin_z)

    -- re-create vector
    local vel_x             = data['vector_x'] or playerVelocity.x
    local vel_y             = data['vector_y'] or playerVelocity.y
    local vel_z             = data['vector_z'] or playerVelocity.z
    local velocity          = Vector(vel_x, vel_y, vel_z)

    if commands then
        input.commands = commands
    end

    if yaw then
        input.yaw = yaw
    end
    
    if pitch then
        input.pitch = pitch
    end

    if origin then
        player:SetOrigin(origin)
    end

    if velocity then
        player:SetVelocity(velocity)
    end

    return player
end

function HiveMindPlayback:OnUpdateServer(server)
    if self.playing then
        if self.currentUpdate > self.totalUpdates then
            HiveMindGlobals:SendChatMessage("Demo complete")
            self.playing = false
            return
        end

        self:OnUpdateDemo()
        self.currentUpdate = self.currentUpdate + 1
    end
end

-- End HiveMindPlayback class

local function CreateHiveMindPlayback()
    HiveMindGlobals:PrintDebug("Creating HiveMindPlayback")
    local playback = HiveMindPlayback()
    playback:Initialise()

    return playback
end

local hm_playback
function GetHiveMindPlayback()
    if not hm_playback then
        hm_playback = CreateHiveMindPlayback()
    end

    return hm_playback
end

local old_Player_OnProcessMove = Player.OnProcessMove
function Player:OnProcessMove(input)
    old_Player_OnProcessMove(self, input)

    local playback = GetHiveMindPlayback()
    playback:ProcessPlayerMove(self, input)
end