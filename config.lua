-- config.lua

return {
    ["game_1"] = {
        name = "Example Game 1",
        ue_version = 25,  -- UE4.25+
        offsets = {
            position = 0x00,
            health = 0x10,
            velocity = 0x14,
            inventory = 0x30,
            status_effect = 0x40,
            equipment = 0x50,
            cooldown = 0x60,
            mana = 0x70,
            stamina = 0x80,
        },
        memory_patterns = {
            ue5_pattern = "48 89 5C 24 08 57 48 83 EC 20 48 8B F9",
            ue4_pattern = "48 89 5C 24 08 57 48 83 EC 30 48 8B F9",
        }
    },
    ["game_2"] = {
        name = "Example Game 2",
        ue_version = 50,  -- UE5
        offsets = {
            position = 0x08,
            health = 0x20,
            velocity = 0x24,
            inventory = 0x40,
            status_effect = 0x50,
            equipment = 0x60,
            cooldown = 0x70,
            mana = 0x80,
            stamina = 0x90,
        },
        memory_patterns = {
            ue5_pattern = "48 89 5C 24 08 57 48 83 EC 20 48 8B F9",
            ue4_pattern = "48 89 5C 24 08 57 48 83 EC 30 48 8B F9",
        }
    }
}
