# 🎮 API de BlobVers

API REST completa para el juego BlobVers con MongoDB, incluyendo sistema de usuarios, sesiones de juego, estadísticas y logros.

## 📋 Características

- ✅ **Sistema de Usuarios**: Registro, login, perfiles
- ✅ **Sesiones de Juego**: Tracking completo de partidas
- ✅ **Estadísticas**: Detalladas por jugador y globales
- ✅ **Logros**: Sistema de achievements automático
- ✅ **Leaderboards**: Tablas de líderes por diferentes métricas
- ✅ **Análisis**: Estadísticas avanzadas y comparativas
- ✅ **Seguridad**: JWT, encriptación de contraseñas, rate limiting
- ✅ **Cliente Lua**: Integración directa con LÖVE

## 🚀 Instalación

### Prerrequisitos

- Node.js (v14 o superior)
- MongoDB (local o Atlas)
- npm o yarn

### 1. Instalar dependencias

```bash
npm install
```

### 2. Configurar variables de entorno

Edita el archivo `config.env`:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/blobvers
JWT_SECRET=tu_jwt_secret_super_seguro_aqui
NODE_ENV=development
```

### 3. Iniciar MongoDB

**Local:**
```bash
# Windows
"C:\Program Files\MongoDB\Server\6.0\bin\mongod.exe"

# macOS/Linux
mongod
```

**MongoDB Atlas:**
- Crea una cuenta en [MongoDB Atlas](https://cloud.mongodb.com)
- Crea un cluster gratuito
- Obtén la URI de conexión
- Reemplaza `MONGODB_URI` en `config.env`

### 4. Iniciar la API

```bash
# Desarrollo (con nodemon)
npm run dev

# Producción
npm start
```

La API estará disponible en `http://localhost:3000`

## 📚 Endpoints de la API

### Autenticación

#### POST `/api/player/register`
Registrar nuevo jugador
```json
{
  "username": "jugador1",
  "email": "jugador1@email.com",
  "password": "contraseña123"
}
```

#### POST `/api/player/login`
Iniciar sesión
```json
{
  "username": "jugador1",
  "password": "contraseña123"
}
```

### Juego

#### POST `/api/game/start`
Iniciar sesión de juego
```json
{
  "initialGameState": {
    "slime": { "x": 1500, "y": 1000, "hp": 100, "maxHp": 100 },
    "world": { "width": 3000, "height": 2000 },
    "enemies": [],
    "projectiles": []
  }
}
```

#### PUT `/api/game/update/:sessionId`
Actualizar estado del juego
```json
{
  "gameState": { /* estado actual */ },
  "score": 1500,
  "round": 3,
  "enemiesKilled": 25,
  "bossesKilled": 1,
  "coinsCollected": 50
}
```

#### POST `/api/game/end/:sessionId`
Finalizar sesión de juego
```json
{
  "finalScore": 2500,
  "round": 5,
  "enemiesKilled": 45,
  "bossesKilled": 2,
  "coinsCollected": 120,
  "deathReason": "enemy"
}
```

### Estadísticas

#### GET `/api/stats/player`
Obtener estadísticas del jugador

#### GET `/api/stats/global`
Obtener estadísticas globales

#### GET `/api/stats/achievements`
Obtener logros del jugador

#### GET `/api/player/leaderboard`
Obtener tabla de líderes

## 🎯 Integración con LÖVE

### 1. Instalar dependencias Lua

```bash
# Instalar luasocket para HTTP requests
luarocks install luasocket

# Instalar cjson para JSON
luarocks install lua-cjson
```

### 2. Usar el cliente API en tu juego

```lua
-- En main.lua
local APIClient = require("api_client")

-- Al inicio del juego
function love.load()
    -- Cargar token guardado
    if APIClient.loadToken() then
        print("Token cargado automáticamente")
    end
    
    -- Verificar conexión
    local success, response = APIClient.checkConnection()
    if success then
        print("API conectada:", response.message)
    else
        print("Error conectando a API:", response.error)
    end
end

-- Al iniciar una partida
function startGame()
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
    end
end

-- Durante el juego (cada cierto tiempo)
function updateGameStats()
    if currentSessionId then
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
end

-- Al finalizar la partida
function endGame()
    if currentSessionId then
        local gameState = {
            slime = { x = slime.x, y = slime.y, hp = slime.hp, maxHp = slime.maxhp },
            world = { width = world.w, height = world.h },
            enemies = {},
            projectiles = {}
        }
        
        APIClient.endGameSession(
            currentSessionId,
            score,
            round,
            enemiesKilledThisSession,
            bossesKilledThisSession,
            coinsCollectedThisSession,
            "enemy", -- deathReason
            gameState
        )
        
        currentSessionId = nil
    end
end

-- Registrar eventos específicos
function onEnemyKilled(enemyType)
    if currentSessionId then
        APIClient.registerGameEvent(currentSessionId, "enemy_killed", {
            enemyType = enemyType
        })
    end
end

function onBossKilled()
    if currentSessionId then
        APIClient.registerGameEvent(currentSessionId, "boss_killed", {})
    end
end

function onCoinCollected()
    if currentSessionId then
        APIClient.registerGameEvent(currentSessionId, "coin_collected", {})
    end
end
```

## 📊 Estructura de la Base de Datos

### Colección: `players`
```json
{
  "_id": "ObjectId",
  "username": "jugador1",
  "email": "jugador1@email.com",
  "password": "hashed_password",
  "avatar": "default-avatar.png",
  "level": 5,
  "experience": 450,
  "coins": 1250,
  "lastLogin": "2024-01-15T10:30:00Z",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### Colección: `gamesessions`
```json
{
  "_id": "ObjectId",
  "playerId": "ObjectId",
  "sessionId": "session_1705312200000_abc123",
  "startTime": "2024-01-15T10:30:00Z",
  "endTime": "2024-01-15T10:45:00Z",
  "duration": 900,
  "score": 2500,
  "round": 5,
  "enemiesKilled": 45,
  "bossesKilled": 2,
  "coinsCollected": 120,
  "gameState": { /* estado completo del juego */ },
  "isCompleted": true,
  "deathReason": "enemy"
}
```

### Colección: `playerstats`
```json
{
  "_id": "ObjectId",
  "playerId": "ObjectId",
  "totalGamesPlayed": 25,
  "totalTimePlayed": 7200,
  "totalScore": 50000,
  "highestScore": 3500,
  "averageScore": 2000,
  "totalEnemiesKilled": 500,
  "totalBossesKilled": 15,
  "totalCoinsCollected": 2500,
  "bestRound": 12,
  "achievements": [
    {
      "id": "first_game",
      "name": "Primera Partida",
      "description": "Completa tu primera partida",
      "unlockedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## 🔧 Configuración Avanzada

### Variables de Entorno

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `PORT` | Puerto del servidor | 3000 |
| `MONGODB_URI` | URI de conexión a MongoDB | mongodb://localhost:27017/blobvers |
| `JWT_SECRET` | Clave secreta para JWT | (requerido) |
| `NODE_ENV` | Entorno de ejecución | development |

### Rate Limiting

La API incluye rate limiting configurado:
- 100 requests por 15 minutos por IP
- Configurable en `server.js`

### Seguridad

- Contraseñas encriptadas con bcrypt
- JWT para autenticación
- Headers de seguridad con helmet
- CORS configurado
- Validación de datos de entrada

## 🚀 Despliegue

### Heroku

1. Crear cuenta en [Heroku](https://heroku.com)
2. Instalar Heroku CLI
3. Crear app:
```bash
heroku create blobvers-api
```

4. Configurar variables:
```bash
heroku config:set MONGODB_URI=tu_uri_de_mongodb_atlas
heroku config:set JWT_SECRET=tu_jwt_secret
heroku config:set NODE_ENV=production
```

5. Desplegar:
```bash
git push heroku main
```

### MongoDB Atlas

1. Crear cuenta en [MongoDB Atlas](https://cloud.mongodb.com)
2. Crear cluster gratuito
3. Configurar red de acceso (0.0.0.0/0 para desarrollo)
4. Obtener URI de conexión
5. Actualizar `MONGODB_URI` en variables de entorno

## 📈 Monitoreo

### Logs

La API incluye logging detallado:
- Errores de conexión
- Requests exitosos
- Errores de validación
- Estadísticas de rendimiento

### Métricas

Endpoints para monitoreo:
- `GET /` - Estado de la API
- `GET /api/stats/global` - Estadísticas globales
- Logs de MongoDB para análisis de queries

## 🐛 Troubleshooting

### Problemas Comunes

1. **Error de conexión a MongoDB**
   - Verificar que MongoDB esté corriendo
   - Verificar URI de conexión
   - Verificar red y firewall

2. **Error de JWT**
   - Verificar `JWT_SECRET` en variables de entorno
   - Verificar formato del token en headers

3. **Error de CORS**
   - Verificar configuración de CORS en `server.js`
   - Verificar origen de requests

4. **Error de rate limiting**
   - Reducir frecuencia de requests
   - Ajustar configuración en `server.js`

### Debug

Habilitar logs detallados:
```bash
NODE_ENV=development npm start
```

## 📝 Licencia

MIT License - Ver archivo `LICENSE` para detalles.

## 🤝 Contribuir

1. Fork el proyecto
2. Crear rama para feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📞 Soporte

Para soporte técnico o preguntas:
- Crear issue en GitHub
- Contactar por email
- Documentación completa en `/docs`

---

**¡Disfruta desarrollando con BlobVers API! 🎮** 