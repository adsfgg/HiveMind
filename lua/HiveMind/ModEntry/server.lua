if not Server then return end

Script.Load("lua/ConfigFileUtility.lua")

local function main()
    local config = LoadConfigFile("ServerConfig.json", {}, true)

    if Server.GetHasTag("hivemind") then
        start_playback(config.tags)
    else
        start_record()
    end
end

local function start_playback(tags)
    Shared.Message("Starting playback")

    local demo_id = ""

    for i = 0, #tags do
        local key = ""
        key,demo_id = tags[i]:match("(%a%a):(%a+)")

        if key and key == "hm" then
            Shared.Message("Found HiveMind demo id: " .. demo_id)
            break
        end
    end

    Shared.Message("Initialising playback...")

    -- Skip this until it's actually implemented.
    return
    
    Script.Load("lua/HiveMind/Playback/HiveMindPlayback.lua")

    local hmp = HiveMindPlayback()
    hmp:Initialize()
end

local function start_record()
    Script.Load("lua/HiveMind/Recorder/HiveMindRecorder.lua")
    
    local hmr = HiveMindRecorder()
    hmr:Initialize()    
end

main()
