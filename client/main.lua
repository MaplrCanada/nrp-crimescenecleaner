-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local onDuty = false
local currentVehicle = nil
local cleaningEquipmentObject = nil
local currentScene = nil
local activeBlips = {}
local uiOpen = false
local scenePeds = {}

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

-- Select a random crime scene with enhanced scene creation
local function SelectCrimeScene()
    if #Config.CrimeScenes == 0 then return nil end
    
    local sceneIndex = math.random(1, #Config.CrimeScenes)
    local scene = Config.CrimeScenes[sceneIndex]
    
    -- Create blood decals and props at the scene
    local coords = scene.coords
    
    -- Add random blood decals in the area
    for i = 1, math.random(5, 12) do
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
    
    -- Create the dead body prop using the custom model from low.ytyp
    local deadBodyModel = GetHashKey("low")
    
    -- Request the model
    RequestModel(deadBodyModel)
    
    -- Wait for the model to load
    local attempts = 0
    while not HasModelLoaded(deadBodyModel) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    
    -- Create the dead body if model loaded
    if HasModelLoaded(deadBodyModel) then
        -- Create the dead body at the scene location
        local deadBody = CreateObject(
            deadBodyModel,
            coords.x, 
            coords.y, 
            coords.z - 1.0, 
            false, false, false
        )
        
        -- Set rotation appropriate for a dead body
        SetEntityRotation(deadBody, 
            0.0, 
            0.0, 
            math.random(0, 359) + 0.0, 
            2, true
        )
        
        -- Ensure props stay in place
        FreezeEntityPosition(deadBody, true)
        
        SetModelAsNoLongerNeeded(deadBodyModel)
    else
        -- Fallback to the default prop if custom model fails to load
        Debug("Failed to load custom dead body model, using fallback")
        local fallbackModel = GetHashKey("prop_cs_dead_guy_01")
        RequestModel(fallbackModel)
        
        while not HasModelLoaded(fallbackModel) do
            Wait(10)
        end
        
        local deadBody = CreateObject(
            fallbackModel,
            coords.x, 
            coords.y, 
            coords.z - 1.0, 
            false, false, false
        )
        
        SetEntityRotation(deadBody, 
            0.0, 
            0.0, 
            math.random(0, 359) + 0.0, 
            2, true
        )
        
        FreezeEntityPosition(deadBody, true)
        SetModelAsNoLongerNeeded(fallbackModel)
    end
    
    -- Add crime scene props (additional environmental props)
    local scenePropModels = {
        "prop_bodyarmour_03",
        "prop_cs_fertilizer",
        "prop_cs_beer_bot_40oz_03",
        "prop_cs_sh_bong",
        "prop_cs_street_binbag_01",
        "prop_bin_08a",
        "prop_cs_rub_binbag_01"
    }
    
    -- Add 2-4 random props
    local numProps = math.random(2, 4)
    for i = 1, numProps do
        local propModel = scenePropModels[math.random(1, #scenePropModels)]
        local xOffset = math.random(-30, 30) / 10
        local yOffset = math.random(-30, 30) / 10
        
        local propHash = GetHashKey(propModel)
        RequestModel(propHash)
        
        local attempts = 0
        while not HasModelLoaded(propHash) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        
        if HasModelLoaded(propHash) then
            local propObject = CreateObject(
                propHash, 
                coords.x + xOffset, 
                coords.y + yOffset, 
                coords.z - 1.0, 
                false, false, false
            )
            SetModelAsNoLongerNeeded(propHash)
            
            -- Give props random rotation
            SetEntityRotation(propObject, 
                math.random(0, 359) + 0.0, 
                math.random(0, 359) + 0.0, 
                math.random(0, 359) + 0.0, 
                2, true
            )
            
            -- Ensure props stay in place
            FreezeEntityPosition(propObject, true)
        end
    end

    -- Add police officers at the scene
    local pedModels = {
        "s_m_y_cop_01",
        "s_f_y_cop_01",
        "s_m_y_hwaycop_01"
    }

    -- Add 2-3 police officers
    local numPeds = math.random(2, 3)
    for i = 1, numPeds do
        local modelHash = GetHashKey(pedModels[math.random(1, #pedModels)])
        RequestModel(modelHash)
        
        local attempts = 0
        while not HasModelLoaded(modelHash) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        
        if HasModelLoaded(modelHash) then
            -- Position the ped with an offset from the crime scene
            local xOffset = math.random(-30, 30) / 10
            local yOffset = math.random(-30, 30) / 10
            
            local policePed = CreatePed(
                4, 
                modelHash, 
                coords.x + xOffset, 
                coords.y + yOffset, 
                coords.z - 1.0, 
                math.random(0, 359) + 0.0, 
                false, 
                true
            )
            
            -- Make the ped permanent until scene is cleaned
            SetEntityAsMissionEntity(policePed, true, true)
            
            -- Add to a table to track and remove later
            table.insert(scenePeds, policePed)
            
            -- Set ped attributes
            SetBlockingOfNonTemporaryEvents(policePed, true)
            SetPedFleeAttributes(policePed, 0, false)
            
            -- Give the ped a random task
            local tasks = {
                "WORLD_HUMAN_CLIPBOARD",
                "WORLD_HUMAN_STAND_IMPATIENT",
                "WORLD_HUMAN_GUARD_STAND",
                "WORLD_HUMAN_COP_IDLES"
            }
            
            TaskStartScenarioInPlace(policePed, tasks[math.random(1, #tasks)], 0, true)
            
            SetModelAsNoLongerNeeded(modelHash)
        end
    end
    
    -- Add police tape around the area
    local tapeModel = GetHashKey("prop_barrier_work05")
    RequestModel(tapeModel)
    
    while not HasModelLoaded(tapeModel) do
        Wait(10)
    end
    
    -- Create police tape in a perimeter
    for i = 0, 3 do
        local angle = (i * 90) * math.pi / 180.0
        local x = coords.x + math.cos(angle) * 3.0
        local y = coords.y + math.sin(angle) * 3.0
        
        local tapeObject = CreateObject(tapeModel, x, y, coords.z - 1.0, false, false, false)
        SetEntityRotation(tapeObject, 0.0, 0.0, angle * 180.0 / math.pi, 2, true)
        FreezeEntityPosition(tapeObject, true)
    end
    
    SetModelAsNoLongerNeeded(tapeModel)
    
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

-- Clean crime scene function (with UI status update)
local function CleanCrimeScene()
    if not currentScene then return end
    if not onDuty or PlayerData.job.name ~= Config.JobName then
        QBCore.Functions.Notify("You are not authorized to clean crime scenes.", "error")
        return
    end
    
    local playerPed = PlayerPedId()
    local dict = Config.CleaningAnimations.dict
    local anim = Config.CleaningAnimations.anim
    
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
    
    -- We'll add kneeling animation first
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    Wait(1000)
    ClearPedTasks(playerPed)
    
    -- Now play the cleaning animation
    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, Config.CleaningAnimations.flag, 0, false, false, false)
    
    -- Update UI to show "in progress"
    SendNUIMessage({
        action = "updateSceneStatus",
        status = "In Progress"
    })
    
    QBCore.Functions.Progressbar("clean_scene", "Cleaning crime scene...", Config.CleaningTime * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        StopAnimTask(playerPed, dict, anim, 1.0)
        DetachCleaningEquipment()
        
        -- Alternate animation to show scrubbing the floor
        LoadAnimDict("amb@world_human_bum_wash@male@low@idle_a")
        TaskPlayAnim(playerPed, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 8.0, -8.0, 3000, 0, 0, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        
        -- Remove blood decals in area
        RemoveDecalsInRange(sceneCoords, 20.0)
        
        -- Also remove any props in the area that might be part of the scene
        local props = GetGamePool('CObject')
        for _, object in ipairs(props) do
            if #(GetEntityCoords(object) - sceneCoords) < 10.0 then
                -- Only remove objects that aren't attached to anything (likely scene props)
                if not IsEntityAttached(object) and not NetworkGetEntityIsNetworked(object) then
                    DeleteEntity(object)
                end
            end
        end
            
        -- Remove the blip from the map
        if currentScene.blip then
            RemoveBlip(currentScene.blip)
            currentScene.blip = nil
        end
        
        -- Update UI to show "completed"
        SendNUIMessage({
            action = "updateSceneStatus",
            status = "Completed"
        })
        
        -- Notify server about completion
        TriggerServerEvent("crime-cleaner:server:SceneCleaned")
        
        -- Reset current scene
        currentScene = nil
        
        -- Get a new scene
        Wait(1000)
        local newScene = SelectCrimeScene()
        
        -- Update UI with new scene info if available
        if newScene then
            SendNUIMessage({
                action = "showJobInfo",
                jobActive = true,
                currentScene = newScene.data.label
            })
        else
            SendNUIMessage({
                action = "showJobInfo",
                jobActive = true,
                currentScene = "No scenes available"
            })
        end
        
        QBCore.Functions.Notify("Crime scene cleaned! Head to the next location.", "success")
    end, function() -- Cancel
        StopAnimTask(playerPed, dict, anim, 1.0)
        DetachCleaningEquipment()
        
        -- Reset UI status on cancel
        SendNUIMessage({
            action = "updateSceneStatus",
            status = "Pending"
        })
        
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

-- Toggle job UI with job check
local function ToggleJobUI()
    -- Check job first
    if PlayerData.job.name ~= Config.JobName then
        QBCore.Functions.Notify("You are not authorized to use this system.", "error")
        return false
    end
    
    uiOpen = not uiOpen
    
    SendNUIMessage({
        action = "toggleUI",
        show = uiOpen,
        jobActive = onDuty
    })
    
    SetNuiFocus(uiOpen, uiOpen)
    return true
end

-- Event handlers
RegisterNetEvent('nrp-crimescenecleaner:client:ToggleJobUI', function()
    if PlayerData.job and PlayerData.job.name == Config.JobName then
        ToggleJobUI()
    else
        QBCore.Functions.Notify("You are not authorized to use this system.", "error")
    end
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

RegisterNUICallback('navigateToJob', function(data, cb)
    if currentScene and currentScene.data then
        SetNewWaypoint(currentScene.data.coords.x, currentScene.data.coords.y)
        QBCore.Functions.Notify("GPS set to crime scene: " .. currentScene.data.label, "success")
    else
        QBCore.Functions.Notify("No active crime scene to navigate to.", "error")
    end
    cb('ok')
end)

-- Create thread for job center interaction with next job indicator
CreateThread(function()
    local jobCenterBlip = CreateJobCenterBlip()
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - Config.JobCenter)
        
        if dist < 10 then
            sleep = 0
            -- Only show markers to players with the job
            if PlayerData.job and PlayerData.job.name == Config.JobName then
                DrawMarker(2, Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                
                if dist < 2.0 then
                    if not onDuty then
                        DrawText3D(Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.3, "Press [E] to access Crime Scene Cleaner job")
                    else
                        -- Different message when on duty
                        if currentScene then
                            DrawText3D(Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.3, "Press [E] to access job menu | [G] to get next job location")
                            
                            -- Add G key for quick "next job" navigation
                            if IsControlJustPressed(0, 47) then -- G key
                                if DoesBlipExist(currentScene.blip) then
                                    SetNewWaypoint(currentScene.data.coords.x, currentScene.data.coords.y)
                                    QBCore.Functions.Notify("GPS set to next crime scene: " .. currentScene.data.label, "success")
                                end
                            end
                        else
                            DrawText3D(Config.JobCenter.x, Config.JobCenter.y, Config.JobCenter.z + 1.3, "Press [E] to access Crime Scene Cleaner job")
                        end
                    end
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        ToggleJobUI()
                    end
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
    if PlayerData.job and PlayerData.job.name == Config.JobName then
        ToggleJobUI()
    else
        QBCore.Functions.Notify("You are not authorized to use this command.", "error")
    end
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