if not Server then return end

local function start_playback(tags)
    HiveMindGlobals:PrintDebug("Starting demo playback")

    local demo_id

    for i = 1, #tags do
        local key = ""
        demo_id = string.match(tags[i], "hm:(.+)")

        if demo_id then
            HiveMindGlobals:PrintDebug("Found HiveMind demo id: " .. demo_id)
            break
        end
    end

    assert(demo_id ~= nil, "Failed to find demo_id")

    HiveMindGlobals:PrintDebug("Initialising demo playback...")
    
    Script.Load("lua/HiveMind/Playback/HiveMindPlayback.lua")

    local hmp = HiveMindPlayback():Initialize(demo_id)
end

local function start_record()
    HiveMindGlobals:PrintDebug("Initialising demo recorder")

    Script.Load("lua/HiveMind/Recorder/HiveMindRecorder.lua")
end

local function main()
    local config = debug.getupvaluex(Server.GetHasTag, "config")

    if Server.GetHasTag("hivemind") then
        HiveMindGlobals:Print("Starting in playback mode")
        HiveMindGlobals:SetType("Playback")
        start_playback(config.tags)
    else
        HiveMindGlobals:Print("Starting in recording mode")
        HiveMindGlobals:SetType("Recording")
        start_record()
    end
end

main()
