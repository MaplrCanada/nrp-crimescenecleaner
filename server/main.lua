-- server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Debug function
local function Debug(msg)
    if Config.Debug then
        print("[CS Cleaner]: " .. msg)
    end
end

-- Player has cleaned a scene
RegisterNetEvent('nrp-crimescenecleaner:server:SceneCleaned', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is on duty and has the job
    if Player.PlayerData.job.name ~= Config.JobName then
        Debug("Player tried to get paid without the correct job")
        return
    end
    
    -- Calculate payment
    local payment = math.random(Config.PayPerScene - 50, Config.PayPerScene + 50)
    
    -- Add money to player
    Player.Functions.AddMoney("bank", payment, "crime-scene-cleaning")
    
    -- Send notification to player
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. payment .. " for cleaning the crime scene.", "success")
    
    -- Log the payment (optional)
    Debug("Player ID " .. src .. " received $" .. payment .. " for cleaning a crime scene")
end)

-- Check player job on resource start (optional)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Debug("Crime Scene Cleaner job started")
    end
end)