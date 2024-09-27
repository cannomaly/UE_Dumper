-- Load the game-specific configuration from config.lua if available, otherwise use defaults
function loadConfig(game_id)
    local configFile = "config.lua"
    local config = {}

    -- Try loading config from config.lua
    local file = io.open(configFile, "r")
    if file then
        file:close()
        local status, result = pcall(dofile, configFile) -- Add pcall for error handling
        if status then
            config = result
            print("Config loaded from config.lua")
        else
            print("Error loading config.lua: " .. result)
        end
    else
        print("Warning: config.lua file not found. Using default configuration.")
    end

    -- Fallback to default config if none is found for the game_id
    config[game_id] = config[game_id] or {
        memory_patterns = {
            ue5_pattern = "default_ue5_pattern",
            ue4_pattern = "default_ue4_pattern"
        }
    }

    return config[game_id]
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

-- Pattern scan caching mechanism to avoid redundant scans
local scanCache = {}

function cacheScan(pattern, description)
    if scanCache[pattern] then
        print(description .. " already cached.")
        return scanCache[pattern]
    else
        local result = AOBScan(pattern, "*W")
        if result then
            scanCache[pattern] = result
            return result
        end
    end
    return nil
end

-- Function to detect Unreal Engine version dynamically based on configuration
function ueDetermineVersion(config)
    if cacheScan(config.memory_patterns.ue5_pattern, "UE5") then
        return 50  -- Return 50 for UE5
    elseif cacheScan(config.memory_patterns.ue4_pattern, "UE4.25+") then
        return 25  -- Return 25 for UE4.25+
    else
        return 22  -- Fallback for older versions of UE4 (4.22 and below)
    end
end

-- Custom exception handling for memory read
function tryReadFloat(address)
    local status, result = pcall(function() return readFloat(address) end)
    if not status then
        print("Error reading float at address: " .. string.format("0x%X", address))
        return nil
    end
    return result
end

function tryReadInteger(address)
    local status, result = pcall(function() return readInteger(address) end)
    if not status then
        print("Error reading integer at address: " .. string.format("0x%X", address))
        return nil
    end
    return result
end

-- Helper function to verify that the coordinates are within a reasonable range
function verifyCoordinates(posX, posY, posZ)
    local validRange = 10000 -- Example of a reasonable range for game coordinates
    if not posX or not posY or not posZ then
        print("Error: One or more coordinates are invalid.")
        return false
    end
    if math.abs(posX) < validRange and math.abs(posY) < validRange and math.abs(posZ) < validRange then
        return true
    else
        print("Coordinates out of valid range. Found: X=" .. posX .. ", Y=" .. posY .. ", Z=" .. posZ)
        return false
    end
end

-- Function to read floating-point values at addresses with validation
local function readEntityValues(address)
    if not address or address == 0 then
        print("Error: Invalid entity address.")
        return
    end

    local posX = tryReadFloat(address)
    local posY = tryReadFloat(address + 0x4)
    local posZ = tryReadFloat(address + 0x8)
    local health = tryReadFloat(address + 0xC)

    -- Validate the coordinates
    if verifyCoordinates(posX, posY, posZ) then
        print("Entity at Address: " .. string.format("0x%X", address))
        print("Position X: " .. posX)
        print("Position Y: " .. posY)
        print("Position Z: " .. posZ)
        print("Health: " .. health)
    else
        print("Invalid entity coordinates, skipping...")
    end
end

-- Memory scan progress bar
function showProgress(current, total)
    local percent = math.floor((current / total) * 100)
    io.write("\rProgress: [" .. string.rep("=", percent // 2) .. string.rep(" ", 50 - percent // 2) .. "] " .. percent .. "%")
    io.flush()
end

-- Function to scan and dissect memory dynamically using pointer paths
function scanAndDissect()
    local x, y, z = promptForCoordinates()
    local baseAddress = heuristicScanForCoordinates(x, y, z)
    local totalAddresses = 100000  -- Example total for progress tracking (adjust based on actual usage)

    if baseAddress then
        print("Base address found: " .. string.format("0x%X", baseAddress))

        -- Read the entity values at the dynamic address
        local co = coroutine.create(function ()
            for i = 1, totalAddresses do
                -- Simulate memory scan
                coroutine.yield(i)
                showProgress(i, totalAddresses)
            end
            readEntityValues(baseAddress)
        end)

        -- Resume coroutine in chunks
        while coroutine.status(co) ~= "dead" do
            local status, result = coroutine.resume(co)
            -- Handle progress here, e.g., show progress every step
        end
    else
        print("Failed to find a valid base address.")
    end
end

-- Function to dissect a memory structure starting from a base address with configurable step size
function dissectStructure(baseAddress, size, stepSize)
    stepSize = stepSize or 4 -- Default to 4-byte step for floats
    local currentAddress = baseAddress
    local endAddress = baseAddress + size
    local offset = 0

    print("Dissecting structure at base address: " .. string.format("0x%X", baseAddress))

    while currentAddress < endAddress do
        local value
        if stepSize == 4 then
            value = tryReadFloat(currentAddress)
        elseif stepSize == 8 then
            value = tryReadInteger(currentAddress)  -- For 8-byte integers
        end
        print("Offset " .. offset .. ": " .. value)
        currentAddress = currentAddress + stepSize
        offset = offset + stepSize
    end
end

-- Logging feature: Log entity values to a file for analysis with automatic backup
function backupLog(filename)
    local file = io.open(filename, "r")
    if file then
        file:close()
        os.rename(filename, filename .. ".bak")
    end
end

function logEntityValues(address, filename)
    backupLog(filename)

    local file, err = io.open(filename, "a+")
    if not file then
        print("Error opening file: " .. filename .. " - " .. err)
        return
    end

    local posX = tryReadFloat(address)
    local posY = tryReadFloat(address + 0x4)
    local posZ = tryReadFloat(address + 0x8)
    local health = tryReadFloat(address + 0xC)

    file:write("Entity Address: " .. string.format("0x%X", address) .. "\n")
    file:write("Position X: " .. posX .. "\n")
    file:write("Position Y: " .. posY .. "\n")
    file:write("Position Z: " .. posZ .. "\n")
    file:write("Health: " .. health .. "\n")
    file:write("--------------------------------------------\n")
    file:close()
    print("Entity values logged to " .. filename)
end

-- Call to scan and dissect entities dynamically using pointer paths
scanAndDissect()

-- Example call: Start dissection at the entity's base address and dissect 64 bytes (size can be adjusted)
-- Uncomment the following line to use it as needed
-- dissectStructure(0x10000000, 64, 4) -- Replace 0x10000000 with the actual base address, stepSize configurable

-- Example of logging:
-- logEntityValues(0x10000000
