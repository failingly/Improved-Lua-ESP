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

-- Declarations --
local localplayer = game.Players.LocalPlayer
local currentcamera = workspace.CurrentCamera
local worldtoviewportpoint = currentcamera.WorldToViewportPoint

-- Functions --
local function draw(obj, props)
    local new = Drawing.new(obj)
    
    props = props or {}
    
    for i, v in pairs(props) do
        new[i] = v
    end
    
    return new
end

function esp:getteam(p)
    local ov = self.overrides.getteam
    
    if ov then
        return ov(p)
    end
    
    return p and p.Team
end

function esp:isteammate(p)
    local ov = self.overrides.isteammate
    
    if ov then
        return ov(p)
    end
    
    return self:getteam(p) == self:getteam(localplayer)
end

function esp:getcolor(obj)
    local ov = self.overrides.getcolor
    
    if ov then
        return ov(obj)
    end
    
    local p = self:getplrfromchar(obj)
    
    return p and (self.useteamcolor and p.Team and p.Team.TeamColor.Color) or (p.Team and p.Team.TeamColor ~= localplayer.Team.TeamColor and self.enemycolor or self.teamcolor)
end

function esp:getplrfromchar(char)
    local ov = self.overrides.getplrfromchar
    
    if ov then
        return ov(char)
    end
    
    return game.Players:GetPlayerFromCharacter(char)
end

function esp:toggle(bool)
    self.enabled = bool
    if not bool then
        for i, v in pairs(self.objects) do
            if v.type == "Box" then
                if v.temporary then
                    v:remove()
                else
                    for i, v in pairs(v.components) do
                        v.Visible = false
                    end
                end
            end
        end
    end
end

function ESP:GetBox(obj)
    return self.Objects[obj]
end

function ESP:AddObjectListener(parent, options)
    local function NewListener(c)
        if (not options.Type or c:IsA(options.Type)) and (not options.Name or c.Name == options.Name) then
            if not options.Validator or options.Validator(c) then
                local box = self:Add(c, {
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
        parent.DescendantAdded:Connect(NewListener)
        for _, v in ipairs(parent:GetDescendants()) do
            task.spawn(NewListener, v)
        end
    else
        parent.ChildAdded:Connect(NewListener)
        for _, v in ipairs(parent:GetChildren()) do
            task.spawn(NewListener, v)
        end
    end
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for _, v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
    end
    self.Components = {}
end

function boxBase:Update()
    if not self.PrimaryPart or not self.PrimaryPart:IsDescendantOf(workspace) then
        return self:Remove()
    end

    local color = ESP.Highlighted == self.Object and ESP.HighlightColor or self.Color or ESP:GetColor(self.Object) or ESP.Color
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
        for _, v in pairs(self.Components) do
            v.Visible = false
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

function ESP:Add(obj, options)
    if not obj.Parent and not options.RenderInNil then
        return warn(obj, "has no parent")
    end

    local box = setmetatable({
        Name = options.Name or obj.Name,
        Type = "Box",
        Color = options.Color,
        Size = options.Size or self.BoxSize,
        Object = obj,
        Player = options.Player or game.Players:GetPlayerFromCharacter(obj),
        PrimaryPart = options.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:IsA("BasePart") and obj,
        Components = {},
        IsEnabled = options.IsEnabled,
        Temporary = options.Temporary,
        RenderInNil = options.RenderInNil
    }, boxBase)

    if self:GetBox(obj) then
        self:GetBox(obj):Remove()
    end

    box.Components["Quad"] = Draw("Quad", {
        Thickness = self.Thickness,
        Color = box.Color,
        Transparency = 1,
        Filled = false,
        Visible = self.Enabled and self.Boxes
    })

    self.Objects[obj] = box

    obj.AncestryChanged:Connect(function(_, parent)
        if not parent and ESP.AutoRemove then
            box:Remove()
        end
    end)

    obj:GetPropertyChangedSignal("Parent"):Connect(function()
        if not obj.Parent and ESP.AutoRemove then
            box:Remove()
        end
    end)

    return box
end

game.Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        ESP:Add(char, {
            Name = p.Name,
            Player = p,
            PrimaryPart = char:WaitForChild("HumanoidRootPart")
        })
    end)
end)

for _, v in pairs(game.Players:GetPlayers()) do
    if v ~= game.Players.LocalPlayer then
        ESP:Add(v.Character, {
            Name = v.Name,
            Player = v,
            PrimaryPart = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
        })
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    for _, v in pairs(ESP.Objects) do
        if v.Update then
            pcall(v.Update, v)
        end
    end
end)

return ESP
