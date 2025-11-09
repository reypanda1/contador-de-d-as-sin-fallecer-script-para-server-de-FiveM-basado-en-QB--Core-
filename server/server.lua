local QBCore = exports['qb-core']:GetCoreObject()

local PlayerSurvivalDays = {}
local tableCreated = false

local function CreateTable()
    if tableCreated then
        return
    end
    
    exports.oxmysql:query('SHOW TABLES LIKE ?', {'player_survival_days'}, function(result)
        if result and #result > 0 then
            tableCreated = true
            print("^2[Contador de Días]^7 Tabla player_survival_days ya existe")
        else
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

local function LoadPlayerDays(citizenid)
    local result = nil
    local done = false
    
    exports.oxmysql:single('SELECT days_survived FROM player_survival_days WHERE citizenid = ?', {citizenid}, function(data)
        result = data
        done = true
    end)
    
    while not done do
        Wait(0)
    end
    
    if result and result.days_survived then
        return result.days_survived
    else
        exports.oxmysql:insert('INSERT INTO player_survival_days (citizenid, days_survived) VALUES (?, ?) ON DUPLICATE KEY UPDATE days_survived = days_survived', {
            citizenid,
            0
        })
        return 0
    end
end

local function SavePlayerDays(citizenid, days)
    exports.oxmysql:insert('INSERT INTO player_survival_days (citizenid, days_survived) VALUES (?, ?) ON DUPLICATE KEY UPDATE days_survived = ?, last_update = CURRENT_TIMESTAMP', {
        citizenid,
        days,
        days
    })
end

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

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then return end
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    local days = LoadPlayerDays(citizenid)
    PlayerSurvivalDays[citizenid] = days
    TriggerClientEvent('survival-days:client:SetDays', Player.PlayerData.source, days)
end)

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

RegisterNetEvent('survival-days:server:UpdateDays', function(days)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        PlayerSurvivalDays[citizenid] = days
    end
end)

CreateThread(function()
    local lastSavedMinute = -1
    while true do
        Wait(1000)
        
        local currentTime = os.date("*t")
        if currentTime.min == Config.Save.minute and currentTime.sec == Config.Save.second and lastSavedMinute ~= currentTime.min then
            SaveAllPlayers()
            lastSavedMinute = currentTime.min
        elseif currentTime.min ~= Config.Save.minute then
            lastSavedMinute = -1
        end
    end
end)

CreateThread(function()
    local attempts = 0
    while not exports.oxmysql do
        Wait(100)
        attempts = attempts + 1
        if attempts > 50 then
            print("^1[Contador de Días]^7 Error: No se pudo conectar con oxmysql")
            return
        end
    end
    Wait(1000)
    CreateTable()
    
    Wait(500)
    
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

