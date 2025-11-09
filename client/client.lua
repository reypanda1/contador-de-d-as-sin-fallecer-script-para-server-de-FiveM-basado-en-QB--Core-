local QBCore = exports['qb-core']:GetCoreObject()

local daysSurvived = 0
local lastHour = nil
local lastDayState = nil
local isDead = false
local playerLoaded = false
local lastUIDays = -1

local function IsDayTime(hour)
    return hour >= Config.DayNight.dayStart and hour < Config.DayNight.nightStart
end

local function UpdateUI(days)
    if days ~= lastUIDays then
        lastUIDays = days
        SendNUIMessage({
            action = 'updateDays',
            days = days
        })
    end
end

local function ShowUI()
    SendNUIMessage({
        action = 'show'
    })
end

local function HideUI()
    SendNUIMessage({
        action = 'hide'
    })
end

local function GetGameTime()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    return hour, minute
end

local function ResetCounter()
    daysSurvived = 0
    lastDayState = nil
    lastHour = nil
    lastUIDays = -1
    UpdateUI(0)
    TriggerServerEvent('survival-days:server:UpdateDays', 0)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
    ShowUI()
end)

RegisterNetEvent('survival-days:client:ShowUI', function()
    if playerLoaded then
        ShowUI()
    end
end)

RegisterNetEvent('survival-days:client:SetDays', function(days)
    daysSurvived = days
    lastUIDays = -1
    UpdateUI(days)
end)

local hasDied = false

RegisterNetEvent('hospital:client:SetDeathStatus', function(isDeadStatus)
    if isDeadStatus and not isDead then
        isDead = true
        hasDied = true
    elseif not isDeadStatus then
        isDead = false
    end
end)

RegisterNetEvent('hospital:client:Revive', function()
    if hasDied then
        Wait(500)
        ResetCounter()
        TriggerServerEvent('survival-days:server:PlayerDied')
        hasDied = false
        isDead = false
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        
        if playerLoaded then
            local ped = PlayerPedId()
            local isPedDead = IsEntityDead(ped) or IsPedDeadOrDying(ped, true)
            
            if isPedDead and not isDead then
                isDead = true
                hasDied = true
            elseif not isPedDead and isDead and not hasDied then
                isDead = false
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        
        if playerLoaded and not isDead then
            local hour, minute = GetGameTime()
            
            if lastHour == 23 and hour == 0 and minute == 0 then
                daysSurvived = daysSurvived + 1
                UpdateUI(daysSurvived)
                TriggerServerEvent('survival-days:server:UpdateDays', daysSurvived)
            end
            
            lastHour = hour
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideUI()
    end
end)

