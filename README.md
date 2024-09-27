# -- Unreal Engine Dumper Script for Cheat Engine --
This project provides a Lua script for dynamically scanning, dissecting, and extracting player data from a game's memory using Cheat Engine. It supports games built with both Unreal Engine 4 and Unreal Engine 5.

## Features

- **Process Attachment Check**: Ensures that Cheat Engine is attached to the target process before scanning memory.
- **Dynamic Game Configuration**: Easily switch between multiple games using a configuration file (`config.lua`) with game-specific memory offsets and patterns.
- **Unreal Engine Version Detection**: Automatically detects whether the game uses UE4 or UE5 based on memory pattern scanning.
- **Pattern Scan Caching**: Cached pattern scanning results to avoid redundant scans, improving performance in repeated scans.
- **Threaded Memory Scanning**: Utilizes Lua's `coroutine` to allow non-blocking memory scans for large memory spaces.
- **Memory Dissection**: Extracts player data such as position and health.
- **Configurable Memory Dissection**: Allows customizable step size for dissection, making it adaptable to various memory structures.
- **Batched Memory Scanning**: Efficiently scans large memory spaces using batch processing for better performance.
- **Custom Exception Handling**: Safely reads memory addresses using custom exception handling with `pcall`, preventing crashes from invalid or inaccessible memory locations.
- **Memory Scan Progress Bar**: Displays a progress bar in the console during large memory scans, providing real-time feedback on the scan's progress.
- **Logging with Automatic Backup**: Extracted player data is logged to a file (`player_data_log.txt`), with automatic backup of previous logs before they are overwritten.

## Prerequisites

1. **Cheat Engine**: Download and install Cheat Engine from the official website.
2. **Lua Environment**: This script is intended to be run within Cheat Engine's Lua scripting environment.

## Setup Instructions

### Step 1: Clone the Repository and Install Cheat Engine

1. Clone this repository to your local machine by downloading or pulling it from your GitHub repository.
   ```bash
   https://github.com/cannomaly/UE_Dumper.git
   ```
   
3. Install Cheat Engine:

   - Download Cheat Engine from the official website.
   - Install it on your system by following the provided installation instructions.

### Step 2: Configure Your Games

To configure the script for specific games, modify the `config.lua` file available in your repository. This file contains game-specific memory offsets and Unreal Engine detection patterns.

### Step 3: Run the Script in Cheat Engine

1. **Open Cheat Engine** and attach it to the game's process:
   - Click on the **Select a process to open** button (computer icon in the top-left).
   - Choose the correct game process from the list.
   
2. Open the Lua script:
   - Click on **Table** > **Show Cheat Table Lua Script**.
   - Copy and paste the Lua script (`UE_Dumper.lua`) into the Lua script window.

3. Execute the script:
   - Click on **Execute Script** to run the script.

### Step 4: Results

Once the script runs, it will scan memory for relevant player data, including:
   - Position (X, Y, Z)
   - Health

Results will be displayed in the Cheat Engine console and logged to `player_data_log.txt`.

```plaintext
### Example Output

Detected Unreal Engine version: 25
Found base address: 0x12345678
Dissected structure at address: 0x12345678
Position: X=120.0, Y=250.0, Z=15.0
Health: 100.0
