--[[
    Class to manage active trackers.
]]

Script.Load("lua/HiveMind/Trackers/PlayerTracker.lua")

class 'TrackerManager'

TrackerManager.trackers = {}

function TrackerManager:Initialize()
    self.trackers = {}
    table.insert(self.trackers, PlayerTracker())

    return self
end

function TrackerManager:UpdateAllTrackers_Record(keyframe)
    local trackerData = {}

    for _,tracker in ipairs(self.trackers) do
        tracker:SetKeyframe(keyframe)
        local data = tracker:OnUpdate_Record()
        if data then
            trackerData[tracker:GetName()] = data
        end
    end

    return trackerData
end

function TrackerManager:UpdateAllTrackers_Playback(update_data)
    local trackerData = {}

    for _,tracker in ipairs(self.trackers) do
        local name = tracker:GetName()
        tracker:OnUpdate_Playback(update_data[name])
    end
end