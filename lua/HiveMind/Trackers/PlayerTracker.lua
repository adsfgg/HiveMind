--[[
    Here we track information about players.

    Currently tracks:
    * id
    * playername
    * pres
    * Health
    * armour
    * position on map
    * direction
]]

Script.Load("lua/HiveMind/Trackers/Tracker.lua")

class 'PlayerTracker' (Tracker)

PlayerTracker.entityIdMap = {}

function PlayerTracker:GetName()
    return "player"
end

function PlayerTracker:OnUpdate_Record()
    -- iterate through all players
    for _, player in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
        local id = player:GetId()
        player = Shared.GetEntity(player.playerId)
        local team = player:GetTeamNumber()

        if team ~= kTeamReadyRoom then
            local playerName = player:GetName()
            local pres = player:GetPersonalResources()
            local health = player:GetHealth()
            local armour = player:GetArmor()
            local alive = player:GetIsAlive()
            local commander = player:isa("Commander")
            local current_weapon = false
            local weapon = player:GetActiveWeapon()
            local spectator = player:GetIsSpectator()
            local origin = player:GetOrigin()
            local viewAngles = player:GetViewAngles()

            if weapon and weapon.GetMapName then
                current_weapon = weapon:GetMapName()
            end

            self:TryUpdateValue("player_name", playerName, id)
            self:TryUpdateValue("team", team, id)
            self:TryUpdateValue("spectator", spectator, id)
            if not spectator then
                self:TryUpdateValue("pres", pres, id)
                self:TryUpdateValue("health", health, id)
                self:TryUpdateValue("armour", armour, id)
                self:TryUpdateValue("alive", alive, id)
                self:TryUpdateValue("commander", commander, id)
                self:TryUpdateValue("current_weapon", current_weapon, id)
                self:TryUpdateValue("origin_x", origin.x, id)
                self:TryUpdateValue("origin_y", origin.y, id)
                self:TryUpdateValue("origin_z", origin.z, id)
                self:TryUpdateValue("viewangle_pitch", viewAngles["pitch"], id)
                self:TryUpdateValue("viewangle_yaw", viewAngles["yaw"], id)
                self:TryUpdateValue("viewangle_roll", viewAngles["roll"], id)
            end
        end
    end

    return Tracker.OnUpdate(self)
end

function PlayerTracker:OnUpdate_Playback(update_data)
    for id,player_data in pairs(update_data) do
        local player = self.entityIdMap[id]

        if not player then
            HiveMindGlobals:PrintDebug("Adding client")
            player = Server.AddVirtualClient():GetControllingPlayer()
        end

        local team = player_data['team']
        local playerName = player_data['player_name']
        local pres = player_data['pres']
        local health = player_data['health']
        local armour = player_data['armour']
        local alive = player_data['alive']
        local commander = player_data['commander']
        local current_weapon = player_data['current_weapon']
        local spectator = player_data['spectator']
        
        local origin = player:GetOrigin()
        local origin_x = player_data['origin_x'] or origin.x
        local origin_y = player_data['origin_y'] or origin.y
        local origin_z = player_data['origin_z'] or origin.z
        local origin = Vector(origin_x, origin_y, origin_z)

        if team ~= nil and player then
            _,player = GetGamerules():JoinTeam(player, team)
        end

        if playerName ~= nil and player then
            player:SetName(playerName)
        end

        if pres ~= nil and player then
            player:SetResources(pres)
        end 

        if health ~= nil and player then
            player:SetHealth(health)

            if health == 0 then
                player = nil
            end
        end

        if armour ~= nil and player then
            player:SetArmor(armour)
        end

        if commander ~= nil and player then
            --
        end

        if origin ~= nil and player then
            player:SetOrigin(origin)
        end

        if alive ~= nil and not alive and player then
            player:Kill()
            player = nil
        end

        self.entityIdMap[id] = player
    end
end
