## Feel free to use this in a script.

## Load the ESP
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
```
## Customizable Settings for ESP
```lua
getgenv().dhlock = {
    enabled = false,
    showfov = false, -- Show FOV circle
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    teamcheck = false, -- Enable/disable team check
    wallcheck = false, -- Checks for walls
    alivecheck = false, -- Enable/disable alive check
    lockpart = "Head", -- Part to lock onto when on the ground
    lockpartair = "Head", -- Part to lock onto when in the air
    smoothness = 1, -- Smoothness factor (higher = slower)
    predictionX = 0, -- Prediction multiplier for X-axis (horizontal)
    predictionY = 0, -- Prediction multiplier for Y-axis (vertical)
    fovcolorlocked = Color3.new(1, 0, 0), -- Color when locked
    fovcolorunlocked = Color3.new(0, 0, 0), -- Color when unlocked
    toggle = false, -- Toggle mode (set true for toggle, false for hold)
    blacklist = {} -- Blacklisted players
}
```
