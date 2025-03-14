## Feel free to use this in a script.

## Load the ESP
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/failingly/Improved-Lua-ESP/refs/heads/main/scripts/ESP.lua"))()
```
## Customizable Settings for ESP
```lua
getgenv().ESP = {
    enabled = false,
    tracers = true,
    boxes = true,
    showinfo = true,
    useteamcolor = true,
    teamcolor = Color3.new(0, 1, 0),
    enemycolor = Color3.new(1, 0, 0),
    showteam = true,
	info = {
		["Name"] = true,
		["Health"] = true,
		["Weapons"] = true,
		["Distance"] = true
	},
	
    boxshift = CFrame.new(0, -1.5, 0),
    boxsize = Vector3.new(4, 6, 0),
    color = Color3.fromRGB(255, 255, 255),
    targetplayers = true,
    facecamera = true, -- i changed last time
    thickness = 1,
    attachShift = 1,
    objects = setmetatable({}, {__mode="kv"}),
    overrides = {}
}
```
