-- main.lua
local scene = "login" -- Cambiar a "login" para empezar con el sistema de login
local titulo
local ondas = {}
local particulas = {}
local tituloScale = 1
local tituloX, tituloY = 0, 0

-- Sistema de login
local loginSystem = require("login_system")
local currentUser = nil
local userStats = nil
local slime = {x=0, y=0, r=24, speed=180}
local world = {w=3000, h=2000}
local cam = {x=0, y=0}
local enemies = {}
local num_enemies = 20

local enemy_types = {
    bomber = {speed=220, color={1,0.7,0.2}, r=18},
    blader = {speed=120, color={0.7,0.7,1}, r=20},
    archer = {speed=80, color={0.3,1,0.3}, r=16}
}

-- Sistema de jefes
local boss_types = {
    shooter = {
        name = "Shooter Boss",
        speed = 50,
        color = {0.2, 0.8, 0.2},
        r = 28,
        hp = 180,
        maxhp = 180,
        attack_pattern = "spiral_shots",
        shot_cooldown = 2.5,
        spiral_angle = 0,
        spiral_radius = 0,
        chess_pattern_timer = 0,
        chess_pattern_phase = 0
    },
    swordsman = {
        name = "Swordsman Boss",
        speed = 120,
        color = {0.8, 0.4, 0.2},
        r = 32,
        hp = 220,
        maxhp = 220,
        attack_pattern = "sword_slash",
        slash_cooldown = 1.8,
        slash_duration = 0.6,
        slash_angle = 0,
        is_slashing = false,
        normal_speed = 120,
        slash_speed = 40
    },
    summoner = {
        name = "Summoner Boss",
        speed = 30,
        color = {0.6, 0.2, 0.8},
        r = 30,
        hp = 160,
        maxhp = 160,
        attack_pattern = "defensive_summon",
        summon_cooldown = 3.0,
        summon_timer = 0,
        escape_speed = 20
    }
}

local boss = nil
local boss_active = false
local boss_spawn_round = 3 -- Cada 3 rondas
local boss_phase = 1
local boss_attack_timer = 0
local boss_charge_timer = 0
local boss_charging = false
local boss_summon_timer = 0
local boss_minions = {}
local boss_projectiles = {}
local boss_sword_anim = {active=false, timer=0, angle=0}

--, no se que hacer XDDDDDD
-- Salud de Blob xd
slime.maxhp = 100
slime.hp = slime.maxhp
local projectiles = {}
local archer_projectiles = {}
local shootTimer = 0
local shotsLeft = 5
local reloadTimer = 0
local reloading = false
local maxShots = 5
local reloadTime = 1.2

local score = 0
local round = 1
local shopActive = false
local shopX, shopY = world.w/2, world.h/2
local showArrow = false
local shopInteracted = false
local nextRoundTimer = 0

-- Agregar variable para mostrar el puntaje de la última oleada
local lastWaveScore = 0

local tituloPath = "imagenes/tittle/titulo.png"
local playBtnPaths = {
    normal = "imagenes/playButton/jugar1.png",
    hover = "imagenes/playButton/jugar2.png",
    pressed = "imagenes/playButton/jugar3.png"
}
local playBtn = {img={}, x=0, y=0, w=0, h=0, state="normal"}

-- Funciones mejoradas para guardar/cargar estadísticas en JSON
local statsFile = "stats.json"
local stats = {
    puntaje_mas_alto = 0,
    ultimo_puntaje = 0,
    partidas_jugadas = 0,
    tiempo_total_jugado = 0,
    enemigos_eliminados = 0,
    jefes_derrotados = 0,
    rondas_completadas = 0,
    monedas_recolectadas = 0,
    fecha_ultima_partida = "",
    mejor_ronda = 0
}

-- Serialización mejorada a JSON
local function tableToJson(tbl)
    local function escapeString(str)
        return string.gsub(str, '["\\]', function(c) return "\\" .. c end)
    end
    
    local function serializeValue(v)
        if type(v) == "string" then
            return '"' .. escapeString(v) .. '"'
        elseif type(v) == "number" or type(v) == "boolean" then
            return tostring(v)
        elseif type(v) == "table" then
            local result = "{"
            local first = true
            for k, val in pairs(v) do
                if not first then result = result .. "," end
                result = result .. '"' .. escapeString(tostring(k)) .. '":' .. serializeValue(val)
                first = false
            end
            return result .. "}"
        else
            return '"' .. tostring(v) .. '"'
        end
    end
    
    return serializeValue(tbl)
end

local function jsonToTable(str)
    local t = {}
    -- Eliminar espacios y saltos de línea
    str = str:gsub("%s+", "")
    
    -- Función para parsear valores
    local function parseValue(s, pos)
        if s:sub(pos, pos) == '"' then
            -- String
            local endPos = pos + 1
            while endPos <= #s and s:sub(endPos, endPos) ~= '"' do
                if s:sub(endPos, endPos) == "\\" then
                    endPos = endPos + 2
                else
                    endPos = endPos + 1
                end
            end
            local value = s:sub(pos + 1, endPos - 1)
            return value, endPos + 1
        elseif s:sub(pos, pos) == '{' then
            -- Object
            local obj = {}
            local currentPos = pos + 1
            while currentPos <= #s and s:sub(currentPos, currentPos) ~= '}' do
                if s:sub(currentPos, currentPos) == '"' then
                    local key, keyEnd = parseValue(s, currentPos)
                    currentPos = keyEnd
                    if s:sub(currentPos, currentPos) == ':' then
                        currentPos = currentPos + 1
                        local value, valueEnd = parseValue(s, currentPos)
                        obj[key] = value
                        currentPos = valueEnd
                    end
                else
                    currentPos = currentPos + 1
                end
            end
            return obj, currentPos + 1
        else
            -- Number or boolean
            local endPos = pos
            while endPos <= #s and s:sub(endPos, endPos):match("[%d%.%-%+]") do
                endPos = endPos + 1
            end
            local value = s:sub(pos, endPos - 1)
            if value == "true" then return true, endPos
            elseif value == "false" then return false, endPos
            else return tonumber(value) or 0, endPos end
        end
    end
    
    local result, _ = parseValue(str, 1)
    return result or {}
end

local function saveStats(stats)
    local json = tableToJson(stats)
    love.filesystem.write(statsFile, json)
    
    -- También guardar en MongoDB si el usuario está logueado
    if currentUser and loginSystem then
        local mongoStats = {
            highScore = stats.puntaje_mas_alto,
            lastScore = stats.ultimo_puntaje,
            totalGames = stats.partidas_jugadas,
            totalTime = stats.tiempo_total_jugado,
            enemiesKilled = stats.enemigos_eliminados,
            bossesKilled = stats.jefes_derrotados,
            roundsCompleted = stats.rondas_completadas,
            coinsCollected = stats.monedas_recolectadas,
            lastGameDate = stats.fecha_ultima_partida,
            bestRound = stats.mejor_ronda,
            userId = currentUser.id,
            username = currentUser.username
        }
        loginSystem:saveGameStats(mongoStats)
    end
end

local function loadStats()
    if love.filesystem.getInfo(statsFile) then
        local contents = love.filesystem.read(statsFile)
        local t = jsonToTable(contents)
        -- Validar y actualizar stats con valores por defecto
        stats.puntaje_mas_alto = tonumber(t.puntaje_mas_alto) or 0
        stats.ultimo_puntaje = tonumber(t.ultimo_puntaje) or 0
        stats.partidas_jugadas = tonumber(t.partidas_jugadas) or 0
        stats.tiempo_total_jugado = tonumber(t.tiempo_total_jugado) or 0
        stats.enemigos_eliminados = tonumber(t.enemigos_eliminados) or 0
        stats.jefes_derrotados = tonumber(t.jefes_derrotados) or 0
        stats.rondas_completadas = tonumber(t.rondas_completadas) or 0
        stats.monedas_recolectadas = tonumber(t.monedas_recolectadas) or 0
        stats.fecha_ultima_partida = t.fecha_ultima_partida or ""
        stats.mejor_ronda = tonumber(t.mejor_ronda) or 0
    end
end

-- Función para obtener fecha actual
local function getCurrentDate()
    local time = os.time()
    return os.date("%d/%m/%Y %H:%M", time)
end

-- Función para formatear tiempo
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local shopItems = {
    {id = "mult4", name = "Multiplicador x4", price = 0, icon = function(x, y, size, anim)
        love.graphics.setColor(0.7+0.3*anim,0.7,1,1)
        love.graphics.rectangle("fill", x, y, size, size, 8, 8)
        love.graphics.setColor(0.2,0.2,0.5,1)
        love.graphics.rectangle("line", x, y, size, size, 8, 8)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf("4", x, y+size/4, size, "center")
        love.graphics.setColor(1,1,1,1)
    end}
}
table.insert(shopItems, {
    id = "double_gun", name = "Arma Doble", price = 0, icon = function(x, y, size, anim)
        love.graphics.setColor(1,0.7+0.3*anim,0.2,1)
        love.graphics.rectangle("fill", x, y, size, size, 8, 8)
        love.graphics.setColor(0.5,0.2,0.2,1)
        love.graphics.rectangle("line", x, y, size, size, 8, 8)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf("x2", x, y+size/4, size, "center")
        love.graphics.setColor(1,1,1,1)
    end
})
local ownedItems = {}
local maxItems = 5
local mult4Anim = 0
local mult4AnimTimer = 0
local roundScore = 0
local roundGoal = 300

local configBtn = {x=0, y=0, w=0, h=0}
local statsBtn = {x=0, y=0, w=0, h=0}
local buyAnim = {active=false, slot=0, timer=0, scale=1}
local dragging = {active=false, slot=0, offsetX=0, offsetY=0}

-- Variables para tracking de estadísticas
local sessionStartTime = 0
local currentSessionTime = 0
local enemiesKilledThisSession = 0
local bossesKilledThisSession = 0
local coinsCollectedThisSession = 0

-- Sistema de configuraciones
local config = {
    volumen_musica = 0.7,
    volumen_efectos = 0.8,
    pantalla_completa = false,
    mostrar_fps = false,
    sensibilidad_mouse = 1.0,
    idioma = "español"
}

-- Función para aplicar pantalla completa
local function applyFullscreen()
    if config.pantalla_completa then
        love.window.setFullscreen(true)
    else
        love.window.setFullscreen(false)
    end
end

-- Botones de configuración
local configButtons = {
    {id = "volumen_musica", name = "Volumen Música", type = "slider", min = 0, max = 1, step = 0.1},
    {id = "volumen_efectos", name = "Volumen Efectos", type = "slider", min = 0, max = 1, step = 0.1},
    {id = "pantalla_completa", name = "Pantalla Completa", type = "toggle"},
    {id = "mostrar_fps", name = "Mostrar FPS", type = "toggle"},
    {id = "sensibilidad_mouse", name = "Sensibilidad Mouse", type = "slider", min = 0.5, max = 2.0, step = 0.1}
}

local selectedConfigButton = 1
local configScrollY = 0

-- Animación de muerte de Blob
local deathAnim = {active=false, timer=0, scale=1, alpha=1, particles={}}

-- Estructura de armas y barra de armas
local weapon_defs = {
    basic = {name="Básica", damage=10, max_ammo=999, reload_time=0, color={1,1,1,1}},
    double = {name="Doble", damage=20, max_ammo=10, reload_time=0.5, color={1,0.7,0.2,1}},
}
local weapons = { {id="basic", ammo=999, reloading=false, reload_timer=0} }
local max_weapons = 3
local selected_weapon = 1

local shopSelected = 1

-- Enemigos pueden soltar munición
local function spawnAmmoDrop(x, y)
    table.insert(ammoDrops, {x=x, y=y, timer=7})
end

-- Enemigos pueden soltar monedas
local function spawnCoinDrop(x, y)
    table.insert(coins, {x=x, y=y})
end

function love.load()
    loadStats()
    
    -- Inicializar sistema de login
    loginSystem:init()
    
    -- Aplicar configuración de pantalla completa al cargar
    applyFullscreen()
    
    titulo = love.graphics.newImage(tituloPath)
    playBtn.img.normal = love.graphics.newImage(playBtnPaths.normal)
    playBtn.img.hover = love.graphics.newImage(playBtnPaths.hover)
    playBtn.img.pressed = love.graphics.newImage(playBtnPaths.pressed)
    -- Escalado del título
    local minFrac = 0.8
    local winW = love.graphics.getWidth()
    tituloScale = (winW * minFrac) / titulo:getWidth()
    if tituloScale > 4 then tituloScale = 4 end -- Limitar escala máxima
    tituloX = winW/2 - (titulo:getWidth()*tituloScale)/2
    tituloY = 40
    -- Escalado y posición del botón de jugar
    playBtn.scale = 0.16
    playBtn.w = playBtn.img.normal:getWidth() * playBtn.scale
    playBtn.h = playBtn.img.normal:getHeight() * playBtn.scale
    playBtn.x = winW/2 - playBtn.w/2
    playBtn.y = love.graphics.getHeight() * 0.75 - playBtn.h/2
    
    -- Inicializar botones de configuración
    configBtn.w = 200
    configBtn.h = 50
    configBtn.x = winW/2 - configBtn.w/2
    configBtn.y = playBtn.y + playBtn.h + 20
    
    statsBtn.w = 200
    statsBtn.h = 50
    statsBtn.x = winW/2 - statsBtn.w/2
    statsBtn.y = configBtn.y + configBtn.h + 20
    
    -- Inicializar tiempo de sesión
    sessionStartTime = love.timer.getTime()
    currentSessionTime = 0
    
    ondas = {}
    particulas = {}
    coins = {}
    ammoDrops = {}
    projectiles = {}
    archer_projectiles = {}
    ownedItems = {}
    -- Centrar slime en el mundo
    slime.x = world.w/2
    slime.y = world.h/2
    -- Generar enemigos aleatorios de diferentes tipos
    enemies = {}
    for i=1,num_enemies do
        local ex = math.random(60, world.w-60)
        local ey = math.random(60, world.h-60)
        local t
        local hp
        if i <= num_enemies/3 then t = "bomber"; hp = 20
        elseif i <= 2*num_enemies/3 then t = "blader"; hp = 40
        else t = "archer"; hp = 10 end
        table.insert(enemies, {x=ex, y=ey, type=t, r=enemy_types[t].r, vx=0, vy=0, hp=hp, maxhp=hp, hitTimer=0, attackTimer=0})
    end
    -- Generar terreno simple (bloques aleatorios)
    world.tilesize = 64
    world.tilesx = math.floor(world.w/world.tilesize)
    world.tilesy = math.floor(world.h/world.tilesize)
    world.terrain = {}
    for y=1,world.tilesy do
        world.terrain[y] = {}
        for x=1,world.tilesx do
            if math.random() < 0.12 then
                world.terrain[y][x] = true -- bloque
            else
                world.terrain[y][x] = false
            end
        end
    end
    shootTimer = 0
    shotsLeft = maxShots
    reloadTimer = 0
    reloading = false
    score = 0
    round = 1
    shopActive = false
    shopInteracted = false
    nextRoundTimer = 0
    shopX, shopY = world.w/2, world.h/2
    roundGoal = 300
    roundScore = 0
    mult4Anim = 0
    mult4AnimTimer = 0
    coinCount = 0
    scoreWave = 0
    waveScoreGlobal = 0
    boss = nil
    boss_active = false
    boss_minions = {}
    boss_projectiles = {}
    boss_sword_anim = {active=false, timer=0, angle=0}
end

function spawnEnemies()
    enemies = {}
    for i=1,20 do
        local ex, ey, safe
        local t, hp
        local r = math.random()
        if r < 0.33 then t = "bomber"; hp = 20
        elseif r < 0.66 then t = "blader"; hp = 40
        else t = "archer"; hp = 10 end
        repeat
            ex = math.random(60, world.w-60)
            ey = math.random(60, world.h-60)
            local dx = ex - slime.x
            local dy = ey - slime.y
            if t == "archer" then
                safe = (dx*dx + dy*dy) > (slime.r+900)^2 -- archer mucho más lejos
            else
                safe = (dx*dx + dy*dy) > (slime.r+400)^2
            end
        until safe
        table.insert(enemies, {x=ex, y=ey, type=t, r=enemy_types[t].r, vx=0, vy=0, hp=hp, maxhp=hp, hitTimer=0, attackTimer=0})
    end
end

function spawnBoss()
    boss_active = true
    boss_phase = 1
    boss_attack_timer = 0
    boss_charge_timer = 0
    boss_charging = false
    boss_summon_timer = 0
    boss_minions = {}
    
    -- Elegir tipo de boss basado en la ronda
    local boss_type
    if round % 9 == 3 then -- Ronda 3
        boss_type = "shooter"
    elseif round % 9 == 6 then -- Ronda 6
        boss_type = "swordsman"
    elseif round % 9 == 9 then -- Ronda 9
        boss_type = "summoner"
    else
        -- Ciclo se repite cada 9 rondas
        local cycle = round % 9
        if cycle == 0 then cycle = 9 end
        if cycle <= 3 then boss_type = "shooter"
        elseif cycle <= 6 then boss_type = "swordsman"
        else boss_type = "summoner" end
    end
    
    local boss_def = boss_types[boss_type]
    boss = {
        x = world.w/2,
        y = world.h/2,
        type = boss_type,
        r = boss_def.r,
        hp = boss_def.hp,
        maxhp = boss_def.maxhp,
        vx = 0,
        vy = 0,
        attack_timer = 0,
        charge_timer = 0,
        charging = false,
        summon_timer = 0,
        phase = 1
    }
    
    -- Generar onda de aparición
    table.insert(ondas, {x=boss.x, y=boss.y, r=0, alpha=1, color={1,0.2,0.2}, boss_spawn=true})
end

local function centroTitulo()
    local x = tituloX + (titulo:getWidth()*tituloScale)/2
    local y = tituloY + (titulo:getHeight()*tituloScale)/2
    return x, y
end

-- Devuelve true si el punto (mx, my) está sobre el área visible del título (80% centrado)
local function isMouseOnTitulo(mx, my)
    local w = titulo:getWidth()*tituloScale
    local h = titulo:getHeight()*tituloScale
    local marginX = w*0.1
    local marginY = h*0.1
    return mx >= tituloX+marginX and mx <= tituloX+w-marginX and my >= tituloY+marginY and my <= tituloY+h-marginY
end

local function isMouseOnPlayBtn(mx, my)
    -- Hitbox 60% centrada
    local marginX = playBtn.w*0.2
    local marginY = playBtn.h*0.2
    return mx >= playBtn.x+marginX and mx <= playBtn.x+playBtn.w-marginX and my >= playBtn.y+marginY and my <= playBtn.y+playBtn.h-marginY
end

local function isMouseOnConfigBtn(mx, my)
    return mx >= configBtn.x and mx <= configBtn.x+configBtn.w and my >= configBtn.y and my <= configBtn.y+configBtn.h
end

local function isMouseOnStatsBtn(mx, my)
    return mx >= statsBtn.x and mx <= statsBtn.x+statsBtn.w and my >= statsBtn.y and my <= statsBtn.y+statsBtn.h
end

function love.keypressed(key)
    if scene == "login" then
        -- Manejar eventos del sistema de login
        loginSystem:keypressed(key)
    elseif scene == "title" and (key == "return" or key == "space") then
        scene = "lobby"
    elseif scene == "lobby" and key == "return" then
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
        -- Centrar slime en el mundo al iniciar run
        slime.x = world.w/2
        slime.y = world.h/2
        spawnEnemies()
        projectiles = {}
        archer_projectiles = {}
        coins = {}
        ammoDrops = {}
        
        -- Reiniciar estadísticas de la sesión
        sessionStartTime = love.timer.getTime()
        currentSessionTime = 0
        enemiesKilledThisSession = 0
        bossesKilledThisSession = 0
        coinsCollectedThisSession = 0
    elseif scene == "run" and key == "escape" then
        scene = "lobby"
    elseif scene == "run" and shopActive and shopInteracted and key == "space" and not deathAnim.active then
        -- Solo activar el temporizador, no cerrar la tienda aún
        nextRoundTimer = 5
    elseif scene == "run" and shopActive and not shopInteracted and key == "e" and not deathAnim.active then
        shopInteracted = true
    elseif scene == "settings" and key == "escape" then
        scene = "title"
    elseif scene == "settings" and key == "up" then
        selectedConfigButton = math.max(1, selectedConfigButton - 1)
    elseif scene == "settings" and key == "down" then
        selectedConfigButton = math.min(#configButtons, selectedConfigButton + 1)
    elseif scene == "settings" and key == "return" then
        local button = configButtons[selectedConfigButton]
        if button.type == "toggle" then
            config[button.id] = not config[button.id]
            -- Aplicar pantalla completa inmediatamente si se cambia
            if button.id == "pantalla_completa" then
                applyFullscreen()
            end
        elseif button.type == "slider" then
            -- Para sliders, usar left/right en lugar de enter
        end
    elseif scene == "settings" and key == "left" then
        local button = configButtons[selectedConfigButton]
        if button.type == "slider" then
            config[button.id] = math.max(button.min, config[button.id] - button.step)
        end
    elseif scene == "settings" and key == "right" then
        local button = configButtons[selectedConfigButton]
        if button.type == "slider" then
            config[button.id] = math.min(button.max, config[button.id] + button.step)
        end
    elseif scene == "stats" and key == "escape" then
        scene = "settings"
    end
    -- Cambiar arma con teclas 1,2,3 SOLO si estamos en run y no está muerto
    if scene == "run" and not deathAnim.active then
        if key == "1" then selected_weapon = 1 end
        if key == "2" and weapons[2] then selected_weapon = 2 end
        if key == "3" and weapons[3] then selected_weapon = 3 end
        -- Soltar arma con TAB (excepto la básica)
        if key == "tab" and selected_weapon > 1 and weapons[selected_weapon] then
            table.remove(weapons, selected_weapon)
            if selected_weapon > #weapons then selected_weapon = #weapons end
        end
    end
    -- Selección de objetos de la tienda con teclas numéricas
    if scene == "run" and shopActive and shopInteracted and not deathAnim.active then
        if key == "1" then shopSelected = 1 end
        if key == "2" then shopSelected = 2 end
        if key == "return" or key == "kpenter" then
            if shopSelected == 1 then
                local canBuyMult4 = true
                for _,it in ipairs(ownedItems) do if it == shopItems[1].id then canBuyMult4 = false end end
                if canBuyMult4 and coinCount >= 10 then
                    coinCount = coinCount - 10
                    table.insert(ownedItems, shopItems[1].id)
                    buyAnim.active = true
                    buyAnim.slot = #ownedItems
                    buyAnim.timer = 0.6
                    buyAnim.scale = 1.8
                end
            elseif shopSelected == 2 then
                local canBuyDouble = true
                for _,wp in ipairs(weapons) do if wp.id == "double" then canBuyDouble = false end end
                if canBuyDouble and coinCount >= 10 then
                    coinCount = coinCount - 10
                    table.insert(weapons, {id="double", ammo=weapon_defs.double.max_ammo, reloading=false, reload_timer=0})
                    selected_weapon = #weapons
                end
            end
        end
    end
end

function love.textinput(text)
    if scene == "login" then
        -- Manejar entrada de texto del sistema de login
        loginSystem:textinput(text)
    end
end

function love.keyreleased(key)
    if scene == "login" then
        -- Manejar eventos de teclas del sistema de login
        loginSystem:keyreleased(key)
    end
end

function love.mousepressed(x, y, button)
    if scene == "login" then
        -- Manejar eventos del sistema de login
        loginSystem:mousepressed(x, y, button)
    elseif scene == "title" and button == 1 then
        if isMouseOnTitulo(x, y) then
            -- Generar onda
            local cx, cy = centroTitulo()
            table.insert(ondas, {x=cx, y=cy, r=0, alpha=1})
            -- Generar partículas
            for i=1, 12 do
                local angle = math.random() * 2 * math.pi
                local speed = 60 + math.random()*60
                local px = cx + math.cos(angle)*(titulo:getWidth()*tituloScale)/3
                local py = cy + math.sin(angle)*(titulo:getHeight()*tituloScale)/3
                table.insert(particulas, {
                    x=px, y=py,
                    dx=math.cos(angle)*speed,
                    dy=math.sin(angle)*speed,
                    alpha=1, size=2+math.random()*2, t=0
                })
            end
        end
        if isMouseOnPlayBtn(x, y) then
            playBtn.state = "pressed"
        end
        if isMouseOnConfigBtn(x, y) then
            scene = "settings"
        end
        -- Manejar clic en botón de logout
        if currentUser and x >= love.graphics.getWidth() - 120 and x <= love.graphics.getWidth() - 20 and y >= 20 and y <= 50 then
            currentUser = nil
            userStats = nil
            loginSystem.isLoggedIn = false
            loginSystem.currentUser = nil
            scene = "login"
        end
    elseif scene == "run" and not shopActive and nextRoundTimer <= 0 and button == 1 and not deathAnim.active then
        -- Disparo con el arma seleccionada (solo si no está muerto)
        local wp = weapons[selected_weapon]
        local def = weapon_defs[wp.id]
        if not wp.reloading and wp.ammo > 0 then
            local mx, my = love.mouse.getPosition()
            mx = mx + cam.x
            my = my + cam.y
            local dx, dy = mx - slime.x, my - slime.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                local speed = 600
                table.insert(projectiles, {
                    x=slime.x, y=slime.y, dx=dx/dist*speed, dy=dy/dist*speed, r=8, damage=def.damage
                })
                wp.ammo = wp.ammo - 1
                if wp.ammo == 0 and def.reload_time > 0 then
                    wp.reloading = true
                    wp.reload_timer = def.reload_time
                end
            end
        end
    elseif scene == "run" and shopActive and shopInteracted and button == 1 and not deathAnim.active then
        local shopW, shopH = 260, 220
        -- Comprar objeto multiplicador x4 solo si no se tiene
        local bx, by, bw, bh = shopX-shopW/2+32, shopY-shopH/2+60, 64, 64
        local canBuyMult4 = true
        for _,it in ipairs(ownedItems) do if it == shopItems[1].id then canBuyMult4 = false end end
        if canBuyMult4 and x >= bx and x <= bx+bw and y >= by and y <= by+bh then
            if coinCount >= 10 then
                coinCount = coinCount - 10
                table.insert(ownedItems, shopItems[1].id)
                -- Animación de compra
                buyAnim.active = true
                buyAnim.slot = #ownedItems
                buyAnim.timer = 0.6
                buyAnim.scale = 1.8
            end
        end
        -- Comprar arma doble solo si no se tiene
        local bx2, by2, bw2, bh2 = shopX+shopW/2-96, shopY-shopH/2+60, 64, 64
        local canBuyDouble = true
        for _,wp in ipairs(weapons) do if wp.id == "double" then canBuyDouble = false end end
        if canBuyDouble and x >= bx2 and x <= bx2+bw2 and y >= by2 and y <= by2+bh2 then
            if coinCount >= 10 then
                coinCount = coinCount - 10
                table.insert(weapons, {id="double", ammo=weapon_defs.double.max_ammo, reloading=false, reload_timer=0})
                selected_weapon = #weapons
            end
        end
    elseif scene == "settings" and button == 1 then
        if isMouseOnStatsBtn(x, y) then
            scene = "stats"
        end
    elseif scene == "run" and button == 1 and not deathAnim.active then
        -- Drag & drop barra de objetos (solo si no está muerto)
        local barX, barY = love.graphics.getWidth()-180-16, 16+120+60
        local slotSize = 36
        for i=1,maxItems do
            local sx = barX+4+(i-1)*slotSize
            local sy = barY+4
            if x >= sx and x <= sx+slotSize and y >= sy and y <= sy+slotSize and ownedItems[i] then
                dragging.active = true
                dragging.slot = i
                dragging.offsetX = x - sx
                dragging.offsetY = y - sy
            end
        end
        -- Selección de arma con clic en la barra de armas
        local barX2, barY2 = 32, love.graphics.getHeight()-60
        local slotSize2 = 48
        for i=1,#weapons do
            if x >= barX2+(i-1)*slotSize2 and x <= barX2+i*slotSize2 and y >= barY2 and y <= barY2+slotSize2 then
                selected_weapon = i
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if scene == "title" and button == 1 then
        if playBtn.state == "pressed" and isMouseOnPlayBtn(x, y) then
            scene = "lobby"
        end
        playBtn.state = "normal"
    elseif scene == "run" and button == 1 and dragging.active and not deathAnim.active then
        -- Soltar objeto en barra de objetos (solo si no está muerto)
        local barX, barY = love.graphics.getWidth()-180-16, 16+120+60
        local slotSize = 36
        for i=1,maxItems do
            local sx = barX+4+(i-1)*slotSize
            local sy = barY+4
            if x >= sx and x <= sx+slotSize and y >= sy and y <= sy+slotSize then
                -- Intercambiar objetos
                ownedItems[dragging.slot], ownedItems[i] = ownedItems[i], ownedItems[dragging.slot]
            end
        end
        dragging.active = false
        dragging.slot = 0
    end
end

function updateEnemy(e, dt)
    local dx = slime.x - e.x
    local dy = slime.y - e.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if e.type == "bomber" then
        -- Corre directo al jugador
        if dist > 1 then
            e.vx = dx/dist * enemy_types.bomber.speed
            e.vy = dy/dist * enemy_types.bomber.speed
        end
    elseif e.type == "blader" then
        -- Se acerca a velocidad media
        if dist > 1 then
            e.vx = dx/dist * enemy_types.blader.speed
            e.vy = dy/dist * enemy_types.blader.speed
        end
    elseif e.type == "archer" then
        -- Huye si está muy cerca, mantiene distancia óptima para ataque
        local fleeDistance = 120 -- Distancia a la que empieza a huir
        local optimalDistance = 200 -- Distancia óptima para atacar
        local maxDistance = 350 -- Distancia máxima antes de acercarse
        
        if dist < fleeDistance then
            -- Huye del jugador cuando está muy cerca
            e.vx = -dx/dist * enemy_types.archer.speed * 1.2 -- Huye más rápido
            e.vy = -dy/dist * enemy_types.archer.speed * 1.2
        elseif dist > maxDistance then
            -- Se acerca si está muy lejos
            e.vx = dx/dist * enemy_types.archer.speed * 0.8
            e.vy = dy/dist * enemy_types.archer.speed * 0.8
        elseif dist > optimalDistance + 50 then
            -- Se acerca ligeramente si está un poco lejos de la distancia óptima
            e.vx = dx/dist * enemy_types.archer.speed * 0.5
            e.vy = dy/dist * enemy_types.archer.speed * 0.5
        elseif dist < optimalDistance - 50 then
            -- Se aleja ligeramente si está muy cerca de la distancia óptima
            e.vx = -dx/dist * enemy_types.archer.speed * 0.5
            e.vy = -dy/dist * enemy_types.archer.speed * 0.5
        else
            -- Mantiene su posición si está en la distancia óptima
            e.vx, e.vy = 0, 0
        end
    end
    e.x = e.x + e.vx*dt
    e.y = e.y + e.vy*dt
    -- Limitar a los bordes del mundo
    e.x = math.max(e.r, math.min(world.w-e.r, e.x))
    e.y = math.max(e.r, math.min(world.h-e.r, e.y))
end

function updateBoss(dt)
    if not boss or not boss_active then return end
    
    local boss_def = boss_types[boss.type]
    local dx = slime.x - boss.x
    local dy = slime.y - boss.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    -- Actualizar timers
    boss.attack_timer = math.max(0, boss.attack_timer - dt)
    boss.summon_timer = math.max(0, boss.summon_timer - dt)
    
    if boss.type == "shooter" then
        -- Shooter Boss: Dispara espirales y patrones de ajedrez
        -- Movimiento lento para mantener distancia
        if dist < 120 then
            boss.vx = -dx/dist * boss_def.speed
            boss.vy = -dy/dist * boss_def.speed
        elseif dist > 180 then
            boss.vx = dx/dist * boss_def.speed
            boss.vy = dy/dist * boss_def.speed
        else
            boss.vx = 0
            boss.vy = 0
        end
        
        -- Disparos espirales
        if boss.attack_timer <= 0 then
            -- Patrón espiral
            for i = 0, 7 do
                local angle = boss_def.spiral_angle + (i * math.pi/4)
                local speed = 300
                table.insert(boss_projectiles, {
                    x = boss.x, y = boss.y,
                    dx = math.cos(angle) * speed,
                    dy = math.sin(angle) * speed,
                    r = 6, damage = 15, type = "spiral"
                })
            end
            boss_def.spiral_angle = boss_def.spiral_angle + 0.3
            boss.attack_timer = boss_def.shot_cooldown
        end
        
        -- Patrón de ajedrez cada 4 segundos
        boss_def.chess_pattern_timer = (boss_def.chess_pattern_timer or 0) + dt
        if boss_def.chess_pattern_timer >= 4.0 then
            boss_def.chess_pattern_timer = 0
            boss_def.chess_pattern_phase = (boss_def.chess_pattern_phase or 0) + 1
            
            -- Crear patrón de ajedrez con espacios
            for i = 0, 15 do
                for j = 0, 15 do
                    local should_shoot = (i + j + boss_def.chess_pattern_phase) % 2 == 0
                    if should_shoot then
                        local angle = math.atan2(j - 7.5, i - 7.5)
                        local speed = 250
                        table.insert(boss_projectiles, {
                            x = boss.x, y = boss.y,
                            dx = math.cos(angle) * speed,
                            dy = math.sin(angle) * speed,
                            r = 5, damage = 12, type = "chess"
                        })
                    end
                end
            end
        end
        
    elseif boss.type == "swordsman" then
        -- Swordsman Boss: Movimiento rápido y espadazos
        local current_speed = boss_def.normal_speed
        if boss_def.is_slashing then
            current_speed = boss_def.slash_speed
        end
        
        -- Movimiento hacia el jugador
        if dist > 1 then
            boss.vx = dx/dist * current_speed
            boss.vy = dy/dist * current_speed
        end
        
        -- Espadazos
        if boss.attack_timer <= 0 and dist < 80 then
            boss_def.is_slashing = true
            boss_def.slash_angle = math.atan2(dy, dx)
            boss.attack_timer = boss_def.slash_cooldown
            boss_def.slash_duration = 0.6
            
            -- Iniciar animación de espada
            boss_sword_anim.active = true
            boss_sword_anim.timer = 0.6
            boss_sword_anim.angle = boss_def.slash_angle
        end
        
        -- Actualizar duración del espadazo
        if boss_def.is_slashing then
            boss_def.slash_duration = boss_def.slash_duration - dt
            if boss_def.slash_duration <= 0 then
                boss_def.is_slashing = false
            end
        end
        
        -- Daño del espadazo
        if boss_def.is_slashing and dist < 60 then
            slime.hp = math.max(0, slime.hp - 25)
        end
        
    elseif boss.type == "summoner" then
        -- Summoner Boss: Invoca defensores y huye
        -- Movimiento de escape lento
        if dist < 200 then
            boss.vx = -dx/dist * boss_def.escape_speed
            boss.vy = -dy/dist * boss_def.escape_speed
        else
            boss.vx = 0
            boss.vy = 0
        end
        
        -- Invocar defensores
        if boss.summon_timer <= 0 then
            -- Invocar bomber
            local angle1 = math.random() * 2 * math.pi
            local spawn_x1 = boss.x + math.cos(angle1) * 60
            local spawn_y1 = boss.y + math.sin(angle1) * 60
            table.insert(boss_minions, {
                x = spawn_x1, y = spawn_y1,
                r = 18, hp = 20, maxhp = 20,
                vx = 0, vy = 0, type = "bomber"
            })
            
            -- Invocar archer
            local angle2 = angle1 + math.pi
            local spawn_x2 = boss.x + math.cos(angle2) * 60
            local spawn_y2 = boss.y + math.sin(angle2) * 60
            table.insert(boss_minions, {
                x = spawn_x2, y = spawn_y2,
                r = 16, hp = 10, maxhp = 10,
                vx = 0, vy = 0, type = "archer", attack_timer = 0
            })
            
            boss.summon_timer = boss_def.summon_cooldown
        end
    end
    
    -- Mover boss
    boss.x = boss.x + boss.vx*dt
    boss.y = boss.y + boss.vy*dt
    
    -- Limitar boss a los bordes del mundo
    boss.x = math.max(boss.r, math.min(world.w-boss.r, boss.x))
    boss.y = math.max(boss.r, math.min(world.h-boss.r, boss.y))
    
    -- Actualizar minions del summoner
    for i = #boss_minions, 1, -1 do
        local minion = boss_minions[i]
        local mdx = slime.x - minion.x
        local mdy = slime.y - minion.y
        local mdist = math.sqrt(mdx*mdx + mdy*mdy)
        
        if minion.type == "bomber" then
            -- Comportamiento de bomber
            if mdist > 1 then
                minion.vx = mdx/mdist * 220
                minion.vy = mdy/mdist * 220
            end
            -- Explosión al tocar
            if mdist < minion.r + slime.r + 8 then
                table.insert(ondas, {x=minion.x, y=minion.y, r=0, alpha=1, color={1,0.7,0.2}})
                if mdist < 80 then
                    slime.hp = math.max(0, slime.hp - 30)
                end
                minion.hp = 0
            end
        elseif minion.type == "archer" then
            -- Comportamiento de archer
            if mdist < 60 then
                minion.vx = -mdx/mdist * 80
                minion.vy = -mdy/mdist * 80
            elseif mdist > 100 then
                minion.vx = mdx/mdist * 80
                minion.vy = mdy/mdist * 80
            else
                minion.vx = 0
                minion.vy = 0
            end
            
            -- Disparar proyectiles
            minion.attack_timer = (minion.attack_timer or 0) - dt
            if minion.attack_timer <= 0 and mdist > 40 and mdist < 200 then
                local speed = 280
                table.insert(archer_projectiles, {
                    x = minion.x, y = minion.y,
                    dx = mdx/mdist * speed, dy = mdy/mdist * speed,
                    r = 7, damage = 10, distancia = 0, max_distancia = 420
                })
                minion.attack_timer = 0.5
            end
        else
            -- Comportamiento genérico
            if mdist > 1 then
                minion.vx = mdx/mdist * 100
                minion.vy = mdy/mdist * 100
            end
        end
        
        minion.x = minion.x + minion.vx*dt
        minion.y = minion.y + minion.vy*dt
        
        -- Limitar minions
        minion.x = math.max(minion.r, math.min(world.w-minion.r, minion.x))
        minion.y = math.max(minion.r, math.min(world.h-minion.r, minion.y))
        
        -- Daño cuerpo a cuerpo de minions
        if mdist < minion.r + slime.r + 6 then
            slime.hp = math.max(0, slime.hp - 5)
        end
    end
    
    -- Actualizar animación de espada
    if boss_sword_anim.active then
        boss_sword_anim.timer = boss_sword_anim.timer - dt
        if boss_sword_anim.timer <= 0 then
            boss_sword_anim.active = false
        end
    end
end

-- Separación de círculos (slime y enemigos, enemigos entre sí)
local function separateCircles(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local minDist = a.r + b.r
    if dist < minDist and dist > 0 then
        local overlap = minDist - dist
        local nx, ny = dx/dist, dy/dist
        -- Empujar ambos círculos por igual
        a.x = a.x - nx*overlap/2
        a.y = a.y - ny*overlap/2
        b.x = b.x + nx*overlap/2
        b.y = b.y + ny*overlap/2
    end
end

function love.update(dt)
    if scene == "login" then
        -- Actualizar sistema de login
        loginSystem:update(dt)
        
        -- Verificar si el login fue exitoso
        if loginSystem.isLoggedIn and loginSystem.currentUser then
            currentUser = loginSystem.currentUser
            userStats = loginSystem:loadGameStats()
            scene = "title"
        end
    elseif scene == "title" then
        local mx, my = love.mouse.getPosition()
        if isMouseOnPlayBtn(mx, my) then
            if love.mouse.isDown(1) then
                playBtn.state = "pressed"
            else
                playBtn.state = "hover"
            end
        else
            playBtn.state = "normal"
        end
        -- Actualizar ondas
        for i=#ondas,1,-1 do
            local onda = ondas[i]
            onda.r = onda.r + 200*dt
            onda.alpha = onda.alpha - 0.7*dt
            if onda.alpha <= 0 then table.remove(ondas, i) end
        end
        -- Actualizar partículas
        for i=#particulas,1,-1 do
            local p = particulas[i]
            p.x = p.x + p.dx*dt
            p.y = p.y + p.dy*dt
            p.dy = p.dy + 60*dt -- gravedad
            p.alpha = p.alpha - 0.8*dt
            p.t = p.t + dt
            if p.alpha <= 0 then table.remove(particulas, i) end
        end
    elseif scene == "run" then
        -- Protección para roundGoal y waveScoreGlobal
        roundGoal = roundGoal or 300
        waveScoreGlobal = waveScoreGlobal or 0
        
        -- Actualizar tiempo de sesión
        currentSessionTime = love.timer.getTime() - sessionStartTime
        -- Movimiento del slime (solo si no está muerto)
        if not deathAnim.active then
            local dx, dy = 0, 0
            if love.keyboard.isDown("w") or love.keyboard.isDown("up") then dy = dy - 1 end
            if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dy = dy + 1 end
            if love.keyboard.isDown("a") or love.keyboard.isDown("left") then dx = dx - 1 end
            if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = dx + 1 end
            if dx ~= 0 or dy ~= 0 then
                local len = math.sqrt(dx*dx + dy*dy)
                dx, dy = dx/len, dy/len
                slime.x = slime.x + dx*slime.speed*dt
                slime.y = slime.y + dy*slime.speed*dt
            end
        end
        -- Limitar a los bordes del mundo
        slime.x = math.max(slime.r, math.min(world.w-slime.r, slime.x))
        slime.y = math.max(slime.r, math.min(world.h-slime.r, slime.y))
        -- Cámara sigue al slime
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        cam.x = math.floor(slime.x - winW/2)
        cam.y = math.floor(slime.y - winH/2)
        -- Limitar cámara a los bordes del mundo
        cam.x = math.max(0, math.min(world.w-winW, cam.x))
        cam.y = math.max(0, math.min(world.h-winH, cam.y))
        -- Actualizar enemigos
        for _,e in ipairs(enemies) do
            updateEnemy(e, dt)
        end
        -- Separar slime de enemigos
        for _,e in ipairs(enemies) do
            separateCircles(slime, e)
        end
        -- Separar enemigos entre sí
        for i=1,#enemies-1 do
            for j=i+1,#enemies do
                separateCircles(enemies[i], enemies[j])
            end
        end
        -- Limitar slime a los bordes del mundo
        slime.x = math.max(slime.r, math.min(world.w-slime.r, slime.x))
        slime.y = math.max(slime.r, math.min(world.h-slime.r, slime.y))
        -- Limitar enemigos a los bordes del mundo
        for _,e in ipairs(enemies) do
            e.x = math.max(e.r, math.min(world.w-e.r, e.x))
            e.y = math.max(e.r, math.min(world.h-e.r, e.y))
        end
        -- Actualizar timers de ataque de enemigos
        for _,e in ipairs(enemies) do
            if e.hitTimer then e.hitTimer = math.max(0, e.hitTimer - dt) end
            if e.attackTimer then e.attackTimer = math.max(0, e.attackTimer - dt) end
        end
        -- Timers de disparo y recarga
        if shootTimer > 0 then shootTimer = shootTimer - dt end
        if reloading then
            reloadTimer = reloadTimer - dt
            if reloadTimer <= 0 then
                shotsLeft = maxShots
                reloading = false
            end
        end
        -- Actualizar proyectiles de Blob
        for i=#projectiles,1,-1 do
            local p = projectiles[i]
            p.x = p.x + p.dx*dt
            p.y = p.y + p.dy*dt
            -- Colisión con enemigos
            for _,e in ipairs(enemies) do
                if e.hp > 0 then
                    local dx, dy = p.x - e.x, p.y - e.y
                    if dx*dx + dy*dy < (p.r + e.r)^2 then
                        e.hp = e.hp - p.damage
                        table.remove(projectiles, i)
                        break
                    end
                end
            end
            -- Colisión con boss
            if boss and boss_active and boss.hp > 0 then
                local dx, dy = p.x - boss.x, p.y - boss.y
                if dx*dx + dy*dy < (p.r + boss.r)^2 then
                    boss.hp = boss.hp - p.damage
                    table.remove(projectiles, i)
                    break
                end
            end
            -- Colisión con minions del boss
            for _,minion in ipairs(boss_minions) do
                if minion.hp > 0 then
                    local dx, dy = p.x - minion.x, p.y - minion.y
                    if dx*dx + dy*dy < (p.r + minion.r)^2 then
                        minion.hp = minion.hp - p.damage
                        table.remove(projectiles, i)
                        break
                    end
                end
            end
            -- Fuera del mundo
            if p.x < 0 or p.x > world.w or p.y < 0 or p.y > world.h then
                table.remove(projectiles, i)
            end
        end
        -- Enemigos bomber: explotan si están muy cerca
        for i=#enemies,1,-1 do
            local e = enemies[i]
            if e.type == "bomber" and e.hp > 0 then
                local dx, dy = slime.x - e.x, slime.y - e.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < e.r + slime.r + 8 then
                    -- Explota
                    table.insert(ondas, {x=e.x, y=e.y, r=0, alpha=1, color={1,0.7,0.2}})
                    if dist < 80 then
                        slime.hp = math.max(0, slime.hp - 30)
                    end
                    e.hp = 0
                end
            end
        end
        -- Las monedas no desaparecen automáticamente, solo se recogen al tocarlas
        -- Recoger monedas
        for i=#coins,1,-1 do
            local coin = coins[i]
            local dx, dy = slime.x - coin.x, slime.y - coin.y
            if dx*dx + dy*dy < (slime.r+14)^2 then
                scoreWave = scoreWave + 10 -- cada moneda suma 10 puntos
                coinCount = coinCount + 1
                coinsCollectedThisSession = coinsCollectedThisSession + 1
                table.remove(coins, i)
            end
        end
        -- Eliminar enemigos muertos y sumar puntaje
        local killed = 0
        for i=#enemies,1,-1 do
            if enemies[i].hp <= 0 then
                -- Drop de moneda (1 en 4)
                if math.random() < 0.25 then
                    spawnCoinDrop(enemies[i].x, enemies[i].y)
                end
                -- Drop de munición (1 en 3)
                if math.random() < 0.33 then
                    spawnAmmoDrop(enemies[i].x, enemies[i].y)
                end
                table.remove(enemies, i)
                scoreWave = scoreWave + 10
                killed = killed + 1
                enemiesKilledThisSession = enemiesKilledThisSession + 1
            end
        end
        
        -- Eliminar minions muertos
        for i=#boss_minions,1,-1 do
            if boss_minions[i].hp <= 0 then
                            -- Drop de moneda (1 en 5)
            if math.random() < 0.2 then
                spawnCoinDrop(boss_minions[i].x, boss_minions[i].y)
            end
                table.remove(boss_minions, i)
                scoreWave = scoreWave + 5
            end
        end
        
        -- Verificar muerte del boss
        if boss and boss_active and boss.hp <= 0 then
            -- Drop de monedas y munición
            for i = 1, 3 do
                local angle = math.random() * 2 * math.pi
                local dist = 30 + math.random() * 40
                local drop_x = boss.x + math.cos(angle) * dist
                local drop_y = boss.y + math.sin(angle) * dist
                spawnCoinDrop(drop_x, drop_y)
            end
            for i = 1, 3 do
                local angle = math.random() * 2 * math.pi
                local dist = 20 + math.random() * 30
                local drop_x = boss.x + math.cos(angle) * dist
                local drop_y = boss.y + math.sin(angle) * dist
                spawnAmmoDrop(drop_x, drop_y)
            end
            
            -- Onda de muerte del boss
            table.insert(ondas, {x=boss.x, y=boss.y, r=0, alpha=1, color={1,0.2,0.2}, boss_death=true})
            
            -- Sumar puntaje del boss
            scoreWave = scoreWave + 100
            bossesKilledThisSession = bossesKilledThisSession + 1
            
            -- Terminar fase del boss
            boss_active = false
            boss = nil
            boss_minions = {}
        end
        -- Actualizar ondas de explosión bomber y de ronda
        for i=#ondas,1,-1 do
            local onda = ondas[i]
            if onda.color then
                if onda.boss_spawn then
                    onda.r = onda.r + 400*dt
                    onda.alpha = onda.alpha - 0.8*dt
                elseif onda.boss_death then
                    onda.r = onda.r + 500*dt
                    onda.alpha = onda.alpha - 0.6*dt
                else
                    onda.r = onda.r + 320*dt
                    onda.alpha = onda.alpha - 1.2*dt
                end
                if onda.alpha <= 0 then table.remove(ondas, i) end
            end
        end
        -- Blader: daño cuerpo a cuerpo cada 1.5s
        for _,e in ipairs(enemies) do
            if e.type == "blader" and e.hp > 0 then
                local dx, dy = slime.x - e.x, slime.y - e.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < e.r + slime.r + 6 and e.hitTimer <= 0 then
                    slime.hp = math.max(0, slime.hp - 10)
                    e.hitTimer = 1.5
                end
            end
        end
        -- Archer: dispara proyectiles cada 0.5s
        for _,e in ipairs(enemies) do
            if e.type == "archer" and e.hp > 0 then
                if e.attackTimer <= 0 then
                    local dx, dy = slime.x - e.x, slime.y - e.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    -- Campo de visión: 120 grados frente al archer
                    local facingX, facingY = 1, 0 -- Por defecto, archer "mira" a la derecha
                    if math.abs(e.vx) > 0.01 or math.abs(e.vy) > 0.01 then
                        local len = math.sqrt(e.vx*e.vx + e.vy*e.vy)
                        facingX, facingY = e.vx/len, e.vy/len
                    end
                    local toPlayerX, toPlayerY = dx/dist, dy/dist
                    local dot = facingX*toPlayerX + facingY*toPlayerY
                    local angle = math.acos(dot) * 180 / math.pi
                    if dist > 80 and dist < 400 and angle <= 60 then -- Solo dispara si está entre 80 y 400 unidades de distancia
                        local speed = 280 -- Velocidad reducida para que sea más fácil esquivar
                        table.insert(archer_projectiles, {
                            x=e.x, y=e.y, dx=dx/dist*speed, dy=dy/dist*speed, r=7, damage=10, distancia=0, max_distancia=420
                        })
                        e.attackTimer = 0.5
                    end
                end
            end
        end
        -- Actualizar proyectiles de archer
        for i=#archer_projectiles,1,-1 do
            local p = archer_projectiles[i]
            p.x = p.x + p.dx*dt
            p.y = p.y + p.dy*dt
            -- Colisión con Blob
            local dx, dy = p.x - slime.x, p.y - slime.y
            if dx*dx + dy*dy < (p.r + slime.r)^2 then
                slime.hp = math.max(0, slime.hp - p.damage)
                table.remove(archer_projectiles, i)
            elseif p.x < 0 or p.x > world.w or p.y < 0 or p.y > world.h then
                table.remove(archer_projectiles, i)
            end
        end
        
        -- Actualizar proyectiles del boss
        for i=#boss_projectiles,1,-1 do
            local p = boss_projectiles[i]
            p.x = p.x + p.dx*dt
            p.y = p.y + p.dy*dt
            -- Colisión con Blob
            local dx, dy = p.x - slime.x, p.y - slime.y
            if dx*dx + dy*dy < (p.r + slime.r)^2 then
                slime.hp = math.max(0, slime.hp - p.damage)
                table.remove(boss_projectiles, i)
            elseif p.x < 0 or p.x > world.w or p.y < 0 or p.y > world.h then
                table.remove(boss_projectiles, i)
            end
        end
        -- Game over si Blob muere
        if slime.hp <= 0 then
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
            end
        end
        -- Actualizar animación de muerte
        if deathAnim.active then
            deathAnim.timer = deathAnim.timer - dt
            deathAnim.scale = 1 + (1 - deathAnim.timer/2.0) * 0.5 -- Se expande ligeramente
            deathAnim.alpha = deathAnim.timer/2.0 -- Se desvanece
            
            -- Actualizar partículas de derretimiento
            for i=#deathAnim.particles,1,-1 do
                local p = deathAnim.particles[i]
                p.x = p.x + p.dx*dt
                p.y = p.y + p.dy*dt
                p.dy = p.dy + 80*dt -- gravedad
                p.alpha = p.alpha - 0.8*dt
                p.t = p.t + dt
                if p.alpha <= 0 then table.remove(deathAnim.particles, i) end
            end
            
            if deathAnim.timer <= 0 then
                -- Terminar animación y guardar estadísticas
                deathAnim.active = false
                
                -- Actualizar estadísticas
                stats.ultimo_puntaje = score
                stats.partidas_jugadas = stats.partidas_jugadas + 1
                stats.tiempo_total_jugado = stats.tiempo_total_jugado + currentSessionTime
                stats.enemigos_eliminados = stats.enemigos_eliminados + enemiesKilledThisSession
                stats.jefes_derrotados = stats.jefes_derrotados + bossesKilledThisSession
                stats.monedas_recolectadas = stats.monedas_recolectadas + coinsCollectedThisSession
                stats.fecha_ultima_partida = getCurrentDate()
                
                if score > stats.puntaje_mas_alto then
                    stats.puntaje_mas_alto = score
                end
                
                if round > stats.mejor_ronda then
                    stats.mejor_ronda = round
                end
                
                saveStats(stats)
                scene = "lobby"
            end
        end
        -- Animación de suma de score tipo Balatro por oleada
        if showWaveScoreAnim then
            waveScoreAnimTimer = waveScoreAnimTimer - dt
            if waveScoreAnimTimer <= 0 then
                showWaveScoreAnim = false
                waveScoreGlobal = waveScoreGlobal + waveScoreAnimTarget
                waveScoreAnimValue = 0
                waveScoreAnimTarget = 0
                waveScoreAnimMult = 1
                -- Recoger todas las monedas automáticamente al terminar la oleada
                local coinsCollected = 0
                for i=#coins,1,-1 do
                    waveScoreGlobal = waveScoreGlobal + 10
                    coinCount = coinCount + 1
                    coinsCollected = coinsCollected + 1
                    table.remove(coins, i)
                end
                -- Mostrar efecto visual si se recogieron monedas
                if coinsCollected > 0 then
                    table.insert(ondas, {x=slime.x, y=slime.y, r=0, alpha=1, color={1,1,0}})
                end
                -- Generar nueva oleada si corresponde
                if waveScorePending then
                    spawnEnemies()
                    waveScorePending = false
                end
            end
        end
        -- Cuando mueren todos los enemigos y no se alcanzó el puntaje de ronda, mostrar animación y sumar score
        if #enemies == 0 and waveScoreGlobal < roundGoal and not showWaveScoreAnim and not boss_active then
            -- Multiplicador x4 si se tiene el objeto
            local mult = 1
            for _,item in ipairs(ownedItems) do
                if item == "mult4" then
                    mult = mult * 4
                end
            end
            waveScoreAnimValue = scoreWave
            waveScoreAnimMult = mult
            waveScoreAnimTarget = scoreWave * mult
            showWaveScoreAnim = true
            waveScoreAnimTimer = 1.5
            waveScorePending = true
            -- Guardar el puntaje de la oleada antes de reiniciar
            lastWaveScore = scoreWave
            scoreWave = 0 -- Reiniciar score de la oleada
        end
        -- Spawnear nuevos enemigos solo después de la animación
        if #enemies == 0 and waveScoreGlobal < roundGoal and not showWaveScoreAnim and not waveScorePending and not boss_active then
            spawnEnemies()
        end
        -- Spawnear boss cada 3 rondas
        if #enemies == 0 and not boss_active and round % boss_spawn_round == 0 and not showWaveScoreAnim then
            spawnBoss()
        end
        -- Si se alcanza el puntaje de ronda, onda y tienda (mantener animación de ronda final)
        if waveScoreGlobal >= roundGoal and not shopActive and not showWaveScoreAnim then
            -- Recoger todas las monedas automáticamente ANTES de cualquier otra lógica
            local coinsCollected = 0
            for i=#coins,1,-1 do
                waveScoreGlobal = waveScoreGlobal + 10
                coinCount = coinCount + 1
                coinsCollected = coinsCollected + 1
                table.remove(coins, i)
            end
            -- Mostrar efecto visual si se recogieron monedas
            if coinsCollected > 0 then
                table.insert(ondas, {x=slime.x, y=slime.y, r=0, alpha=1, color={1,1,0}})
            end
            -- Guardar el score de la ronda antes de multiplicar
            roundScore = waveScoreGlobal
            -- Multiplicador x4 si se tiene el objeto (solo una vez al terminar la ronda)
            local mult = 1
            for _,item in ipairs(ownedItems) do
                if item == "mult4" then
                    mult = mult * 4
                    mult4AnimTimer = 1.2
                end
            end
            if mult > 1 then
                waveScoreGlobal = roundScore * mult
                roundScore = waveScoreGlobal
            end
            table.insert(ondas, {x=slime.x, y=slime.y, r=0, alpha=1, color={1,0.7,0.2}})
            for _,e in ipairs(enemies) do
                e.hp = 0
            end
            shopActive = true
            showArrow = true
            shopInteracted = false
            -- Asegurar que las monedas se recojan cuando aparece la tienda
            if #coins > 0 then
                local coinsCollected = 0
                for i=#coins,1,-1 do
                    waveScoreGlobal = waveScoreGlobal + 10
                    coinCount = coinCount + 1
                    coinsCollected = coinsCollected + 1
                    table.remove(coins, i)
                end
                if coinsCollected > 0 then
                    table.insert(ondas, {x=slime.x, y=slime.y, r=0, alpha=1, color={1,1,0}})
                end
            end
        end
        -- Al salir de la tienda, reiniciar puntos y aumentar meta SOLO cuando el temporizador de siguiente ronda termina
        if shopActive and shopInteracted and nextRoundTimer > 0 and not showWaveScoreAnim then
            nextRoundTimer = nextRoundTimer - dt
            if nextRoundTimer <= 0 then
                round = round + 1
                roundGoal = 300 * round
                shopActive = false
                shopInteracted = false
                nextRoundTimer = 0
                waveScoreGlobal = 0
                slime.hp = slime.maxhp
                spawnEnemies()
                stats.rondas_completadas = stats.rondas_completadas + 1
            end
        end
        -- Actualizar recarga de armas
        for i,wp in ipairs(weapons) do
            if wp.reloading then
                wp.reload_timer = wp.reload_timer - dt
                if wp.reload_timer <= 0 then
                    wp.reloading = false
                    wp.ammo = weapon_defs[wp.id].max_ammo
                end
            end
        end
        -- Actualizar drops de munición
        for i=#ammoDrops,1,-1 do
            local drop = ammoDrops[i]
            drop.timer = drop.timer - dt
            if drop.timer <= 0 then
                table.remove(ammoDrops, i)
            else
                local dx, dy = slime.x - drop.x, slime.y - drop.y
                if dx*dx + dy*dy < (slime.r+14)^2 then
                    -- Recoger munición: recarga el arma seleccionada si no está llena
                    local wp = weapons[selected_weapon]
                    local def = weapon_defs[wp.id]
                    if wp.ammo < def.max_ammo then
                        wp.ammo = def.max_ammo
                        wp.reloading = false
                        wp.reload_timer = 0
                        table.remove(ammoDrops, i)
                    end
                end
            end
        end
        updateBoss(dt)
    end
    if buyAnim.active then
        buyAnim.timer = buyAnim.timer - dt
        buyAnim.scale = 1 + 0.8 * math.max(0, buyAnim.timer/0.6)
        if buyAnim.timer <= 0 then
            buyAnim.active = false
            buyAnim.scale = 1
        end
    end
end

function love.draw()
    if scene == "login" then
        -- Dibujar sistema de login
        loginSystem:draw()
    elseif scene == "title" then
        -- Ondas
        for _,onda in ipairs(ondas) do
            love.graphics.setColor(1,1,1,onda.alpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", onda.x, onda.y, onda.r)
        end
        -- Partículas
        for _,p in ipairs(particulas) do
            love.graphics.setColor(1,1,1,p.alpha)
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(titulo, tituloX, tituloY, 0, tituloScale, tituloScale)
        -- Botón de jugar escalado
        love.graphics.draw(playBtn.img[playBtn.state], playBtn.x, playBtn.y, 0, playBtn.scale, playBtn.scale)
        -- Botón de configuración
        love.graphics.setColor(0.8,0.8,1,1)
        love.graphics.rectangle("fill", configBtn.x, configBtn.y, configBtn.w, configBtn.h, 10, 10)
        love.graphics.setColor(0.2,0.2,0.4,1)
        love.graphics.rectangle("line", configBtn.x, configBtn.y, configBtn.w, configBtn.h, 10, 10)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf("Configuración", configBtn.x, configBtn.y+configBtn.h/4, configBtn.w, "center")
        love.graphics.setColor(1,1,1,1)
        -- Debug: dibujar hitbox del botón (opcional)
        -- love.graphics.setColor(1,0,0,0.2)
        -- local marginX = playBtn.w*0.2
        -- local marginY = playBtn.h*0.2
        -- love.graphics.rectangle("line", playBtn.x+marginX, playBtn.y+marginY, playBtn.w-2*marginX, playBtn.h-2*marginY)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Presiona ENTER o haz click sobre el título para animar", 0, playBtn.y+playBtn.h+24, love.graphics.getWidth(), "center")
        
        -- Mostrar información del usuario si está logueado
        if currentUser then
            love.graphics.setColor(0.5, 1, 0.5, 1)
            love.graphics.printf("Usuario: " .. currentUser.username, 0, 20, love.graphics.getWidth(), "center")
            
            if userStats then
                love.graphics.setColor(0.8, 0.8, 1, 1)
                love.graphics.printf("Mejor puntuación: " .. userStats.highScore, 0, 50, love.graphics.getWidth(), "center")
            end
            
            -- Botón de logout
            love.graphics.setColor(0.8, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 120, 20, 100, 30, 5, 5)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Logout", love.graphics.getWidth() - 120, 25, 100, "center")
        end
    elseif scene == "lobby" then
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Lobby - Presiona ENTER para iniciar run", 0, 200, love.graphics.getWidth(), "center")
    elseif scene == "run" then
        love.graphics.push()
        love.graphics.translate(-cam.x, -cam.y)
        -- Fondo del mundo
        love.graphics.setColor(0.12,0.12,0.15,1)
        love.graphics.rectangle("fill", 0, 0, world.w, world.h)
        -- Terreno
        for y=1,world.tilesy do
            for x=1,world.tilesx do
                if world.terrain[y][x] then
                    love.graphics.setColor(0.18,0.18,0.22,1)
                    love.graphics.rectangle("fill", (x-1)*world.tilesize, (y-1)*world.tilesize, world.tilesize, world.tilesize)
                end
            end
        end
        -- Ondas de explosión bomber y de ronda
        for _,onda in ipairs(ondas) do
            if onda.color then
                love.graphics.setColor(onda.color[1], onda.color[2], onda.color[3], onda.alpha)
                love.graphics.setLineWidth(5)
                love.graphics.circle("line", onda.x, onda.y, onda.r)
            end
        end
        -- Proyectiles de archer
        for _,p in ipairs(archer_projectiles) do
            love.graphics.setColor(0.3,1,0.3,1)
            love.graphics.circle("fill", p.x, p.y, p.r)
        end
        
        -- Proyectiles del boss
        for _,p in ipairs(boss_projectiles) do
            if p.type == "spiral" then
                love.graphics.setColor(0.2, 0.8, 0.2, 1)
            elseif p.type == "chess" then
                love.graphics.setColor(0.8, 0.2, 0.2, 1)
            else
                love.graphics.setColor(0.6, 0.6, 0.6, 1)
            end
            love.graphics.circle("fill", p.x, p.y, p.r)
        end
        -- Proyectiles de Blob
        for _,p in ipairs(projectiles) do
            love.graphics.setColor(1,1,1,1)
            love.graphics.circle("fill", p.x, p.y, p.r)
        end
        -- Enemigos
        for _,e in ipairs(enemies) do
            local c = enemy_types[e.type].color
            love.graphics.setColor(c[1],c[2],c[3],1)
            love.graphics.circle("fill", e.x, e.y, e.r)
            -- Icono de tipo
            love.graphics.setColor(0,0,0,0.7)
            if e.type == "bomber" then
                love.graphics.circle("line", e.x, e.y, e.r-4)
            elseif e.type == "blader" then
                love.graphics.rectangle("fill", e.x-6, e.y-2, 12, 4)
            elseif e.type == "archer" then
                love.graphics.polygon("fill", e.x-6, e.y+4, e.x+6, e.y+4, e.x, e.y-6)
            end
            -- Barra de vida sobre enemigo
            local ew, eh = 32, 6
            local ex, ey = e.x-ew/2, e.y-e.r-14
            love.graphics.setColor(0.2,0.2,0.2,0.8)
            love.graphics.rectangle("fill", ex, ey, ew, eh, 3, 3)
            love.graphics.setColor(1,0.2,0.2,0.9)
            love.graphics.rectangle("fill", ex, ey, ew*(e.hp/e.maxhp), eh, 3, 3)
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line", ex, ey, ew, eh, 3, 3)
        end
        
        -- Boss
        if boss and boss_active then
            local boss_def = boss_types[boss.type]
            local c = boss_def.color
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.circle("fill", boss.x, boss.y, boss.r)
            
            -- Efectos especiales según tipo
            if boss.type == "shooter" then
                -- Efecto de disparo
                love.graphics.setColor(0.2, 1, 0.2, 0.4)
                love.graphics.circle("line", boss.x, boss.y, boss.r + 12)
            elseif boss.type == "swordsman" then
                -- Animación de espada
                if boss_sword_anim.active then
                    local angle = boss_sword_anim.angle
                    local sword_length = 50
                    local sword_x = boss.x + math.cos(angle) * sword_length
                    local sword_y = boss.y + math.sin(angle) * sword_length
                    love.graphics.setColor(1, 0.8, 0.2, 0.8)
                    love.graphics.setLineWidth(6)
                    love.graphics.line(boss.x, boss.y, sword_x, sword_y)
                    love.graphics.setLineWidth(1)
                end
            elseif boss.type == "summoner" then
                -- Efecto de invocación
                love.graphics.setColor(0.6, 0.2, 0.8, 0.3)
                love.graphics.circle("fill", boss.x, boss.y, boss.r + 15)
            end
            
            -- Icono de tipo de boss
            love.graphics.setColor(0,0,0,0.8)
            if boss.type == "shooter" then
                love.graphics.circle("fill", boss.x, boss.y, 8)
            elseif boss.type == "swordsman" then
                love.graphics.rectangle("fill", boss.x-6, boss.y-3, 12, 6)
            elseif boss.type == "summoner" then
                love.graphics.polygon("fill", boss.x-4, boss.y+4, boss.x+4, boss.y+4, boss.x, boss.y-4)
            end
            
            -- Barra de vida del boss
            local bw, bh = 80, 8
            local bx, by = boss.x-bw/2, boss.y-boss.r-20
            love.graphics.setColor(0.2,0.2,0.2,0.9)
            love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)
            love.graphics.setColor(1,0.2,0.2,1)
            love.graphics.rectangle("fill", bx, by, bw*(boss.hp/boss.maxhp), bh, 4, 4)
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
            
            -- Nombre del boss
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(boss_def.name, bx, by-20, bw, "center")
        end
        
        -- Minions del boss
        for _,minion in ipairs(boss_minions) do
            if minion.hp > 0 then
                love.graphics.setColor(0.6, 0.2, 0.8, 1)
                love.graphics.circle("fill", minion.x, minion.y, minion.r)
                
                -- Barra de vida de minion
                local mw, mh = 24, 4
                local mx, my = minion.x-mw/2, minion.y-minion.r-10
                love.graphics.setColor(0.2,0.2,0.2,0.8)
                love.graphics.rectangle("fill", mx, my, mw, mh, 2, 2)
                love.graphics.setColor(0.8,0.2,0.8,0.9)
                love.graphics.rectangle("fill", mx, my, mw*(minion.hp/minion.maxhp), mh, 2, 2)
                love.graphics.setColor(1,1,1,1)
                love.graphics.rectangle("line", mx, my, mw, mh, 2, 2)
            end
        end
        -- Slime
        if deathAnim.active then
            -- Dibujar Blob derritiéndose
            love.graphics.setColor(1,0.6,0.8,deathAnim.alpha)
            love.graphics.circle("fill", slime.x, slime.y, slime.r * deathAnim.scale)
            -- Dibujar partículas de derretimiento
            for _,p in ipairs(deathAnim.particles) do
                love.graphics.setColor(1,0.6,0.8,p.alpha)
                love.graphics.circle("fill", p.x, p.y, p.size)
            end
        else
            love.graphics.setColor(1,0.6,0.8,1)
            love.graphics.circle("fill", slime.x, slime.y, slime.r)
        end
        love.graphics.setColor(1,1,1,1)
        -- Tienda
        if shopActive then
            local shopW, shopH = 260, 220
            love.graphics.setColor(0.9,0.8,0.2,1)
            love.graphics.rectangle("fill", shopX-shopW/2, shopY-shopH/2, shopW, shopH, 24, 24)
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("line", shopX-shopW/2, shopY-shopH/2, shopW, shopH, 24, 24)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("TIENDA", shopX-shopW/2, shopY-shopH/2+12, shopW, "center")
            local showMult4 = true
            for _,it in ipairs(ownedItems) do if it == shopItems[1].id then showMult4 = false end end
            if showMult4 then
                local bx, by = shopX-shopW/2+32, shopY-shopH/2+60
                if shopSelected == 1 then
                    love.graphics.setColor(1,1,0.2,0.5)
                    love.graphics.rectangle("fill", bx-6, by-6, 76, 76, 10, 10)
                end
                shopItems[1].icon(bx, by, 64, mult4Anim)
                love.graphics.setColor(0,0,0,1)
                love.graphics.rectangle("line", bx, by, 64, 64, 8, 8)
                love.graphics.setColor(1,1,1,1)
                love.graphics.printf("x4 puntos\n(1 vez por ronda)\n[1]", bx, by+68, 64, "center")
            end
            local showDouble = true
            for _,wp in ipairs(weapons) do if wp.id == "double" then showDouble = false end end
            if showDouble then
                local bx2, by2 = shopX+shopW/2-96, shopY-shopH/2+60
                if shopSelected == 2 then
                    love.graphics.setColor(1,1,0.2,0.5)
                    love.graphics.rectangle("fill", bx2-6, by2-6, 76, 76, 10, 10)
                end
                shopItems[2].icon(bx2, by2, 64, 0)
                love.graphics.setColor(0,0,0,1)
                love.graphics.rectangle("line", bx2, by2, 64, 64, 8, 8)
                love.graphics.setColor(1,1,1,1)
                love.graphics.printf("Arma x2\n(10 balas)\n[2]", bx2, by2+68, 64, "center")
            end
            if not shopInteracted then
                love.graphics.printf("Presiona E para interactuar", shopX-shopW/2, shopY+shopH/2-40, shopW, "center")
            else
                love.graphics.printf("Selecciona con 1 o 2 y compra con ENTER\nPresiona ESPACIO para salir", shopX-shopW/2, shopY+shopH/2-40, shopW, "center")
            end
        end
        -- Flecha hacia la tienda
        if shopActive and not shopInteracted then
            local dx, dy = shopX - slime.x, shopY - slime.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 60 then
                local arrowX = slime.x + dx/dist * (slime.r+32)
                local arrowY = slime.y + dy/dist * (slime.r+32)
                love.graphics.setColor(1,1,0.2,1)
                love.graphics.push()
                love.graphics.translate(arrowX, arrowY)
                love.graphics.rotate(math.atan2(dy, dx))
                love.graphics.polygon("fill", -10,-8, 18,0, -10,8)
                love.graphics.pop()
            end
        end
        -- Dibujar monedas (en el mundo, no en la pantalla)
        for _,coin in ipairs(coins) do
            love.graphics.setColor(1,0.9,0.2,1)
            love.graphics.circle("fill", coin.x, coin.y, 14)
            love.graphics.setColor(0.8,0.7,0.1,1)
            love.graphics.circle("line", coin.x, coin.y, 14)
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf("$", coin.x-8, coin.y-10, 16, "center")
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.pop()
        -- Minimap
        local mw, mh = 180, 120
        local mx, my = love.graphics.getWidth()-mw-16, 16
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill", mx, my, mw, mh, 8, 8)
        local sx, sy = mw/world.w, mh/world.h
        -- Terreno minimapa
        for y=1,world.tilesy do
            for x=1,world.tilesx do
                if world.terrain[y][x] then
                    love.graphics.setColor(0.22,0.22,0.28,0.7)
                    love.graphics.rectangle("fill", mx+(x-1)*world.tilesize*sx, my+(y-1)*world.tilesize*sy, world.tilesize*sx, world.tilesize*sy)
                end
            end
        end
        -- Enemigos minimapa
        for _,e in ipairs(enemies) do
            local c = enemy_types[e.type].color
            love.graphics.setColor(c[1],c[2],c[3],0.8)
            love.graphics.circle("fill", mx+e.x*sx, my+e.y*sy, 4)
        end
        
        -- Boss minimapa
        if boss and boss_active then
            local boss_def = boss_types[boss.type]
            local c = boss_def.color
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.circle("fill", mx+boss.x*sx, my+boss.y*sy, 6)
        end
        
        -- Minions minimapa
        for _,minion in ipairs(boss_minions) do
            if minion.hp > 0 then
                love.graphics.setColor(0.6, 0.2, 0.8, 0.8)
                love.graphics.circle("fill", mx+minion.x*sx, my+minion.y*sy, 3)
            end
        end
        -- Slime minimapa
        love.graphics.setColor(1,0.6,0.8,1)
        love.graphics.circle("fill", mx+slime.x*sx, my+slime.y*sy, 4)
        love.graphics.setColor(1,1,1,1)
        -- Puntero que sigue el mouse
        local mx, my = love.mouse.getPosition()
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.circle("line", mx, my, 14, 32)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Run en progreso - Presiona ESC para volver al lobby", 0, 20, love.graphics.getWidth(), "center")
        -- Barra de vida de Blob
        local barW, barH = 320, 24
        local barX = love.graphics.getWidth()/2 - barW/2
        local barY = 60
        love.graphics.setColor(0.2,0.2,0.2,0.8)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 8, 8)
        local hpFrac = slime.hp/slime.maxhp
        love.graphics.setColor(1,0.2,0.2,0.9)
        love.graphics.rectangle("fill", barX, barY, barW*hpFrac, barH, 8, 8)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line", barX, barY, barW, barH, 8, 8)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf(string.format("%d%%", math.floor(hpFrac*100)), barX, barY+2, barW, "center")
        -- Interfaz de munición
        local ammoX, ammoY = mx, my+mh+16
        love.graphics.setColor(0.1,0.1,0.1,0.8)
        love.graphics.rectangle("fill", ammoX, ammoY, mw, 32, 8, 8)
        for i=1,maxShots do
            if i <= shotsLeft and not reloading then
                love.graphics.setColor(1,1,1,1)
            else
                love.graphics.setColor(0.5,0.5,0.5,1)
            end
            love.graphics.rectangle("fill", ammoX+12+(i-1)*30, ammoY+8, 18, 16, 4, 4)
        end
        love.graphics.setColor(1,1,1,1)
        if reloading then
            love.graphics.printf("Recargando...", ammoX, ammoY+2, mw, "center")
        else
            love.graphics.printf("Munición", ammoX, ammoY-16, mw, "center")
        end
        -- Puntaje y ronda
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Puntaje global: "..waveScoreGlobal.."  Ronda: "..round, 0, 100, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,0.2,1)
        love.graphics.printf("Puntos necesarios para pasar de ronda: "..roundGoal, 0, 120, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,1,1)
        -- Mostrar el puntaje de la oleada correctamente
        local mostrarScore = scoreWave
        if not showWaveScoreAnim and (#enemies == 0 or shopActive) then
            mostrarScore = lastWaveScore
        end
        love.graphics.printf("Puntaje de la oleada: "..mostrarScore, 0, 140, love.graphics.getWidth(), "center")
        -- Contador de siguiente ronda
        if nextRoundTimer > 0 and shopActive and shopInteracted and not showWaveScoreAnim then
            love.graphics.setColor(1,1,0.2,1)
            love.graphics.printf("Siguiente ronda en "..math.ceil(nextRoundTimer).."...", 0, 140, love.graphics.getWidth(), "center")
        end
        -- Contador de monedas
        love.graphics.setColor(1,0.9,0.2,1)
        love.graphics.circle("fill", 32, 32, 16)
        love.graphics.setColor(0.8,0.7,0.1,1)
        love.graphics.circle("line", 32, 32, 16)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf("$", 24, 22, 16, "center")
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("x"..coinCount, 52, 24, 60, "left")
        -- Barra de objetos debajo del minimapa (posición fija)
        local mw, mh = 180, 120
        local mx, my = love.graphics.getWidth()-mw-16, 16
        local barX, barY = mx, my+mh+24
        local slotSize = 36
        love.graphics.setColor(0.2,0.2,0.2,0.8)
        love.graphics.rectangle("fill", barX, barY, slotSize*maxItems+8, slotSize+8, 8, 8)
        for i=1,maxItems do
            love.graphics.setColor(0.4,0.4,0.4,0.7)
            love.graphics.rectangle("line", barX+4+(i-1)*slotSize, barY+4, slotSize, slotSize, 6, 6)
            if ownedItems[i] and not (dragging.active and dragging.slot == i) then
                for _,item in ipairs(shopItems) do
                    if item.id == ownedItems[i] then
                        local scale = 1
                        if buyAnim.active and buyAnim.slot == i then
                            scale = buyAnim.scale
                        end
                        local cx = barX+4+(i-1)*slotSize + (slotSize-4)/2
                        local cy = barY+4 + (slotSize-4)/2
                        love.graphics.push()
                        love.graphics.translate(cx, cy)
                        love.graphics.scale(scale, scale)
                        item.icon(-(slotSize-4)/2, -(slotSize-4)/2, slotSize-4, mult4Anim)
                        love.graphics.pop()
                    end
                end
            end
        end
        -- Dibujar objeto arrastrado (opcional, solo si quieres drag&drop)
        if dragging.active and ownedItems[dragging.slot] then
            local mx, my = love.mouse.getPosition()
            for _,item in ipairs(shopItems) do
                if item.id == ownedItems[dragging.slot] then
                    love.graphics.push()
                    love.graphics.translate(mx-dragging.offsetX+slotSize/2, my-dragging.offsetY+slotSize/2)
                    love.graphics.scale(1.1, 1.1)
                    item.icon(-(slotSize-4)/2, -(slotSize-4)/2, slotSize-4, mult4Anim)
                    love.graphics.pop()
                end
            end
        end
        love.graphics.setColor(1,1,1,1)
        -- Barra de armas (máx 3)
        local barX, barY = 32, love.graphics.getHeight()-60
        local slotSize = 48
        for i=1,max_weapons do
            love.graphics.setColor(0.2,0.2,0.2,0.8)
            love.graphics.rectangle("fill", barX+(i-1)*slotSize, barY, slotSize-4, slotSize-4, 8, 8)
            if weapons[i] then
                local def = weapon_defs[weapons[i].id]
                love.graphics.setColor(def.color)
                love.graphics.rectangle("fill", barX+(i-1)*slotSize+6, barY+6, slotSize-16, slotSize-16, 6, 6)
                love.graphics.setColor(0,0,0,1)
                love.graphics.printf(def.name, barX+(i-1)*slotSize, barY+slotSize-22, slotSize-4, "center")
                love.graphics.setColor(1,1,1,1)
                love.graphics.printf(weapons[i].ammo.."/"..def.max_ammo, barX+(i-1)*slotSize, barY+8, slotSize-4, "center")
                if weapons[i].reloading then
                    love.graphics.setColor(1,0.5,0.2,1)
                    love.graphics.printf("Recargando", barX+(i-1)*slotSize, barY+slotSize-36, slotSize-4, "center")
                end
            end
            if i == selected_weapon then
                love.graphics.setColor(1,1,0.2,1)
                love.graphics.rectangle("line", barX+(i-1)*slotSize, barY, slotSize-4, slotSize-4, 8, 8)
            end
        end
        love.graphics.setColor(1,1,1,1)
        -- Interfaz de multiplicador tipo Balatro al terminar una oleada
        if showWaveScoreAnim then
            local w, h = 420, 120
            local x = love.graphics.getWidth()/2 - w/2
            local y = love.graphics.getHeight()/2 - h/2
            love.graphics.setColor(0.1,0.1,0.1,0.92)
            love.graphics.rectangle("fill", x, y, w, h, 18, 18)
            love.graphics.setColor(1,1,1,1)
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", x, y, w, h, 18, 18)
            love.graphics.setFont(love.graphics.newFont(32))
            love.graphics.printf(waveScoreAnimValue.."  x  "..waveScoreAnimMult.."  =  "..waveScoreAnimTarget, x, y+32, w, "center")
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.printf("Puntaje de la oleada multiplicado", x, y+10, w, "center")
            love.graphics.setFont(love.graphics.newFont(18))
            love.graphics.printf("El total se sumará a tu puntaje global", x, y+80, w, "center")
            love.graphics.setFont(love.graphics.newFont(14))
        end
    elseif scene == "settings" then
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Configuración", 0, 40, love.graphics.getWidth(), "center")
        
        -- Dibujar opciones de configuración
        local startY = 100
        local buttonHeight = 40
        local spacing = 10
        
        for i, button in ipairs(configButtons) do
            local y = startY + (i-1) * (buttonHeight + spacing)
            
            -- Color de fondo según selección
            if i == selectedConfigButton then
                love.graphics.setColor(0.8,0.8,1,1)
            else
                love.graphics.setColor(0.6,0.6,0.8,1)
            end
            
            -- Fondo del botón
            love.graphics.rectangle("fill", 100, y, love.graphics.getWidth()-200, buttonHeight, 8, 8)
            love.graphics.setColor(0.2,0.2,0.4,1)
            love.graphics.rectangle("line", 100, y, love.graphics.getWidth()-200, buttonHeight, 8, 8)
            
            -- Texto del botón - color diferente si está seleccionado
            if i == selectedConfigButton then
                love.graphics.setColor(0,0,0,1) -- Negro para contraste con fondo blanco
            else
                love.graphics.setColor(1,1,1,1) -- Blanco para opciones no seleccionadas
            end
            love.graphics.printf(button.name, 120, y+10, love.graphics.getWidth()-240, "left")
            
            -- Valor actual
            local currentValue = config[button.id]
            local valueText = ""
            if button.type == "slider" then
                valueText = string.format("%.1f", currentValue)
            elseif button.type == "toggle" then
                valueText = currentValue and "Activado" or "Desactivado"
            end
            
            -- Color del valor también cambia según selección
            if i == selectedConfigButton then
                love.graphics.setColor(0,0,0,1) -- Negro para contraste
            else
                love.graphics.setColor(0.8,0.8,0.8,1) -- Gris para opciones no seleccionadas
            end
            love.graphics.printf(valueText, 120, y+10, love.graphics.getWidth()-240, "right")
        end
        
        -- Botón de estadísticas
        love.graphics.setColor(0.8,1,0.8,1)
        love.graphics.rectangle("fill", statsBtn.x, statsBtn.y, statsBtn.w, statsBtn.h, 10, 10)
        love.graphics.setColor(0.2,0.4,0.2,1)
        love.graphics.rectangle("line", statsBtn.x, statsBtn.y, statsBtn.w, statsBtn.h, 10, 10)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf("Estadísticas", statsBtn.x, statsBtn.y+statsBtn.h/4, statsBtn.w, "center")
        
        -- Instrucciones
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Usa ↑↓ para navegar, ENTER para toggles, ←→ para sliders", 0, love.graphics.getHeight()-80, love.graphics.getWidth(), "center")
        love.graphics.printf("Presiona ESC para volver", 0, love.graphics.getHeight()-50, love.graphics.getWidth(), "center")
    elseif scene == "stats" then
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Estadísticas de Jugador", 0, 60, love.graphics.getWidth(), "center")
        
        -- Estadísticas principales
        love.graphics.setColor(0.9,0.9,1,1)
        love.graphics.printf("Puntaje Más Alto: "..stats.puntaje_mas_alto, 0, 120, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.8,1,0.8,1)
        love.graphics.printf("Último Puntaje: "..stats.ultimo_puntaje, 0, 150, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,0.8,1)
        love.graphics.printf("Partidas Jugadas: "..stats.partidas_jugadas, 0, 180, love.graphics.getWidth(), "center")
        
        -- Estadísticas detalladas
        love.graphics.setColor(1,0.8,0.8,1)
        love.graphics.printf("Tiempo Total Jugado: "..formatTime(stats.tiempo_total_jugado), 0, 220, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.8,1,0.8,1)
        love.graphics.printf("Enemigos Eliminados: "..stats.enemigos_eliminados, 0, 250, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,0.8,1,1)
        love.graphics.printf("Jefes Derrotados: "..stats.jefes_derrotados, 0, 280, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,0.8,1)
        love.graphics.printf("Rondas Completadas: "..stats.rondas_completadas, 0, 310, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,0.9,0.2,1)
        love.graphics.printf("Monedas Recolectadas: "..stats.monedas_recolectadas, 0, 340, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.8,0.8,1,1)
        love.graphics.printf("Mejor Ronda: "..stats.mejor_ronda, 0, 370, love.graphics.getWidth(), "center")
        
        -- Fecha de última partida
        if stats.fecha_ultima_partida ~= "" then
            love.graphics.setColor(0.7,0.7,0.7,1)
            love.graphics.printf("Última Partida: "..stats.fecha_ultima_partida, 0, 400, love.graphics.getWidth(), "center")
        end
        
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Presiona ESC para volver", 0, 450, love.graphics.getWidth(), "center")
    end
    
    -- Mostrar FPS si está habilitado en configuración
    if config.mostrar_fps then
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.printf("FPS: "..love.timer.getFPS(), 10, 10, 200, "left")
    end
    
    -- Dibujar drops de munición
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)
    for _,drop in ipairs(ammoDrops) do
        love.graphics.setColor(0.2,0.8,1,0.8)
        love.graphics.circle("fill", drop.x, drop.y, 14)
        love.graphics.setColor(0,0.3,0.5,1)
        love.graphics.circle("line", drop.x, drop.y, 14)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("A", drop.x-8, drop.y-10, 16, "center")
    end
    love.graphics.pop()
end 