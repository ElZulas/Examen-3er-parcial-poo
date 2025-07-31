-- api_client.lua
-- Cliente HTTP para conectar BlobVers con la API REST

local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")

local APIClient = {}
APIClient.__index = APIClient

-- Configuración de la API
local API_BASE_URL = "http://localhost:3000/api"
local API_TOKEN = nil
local API_PLAYER_ID = nil

-- Función para hacer requests HTTP
local function makeRequest(method, endpoint, data, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json"
    
    if API_TOKEN then
        headers["Authorization"] = "Bearer " .. API_TOKEN
    end
    
    local url = API_BASE_URL .. endpoint
    local body = data and json.encode(data) or ""
    
    local response_body = {}
    local res, code, response_headers = http.request{
        url = url,
        method = method,
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body)
    }
    
    if res then
        local response_text = table.concat(response_body)
        local success, response_data = pcall(json.decode, response_text)
        
        if success then
            return response_data, code
        else
            return { error = "Error parsing JSON response" }, code
        end
    else
        return { error = "Network error" }, code or 0
    end
end

-- Registrar nuevo jugador
function APIClient.registerPlayer(username, email, password)
    local data = {
        username = username,
        email = email,
        password = password
    }
    
    local response, code = makeRequest("POST", "/player/register", data)
    
    if code == 201 and response.token then
        API_TOKEN = response.token
        API_PLAYER_ID = response.player.id
        return true, response
    else
        return false, response
    end
end

-- Iniciar sesión
function APIClient.loginPlayer(username, password)
    local data = {
        username = username,
        password = password
    }
    
    local response, code = makeRequest("POST", "/player/login", data)
    
    if code == 200 and response.token then
        API_TOKEN = response.token
        API_PLAYER_ID = response.player.id
        return true, response
    else
        return false, response
    end
end

-- Obtener perfil del jugador
function APIClient.getPlayerProfile()
    local response, code = makeRequest("GET", "/player/profile")
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Iniciar sesión de juego
function APIClient.startGameSession(initialGameState)
    local data = {
        initialGameState = initialGameState or {
            slime = { x = 1500, y = 1000, hp = 100, maxHp = 100 },
            world = { width = 3000, height = 2000 },
            enemies = {},
            projectiles = {}
        }
    }
    
    local response, code = makeRequest("POST", "/game/start", data)
    
    if code == 201 then
        return true, response
    else
        return false, response
    end
end

-- Actualizar estado del juego
function APIClient.updateGameSession(sessionId, gameState, score, round, enemiesKilled, bossesKilled, coinsCollected)
    local data = {
        gameState = gameState,
        score = score,
        round = round,
        enemiesKilled = enemiesKilled,
        bossesKilled = bossesKilled,
        coinsCollected = coinsCollected
    }
    
    local response, code = makeRequest("PUT", "/game/update/" .. sessionId, data)
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Finalizar sesión de juego
function APIClient.endGameSession(sessionId, finalScore, round, enemiesKilled, bossesKilled, coinsCollected, deathReason, gameState)
    local data = {
        finalScore = finalScore,
        round = round,
        enemiesKilled = enemiesKilled,
        bossesKilled = bossesKilled,
        coinsCollected = coinsCollected,
        deathReason = deathReason or "other",
        gameState = gameState
    }
    
    local response, code = makeRequest("POST", "/game/end/" .. sessionId, data)
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Registrar evento del juego
function APIClient.registerGameEvent(sessionId, eventType, eventData)
    local data = {
        eventType = eventType,
        eventData = eventData
    }
    
    local response, code = makeRequest("POST", "/game/event/" .. sessionId, data)
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Obtener estadísticas del jugador
function APIClient.getPlayerStats(detailed)
    local endpoint = "/stats/player"
    if detailed then
        endpoint = endpoint .. "?detailed=true"
    end
    
    local response, code = makeRequest("GET", endpoint)
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Obtener estadísticas globales
function APIClient.getGlobalStats()
    local response, code = makeRequest("GET", "/stats/global")
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Obtener logros del jugador
function APIClient.getAchievements()
    local response, code = makeRequest("GET", "/stats/achievements")
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Obtener tabla de líderes
function APIClient.getLeaderboard(type, limit)
    local endpoint = "/player/leaderboard"
    local params = {}
    
    if type then table.insert(params, "type=" .. type) end
    if limit then table.insert(params, "limit=" .. limit) end
    
    if #params > 0 then
        endpoint = endpoint .. "?" .. table.concat(params, "&")
    end
    
    local response, code = makeRequest("GET", endpoint)
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Verificar conexión con la API
function APIClient.checkConnection()
    local response, code = makeRequest("GET", "/")
    
    if code == 200 then
        return true, response
    else
        return false, response
    end
end

-- Guardar token en archivo local
function APIClient.saveToken()
    if API_TOKEN then
        local file = io.open("api_token.txt", "w")
        if file then
            file:write(API_TOKEN)
            file:close()
            return true
        end
    end
    return false
end

-- Cargar token desde archivo local
function APIClient.loadToken()
    local file = io.open("api_token.txt", "r")
    if file then
        API_TOKEN = file:read("*all")
        file:close()
        return true
    end
    return false
end

-- Limpiar token
function APIClient.clearToken()
    API_TOKEN = nil
    API_PLAYER_ID = nil
    os.remove("api_token.txt")
end

-- Obtener estado de autenticación
function APIClient.isAuthenticated()
    return API_TOKEN ~= nil
end

-- Obtener token actual
function APIClient.getToken()
    return API_TOKEN
end

-- Obtener ID del jugador
function APIClient.getPlayerId()
    return API_PLAYER_ID
end

return APIClient 