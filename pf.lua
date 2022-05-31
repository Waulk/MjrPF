-- Libraries
local Math = loadstring(game:HttpGet("https://raw.githubusercontent.com/Waulk/MjrPF/main/irays_math.lua"))()
local Prediction = loadstring(game:HttpGet("https://raw.githubusercontent.com/Waulk/MjrPF/main/prediction.lua"))()
local Flux = loadstring(game:HttpGet"https://raw.githubusercontent.com/Waulk/MjrPF/main/FluxLib.lua)()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--Random values
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local mouse = Players.LocalPlayer:GetMouse()
userInput = game:GetService("UserInputService")
local gravity = workspace.gravity

local guns = {}
local disallowed = {"JUGGUN", "PAINTBALL GUN", "PPK12", "SVK12E", "MG42"}
for i,v in pairs(game.ReplicatedStorage.Content.ProductionContent.GunModules:GetChildren()) do
    if not table.find(disallowed, v.Name) and not string.find(string.lower(v.Name),"old") then
        guns[v.Name] = require(v)
    end
end
function GetWeaponSpeed()
    local name = nil 
    for i,v in pairs(workspace.CurrentCamera:GetChildren()) do
        if v.Name ~= "Left Arm" and v.Name ~= "Right Arm" then
            name = v.Name
            break
        end
    end
    if (guns[name]) then
        return guns[name].bulletspeed
    end
    return nil
end


local settings = {visuals = {
    name = true,
    chams = true,
    chamc = Color3.fromRGB(255,25,25),
    vchams = true,
    vchamc = Color3.fromRGB(4, 255, 0),
    ball = true,
    cross = true,
    crossc = Color3.fromRGB(255,0,0),
    dead = true
}, rage ={
    aim = true,
    aiming = false,
    velocity = false,
    smooth = 3,
    showfov = false,
    fov = 30,
    wallcheck = true
}}


drawingcache = {}
function Create(Class, Properties)
    local Object = Drawing.new(Class)

    for i,v in pairs(Properties) do
        Object[i] = v
    end

    table.insert(drawingcache, Object)
    return Object
end

local crosshair = Create("Circle",{Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2),
Color = Color3.fromRGB(255,0,0),
Thickness = 0.1,
NumSides = 12,
Radius = 4,
Visible = false,
Filled = false})

local fov = Create("Circle",{Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2),
Color = Color3.fromRGB(255,255,255),
Thickness = 0.1,
NumSides = 12,
Radius = 4,
Visible = false,
Filled = false})


velocities = {}
lastTime = 0

--[[
######
######  WINDOW START
######
]]

local win = Flux:Window("Mjr PF 2.0", "Ur A Pred", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local visuals = win:Tab("Visuals ", "https://www.roblox.com/library/243755563/Eye")
local rage = win:Tab("Rage","https://www.roblox.com/library/20016321/Skull")
visuals:Toggle("Names", "Show the names of your foes.", true, function(value)
    settings.visuals.name = value
end)
visuals:Toggle("Chams", "See enemy players through walls!", true, function(value)
    settings.visuals.chams = value
    destroyChams()
    loadChams()
end)
visuals:Colorpicker("Chams Color", Color3.fromRGB(255,25,25), function(value)
    settings.visuals.chamc = value
    destroyChams()
    loadChams()
end)

visuals:Toggle("Visible Chams", "Highlights the visible parts of the enemies!", true, function(value)
    settings.visuals.vchams = value
    destroyChams()
    loadChams()
end)
visuals:Colorpicker("Visible Chams Color", Color3.fromRGB(4, 255, 0), function(value)
    settings.visuals.vchamc = value
    destroyChams()
    loadChams()
end)
visuals:Line()
visuals:Toggle("Ballistics Tracker", "A built in ballistics tracker into every gun!", true, function(value)
    settings.visuals.ball = value
end)
visuals:Toggle("Crosshair", "Shows you the centre of you screen.", true, function(value)
    settings.visuals.cross = value
end)
visuals:Colorpicker("Crosshair Colour", Color3.fromRGB(255,0,0), function(value)
    settings.visuals.crossc = value
    crosshair.Color = value
end)
visuals:Toggle("Remove Bodies", "Removes all the dead bodies when they appear.", true, function(value)
    settings.visuals.dead = value
end)
--RAGE
rage:Toggle("Aimbot", "Show off your true skill with this trusty aim!", true, function(value)
    settings.rage.aim = value
end)
rage:Toggle("Predit Movement", "Predicts the movement of the person moving.", false, function(value)
    settings.rage.velocity = value
end)
rage:Toggle("Wall Check", "Choose to shoot through walls or not", true, function(value)
    settings.rage.wallcheck = value
end)
rage:Slider("Smoothness", "How smooth your movement will be for locking on.", 1, 50, 3, function(value)
    settings.rage.smooth = value
end)
rage:Toggle("Show FOV", "See your FOV for your skill!", false, function(value)
    settings.rage.showfov = value
end)
rage:Slider("FOV", "Set your FOV for the aimbot.", 5, 400, 30, function(value)
    settings.rage.fov = value
end)
--[[
######
######  WINDOW END
######
]]


animations = {}
getgenv().client = {}; do
    local gc = getgc(true)  
    for i = #gc, 1, -1 do
        local v = gc[i]
        local type = type(v)
        if type == 'function' then
            if debug.getinfo(v).name == "loadmodules" then
                client.loadmodules = v
            end
        end 
        if type == "table" then
            if (rawget(v, 'send')) then
                client.network = v
            elseif (rawget(v, 'basecframe')) then
                client.camera = v
            elseif (rawget(v, "gammo")) then
                client.gamelogic = v
            elseif (rawget(v, "getbodyparts")) then
                client.replication = v
                client.replication.bodyparts = debug.getupvalue(client.replication.getbodyparts, 1)
            elseif (rawget(v, "updateammo")) then
                client.hud = v
            elseif (rawget(v, "setbasewalkspeed")) then
                client.char = v
            elseif (rawget(v, "getscale")) then
                client.uiscaler = v
            end
            if rawget(v, 'player') then
                table.insert(animations, v)
            end
        end
    end
end


function addSurface(obj)
    
	for i,v in pairs({"Back","Front","Left","Right","Bottom","Top"}) do
        if (settings.visuals.chams) then
            local new = Instance.new("SurfaceGui")
            new.AlwaysOnTop=true
            new.Face = v
            local frame = Instance.new("Frame",new)
            frame.Size = UDim2.new(1,0,1,0)
            frame.BackgroundColor3 = settings.visuals.chamc
            frame.Transparency = .7
            frame.BorderSizePixel = 0
            new.Adornee = obj
            new.Parent = obj
        end

        if (settings.visuals.vchams) then
            local newVIS = Instance.new("SurfaceGui")
            newVIS.Face = v
            local frameVIS = Instance.new("Frame",newVIS)
            frameVIS.Size = UDim2.new(1,0,1,0)
            frameVIS.BackgroundColor3 = settings.visuals.vchamc
            frameVIS.Transparency = 0
            frameVIS.BorderSizePixel = 0
            newVIS.Adornee = obj
            newVIS.Parent = obj
        end
	end
end

function CheckTeam(Player)
    return Player.Team.Name == game.Players.LocalPlayer.Team.Name
end

function GetCharacter(Player)
    local Character = client.replication.getbodyparts(Player)

    return Character and Character.torso.Parent, Character and Character.torso
end

function GetHealth(Player)
    return client.hud:getplayerhealth(Player)
end

function givePlayer(plr)
	for i,v in pairs(plr:GetChildren()) do
        addSurface(v)
	end
end

function destroyChams()
    for i,v in pairs(workspace.Players:GetDescendants()) do
        if v:IsA("SurfaceGui") then
            v:Destroy()
        end
    end
end

function loadChams()
    if (settings.visuals.vchams or settings.visuals.chams) then
        for i,v in pairs(Players:GetPlayers()) do
            if (not CheckTeam(v)) then
                local Character, Root = GetCharacter(v)
                if(Character and Root) then
                    givePlayer(Character)
                end
            end
        end
    end
end


function GetBoundingBox(Character)
    local Data = {}

    for i,v in pairs(Character:GetChildren()) do
        if (v:IsA("BasePart") and v.Name ~= "HumanoidRootPart") then
            for i2, v2 in pairs(Math.getpartinfo2(v.CFrame, v.Size)) do
                table.insert(Data, v2)
            end
        end
    end

    return Math.getposlist2(Data)
end

function AddEsp(Player)
    if (Player == LocalPlayer) then
        return
    end

    local Retainer = {}

    Retainer.nameobject = Create("Text", {
        Visible = false,
        Text = Player.Name,
        Color = Color3.fromRGB(255,25,25),
        Size = 15,
        Center = true,
        Outline = false,
        OutlineColor = Color3.new(0, 0, 0),
        Font = Drawing.Fonts.Plex
    })
    Retainer.head = Create("Circle",{
        Visible = false,
        Color = Color3.fromRGB(238,223,178),
        Thickness = 0,
        NumSides = 6,
        Radius = 6,
        Filled = true
    })
    local CanRun = true
    local first = true

    RunService:BindToRenderStep(Player.Name .. "Esp", 1, function()
        if (not CanRun) then
            return
        end
        
        local Character, Root = GetCharacter(Player)

        CanRun = false

        
        
        if (Character and Root) then

            local Health, MaxHealth = GetHealth(Player)
            local _, OnScreen = CurrentCamera:WorldToViewportPoint(Root.Position)
            local Magnitude = (Root.Position - CurrentCamera.CFrame.p).Magnitude
            local CanShow = OnScreen
            if (CheckTeam(Player)) then
                CanShow = false
            end

            if (Health <= 0) then
                CanShow = false
            end

            if (CanShow) then
                if (first) then
                    first = false
                    givePlayer(Character)
                end
                local Data = GetBoundingBox(Character)
                local Width, Height = math.floor(Data.Positions.TopLeft.X - Data.Positions.TopRight.X), math.floor(Data.Positions.TopLeft.Y - Data.Positions.BottomLeft.Y)
                local speed = GetWeaponSpeed()
                if (settings.visuals.ball and Character:FindFirstChild("Head") and speed and ShootRay(Character)) then
                    local positionOffset = Character.Head.Position - game.Workspace.CurrentCamera.CFrame.Position
                    local vel = Vector3.new(0,0,0)
                    if (Character.Head:FindFirstChild("spe")) then
                        vel = Character.Head.spe.Value
                    end
                    local num,position = Prediction:solve_ballistic_arc(Vector3.new(0,0,0), speed, positionOffset, vel, gravity)
                    position = position + game.Workspace.CurrentCamera.CFrame.Position
                    if(num > 0) then
                        Retainer.head.Visible = true
                        local pos = workspace.CurrentCamera:WorldToViewportPoint(position)
                        Retainer.head.Position = Vector2.new(pos.X - 3,pos.Y - 3)
                    else
                        Retainer.head.Visible = false
                    end
                else
                    Retainer.head.Visible = false
                end
                Retainer.nameobject.Visible = settings.visuals.name
                Retainer.nameobject.Position = Vector2.new(Data.Positions.Middle.X, (Data.Positions.TopLeft.Y - 15))
            else
                Retainer.nameobject.Visible = false
                Retainer.head.Visible = false
            end
        else
            Retainer.nameobject.Visible = false
            Retainer.head.Visible = false
            first = true
            
        end

        task.wait(math.clamp(1 / 60, 0, 9e9))

        CanRun = true

    end)
end

for i,v in pairs(Players:GetPlayers()) do
    AddEsp(v)
end

Players.PlayerAdded:Connect(function(Player)
    AddEsp(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    AddEsp(Player)
end)

workspace.Ignore.DeadBody.ChildAdded:connect(function(ch)
    if (settings.visuals.dead) then
        ch:Destroy()
    end
end)
mouse.Button2Down:connect(function() 
    settings.rage.aiming = true
end)
mouse.Button2Up:connect(function() 
    settings.rage.aiming = false
end)

local aimTarget = nil
local playerTarget = nil
function aimAt(pos)
    local targetPos = CurrentCamera:WorldToScreenPoint(pos)
    local mousePos = CurrentCamera:WorldToScreenPoint(mouse.Hit.p)
    local xD = (targetPos.X-mousePos.X)
    local yD = (targetPos.Y-mousePos.Y)
    mousemoverel(xD/settings.rage.smooth,yD/settings.rage.smooth)

end
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {CurrentCamera, workspace.Players}
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
function ShootRay(plr)
    if(not settings.rage.wallcheck) then 
        return true
    end
    local i = 0
    local lastHitVector = CurrentCamera.CFrame.Position
    while true do
        local result = workspace:Raycast(lastHitVector, plr.Head.Position - lastHitVector, raycastParams)
        i = i + 1
        if (result == nil) then
            return true
        elseif result.Instance.Transparency ~= 0 then
            lastHitVector =  result.Position
            table.insert(raycastParams.FilterDescendantsInstances, result.Instance)
        else
            return false
        end
        if (i > 10) then
            return false
        end
    end
end

while wait(1/30) do
    if Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and settings.rage.aim and settings.rage.aiming then
        local speed = GetWeaponSpeed()
        if speed then
            if not aimTarget or not aimTarget.Parent then
                local closest = nil
                local distance = 100000000000
                local screenCenter = CurrentCamera.ViewportSize / 2
                for i,x in pairs(workspace.Players:GetChildren()) do
                    if x.Name ~= game.Players.LocalPlayer.TeamColor.Name then
                        for i,v in pairs(x:GetChildren()) do
                            local positionOnScreen, onScreen = CurrentCamera:WorldToViewportPoint(v.Head.Position)
                            positionOnScreen = Vector2.new(positionOnScreen.x,positionOnScreen.y)
                            
                            local magnitude = (positionOnScreen - screenCenter)
                            magnitude = magnitude.Magnitude
                            if magnitude < distance and magnitude < settings.rage.fov and onScreen and ShootRay(v) then -- Checking if the part is closer to the center than the previous parts checked
                                distance = magnitude
                                closest = v
                            end
                        end
                    end
                end
                aimTarget = closest
            end
            if(aimTarget and aimTarget:FindFirstChild("Head")) then
                local vel = Vector3.new(0,0,0)
                if(aimTarget.Head:FindFirstChild("spe")) then
                    vel = aimTarget.Head.spe.Value
                end
                local num,position = Prediction:solve_ballistic_arc(CurrentCamera.CFrame.Position, speed, aimTarget.Head.Position, vel, gravity)
                if(num > 0) then
                    aimAt(position)
                end
            end
        end
    else
        settings.rage.aiming = false
        aimTarget = nil
    end
    if Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and settings.visuals.cross then
        crosshair.Visible = true
        crosshair.Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2)
    else
        crosshair.Visible = false
    end
    if settings.rage.showfov then
        fov.Visible = true
        fov.Position = Vector2.new(CurrentCamera.ViewportSize.X/2, CurrentCamera.ViewportSize.Y/2)
        fov.Radius = settings.rage.fov
    else
        fov.Visible = false
    end
    
    for i,v in pairs(Players:GetPlayers()) do
        local Character,Root = GetCharacter(v)
        if(Character and Root and Character:FindFirstChild("Head") and settings.rage.velocity) then
            if(not Character.Head:FindFirstChild("spe")) then
                local spe = Instance.new("Vector3Value",Character.Head)
                spe.Name = "spe"
            end
            if (velocities[v.Name]) then
                local del = ((tick() - lastTime))
                Character.Head.spe.Value = (Character.Head.Position - velocities[v.Name])/del
            end

            velocities[v.Name] = Character.Head.Position
        end
    end
    lastTime = tick()
end
