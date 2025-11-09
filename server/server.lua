local QBCore = exports['qb-core']:GetCoreObject()

-- Tabla en RAM para almacenar los días sobrevividos
local PlayerSurvivalDays = {}

-- Variable para controlar si la tabla ya fue creada
local tableCreated = false

-- Función para crear la tabla en la base de datos (solo una vez)
local function CreateTable()
    if tableCreated then
        return
    end
    
    -- Verificar si la tabla ya existe antes de crearla
    exports.oxmysql:query('SHOW TABLES LIKE ?', {'player_survival_days'}, function(result)
        if result and #result > 0 then
            -- La tabla ya existe, solo marcar como creada
            tableCreated = true
            print("^2[Contador de Días]^7 Tabla player_survival_days ya existe")
        else
            -- La tabla no existe, crearla
            local query = [[
                CREATE TABLE `player_survival_days` (
                    `citizenid` VARCHAR(50) NOT NULL,
                    `days_survived` INT NOT NULL DEFAULT 0,
                    `last_update` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`citizenid`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
            
            exports.oxmysql:execute(query, {}, function(createResult)
                tableCreated = true
                print("^2[Contador de Días]^7 Tabla player_survival_days creada correctamente")
            end)
        end
    end)
end

-- Función para cargar días sobrevividos desde la BD
local function LoadPlayerDays(citizenid)
    -- Usar exports.oxmysql con callback (await no está disponible directamente)
    local result = nil
    local done = false
    
    exports.oxmysql:single('SELECT days_survived FROM player_survival_days WHERE citizenid = ?', {citizenid}, function(data)
        result = data
        done = true
    end)
    
    -- Esperar a que la query termine
    while not done do
        Wait(0)
    end
    
    if result and result.days_survived then
        return result.days_survived
    else
        -- Si no existe, crear registro con 0 días
        exports.oxmysql:insert('INSERT INTO player_survival_days (citizenid, days_survived) VALUES (?, ?) ON DUPLICATE KEY UPDATE days_survived = days_survived', {
            citizenid,
            0
        })
        return 0
    end
end

-- Función para guardar días sobrevividos en la BD (optimizada)
local function SavePlayerDays(citizenid, days)
    -- Usar exports.oxmysql:insert para mejor rendimiento
    exports.oxmysql:insert('INSERT INTO player_survival_days (citizenid, days_survived) VALUES (?, ?) ON DUPLICATE KEY UPDATE days_survived = ?, last_update = CURRENT_TIMESTAMP', {
        citizenid,
        days,
        days
    })
end

-- Función para guardar todos los jugadores en RAM a la BD (optimizada con batch)
local function SaveAllPlayers()
    local saved = 0
    
    for citizenid, days in pairs(PlayerSurvivalDays) do
        SavePlayerDays(citizenid, days)
        saved = saved + 1
    end
    
    if saved > 0 then
        print(string.format("^2[Contador de Días]^7 Guardados %d jugador(es) en la base de datos", saved))
    end
end

-- Evento cuando un jugador se conecta
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then return end
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    local days = LoadPlayerDays(citizenid)
    PlayerSurvivalDays[citizenid] = days
    TriggerClientEvent('survival-days:client:SetDays', Player.PlayerData.source, days)
end)

-- Evento cuando un jugador se desconecta
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        if PlayerSurvivalDays[citizenid] then
            SavePlayerDays(citizenid, PlayerSurvivalDays[citizenid])
            PlayerSurvivalDays[citizenid] = nil
        end
    end
end)

-- Evento para reiniciar contador cuando el jugador muere
RegisterNetEvent('survival-days:server:PlayerDied', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        PlayerSurvivalDays[citizenid] = 0
        SavePlayerDays(citizenid, 0)
        TriggerClientEvent('survival-days:client:SetDays', src, 0)
    end
end)

-- Evento para actualizar días desde el cliente
RegisterNetEvent('survival-days:server:UpdateDays', function(days)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        PlayerSurvivalDays[citizenid] = days
    end
end)

-- Thread para guardar cada 59:30
CreateThread(function()
    local lastSavedMinute = -1
    while true do
        Wait(1000) -- Verificar cada segundo para mayor precisión
        
        local currentTime = os.date("*t")
        -- Guardar solo una vez cuando llegue a 59:30
        if currentTime.min == Config.Save.minute and currentTime.sec == Config.Save.second and lastSavedMinute ~= currentTime.min then
            SaveAllPlayers()
            lastSavedMinute = currentTime.min
        elseif currentTime.min ~= Config.Save.minute then
            lastSavedMinute = -1 -- Resetear cuando cambie el minuto
        end
    end
end)

-- Crear tabla al iniciar el recurso y cargar jugadores conectados
CreateThread(function()
    -- Esperar a que oxmysql esté disponible
    local attempts = 0
    while not exports.oxmysql do
        Wait(100)
        attempts = attempts + 1
        if attempts > 50 then -- Timeout después de 5 segundos
            print("^1[Contador de Días]^7 Error: No se pudo conectar con oxmysql")
            return
        end
    end
    Wait(1000) -- Esperar un segundo adicional para asegurar que oxmysql esté completamente listo
    CreateTable()
    
    -- Esperar un poco más para que la tabla esté lista
    Wait(500)
    
    -- Cargar días para todos los jugadores conectados
    for _, Player in pairs(QBCore.Players) do
        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            local citizenid = Player.PlayerData.citizenid
            local days = LoadPlayerDays(citizenid)
            PlayerSurvivalDays[citizenid] = days
            TriggerClientEvent('survival-days:client:SetDays', Player.PlayerData.source, days)
            TriggerClientEvent('survival-days:client:ShowUI', Player.PlayerData.source)
        end
    end
end)

