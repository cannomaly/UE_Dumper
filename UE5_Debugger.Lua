-- Load the game-specific configuration from config.lua
function loadConfig(game_id)
    local config = dofile("config.lua")
    if config and config[game_id] then
        return config[game_id]
    else
        print("Error: Invalid game ID or missing configuration.")
        return nil
    end
end

-- Function to select game configuration
function selectGameConfig()
    local game_id = inputQuery("Enter Game ID", "Enter the game ID (e.g., 'game_1' or 'game_2'):", "game_1")
    return loadConfig(game_id)
end

-- Environment and general setup
local ObjectsPerThread = 0x200
local FNameIndexMultiplier = string.find(process:lower(), 'chivalry2') and 2 or 1

-- Check if Cheat Engine is attached to a process
function checkProcessAttached()
    if not process or process == 0 then
        print("Error: No process attached. Attach Cheat Engine to a target process.")
        return false
    end
    return true
end

-- Function to detect Unreal Engine version dynamically based on configuration
function ueDetermineVersion(config)
    local ue5_pattern = config.memory_patterns.ue5_pattern
    local ue4_pattern = config.memory_patterns.ue4_pattern

    -- Scan for UE5-specific pattern
    if AOBScan(ue5_pattern, "*W") then
        return 50  -- Return 50 for UE5
    elseif AOBScan(ue4_pattern, "*W") then
        return 25  -- Return 25 for UE4.25+
    else
        return 22  -- Fallback for older versions of UE4 (4.22 and below)
    end
end

-- Function to safely read float values with error handling
function safeReadFloat(address)
    if address and address ~= 0 then
        return readFloat(address)
    else
        print("Error: Invalid memory address.")
        return nil
    end
end

-- Function to safely read integer values with error handling
function safeReadInteger(address)
    if address and address ~= 0 then
        return readInteger(address)
    else
        print("Error: Invalid memory address.")
        return nil
    end
end

-- Function to get user input for X, Y, Z coordinates
function getPlayerCoordinates()
    local x = inputQuery("Enter Player X Coordinate", "X:", "0.0")
    local y = inputQuery("Enter Player Y Coordinate", "Y:", "0.0")
    local z = inputQuery("Enter Player Z Coordinate", "Z:", "0.0")

    -- Ensure inputs are converted to float values
    return tonumber(x), tonumber(y), tonumber(z)
end

-- Function to log extracted data to a file
function logToFile(logData)
    local logFile = io.open("player_data_log.txt", "a")
    if logFile then
        logFile:write(logData .. "\n")
        logFile:close()
    else
        print("Error: Could not open log file.")
    end
end

-- Function to dissect structure and extract player data based on dynamic configuration
function dissectStructureAtAddress(address, config)
    if not address or address == 0 then
        print("Error: Invalid address for dissection.")
        return
    end

    local offsets = config.offsets

    -- Create a structure dissection object in Cheat Engine
    local dissectionResult = createStructureDissectData()
    dissectionResult.dissect(address)

    if dissectionResult then
        print("Dissected structure at address: " .. address)

        -- Use safe read functions to avoid errors when accessing invalid memory
        local positionX = safeReadFloat(address + offsets.position)
        local health = safeReadFloat(address + offsets.health)
        local inventory = safeReadInteger(address + offsets.inventory)

        if positionX and health and inventory then
            print(string.format("Position: X=%f", positionX))
            print("Health: " .. health)
            print("Inventory Item ID: " .. inventory)

            -- Log to file
            local logData = string.format("Position: X=%f, Health: %f, Inventory: %d", positionX, health, inventory)
            logToFile(logData)
        else
            print("Error: Failed to read one or more attributes.")
        end
    else
        print("Error: Failed to dissect structure at address: " .. address)
    end
end

-- Main function to execute the script
function main()
    -- Step 1: Select game configuration dynamically
    local config = selectGameConfig()
    if not config then return end

    -- Step 2: Check if a process is attached
    if not checkProcessAttached() then return end

    -- Step 3: Detect Unreal Engine version dynamically based on config
    local engineVersion = ueDetermineVersion(config)
    print("Detected Unreal Engine version: " .. engineVersion)

    -- Step 4: Get user input for player coordinates
    local x, y, z = getPlayerCoordinates()
    print("Scanning for player coordinates: X=" .. x .. ", Y=" .. y .. ", Z=" .. z)

    -- Step 5: Perform a heuristic memory scan for the coordinates (could implement batched scanning if needed)
    -- Assume batchedMemoryScan is already implemented if needed
    local coordinateAddresses = scanForCoordinates(x, y, z)
    if not coordinateAddresses.x or not coordinateAddresses.y or not coordinateAddresses.z then
        print("Error: Failed to find one or more coordinate addresses.")
        return
    end

    -- Step 6: Dissect the structure at the found X coordinate address (using dynamic offsets)
    dissectStructureAtAddress(coordinateAddresses.x, config)
end

-- Execute the main function
main()
