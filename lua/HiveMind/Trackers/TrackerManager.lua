--[[
    Class to manage active trackers.
]]

Script.Load("lua/HiveMind/Trackers/PlayerTracker.lua")

class 'TrackerManager'

TrackerManager.trackers = {}

function TrackerManager:Initialize()
    self.trackers = {}
    table.insert(self.trackers, PlayerTracker())
end

function TrackerManager:UpdateAllTrackers(keyframe)
    local trackerData = {}

    for _,tracker in ipairs(self.trackers) do
        tracker:SetKeyframe(keyframe)
        local data = tracker:OnUpdate()
        if data then
            trackerData[tracker:GetName()] = data
        end
    end

    return trackerData
end
