-- main_with_api.lua
-- Versión de main.lua integrada con la API REST

-- Importar el cliente API
local APIClient = require("api_client")

-- Variables para la API
local currentSessionId = nil
local apiConnected = false
local lastApiUpdate = 0
local apiUpdateInterval = 5 -- Actualizar cada 5 segundos

-- Variables para el estado del juego (mantener las originales)
local scene = "title"
local titulo
local ondas = {}
local particulas = {}
local tituloScale = 1
local tituloX, tituloY = 0, 0
local slime = {x=0, y=0, r=24, speed=180}
local world = {w=3000, h=2000}
local cam = {x=0, y=0}
local enemies = {}
local num_enemies = 20

-- ... (mantener todas las variables originales del main.lua)

-- Función para inicializar la API
local function initAPI()
    -- Cargar token guardado
    if APIClient.loadToken() then
        print("Token cargado automáticamente")
    end
    
    -- Verificar conexión con la API
    local success, response = APIClient.checkConnection()
    if success then
        apiConnected = true
        print("API conectada:", response.message)
    else
        apiConnected = false
        print("Error conectando a API:", response.error)
    end
end

-- Función para iniciar sesión de juego
local function startGameSession()
    if not apiConnected then return end
    
    local gameState = {
        slime = { x = slime.x, y = slime.y, hp = slime.hp, maxHp = slime.maxhp },
        world = { width = world.w, height = world.h },
        enemies = {},
        projectiles = {}
    }
    
    local success, response = APIClient.startGameSession(gameState)
    if success then
        currentSessionId = response.sessionId
        print("Sesión iniciada:", currentSessionId)
    else
        print("Error iniciando sesión:", response.error)
    end
end

-- Función para actualizar estadísticas en la API
local function updateGameStats()
    if not apiConnected or not currentSessionId then return end
    
    local gameState = {
        slime = { x = slime.x, y = slime.y, hp = slime.hp, maxHp = slime.maxhp },
        world = { width = world.w, height = world.h },
        enemies = {},
        projectiles = {}
    }
    
    APIClient.updateGameSession(
        currentSessionId,
        gameState,
        score,
        round,
        enemiesKilledThisSession,
        bossesKilledThisSession,
        coinsCollectedThisSession
    )
end

-- Función para finalizar sesión de juego
local function endGameSession(deathReason)
    if not apiConnected or not currentSessionId then return end
    
    local gameState = {
        slime = { x = slime.x, y = slime.y, hp = slime.hp, maxHp = slime.maxhp },
        world = { width = world.w, height = world.h },
        enemies = {},
        projectiles = {}
    }
    
    local success, response = APIClient.endGameSession(
        currentSessionId,
        score,
        round,
        enemiesKilledThisSession,
        bossesKilledThisSession,
        coinsCollectedThisSession,
        deathReason or "other",
        gameState
    )
    
    if success then
        print("Sesión finalizada correctamente")
        -- Mostrar estadísticas del jugador si están disponibles
        if response.playerUpdate then
            print("Experiencia ganada:", response.playerUpdate.experienceGained)
            if response.playerUpdate.levelUp then
                print("¡Subiste de nivel! Nuevo nivel:", response.playerUpdate.newLevel)
            end
        end
    else
        print("Error finalizando sesión:", response.error)
    end
    
    currentSessionId = nil
end

-- Función para registrar eventos específicos
local function registerGameEvent(eventType, eventData)
    if not apiConnected or not currentSessionId then return end
    
    APIClient.registerGameEvent(currentSessionId, eventType, eventData)
end

-- Modificar love.load() para incluir inicialización de API
local originalLoveLoad = love.load
function love.load()
    -- Llamar la función original
    originalLoveLoad()
    
    -- Inicializar API
    initAPI()
end

-- Modificar love.update() para incluir actualizaciones de API
local originalLoveUpdate = love.update
function love.update(dt)
    -- Llamar la función original
    originalLoveUpdate(dt)
    
    -- Actualizar API cada cierto tiempo
    lastApiUpdate = lastApiUpdate + dt
    if lastApiUpdate >= apiUpdateInterval then
        updateGameStats()
        lastApiUpdate = 0
    end
end

-- Modificar la función de inicio de juego
local originalStartGame = function()
    -- Código original de inicio de juego
    scene = "run"
    slime.hp = slime.maxhp
    scoreWave = 0
    waveScoreGlobal = 0
    round = 1
    roundGoal = 300
    shopActive = false
    shopInteracted = false
    nextRoundTimer = 0
    shopX, shopY = world.w/2, world.h/2
    slime.x = world.w/2
    slime.y = world.h/2
    spawnEnemies()
    projectiles = {}
    archer_projectiles = {}
    coins = {}
    ammoDrops = {}
    
    sessionStartTime = love.timer.getTime()
    currentSessionTime = 0
    enemiesKilledThisSession = 0
    bossesKilledThisSession = 0
    coinsCollectedThisSession = 0
    
    -- Iniciar sesión de juego en la API
    startGameSession()
end

-- Modificar love.keypressed() para usar la nueva función de inicio
local originalLoveKeypressed = love.keypressed
function love.keypressed(key)
    if scene == "title" and (key == "return" or key == "space") then
        scene = "lobby"
    elseif scene == "lobby" and key == "return" then
        originalStartGame()
    elseif scene == "run" and key == "escape" then
        scene = "lobby"
    -- ... resto del código original
    end
    
    -- Llamar la función original para el resto de teclas
    originalLoveKeypressed(key)
end

-- Modificar la función de muerte para finalizar sesión
local originalDeathAnim = deathAnim
local function handlePlayerDeath()
    if not deathAnim.active then
        -- Iniciar animación de muerte
        deathAnim.active = true
        deathAnim.timer = 2.0
        deathAnim.scale = 1
        deathAnim.alpha = 1
        deathAnim.particles = {}
        
        -- Generar partículas de derretimiento
        for i=1, 15 do
            local angle = math.random() * 2 * math.pi
            local speed = 30 + math.random()*40
            table.insert(deathAnim.particles, {
                x=slime.x, y=slime.y,
                dx=math.cos(angle)*speed,
                dy=math.sin(angle)*speed,
                alpha=1, size=3+math.random()*4, t=0
            })
        end
        
        -- Finalizar sesión de juego en la API
        endGameSession("enemy")
    end
end

-- Modificar las funciones de eventos para registrar en la API
local originalEnemyKilled = function(enemyType)
    -- Código original de eliminación de enemigo
    scoreWave = scoreWave + 10
    enemiesKilledThisSession = enemiesKilledThisSession + 1
    
    -- Registrar evento en la API
    registerGameEvent("enemy_killed", { enemyType = enemyType })
end

local originalBossKilled = function()
    -- Código original de eliminación de jefe
    scoreWave = scoreWave + 100
    bossesKilledThisSession = bossesKilledThisSession + 1
    
    -- Registrar evento en la API
    registerGameEvent("boss_killed", {})
end

local originalCoinCollected = function()
    -- Código original de recolección de moneda
    scoreWave = scoreWave + 10
    coinCount = coinCount + 1
    coinsCollectedThisSession = coinsCollectedThisSession + 1
    
    -- Registrar evento en la API
    registerGameEvent("coin_collected", {})
end

-- Función para mostrar estadísticas del jugador
local function showPlayerStats()
    if not apiConnected then return end
    
    local success, response = APIClient.getPlayerStats()
    if success then
        print("=== Estadísticas del Jugador ===")
        print("Nivel:", response.player.level)
        print("Experiencia:", response.player.experience)
        print("Monedas:", response.player.coins)
        if response.stats then
            print("Partidas jugadas:", response.stats.totalGamesPlayed)
            print("Puntaje más alto:", response.stats.highestScore)
            print("Enemigos eliminados:", response.stats.totalEnemiesKilled)
            print("Jefes derrotados:", response.stats.totalBossesKilled)
        end
    else
        print("Error obteniendo estadísticas:", response.error)
    end
end

-- Función para mostrar logros
local function showAchievements()
    if not apiConnected then return end
    
    local success, response = APIClient.getAchievements()
    if success then
        print("=== Logros ===")
        print("Desbloqueados:", response.totalUnlocked)
        print("Disponibles:", response.totalAvailable)
        
        for i, achievement in ipairs(response.unlocked) do
            print(string.format("✓ %s: %s", achievement.name, achievement.description))
        end
    else
        print("Error obteniendo logros:", response.error)
    end
end

-- Función para mostrar leaderboard
local function showLeaderboard()
    if not apiConnected then return end
    
    local success, response = APIClient.getLeaderboard("score", 10)
    if success then
        print("=== Top 10 Puntajes ===")
        for i, entry in ipairs(response.leaderboard) do
            print(string.format("%d. %s - %d puntos", 
                entry.rank, entry.player.username, entry.value))
        end
    else
        print("Error obteniendo leaderboard:", response.error)
    end
end

-- Agregar teclas para funciones de API
local originalLoveKeypressed = love.keypressed
function love.keypressed(key)
    -- Llamar función original
    originalLoveKeypressed(key)
    
    -- Teclas adicionales para API
    if key == "f1" then
        showPlayerStats()
    elseif key == "f2" then
        showAchievements()
    elseif key == "f3" then
        showLeaderboard()
    elseif key == "f4" then
        -- Recargar conexión API
        initAPI()
    end
end

-- Modificar love.draw() para mostrar estado de API
local originalLoveDraw = love.draw
function love.draw()
    -- Llamar función original
    originalLoveDraw()
    
    -- Mostrar estado de API en la esquina
    if scene == "run" then
        love.graphics.setColor(apiConnected and {0,1,0,1} or {1,0,0,1})
        love.graphics.print("API: " .. (apiConnected and "Conectada" or "Desconectada"), 10, 10)
        
        if currentSessionId then
            love.graphics.setColor(1,1,1,0.8)
            love.graphics.print("Sesión: " .. string.sub(currentSessionId, 1, 10) .. "...", 10, 30)
        end
        
        love.graphics.setColor(1,1,1,1)
    end
end

-- Función para limpiar al salir
function love.quit()
    -- Finalizar sesión si está activa
    if currentSessionId then
        endGameSession("manual")
    end
    
    -- Guardar token
    APIClient.saveToken()
end

-- ... (mantener el resto del código original del main.lua) 