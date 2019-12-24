--[[
    Right now we store the entire contents of the structure in memory and write it all out to file at the end. 
    It would be better to only keep the most recent data in memory and write to disk more often. 
    sEvery 1-2 seconds perhaps?

    This would mean that each write we would append to a file that contains the JSON streucture,
    then when the demo is finished, we compress everything and rewrite the file. 
    This would mean having to load the entire JSON structure into memory anyway, 
    but it would mean reduced memory usage throughout the round. Would need to test to find out the average memory usage.
    My estimate is it shouldn't be more than ~20MB unless it's a really really long round.

    I consider that acceptable for now.
]]

Script.Load("lua/HiveMind/LibDeflate.lua")
Script.Load("lua/HiveMind/base64.lua")

local HiveMindStatsURL = "localhost:8000/api/round"

local LibDeflate = GetLibDeflate()
local B64 = GetBase64()

local function HTTPRequestCallback(response, request_error)
    local status, reason, data, pos, err

    if request_error then
        status, reason = 128, request_error
    else
        data, pos, err = json.decode(response)

        if err then
            Shared.Message("Could not parse HiveMind response. Error: " .. ToString(err))
            status, reason  = 1, "Could not parse HiveMind response."
        else
            status = data['status']
            reason = data['reason']
        end
    end

    if status ~= 0 then
        HiveMindGlobals:SendChatMessage("Demo failed to upload.")
        HiveMindGlobals:SendChatMessage("Status: " .. status)
        SendHiveMindChatMessage("Reason: " .. reason)
    else
        -- notify the players that the demo was saved successfully.
        HiveMindGlobals:SendChatMessage("Demo recorded.")
        HiveMindGlobals:SendChatMessage("Round ID: " .. data['round_uuid'])
    end
end

local function SendData(jsonData)
    Shared.SendHTTPRequest( HiveMindStatsURL, "POST", { data = jsonData }, HTTPRequestCallback)
end

local function SaveData(jsonData, cJsonData, bJsonData)
    local dataFile = io.open("config://HiveMind/RoundStats.json", "w+")
    local cDataFile = io.open("config://HiveMind/RoundStatsCompressed.bin", "w+")
    local bDataFile = io.open("config://HiveMind/RoundStatsB64.txt", "w+")

    if dataFile then
        dataFile:write(jsonData)
        io.close(dataFile)
    end

    if cDataFile then
        cDataFile:write(cJsonData)
        io.close(cDataFile)
    end

    if bDataFile then
        bDataFile:write(bJsonData)
        io.close(bDataFile)
    end
end

function SaveAndSendRoundData(jsonStructure)
    -- for debug
    local jsonData = json.encode(jsonStructure, { indent=true })
    local cJsonData = LibDeflate:CompressZlib(json.encode(jsonStructure, { index = false }))

    local bJsonData = B64.encode(cJsonData)

    SaveData(jsonData, cJsonData, bJsonData)
    -- Disable upload for now.
    -- SendData(bJsonData)
end