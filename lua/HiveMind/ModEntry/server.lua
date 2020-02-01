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

    -- Create a new HiveMindPlayback instance
    GetHiveMindPlayback(demo_id)
end

local function CreateHiveMindPlayback(demo_id)
    HiveMindGlobals:PrintDebug("Creating HiveMindPlayback")
    local playback = HiveMindPlayback()
    playback:Initialise(demo_id)

    return playback
end

local hm_playback
function GetHiveMindPlayback(demo_id)
    if not hm_playback then
        hm_playback = CreateHiveMindPlayback(demo_id)
    end

    return hm_playback
end

local function start_record()
    HiveMindGlobals:PrintDebug("Initialising demo recorder")

    Script.Load("lua/HiveMind/Recorder/HiveMindRecorder.lua")
end

local function CreateHiveMindRecorder()
    HiveMindGlobals:PrintDebug("Creating HiveMindRecorder")
    local recorder = HiveMindRecorder()
    recorder:Initialise()

    return recorder
end

local hm_recorder
function GetHiveMindRecorder()
    if not hm_recorder then
        hm_recorder = CreateHiveMindRecorder()
    end

    return hm_recorder
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
