Config = {}

-- Configuración de UI
Config.UI = {
    position = {
        x = 0.02,  -- Esquina inferior izquierda (2% desde la izquierda)
        y = 0.85   -- Esquina inferior izquierda (95% desde arriba)
    },
    colors = {
        background = '#1a0000',  -- Rojo oscuro
        text = '#FFFFFF',         -- Blanco
        accent = '#FF0000',       -- Rojo
        border = '#CC0000'        -- Rojo oscuro para borde
    }
}

-- Configuración de día/noche
Config.DayNight = {
    dayStart = 6,    -- Hora de inicio del día (6:00)
    nightStart = 20  -- Hora de inicio de la noche (20:00)
}

-- Configuración de guardado
Config.Save = {
    minute = 59,     -- Minuto para guardar (59)
    second = 30      -- Segundo para guardar (30)
}

