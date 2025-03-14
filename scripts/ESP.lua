-- Set the global ESP environment
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
    facecamera = true,
    thickness = 1,
    attachShift = 1,
    objects = setmetatable({}, {__mode = "kv"}), -- Weak table to avoid memory leaks
    overrides = {}
}

-- Utility functions
local function draw(obj, props)
    local new = Drawing.new(obj)
    
    props = props or {}
    
    for i, v in pairs(props) do
        new[i] = v
    end
    
    return new
end

local function getPlrFromChar(char)
    local ov = ESP.overrides.getPlrFromChar
    
    if ov then
        return ov(char)
    end
    
    return game.Players:GetPlayerFromCharacter(char)
end

local function toggle(enabled)
    ESP.enabled = enabled
    if not enabled then
        for _, v in pairs(ESP.objects) do
            if v.type == "Box" then
                if v.temporary then
                    v:remove()
                else
                    for _, component in pairs(v.components) do
                        component.Visible = false
                    end
                end
            end
        end
    end
end

-- Get Box method restored
function ESP:getBox(obj)
    return ESP.objects[obj]
end

local function addObjectListener(parent, options)
    local function newListener(c)
        if (not options.Type or c:IsA(options.Type)) and (not options.Name or c.Name == options.Name) then
            if not options.Validator or options.Validator(c) then
                local box = ESP:add(c, {
                    PrimaryPart = (type(options.PrimaryPart) == "string" and c:FindFirstChild(options.PrimaryPart)) or
                                  (type(options.PrimaryPart) == "function" and options.PrimaryPart(c)),
                    Color = (type(options.Color) == "function" and options.Color(c)) or options.Color,
                    ColorDynamic = options.ColorDynamic,
                    Name = (type(options.CustomName) == "function" and options.CustomName(c)) or options.CustomName,
                    IsEnabled = options.IsEnabled,
                    RenderInNil = options.RenderInNil
                })
                
                if options.OnAdded then
                    task.spawn(options.OnAdded, box)  -- Using task.spawn instead of coroutine.wrap
                end
            end
        end
    end

    if options.Recursive then
        parent.DescendantAdded:Connect(newListener)
        for _, v in ipairs(parent:GetDescendants()) do
            task.spawn(newListener, v)
        end
    else
        parent.ChildAdded:Connect(newListener)
        for _, v in ipairs(parent:GetChildren()) do
            task.spawn(newListener, v)
        end
    end
end

-- Define the boxBase class with methods for remove and update
local boxBase = {}
boxBase.__index = boxBase

function boxBase:remove()
    ESP.objects[self.Object] = nil
    for _, component in pairs(self.Components) do
        component.Visible = false
        component:Remove()
    end
    self.Components = {}
end

function boxBase:update()
    if not self.PrimaryPart or not self.PrimaryPart:IsDescendantOf(workspace) then
        return self:remove()
    end

    local color = ESP.Highlighted == self.Object and ESP.HighlightColor or self.Color or ESP.Color
    local allow = true

    if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
        allow = false
    end
    if self.Player and not ESP.ShowTeam and ESP:IsTeamMate(self.Player) then
        allow = false
    end
    if self.Player and not ESP.TargetPlayers then
        allow = false
    end
    if self.IsEnabled and ((type(self.IsEnabled) == "string" and not ESP[self.IsEnabled]) or (type(self.IsEnabled) == "function" and not self:IsEnabled())) then
        allow = false
    end

    if not allow then
        for _, component in pairs(self.Components) do
            component.Visible = false
        end
        return
    end

    local cf = self.PrimaryPart.CFrame + Vector3.new(0, 1, 0)

    if ESP.FaceCamera then
        cf = CFrame.new(cf.p, workspace.CurrentCamera.CFrame.p)
    end

    local size = self.Size
    local locs = {
        TopLeft = cf * ESP.BoxShift * CFrame.new(size.X / 2, size.Y / 2, 0),
        TopRight = cf * ESP.BoxShift * CFrame.new(-size.X / 2, size.Y / 2, 0),
        BottomLeft = cf * ESP.BoxShift * CFrame.new(size.X / 2, -size.Y / 2, 0),
        BottomRight = cf * ESP.BoxShift * CFrame.new(-size.X / 2, -size.Y / 2, 0),
        TagPos = cf * ESP.BoxShift * CFrame.new(0, size.Y / 2, 0)
    }

    -- Box Drawing --
    if ESP.Boxes and self.Components.Quad then
        local TopLeft, Vis1 = workspace.CurrentCamera:WorldToViewportPoint(locs.TopLeft.p)
        local TopRight, Vis2 = workspace.CurrentCamera:WorldToViewportPoint(locs.TopRight.p)
        local BottomLeft, Vis3 = workspace.CurrentCamera:WorldToViewportPoint(locs.BottomLeft.p)
        local BottomRight, Vis4 = workspace.CurrentCamera:WorldToViewportPoint(locs.BottomRight.p)

        self.Components.Quad.Visible = Vis1 or Vis2 or Vis3 or Vis4
        if self.Components.Quad.Visible then
            self.Components.Quad.PointA = Vector2.new(TopRight.X, TopRight.Y)
            self.Components.Quad.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
            self.Components.Quad.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
            self.Components.Quad.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
            self.Components.Quad.Color = color
        end
    end
end

-- Add an object to the ESP
function ESP:add(obj, options)
    if not obj.Parent and not options.RenderInNil then
        return warn(obj, "has no parent")
    end

    local box = setmetatable({
        Name = options.Name or obj.Name,
        Type = "Box",
        Color = options.Color,
        Size = options.Size or ESP.BoxSize,
        Object = obj,
        Player = options.Player or game.Players:GetPlayerFromCharacter(obj),
        PrimaryPart = options.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:IsA("BasePart") and obj,
        Components = {},
        IsEnabled = options.IsEnabled,
        Temporary = options.Temporary,
        RenderInNil = options.RenderInNil
    }, boxBase)

    -- Prevent adding the same object again
    if ESP:getBox(obj) then
        ESP:getBox(obj):remove()
    end

    -- Adding drawing for the box
    box.Components["Quad"] = draw("Quad", {
        Thickness = ESP.Thickness,
        Color = box.Color,
        Transparency = 1,
        Filled = false,
        Visible = ESP.enabled and ESP.Boxes
    })

    ESP.objects[obj] = box

    -- Handle object removal if it loses parent
    obj.AncestryChanged:Connect(function(_, parent)
        if not parent and ESP.AutoRemove then
            box:remove()
        end
    end)

    obj:GetPropertyChangedSignal("Parent"):Connect(function()
        if not obj.Parent and ESP.AutoRemove then
            box:remove()
        end
    end)

    return box
end

-- Event listeners for adding ESP to characters
game.Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        ESP:add(char, {
            Name = p.Name,
            Player = p,
            PrimaryPart = char:WaitForChild("HumanoidRootPart")
        })
    end)
end)

-- Loop through existing players and add ESP
for _, v in pairs(game.Players:GetPlayers()) do
    if v ~= game.Players.LocalPlayer then
        ESP:add(v.Character, {
            Name = v.Name,
            Player = v,
            PrimaryPart = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
        })
    end
end

-- Continuously update the ESP boxes during the RenderStepped event
game:GetService("RunService").RenderStepped:Connect(function()
    for _, v in pairs(ESP.objects) do
        if v.update then
            pcall(v.update, v)
        end
    end
end)

return ESP
