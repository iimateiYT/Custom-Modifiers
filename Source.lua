-- Documentations At: https://github.com/iimateiYT/Custom-Modifiers/blob/main/README.md

-- Wait For The Game
repeat
	task.wait()
until game:IsLoaded()

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- Modules
local Modifiers = require(ReplicatedStorage:WaitForChild("Modifiers"))
local AccessibleFloors = require(ReplicatedStorage:WaitForChild("AccessibleFloors"))

-- Place Check
if game.PlaceId == 6839171747 then
	local ModifierData = TeleportService:GetTeleportSetting("ModifierData")
	local CategoryData = TeleportService:GetTeleportSetting("CategoryData")

	Modifiers.categories = CategoryData

	for Name, Data in pairs(ModifierData) do
		local ModifierFolder = Instance.new("Folder", ReplicatedStorage:WaitForChild("LiveModifiers"))
		ModifierFolder.Name = Name

		Modifiers.mods[Name] = Data
	end

	return
elseif game.PlaceId ~= 6516141723 and game.PlaceId ~= 12308344607 then
	return
end

-- Tables
local CustomModifiers = {}
local FunctionTable = {
	GetInfo = function(ModSettings)
		if ModSettings.Merge then
			if ModSettings.Connect then
				return ModSettings
			else
				local Extra1 = 0
				local Extra2 = 0
				for _, Mods in pairs(Modifiers.mods) do
					if Mods.Category == ModSettings.Category and Mods.Merge == ModSettings.Merge and ModSettings.Merge ~= nil and math.abs(Mods.Sort - ModSettings.Sort) == 1 then
						if Mods.Sort - ModSettings.Sort > 0 then
							Extra2 = -0.5
						else
							Extra1 = 0.5
						end
					end
				end
				ModSettings.Connect = 0.5 + (Extra2 + Extra1)
			end
		end
		return ModSettings
	end
}

-- Guis
local PlayerGui = Players.LocalPlayer.PlayerGui
local MainUI = PlayerGui:WaitForChild("MainUI")
local CreateElevator = MainUI:WaitForChild("LobbyFrame"):WaitForChild("CreateElevator")

-- Variables
local ElevatorExists = false
local QueueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local WaitingCode = [[
repeat
	task.wait()
until game:IsLoaded() and not game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingUI").Enabled
]]

-- Global Variables
shared.EveryModifier = shared.EveryModifier or table.clone(Modifiers.mods)
shared.EveryCategory = shared.EveryCategory or table.clone(Modifiers.categories)
shared.EveryFloor = shared.EveryFloor or table.clone(AccessibleFloors)

shared.CustomModifiers = shared.CustomModifiers or {}
shared.CustomFloors = shared.CustomFloors or 101

shared.ToggleConnotations = false
shared.Teleported = false

-- Table Index
FunctionTable.__index = FunctionTable

-- Functions
function CreateModifier(ModifierAttributes)
	local randomCategory
	
	for Category in pairs(ModifierAttributes.Floor and AccessibleFloors[ModifierAttributes.Floor].Categories or Modifiers.categories) do
		randomCategory = Category
		break
	end
	
	return setmetatable({
		Category = ModifierAttributes.Category or randomCategory, 
		Name = ModifierAttributes.Title or "Modifier",
		Title = ModifierAttributes.Title or "Modifier",
		Desc = ModifierAttributes.Desc or "This probably does something, me meow.",
		Sort = ModifierAttributes.Sort or 99,
		Color = ModifierAttributes.Color or Color3.fromRGB(255, 222, 189),
		Bonus = ModifierAttributes.Bonus or 0,
		Penalties = ModifierAttributes.Penalties or {},
		Floor = ModifierAttributes.Floor or nil,
		Merge = ModifierAttributes.Merge or nil,
		Solo = ModifierAttributes.Solo or false,
		Unlock = ModifierAttributes.Unlock or nil,
		Activation = ModifierAttributes.Activation and (WaitingCode .. ModifierAttributes.Activation) or nil
	}, table.clone(FunctionTable))
end

function CreateCategory(CategoryAttributes)
	return {
		Name = CategoryAttributes.Name or "Example",
		sort = CategoryAttributes.Sort or 0,
		Floor = CategoryAttributes.Floor or nil,
		color = CategoryAttributes.Color or Color3.fromRGB(255, 222, 189)
	}
end

function CreateFloor(FloorAttributes)
	if not CreateElevator.Floors:FindFirstChild(FloorAttributes.Title or "[Floor]") then
		local newFloor = CreateElevator.Floors.Hotel:Clone()
		newFloor.Visible = false
		newFloor.Parent = CreateElevator.Floors
		newFloor.Name = FloorAttributes.Title or "[Floor]"
		newFloor.Text = FloorAttributes.Title or "[Floor]"
		newFloor.Background.Image = FloorAttributes.Image or ""
		newFloor.Font = FloorAttributes.Font or newFloor.Font
		newFloor.BackgroundColor3 = FloorAttributes.Theme or Color3.fromRGB(252, 219, 187)
		newFloor.TextColor3 = FloorAttributes.FontColor or Color3.fromRGB(255, 222, 189)
		shared.CustomFloors += 1
	end

	return {
		Name = FloorAttributes.Title or "[Floor]",
		Title = FloorAttributes.Title or "[Floor]",
		Destination = FloorAttributes.Destination or "Hotel",
		Requires = FloorAttributes.Requires or nil,
		Sort = FloorAttributes.Sort or shared.CustomFloors,
		Categories = {},
		Mods = {},
		Moddable = FloorAttributes.Moddable or false
	}
end

-- Module Functions
function CustomModifiers:DeleteModifier(Modifier, All)
	if All then
		Modifiers.mods = {}
		CustomModifiers:Connotation("Deleted All Modifiers.")
	elseif Modifier and Modifiers.mods[Modifier] then
		Modifiers.mods[Modifier] = nil
		CustomModifiers:Connotation('Deleted Modifier "' .. Modifier .. '".')
	else
		for _, FloorData in pairs(AccessibleFloors) do
			if FloorData.Mods and FloorData.Mods[Modifier] then
				FloorData.Mods[Modifier] = nil
			end
		end
	end

	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:DeleteCategory(Category, All)
	if All then
		for CategoryData in pairs(Modifiers.categories) do
			CategoryData = nil
		end
		CustomModifiers:Connotation("Deleted All Categories.")
	elseif Category and Modifiers.categories[Category] then
		Modifiers.categories[Category] = nil
		CustomModifiers:Connotation('Deleted Category "' .. Category .. '".')
	else
		for _, FloorData in pairs(AccessibleFloors) do
			if FloorData.Categories and FloorData.Categories[Category] then
				FloorData.Categories[Category] = nil
			end
		end
	end

	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:DeleteFloor(Floor)
	if Floor and AccessibleFloors[Floor] then
		if CustomModifiers:GetCurrentFloor() == Floor then
			CustomModifiers:ReloadModifiers(-1)
			CustomModifiers:UpdateFloorStuff()
		end
		AccessibleFloors[Floor] = nil
		CustomModifiers:Connotation('Deleted Floor "' .. Floor .. '".')
		CustomModifiers:ReloadModifiers()
		shared.CustomFloors -= 1
		CreateElevator.Floors.Visible = shared.CustomFloors >= 100
	else
		CustomModifiers:Caption('Error Deleting Floor "' .. Floor .. '".')
	end
end

function CustomModifiers:RestoreModifier(Modifier, All)
	if All then
		Modifiers.mods = shared.EveryModifier
		CustomModifiers:Connotation("Restored All Modifiers.")
	elseif Modifier and not Modifiers.mods[Modifier] then
		if CustomModifiers:GetCurrentFloor() ~= shared.EveryModifier[Modifier].Floor then
			AccessibleFloors[shared.EveryModifier[Modifier].Floor].Mods[Modifier] = shared.EveryModifier[Modifier]
		else
			Modifiers.mods[Modifier] = shared.EveryModifier[Modifier]
		end
		CustomModifiers:Connotation('Restored Modifier "' .. Modifier .. '".')
	else
		CustomModifiers:Caption('Error Restoring Modifier "' .. Modifier .. '".')
	end

	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:RestoreCategory(Category, All)
	if All then
		Modifiers.categories = shared.EveryCategory
		CustomModifiers:Connotation("Restored All Categories.")
	elseif Category and not Modifiers.categories[Category] then
		if CustomModifiers:GetCurrentFloor() ~= shared.EveryCategory[Category].Floor then
			AccessibleFloors[shared.EveryCategory[Category].Floor].Categories[Category] = shared.EveryCategory[Category]
		else
			Modifiers.categories[Category] = shared.EveryCategory[Category]
		end
		CustomModifiers:Connotation('Restored Category "' .. Category .. '".')
	else
		CustomModifiers:Caption('Error Restoring Category "' .. Category .. '".')
	end

	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:RestoreFloor(Floor)
	if Floor and not AccessibleFloors[Floor] and shared.EveryFloor[Floor] then
		AccessibleFloors[Floor] = shared.EveryFloor[Floor]
		CustomModifiers:Connotation('Restored Floor "' .. Floor .. '".')
		CustomModifiers:ReloadModifiers()
		shared.CustomFloors += 1
		CreateElevator.Floors.Visible = shared.CustomFloors >= 100
	else
		CustomModifiers:Caption('Error Restoring Floor "' .. Floor .. '".')
	end
end

function CustomModifiers:CreateModifier(Arguements)
	if not shared.EveryCategory[Arguements.Category] then
		CustomModifiers:Caption("The Category does not exist.")
	end
	
	Arguements.Floor = shared.EveryCategory[Arguements.Category].Floor or "Hotel"
	
	Modifiers.mods[Arguements.Title] = CreateModifier({
		Title = Arguements.Title,
		Desc = Arguements.Desc,
		Color = Arguements.Color,
		Category = Arguements.Category,
		Sort = Arguements.Sort,
		Merge = Arguements.Merge,
		Bonus = Arguements.Bonus,
		Solo = Arguements.Solo,
		Penalties = Arguements.Penalties,
		Floor = Arguements.Floor,
		Unlock = Arguements.Unlock,
		Activation = Arguements.Activation
	})
	
	CustomModifiers:EnableFloor(Arguements.Floor, true)
	
	shared.CustomModifiers[Arguements.Title] = Arguements.Title
	shared.EveryModifier[Arguements.Title] = table.clone(Modifiers.mods[Arguements.Title])
	
	if Arguements.Floor then
		if AccessibleFloors[Arguements.Floor] then
			AccessibleFloors[Arguements.Floor].Mods[Arguements.Title] = table.clone(Modifiers.mods[Arguements.Title])
		else
			AccessibleFloors.Hotel.Mods[Arguements.Title] = table.clone(Modifiers.mods[Arguements.Title])
			CustomModifiers:Caption('The floor "' .. Arguements.Floor .. '" does not exist, make sure the floor is at the very top.')
		end
	end
	
	task.spawn(function()
		local Found = false
		
		CustomModifiers:Caption("Go through the pages on the Modifiers frame to spawn the modifiers.")
		
		repeat
			for _, ModifierButton in pairs(CreateElevator.Modifiers:GetChildren()) do
				if ModifierButton:IsA("TextButton") and ModifierButton.Name == Arguements.Title then
					Found = true
					break
				end
			end
			task.wait(0.1)
		until Found
		
		CustomModifiers:Caption("Successfully spawned modifiers.")
		CustomModifiers:Connotation('Created Modifier "' .. Arguements.Title .. '".')
		CustomModifiers:ReloadModifiers()
	end)
end

function CustomModifiers:CreateCategory(Arguements)
	Modifiers.categories[Arguements.Title] = CreateCategory({
		Name = Arguements.Title,
		Sort = Arguements.Sort,
		Floor = Arguements.Floor,
		Color = Arguements.Color
	})

	shared.EveryCategory[Arguements.Title] = table.clone(Modifiers.categories[Arguements.Title])
	
	if Arguements.Floor then
		CustomModifiers:EnableFloor(Arguements.Floor, true)
		if AccessibleFloors[Arguements.Floor] then
			AccessibleFloors[Arguements.Floor].Categories[Arguements.Title] = AccessibleFloors[Arguements.Floor].Categories[Arguements.Title] or table.clone(Modifiers.categories[Arguements.Title])
		else
			AccessibleFloors.Hotel.Categories[Arguements.Title] = AccessibleFloors.Hotel.Categories[Arguements.Title] or table.clone(Modifiers.categories[Arguements.Title])
			CustomModifiers:Caption('The floor "' .. Arguements.Floor .. '" does not exist, make sure the floor is at the very top.')
		end
	end
	
	CustomModifiers:Connotation('Created Category "' .. Arguements.Title .. '".')
	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:CreateFloor(Arguements)
	AccessibleFloors[Arguements.Title] = CreateFloor({
		Name = Arguements.Title,
		Title = Arguements.Title,
		Destination = Arguements.Destination,
		Image = Arguements.Image,
		Font = Arguements.Font,
		FontColor = Arguements.FontColor,
		Theme = Arguements.Theme,
		Requires = Arguements.Requires,
		Sort = Arguements.Sort,
		Moddable = Arguements.Moddable
	})

	CreateElevator.Floors.Visible = shared.CustomFloors >= 100
	shared.EveryFloor[Arguements.Title] = AccessibleFloors[Arguements.Title]
	CustomModifiers:Connotation('Created Floor "' .. Arguements.Title .. '".')
	CustomModifiers:ReloadModifiers()
end

function CustomModifiers:ModifierExists(Modifier)
	for _, FloorData in pairs(AccessibleFloors) do
		if FloorData.Mods[Modifier] then
			return true
		end
	end
	return false
end

function CustomModifiers:CategoryExists(Category)
	for _, FloorData in pairs(AccessibleFloors) do
		if FloorData.Categories[Category] then
			return true
		end
	end
	return false
end

function CustomModifiers:FloorExists(Floor)
	return AccessibleFloors[Floor] and true or false
end

function CustomModifiers:GetModifierCount()
	local Amount = 0
	
	for _, FloorData in pairs(AccessibleFloors) do
		for _ in pairs(FloorData.Mods) do
			Amount += 1
		end
	end

	return Amount
end

function CustomModifiers:GetCategoryCount()
	local Amount = 0

	for _, FloorData in pairs(AccessibleFloors) do
		for _ in pairs(FloorData.Categories) do
			Amount += 1
		end
	end
	
	return Amount
end

function CustomModifiers:GetFloorCount()
	local Amount = 0

	for _ in pairs(AccessibleFloors) do
		Amount += 1
	end

	return Amount
end

function CustomModifiers:GetCurrentFloor()
	for _, Floor in pairs(CreateElevator.Floors:GetChildren()) do
		if Floor:IsA("TextLabel") and Floor.Visible then
			return Floor.Name
		end
	end
	return nil
end

function CustomModifiers:ReloadModifiers(FloorsAhead)
	task.spawn(function()
		getsenv(MainUI.Initiator.Main_Lobby.UIStuff).doFloorStuff(FloorsAhead or 0)
	end)
end

function CustomModifiers:ToggleConnotations(Force)
	shared.ToggleConnotations = Force or not shared.ToggleConnotations
end

function CustomModifiers:UpdateFloorStuff()
	task.wait()
	for _, Floor in pairs(CreateElevator.Floors:GetChildren()) do
		if Floor:IsA("TextLabel") and Floor.Visible and AccessibleFloors[Floor.Name] then
			Modifiers.categories = AccessibleFloors[Floor.Name].Categories
			Modifiers.mods = AccessibleFloors[Floor.Name].Mods
			CustomModifiers:ReloadModifiers()
			break
		end
	end
end

function CustomModifiers:Caption(Text)
	warn(Text)
	task.spawn(function()
		if getconnections then
			for _, Connection in pairs(getconnections(ReplicatedStorage.RemotesFolder.Caption.OnClientEvent)) do
				Connection.Function(Text)
			end
		end
	end)
end

function CustomModifiers:Connotation(Text)
	if shared.ToggleConnotations then
		CustomModifiers:Caption(Text)
	end
end

function CustomModifiers:EnableFloor(Floor, Status)
	if AccessibleFloors[Floor] then
		AccessibleFloors[Floor].Moddable = Status or not AccessibleFloors[Floor].Moddable
	end
end

-- Handle Switch
CreateElevator.Floors.MouseButton1Down:Connect(function()
	CustomModifiers:UpdateFloorStuff()
end)

CreateElevator.Floors.NavLeft.MouseButton1Down:Connect(function()
	CustomModifiers:UpdateFloorStuff()
end)

CreateElevator.Floors.NavRight.MouseButton1Down:Connect(function()
	CustomModifiers:UpdateFloorStuff()
end)

-- Teleport Check
Players.LocalPlayer.OnTeleport:Connect(function(_, PlaceId)
	if not shared.Teleported and PlaceId == 6839171747 and ElevatorExists then
		shared.Teleported = true

		local ModifierData = {}

		for _, Modifier in pairs(CreateElevator.Modifiers:GetChildren()) do
			if Modifier:IsA("TextButton") and Modifier.BackgroundTransparency <= 0.7 then
				ModifierData[Modifier.Name] = Modifiers.mods[Modifier.Name]
			end
		end

		TeleportService:SetTeleportSetting("ModifierData", ModifierData)
		TeleportService:SetTeleportSetting("CategoryData", Modifiers.categories)
		
		QueueTeleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/iimateiYT/Custom-Modifiers/main/Source.lua'))()")

		for _, Modifier in pairs(ModifierData) do
			if Modifier.Activation then
				QueueTeleport(Modifier.Activation)
			end
		end
	end
end)

-- Elevator Detector
workspace.Lobby.LobbyElevators.ChildAdded:Connect(function(Elevator)
	if not Elevator:GetAttribute("KnobPercentage") then
		Elevator:SetAttribute("KnobPercentage", 0)
	end

	repeat
		task.wait()
	until Elevator:GetAttribute("Host")

	if Elevator and Elevator:GetAttribute("Host") == Players.LocalPlayer.Name then
		local ModifierCount = 0
		local ModifierBonus = 0
		local TempMods = MainUI.LobbyFrame:WaitForChild("TempMods")
		local BigListActive = false

		for _, ModifierButton in pairs(CreateElevator.Modifiers:GetChildren()) do
			if ModifierButton:IsA("TextButton") and ModifierButton.BackgroundTransparency <= 0.7 then
				ModifierCount += 1
			end
		end

		TempMods.Visible = ModifierCount > 0

		if ModifierCount >= 14 then
			BigListActive = true
			TempMods.BigList.Visible = true
		end

		if BigListActive then
			for _, Modifier in pairs(TempMods:GetChildren()) do
				if Modifier:IsA("TextButton") then
					Modifier.Parent = TempMods.BigList
				end
			end
		end

		for _, Modifier in pairs(CreateElevator.Modifiers:GetChildren()) do
			if Modifier:IsA("TextButton") and Modifier.BackgroundTransparency <= 0.7 then
				if BigListActive then
					if TempMods.BigList:FindFirstChild(Modifier.Name) then
						TempMods.BigList[Modifier.Name]:Destroy()
					end
				else
					if TempMods:FindFirstChild(Modifier.Name) then
						TempMods[Modifier.Name]:Destroy()
					end
				end

				local ModifierSettings = Modifiers.mods[Modifier.Name]
				local Template = BigListActive and TempMods.BigList.Template:Clone() or TempMods.Template:Clone()

				ModifierBonus += ModifierSettings.Bonus

				Template.Visible = true
				Template.Name = ModifierSettings.Name
				Template.LayoutOrder = math.abs(ModifierSettings.Sort) + math.abs(Modifiers.categories[ModifierSettings.Category].sort) * 1000
				Template.Text = ModifierSettings.Title
				Template.BackgroundColor3 = ModifierSettings.Color
				Template.TextColor3 = ModifierSettings.Color
				Template.Parent = BigListActive and TempMods.BigList or TempMods
			end
		end

		TempMods.Desc.Text = ModifierCount .. " MODIFIER ACTIVATED"
		TempMods.KnobBonus.Text = Elevator:GetAttribute("KnobPercentage") + ModifierBonus .. "%"
		
		ElevatorExists = true
		
		repeat
			task.wait(1)
		until not Elevator:IsDescendantOf(workspace)
		
		ElevatorExists = false
	end
end)

-- Create Elevator Hook
if not shared.Hooked then
	shared.Hooked = true
	
	for _, FloorData in pairs(AccessibleFloors) do
		FloorData.Mods = {}
		FloorData.Categories = {}
	end

	AccessibleFloors.Hotel.Mods = table.clone(Modifiers.mods)
	AccessibleFloors.Hotel.Categories = table.clone(Modifiers.categories)
	
	local Old
	Old = hookmetamethod(game, "__namecall", function(self, ...)
		local Arguments = {...}
		local Method = getnamecallmethod()
		if tostring(self) == 'CreateElevator' and Method == "FireServer" then
			local Mods = Arguments[1].Mods
			for Name, Data in pairs(AccessibleFloors) do
				if Name == Arguments[1].Destination and Data.Destination then
					Arguments[1].Destination = Data.Destination
					break
				end
			end
			for Index = #Mods, 1, -1 do
				if shared.CustomModifiers[Mods[Index]] then
					table.remove(Mods, Index)
				end
			end
			return Old(self, unpack(Arguments))
		end
		return Old(self, ...)
	end)
end

-- Executor Functions Check
task.spawn(function()
	if not QueueTeleport then
		CustomModifiers:Caption('Incompatible | Function "queue_on_teleport" is missing, Modifiers wont work in game.')
	end

	if not hookmetamethod then
		CustomModifiers:Caption('Incompatible | Function "hookmetamethod" is missing, Elevators cannot be made with Custom Modifiers.')
	end

	if not getsenv then
		CustomModifiers:Caption('Incompatible | Function "getsenv" is missing, Modifier pages cannot auto reload.')
	end

	if not getconnections then
		CustomModifiers:Caption('Incompatible | Function "getconnections" is missing, Captions cannot be made. (F9 Console Has Captions)')
	end
end)

-- Return Module
return CustomModifiers
