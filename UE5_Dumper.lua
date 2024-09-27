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

-- Function to scan a pattern with description and return result
function scanPattern(pattern, description)
    local scanResult = AOBScan(pattern, "*W")
    if scanResult then
        print(description .. " detected.")
        return true
    end
    return false
end

-- Function to detect Unreal Engine version dynamically based on configuration
function ueDetermineVersion(config)
    if scanPattern(config.memory_patterns.ue5_pattern, "UE5") then
        return 50  -- Return 50 for UE5
    elseif scanPattern(config.memory_patterns.ue4_pattern, "UE4.25+") then
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

    local posX = readFloat(address)
    local posY = readFloat(address + 0x4)
    local posZ = readFloat(address + 0x8)
    local health = readFloat(address + 0xC)

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

-- Function to scan and dissect memory dynamically using pointer paths
function scanAndDissect()
    local x, y, z = promptForCoordinates()
    local baseAddress = heuristicScanForCoordinates(x, y, z)

    if baseAddress then
        print("Base address found: " .. string.format("0x%X", baseAddress))

        -- Read the entity values at the dynamic address
        readEntityValues(baseAddress)
    else
        print("Failed to find a valid base address.")
    end
end

-- Function to dissect a memory structure starting from a base address
function dissectStructure(baseAddress, size, stepSize)
    stepSize = stepSize or 4 -- Default to 4-byte step for float values
    local currentAddress = baseAddress
    local endAddress = baseAddress + size
    local offset = 0

    print("Dissecting structure at base address: " .. string.format("0x%X", baseAddress))

    while currentAddress < endAddress do
        local value = readFloat(currentAddress)

        -- Guess the type or label based on certain criteria (e.g., position, health, etc.)
        if offset == 0 then
            print("Offset " .. offset .. " (X Coordinate): " .. value)
        elseif offset == 4 then
            print("Offset " .. offset .. " (Y Coordinate): " .. value)
        elseif offset == 8 then
            print("Offset " .. offset .. " (Z Coordinate): " .. value)
        elseif offset == 12 then
            print("Offset " .. offset .. " (Health): " .. value)
        else
            print("Offset " .. offset .. ": " .. value)
        end

        currentAddress = currentAddress + stepSize
        offset = offset + stepSize
    end
end

-- Logging feature: Log entity values to a file for analysis
function logEntityValues(address, filename)
    local file, err = io.open(filename, "a+")
    if not file then
        print("Error opening file: " .. filename .. " - " .. err)
        return
    end

    local posX = readFloat(address)
    local posY = readFloat(address + 0x4)
    local posZ = readFloat(address + 0x8)
    local health = readFloat(address + 0xC)

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
-- dissectStructure(0x10000000, 64) -- Replace 0x10000000 with the actual base address

-- Example of logging:
-- logEntityValues(0x10000000, "entity_log.txt") -- Replace with actual base address
