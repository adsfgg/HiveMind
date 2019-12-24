--[[
    Generic Tracker class.
]]

-- Abstract
class 'Tracker'

Tracker.fullInfo = {}
Tracker.changes = {}
Tracker.keyFrame = false

--https://stackoverflow.com/a/1283608
local function tableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                tableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

function Tracker:SetKeyframe(keyFrame)
    assert(keyFrame ~= nil and type(keyFrame) == "boolean")
    self.keyFrame = keyFrame
end

-- Here we gather info for the tracker
function Tracker:OnUpdate()
    if next(self.changes) == nil then
        return nil
    end

    self.fullInfo = tableMerge(self.fullInfo, self.changes)

    local changes = self.changes
    self.changes = {}

    self.keyFrame = false

    return changes
end

function Tracker:OnReset()
    self.fullInfo = {}
    self.changes = {}
end

function Tracker:GetName()
    assert(false)
end

function Tracker:ShouldUpdate(key, value, subarray)
    assert(key)
    assert(value ~= nil)

    if self.keyFrame == true then
        return true
    end

    -- don't add empty tables.
    if type(value) == "table" and next(value) == nil then
        return false
    end

    if subarray then
        if not self.fullInfo[subarray] then
            return true
        end

        if self.fullInfo[subarray][key] == value then
            return false
        end
    else
        if self.fullInfo[key] == value then
            return false
        end
    end

    return true
end

function Tracker:TryUpdateValue(key, value, subarray)
    if self:ShouldUpdate(key, value, subarray) then
        self:UpdateValue(key, value, subarray)
    end
end

function Tracker:UpdateValue(key, value, subarray)
    assert(key)
    assert(value ~= nil)

    if subarray then
        if not self.changes[subarray] then
            self.changes[subarray] = {}
        end

        self.changes[subarray][key] = value
    else
        self.changes[key] = value
    end
end

function Tracker:DeleteValue(key)
    self.changes[key] = nil
end

function Tracker:GetChanges()
    return self.changes
end

function Tracker:GetFullInfo()
    return self.fullInfo
end
