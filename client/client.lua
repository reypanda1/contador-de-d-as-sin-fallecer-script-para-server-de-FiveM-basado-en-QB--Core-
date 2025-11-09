local QBCore = exports['qb-core']:GetCoreObject()

-- Variables locales
local daysSurvived = 0
local lastHour = nil
local lastDayState = nil -- 'day' o 'night'
local isDead = false
local playerLoaded = false
local lastUIDays = -1 -- Para evitar actualizaciones innecesarias de UI

-- Función para obtener si es día o noche
local function IsDayTime(hour)
    return hour >= Config.DayNight.dayStart and hour < Config.DayNight.nightStart
end

-- Función para actualizar la UI (solo si cambió el valor)
local function UpdateUI(days)
    if days ~= lastUIDays then
        lastUIDays = days
        SendNUIMessage({
            action = 'updateDays',
            days = days
        })
    end
end

-- Función para mostrar la UI
local function ShowUI()
    SendNUIMessage({
        action = 'show'
    })
end

-- Función para ocultar la UI
local function HideUI()
    SendNUIMessage({
        action = 'hide'
    })
end

-- Función para obtener la hora del juego
-- El export getTime está en el servidor, necesitamos obtenerlo de otra forma
local function GetGameTime()
    -- Solicitar el tiempo al servidor o usar el tiempo local del juego
    -- Alternativa: usar eventos de qb-weathersync o calcular desde el tiempo del juego
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    return hour, minute
end

-- Función para reiniciar el contador
local function ResetCounter()
    daysSurvived = 0
    lastDayState = nil
    lastHour = nil
    lastUIDays = -1 -- Forzar actualización
    UpdateUI(0)
    TriggerServerEvent('survival-days:server:UpdateDays', 0)
end

-- Evento cuando el jugador se carga
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
    ShowUI()
end)

-- Evento para mostrar la UI cuando el script se inicia
RegisterNetEvent('survival-days:client:ShowUI', function()
    if playerLoaded then
        ShowUI()
    end
end)

-- Evento para recibir días desde el servidor
RegisterNetEvent('survival-days:client:SetDays', function(days)
    daysSurvived = days
    lastUIDays = -1 -- Forzar actualización
    UpdateUI(days)
end)

-- Variable para marcar que el jugador murió (pero aún no ha revivido)
local hasDied = false

-- Detectar muerte del jugador - solo marcar que murió, NO reiniciar todavía
RegisterNetEvent('hospital:client:SetDeathStatus', function(isDeadStatus)
    if isDeadStatus and not isDead then
        isDead = true
        hasDied = true -- Solo marcar que murió, esperar a que reviva
    elseif not isDeadStatus then
        isDead = false
        -- No reiniciar aquí, esperar al evento de revive
    end
end)

-- Escuchar evento de revive - aquí es donde reiniciamos el contador
RegisterNetEvent('hospital:client:Revive', function()
    if hasDied then
        -- El jugador ha revivido, ahora reiniciamos el contador
        Wait(500) -- Pequeño delay para asegurar que el jugador esté completamente revivido
        ResetCounter()
        TriggerServerEvent('survival-days:server:PlayerDied')
        hasDied = false -- Resetear la bandera
        isDead = false
    end
end)

-- Verificar si el jugador está muerto mediante el estado del ped (solo para actualizar isDead)
CreateThread(function()
    while true do
        Wait(1000)
        
        if playerLoaded then
            local ped = PlayerPedId()
            local isPedDead = IsEntityDead(ped) or IsPedDeadOrDying(ped, true)
            
            if isPedDead and not isDead then
                isDead = true
                hasDied = true -- Solo marcar que murió, esperar a que reviva
            elseif not isPedDead and isDead and not hasDied then
                -- Si el jugador ya no está muerto pero no había marcado hasDied, solo actualizar isDead
                isDead = false
            end
        end
    end
end)

-- Thread principal para contar días
CreateThread(function()
    while true do
        Wait(1000) -- Verificar cada segundo
        
        if playerLoaded and not isDead then
            local hour, minute = GetGameTime()
            
            -- Detectar cambio de día cuando sean las 00:00 (medianoche)
            -- Verificar si pasamos de 23:59 a 00:00
            if lastHour == 23 and hour == 0 and minute == 0 then
                daysSurvived = daysSurvived + 1
                UpdateUI(daysSurvived)
                TriggerServerEvent('survival-days:server:UpdateDays', daysSurvived)
            end
            
            -- Actualizar última hora
            lastHour = hour
        end
    end
end)

-- Limpiar al detener el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideUI()
    end
end)

