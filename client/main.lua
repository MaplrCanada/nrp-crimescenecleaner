local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local onDuty = false
local currentVehicle = nil
local cleaningEquipmentObject = nil
local currentScene = nil
local activeBlips = {}
local uiOpen = false

-- Initialize player data when player loads
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- Update player data when job changes
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    if PlayerData.job.name ~= Config.JobName and onDuty then
        EndShift()
    end
end)

-- Debug function
local function Debug(msg)
    if Config.Debug then
        print("[CS Cleaner]: " .. msg)
    end
end

-- Create job center blip
local function CreateJobCenterBlip()
    local blip = AddBlipForCoord(Config.JobCenter)
    SetBlipSprite(blip, Config.Blips.jobCenter.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blips.jobCenter.scale)
    SetBlipColour(blip, Config.Blips.jobCenter.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.jobCenter.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Create crime scene blip
local function CreateCrimeSceneBlip(location)
    local blip = AddBlipForCoord(location.coords)
    SetBlipSprite(blip, Config.Blips.crimeScene.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blips.crimeScene.scale)
    SetBlipColour(blip, Config.Blips.crimeScene.color)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(location.label)
    EndTextCommandSetBlipName(blip)
    
    table.insert(activeBlips, blip)
    return blip
end

-- Remove all active blips
local function RemoveAllBlips()
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}
end

-- Spawn work vehicle
local function SpawnWorkVehicle()
    local model = GetHashKey(Config.VehicleModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    currentVehicle = CreateVehicle(model, Config.VehicleSpawnLocation.x, Config.VehicleSpawnLocation.y, Config.VehicleSpawnLocation.z, Config.VehicleSpawnLocation.w, true, false)
    SetEntityAsMissionEntity(currentVehicle, true, true)
    SetVehicleNumberPlateText(currentVehicle, "CLEANER")
    SetVehicleDirtLevel(currentVehicle, 0.0)
    SetVehicleEngineOn(currentVehicle, false, true, false)
    
    -- Add custom livery/modifications if wanted
    SetVehicleColours(currentVehicle, 0, 0) -- Black primary and secondary
    
    -- Set as player owned temporarily
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(currentVehicle))
    
    SetModelAsNoLongerNeeded(model)
    return currentVehicle
end

-- Remove work vehicle
local function RemoveWorkVehicle()
    if currentVehicle then
        QBCore.Functions.DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end
end

-- Select a random crime scene
local function SelectCrimeScene()
    if #Config.CrimeScenes == 0 then return nil end
    
    local sceneIndex = math.random(1, #Config.CrimeScenes)
    local scene = Config.CrimeScenes[sceneIndex]
    
    -- Create blood decals and props at the scene
    local coords = scene.coords
    
    -- Add random blood decals in the area
    local decalTypes = {
        "Blood splatter",
        "Blood pool"
    }
    
    for i = 1, math.random(3, 7) do
        local xOffset = math.random(-20, 20) / 10
        local yOffset = math.random(-20, 20) / 10
        
        AddDecal(
            math.random(1, 12), -- Decal type (blood variants)
            coords.x + xOffset, 
            coords.y + yOffset, 
            coords.z - 0.5, 
            0.0, 0.0, 0.0, 
            1.0, 1.0, 1.0, 
            1.0, -- Opacity
            300.0, -- Width
            false, true, false
        )
    end
    
    currentScene = {
        index = sceneIndex,
        data = scene,
        blip = CreateCrimeSceneBlip(scene)
    }
    
    return currentScene
end

-- Load animation dictionary
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Attach cleaning equipment to player
local function AttachCleaningEquipment()
    local model = GetHashKey(Config.CleaningEquipment.prop)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local playerPed = PlayerPedId()
    cleaningEquipmentObject = CreateObject(model, 0, 0, 0, true, true, false)
    
    AttachEntityToEntity(
        cleaningEquipmentObject, 
        playerPed, 
        GetPedBoneIndex(playerPed, Config.CleaningEquipment.bone), 
        Config.CleaningEquipment.offset.x,
        Config.CleaningEquipment.offset.y,
        Config.CleaningEquipment.offset.z,
        Config.CleaningEquipment.rotation.x,
        Config.CleaningEquipment.rotation.y,
        Config.CleaningEquipment.rotation.z,
        true, false, false, false, 2, true
    )
    
    SetModelAsNoLongerNeeded(model)
end

-- Detach cleaning equipment from player
local function DetachCleaningEquipment()
    if cleaningEquipmentObject then
        DeleteEntity(cleaningEquipmentObject)
        cleaningEquipmentObject = nil
    end
end

-- Clean crime scene function
local function CleanCrimeScene()
    if not currentScene then return end
    
    local playerPed = PlayerPedId()
    local dict = "amb@world_human_maid_clean@base"
    
    -- Check if player is near crime scene
    local playerCoords = GetEntityCoords(playerPed)
    local sceneCoords = currentScene.data.coords
    
    if #(playerCoords - sceneCoords) > 5.0 then
        QBCore.Functions.Notify("You need to be closer to the crime scene.", "error")
        return
    end
    
    -- Start cleaning animation
    LoadAnimDict(dict)
    AttachCleaningEquipment()
    
    TaskPlayAnim(playerPed, dict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    QBCore.Functions.Progressbar("clean_scene", "Cleaning crime scene...", Config.CleaningTime * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        StopAnimTask(playerPed, dict, "base", 1.0)
        DetachCleaningEquipment()
        
        -- Remove blood decals in area
        RemoveDecalsInRange(sceneCoords, 15.0)
        
        -- Remove the blip
        RemoveBlip(currentScene.blip)
        currentScene.blip = nil
        
        -- Notify server about completion
        TriggerServerEvent("nrp-crimescenecleaner:server:SceneCleaned")
        
        -- Reset current scene
        currentScene = nil
        
        -- Get a new scene
        Wait(1000)
        SelectCrimeScene()
        QBCore.Functions.Notify("Crime scene cleaned! Head to the next location.", "success")
    end, function() -- Cancel
        StopAnimTask(playerPed, dict, "base", 1.0)
        DetachCleaningEquipment()
        QBCore.Functions.Notify("Cleaning cancelled.", "error")
    end)
end

-- Start shift function
local function StartShift()
    if onDuty then
        QBCore.Functions.Notify("You are already on duty!", "error")
        return
    end
    
    if PlayerData.job.name ~= Config.JobName then
        QBCore.Functions.Notify("You are not a crime scene cleaner.", "error")
        return
    end
    
    onDuty = true
    SpawnWorkVehicle()
    SelectCrimeScene()
    QBCore.Functions.Notify("You have started your shift as a crime scene cleaner.", "success")
    
    SendNUIMessage({
        action = "showJobInfo",
        jobActive = true,
        currentScene = currentScene.data.label
    })
end

-- End shift function
local function EndShift()
    if not onDuty then
        QBCore.Functions.Notify("You are not on duty!", "error")
        return
    end
    
    onDuty = false
    RemoveWorkVehicle()
    RemoveAllBlips()
    
    if currentScene and currentScene.blip then
        RemoveBlip(currentScene.blip)
    end
    
    currentScene = nil
    DetachCleaningEquipment()
    
    QBCore.Functions.Notify("You have ended your shift.", "success")
    
    SendNUIMessage({
        action = "showJobInfo",
        jobActive = false
    })
end

-- Toggle job UI
local function ToggleJobUI()
    uiOpen = not uiOpen
    
    SendNUIMessage({
        action = "toggleUI",
        show = uiOpen,
        jobActive = onDuty
    })
    
    SetNuiFocus(uiOpen, uiOpen)
end

-- Event handlers
RegisterNetEvent('nrp-crimescenecleaner:client:ToggleJobUI', function()
    ToggleJobUI()
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    ToggleJobUI()
    cb('ok')
end)

RegisterNUICallback('startShift', function(data, cb)
    StartShift()
    cb('ok')
end)

RegisterNUICallback('endShift', function(data, cb)
    EndShift()
    cb('ok')
end)

RegisterNUICallback('cleanScene', function(data, cb)
    CleanCrimeScene()
    cb('ok')
end)

-- Create thread for job center interaction
CreateThread(function()
    local jobCenterBlip = CreateJobCenterBlip()
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - Config.JobCenter)
        
        if dist < 10 then
            sleep = 0
            DrawMarker(2, Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
            
            if dist < 2.0 then
                DrawText3D(Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.3, "Press [E] to access Crime Scene Cleaner job")
                
                if IsControlJustPressed(0, 38) then -- E key
                    ToggleJobUI()
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Thread for cleaning scene interaction
CreateThread(function()
    while true do
        local sleep = 1000
        if onDuty and currentScene then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local sceneCoords = currentScene.data.coords
            local dist = #(playerCoords - sceneCoords)
            
            if dist < 10.0 then
                sleep = 0
                DrawMarker(1, sceneCoords.x, sceneCoords.y, sceneCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                
                if dist < 5.0 then
                    DrawText3D(sceneCoords.x, sceneCoords.y, sceneCoords.z + 0.5, "Press [E] to clean crime scene")
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        CleanCrimeScene()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Helper function for 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Command to toggle the UI
RegisterCommand('cleanerjob', function()
    ToggleJobUI()
end, false)

-- Event when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if cleaningEquipmentObject then
            DeleteEntity(cleaningEquipmentObject)
        end
        
        if currentVehicle then
            DeleteEntity(currentVehicle)
        end
        
        RemoveAllBlips()
    end
end)