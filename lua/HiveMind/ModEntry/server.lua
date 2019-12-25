if not Server then return end

local function start_playback(tags)
    HiveMindGlobals:Print("Starting demo playback")

    local demo_id

    for i = 1, #tags do
        local key = ""
        key,demo_id = string.match(tags[i], "(%a%a):(.+)")

        if key and key == "hm" then
            HiveMindGlobals:Print("Found HiveMind demo id: " .. demo_id)
            break
        end
    end

    assert(demo_id ~= nil, "Failed to find demo_id")

    HiveMindGlobals:Print("Initialising demo playback...")

    -- Skip this until it's actually implemented.
    --[[
    
    Script.Load("lua/HiveMind/Playback/HiveMindPlayback.lua")

    local hmp = HiveMindPlayback()
    hmp:Initialize()
    ]]
end

local function start_record()
    HiveMindGlobals:Print("Initialising demo recorder")

    Script.Load("lua/HiveMind/Recorder/HiveMindRecorder.lua")
    
    local hmr = HiveMindRecorder()
    hmr:Initialize()    
end

local function main()
    local config = debug.getupvaluex(Server.GetHasTag, "config")

    if Server.GetHasTag("hivemind") then
        HiveMindGlobals:Print("Starting in playback mode")
        start_playback(config.tags)
    else
        HiveMindGlobals:Print("Starting in recording mode")
        start_record()
    end
end

main()
