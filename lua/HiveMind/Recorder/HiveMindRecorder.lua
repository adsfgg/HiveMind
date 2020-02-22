if not Server then return end

Script.Load("lua/HiveMind/Recorder/SaveSend.lua")

class 'HiveMindRecorder'

HiveMindRecorder.recording = nil

function HiveMindRecorder:Initialise()
    HiveMindGlobals:PrintDebug("Initialise HiveMindRecorder")

    -- init vars
    self:InitRecordingData()

    local old_HookNetworkMessage = Server.HookNetworkMessage
    function Server.HookNetworkMessage(name, func)
        HiveMindGlobals:PrintDebug("Found network message hook: " .. name)
        old_HookNetworkMessage(name, func)
    end
end

function HiveMindRecorder:InitRecordingData()
    HiveMindGlobals:PrintDebug("Initialising data for recording")
    self.recording      = false
end
