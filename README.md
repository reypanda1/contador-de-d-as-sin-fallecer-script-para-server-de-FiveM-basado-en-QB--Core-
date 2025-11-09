# Contador de Días - QBCore

Pequeño recurso para QBCore que cuenta los días que un jugador sobrevive sin morir y los muestra en una interfaz NUI.

## Instalación

1. Copia la carpeta del recurso dentro de tu carpeta `resources` del servidor.
2. Asegúrate de tener instalados y configurados:
   - qb-core
   - qb-weathersync
   - oxmysql
3. Añade el recurso al `server.cfg`:
   ```sh
   ensure Contador de dias
   ```
4. Configura tu conexión MySQL para `oxmysql` (archivo de configuración de tu servidor).
5. Reinicia el servidor. La tabla SQL se creará automáticamente si no existe.

## Archivos clave

- `config.lua` — configuración del UI, día/noche y guardado.
- `fxmanifest.lua` — manifiesto del recurso.
- `client/client.lua` — lógica del cliente (conteo, UI, detección de muertes).
- `server/server.lua` — manejo en servidor, persistencia en base de datos.
- `html/index.html` — NUI.
- `html/script.js` — JS del NUI.
- `html/style.css` — estilos del NUI.

## Cómo funciona (resumen técnico)

- Al iniciar el recurso se ejecuta `CreateTable` para crear la tabla `player_survival_days` si no existe.
- Cuando un jugador se carga, el servidor maneja el evento de carga y llama a `LoadPlayerDays` para recuperar los días guardados y los mantiene en memoria en `PlayerSurvivalDays`.
- El cliente cuenta días usando la hora del juego (`GetClockHours`, `GetClockMinutes`) y detecta la transición de 23:59 -> 00:00 para incrementar `daysSurvived`.
- Cuando el contador cambia, el cliente actualiza la NUI mediante `UpdateUI` que envía mensajes a script.js.
- El servidor guarda periódicamente todos los registros en la base de datos ejecutando `SaveAllPlayers` en un thread que checa la hora según `Config.Save`.
- Si el jugador muere y revive, el contador se reinicia. El cliente escucha eventos de muerte/respawn (`hospital:client:SetDeathStatus`, `hospital:client:Revive`) y notifica al servidor.

## Personalización

- UI: ajusta colores y posición en `config.lua` o modifica `html/style.css`.
- Frecuencia de guardado: modifica `Config.Save.minute` y `Config.Save.second` en `config.lua`.

## Eventos y funciones útiles

### Servidor
- `survival-days:server:UpdateDays` — actualización enviada por el cliente.
- `survival-days:server:PlayerDied` — reinicia contador de un jugador en el servidor.
- `QBCore:Server:PlayerLoaded` — handler de carga de jugador.

### Cliente
- `survival-days:client:SetDays` — cliente recibe el valor inicial de días.
- `survival-days:client:ShowUI` — mostrar UI.
- `ResetCounter` — reinicia contador local y notifica al servidor.

## Notas y buenas prácticas

- Asegúrate de que `oxmysql` esté funcionando antes de iniciar el recurso.
- La tabla SQL se crea automáticamente, pero revisa permisos y charset de tu base de datos si hay problemas.
- El conteo evita incrementos si el jugador está muerto. El reinicio ocurre al revivir.

## Soporte

Si encuentras algún problema o necesitas ayuda, puedes abrir un issue en el repositorio o contactar al desarrollador.