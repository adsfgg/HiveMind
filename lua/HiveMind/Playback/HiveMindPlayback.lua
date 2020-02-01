if not Server then return end

-- Libraries
Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

-- Includes
Script.Load("lua/HiveMind/Playback/PlaybackBot.lua")

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

HiveMindPlayback.entityIdToPlayerId = {}
HiveMindPlayback.playerIdToEntityId = {}

function HiveMindPlayback:Initialise(demo_id)
    HiveMindGlobals:PrintDebug("Initialise HiveMindPlayback")
    assert(demo_id ~= nil, "No demo id given")

    self.data = self:LoadData(demo_id)
    self.playing = false
    self.currentUpdate = 0
    self.entityIdToPlayerId = {}
    self.playerIdToEntityId = {}
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

function HiveMindPlayback:OnUpdateDemo()
    local playerData = self:GetCurrentPlayerMoves()

    if not playerData then
        return
    end
    
    for playerId, data in pairs(playerData) do
        if not self.playerIdToEntityId[playerId] then
            HiveMindGlobals:PrintDebug("Adding new PlaybackBot for playerId: " .. playerId)

            -- hack for now 
            HiveMindGlobals:PrintWarn("HACK: Forcing new player to marines")

            local playerBot = PlaybackBot()
            playerBot:Initialize(playerId, kTeam1Index, true)

            self:MapEntityIdToPlayerId(playerBot:GetPlayer():GetId(), playerId)
        end
    end
end

function HiveMindPlayback:MapEntityIdToPlayerId(entityId, playerId)
    assert(not self.entityIdToPlayerId[entityId])
    assert(not self.playerIdToEntityId[playerId])

    self.entityIdToPlayerId[entityId] = playerId
    self.playerIdToEntityId[playerId] = entityId
    HiveMindGlobals:PrintDebug("Mapped: " .. entityId .. " -> " .. playerId)
end

function HiveMindPlayback:UnmapEntityId(entityId)
    assert(self.entityIdToPlayerId[entityId])

    self.entityIdToPlayerId[entityId] = nil
    HiveMindGlobals:PrintDebug("Unmapped entityId: " .. entityId)
end

function HiveMindPlayback:UnmapPlayerId(playerId)
    assert(self.playerIdToEntityId[playerId])

    self.playerIdToEntityId[playerId] = nil
    HiveMindGlobals:PrintDebug("Unmapped playerId: " .. playerId)
end

function HiveMindPlayback:GetCurrentPlayerMoves()
    -- TODO: Don't know why currentUpdate needs to be a string...
    local update = self.data['player_moves'][''..self.currentUpdate]
    while not update do
        self.currentUpdate = self.currentUpdate + 1

        if self.currentUpdate > self.totalUpdates then
            return {}
        end

        update = self.data['player_moves'][''..self.currentUpdate]
    end

    return update
end

function HiveMindPlayback:GetNextMove(playbackBot)
    if not self.playing then return nil end

    local player        = playbackBot:GetPlayer()
    local playerId      = playbackBot:GetPlayerId()
    local currentMoves  = self:GetCurrentPlayerMoves()

    return self:GetPlayerMove(player, currentMoves[playerId])
end

function HiveMindPlayback:GetPlayerMove(player, data)
    if not data then return nil end

    local playerOrigin      = player:GetOrigin()
    local playerVelocity    = player:GetVelocity()
    local playerViewAngles  = player:GetViewAngles()
    local currentName       = player:GetName() or "Epic Gamer"

    local commands          = data['commands']  or 0
    local yaw               = data['yaw']       or playerViewAngles.yaw
    local pitch             = data['pitch']     or playerViewAngles.pitch
    local name              = data['name']      or currentName 
    
    -- re-create origin
    local origin_x          = data['origin_x']  or playerOrigin.x
    local origin_y          = data['origin_y']  or playerOrigin.y
    local origin_z          = data['origin_z']  or playerOrigin.z
    local origin            = Vector(origin_x, origin_y, origin_z)

    -- re-create velocity
    local vel_x             = data['velocity_x']  or playerVelocity.x
    local vel_y             = data['velocity_y']  or playerVelocity.y
    local vel_z             = data['velocity_z']  or playerVelocity.z
    local velocity          = Vector(vel_x, vel_y, vel_z)

    -- Create view angles
    local viewAngles        = Angles()
    viewAngles.yaw          = yaw
    viewAngles.pitch        = pitch

    -- Setup our bot's next move
    local move = {}
    move.commands   = commands
    move.yaw        = yaw
    move.pitch      = pitch
    move.origin     = origin
    move.velocity   = velocity
    move.viewAngles = viewAngles
    move.name       = name

    HiveMindGlobals:PrintDebug(self.currentUpdate)

    return move
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
