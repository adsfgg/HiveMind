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

HiveMindPlayback.entityIdToPlayerId = {}
HiveMindPlayback.playerIdToEntityId = {}

function HiveMindPlayback:Initialise(demo_id)
    HiveMindGlobals:PrintDebug("Initialise HiveMindPlayback")
    assert(demo_id ~= nil, "No demo id given")

    self.data = self:LoadData(demo_id)
    self.playing = false
    self.currentUpdate = 1
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
            HiveMindGlobals:PrintDebug("Adding new virtual client for playerId: " .. playerId)
            local player = Server.AddVirtualClient():GetControllingPlayer()

            -- hack for now 
            HiveMindGlobals:PrintDebug("HACK - Forcing new player to marines")
            teamJoinSuccess, player = GetGamerules():JoinTeam(player, 1)

            self:MapEntityIdToPlayerId(player:GetId(), playerId)
        end
    end
end

function HiveMindPlayback:MapEntityIdToPlayerId(entityId, playerId)
    assert(not self.entityIdToPlayerId[entityId])
    assert(not self.playerIdToEntityId[playerId])

    self.entityIdToPlayerId[entityId] = playerId
    self.playerIdToEntityId[playerId] = entityId
end

function HiveMindPlayback:UnmapEntityId(entityId)
    assert(self.entityIdToPlayerId[entityId])

    self.entityIdToPlayerId[entityId] = nil
end

function HiveMindPlayback:UnmapPlayerId(playerId)
    assert(self.playerIdToEntityId[playerId])

    self.playerIdToEntityId[playerId] = nil
end

function HiveMindPlayback:GetCurrentPlayerMoves()
    -- TODO: Don't know why currentUpdate needs to be a string...
    return self.data['player_moves'][''..self.currentUpdate]
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
        HiveMindGlobals:PrintDebug("Updating commands")
        input.commands = commands
    end

    if yaw then
        HiveMindGlobals:PrintDebug("Updating yaw")
        input.yaw = yaw
    end
    
    if pitch then
        HiveMindGlobals:PrintDebug("Updating pitch")
        input.pitch = pitch
    end

    if origin then
        HiveMindGlobals:PrintDebug("Updating origin")
        player:SetOrigin(origin)
    end

    if velocity then
        HiveMindGlobals:PrintDebug("Updating velocity")
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
