const express = require('express');
const jwt = require('jsonwebtoken');
const GameSession = require('../models/GameSession');
const PlayerStats = require('../models/PlayerStats');
const Player = require('../models/Player');
const router = express.Router();

// Middleware para verificar JWT
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token de acceso requerido' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const player = await Player.findById(decoded.playerId);
    
    if (!player) {
      return res.status(404).json({ error: 'Jugador no encontrado' });
    }
    
    req.player = player;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Token inválido' });
  }
};

// Generar ID único para sesión
const generateSessionId = () => {
  return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
};

/**
 * @swagger
 * /api/game/start:
 *   post:
 *     summary: Iniciar nueva sesión de juego
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               initialGameState:
 *                 type: object
 *                 description: Estado inicial del juego
 *                 example:
 *                   slime: { x: 1500, y: 1000, hp: 100, maxHp: 100 }
 *                   world: { width: 3000, height: 2000 }
 *                   enemies: []
 *                   projectiles: []
 *     responses:
 *       201:
 *         description: Sesión de juego iniciada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Sesión de juego iniciada"
 *                 sessionId:
 *                   type: string
 *                   description: ID único de la sesión
 *                 session:
 *                   $ref: '#/components/schemas/GameSession'
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/start', authenticateToken, async (req, res) => {
  try {
    const { initialGameState } = req.body;
    const player = req.player;

    // Crear nueva sesión de juego
    const session = new GameSession({
      playerId: player._id,
      sessionId: generateSessionId(),
      gameState: initialGameState || {
        slime: { x: 1500, y: 1000, hp: 100, maxHp: 100 },
        world: { width: 3000, height: 2000 },
        enemies: [],
        projectiles: []
      }
    });

    await session.save();

    res.status(201).json({
      message: 'Sesión de juego iniciada',
      sessionId: session.sessionId,
      session: session.getSessionStats()
    });

  } catch (error) {
    console.error('Error iniciando sesión:', error);
    res.status(500).json({
      error: 'Error al iniciar sesión de juego',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/update/{sessionId}:
 *   put:
 *     summary: Actualizar estado del juego
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sesión de juego
 *         example: "session_1234567890_abc123"
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               gameState:
 *                 type: object
 *                 description: Estado actual del juego
 *               score:
 *                 type: number
 *                 description: Puntuación actual
 *                 example: 1500
 *               round:
 *                 type: number
 *                 description: Ronda actual
 *                 example: 5
 *               enemiesKilled:
 *                 type: number
 *                 description: Enemigos eliminados
 *                 example: 25
 *               bossesKilled:
 *                 type: number
 *                 description: Jefes eliminados
 *                 example: 2
 *               coinsCollected:
 *                 type: number
 *                 description: Monedas recolectadas
 *                 example: 150
 *     responses:
 *       200:
 *         description: Estado del juego actualizado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Estado del juego actualizado"
 *                 session:
 *                   $ref: '#/components/schemas/GameSession'
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Sesión de juego no encontrada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.put('/update/:sessionId', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { gameState, score, round, enemiesKilled, bossesKilled, coinsCollected } = req.body;
    const player = req.player;

    // Buscar sesión
    const session = await GameSession.findOne({
      sessionId,
      playerId: player._id
    });

    if (!session) {
      return res.status(404).json({
        error: 'Sesión de juego no encontrada'
      });
    }

    // Actualizar estado del juego
    if (gameState) {
      session.updateGameState(gameState);
    }

    // Actualizar estadísticas
    if (score !== undefined) session.addScore(score);
    if (round !== undefined) session.round = round;
    if (enemiesKilled !== undefined) session.enemiesKilled = enemiesKilled;
    if (bossesKilled !== undefined) session.bossesKilled = bossesKilled;
    if (coinsCollected !== undefined) session.coinsCollected = coinsCollected;

    await session.save();

    res.json({
      message: 'Estado del juego actualizado',
      session: session.getSessionStats()
    });

  } catch (error) {
    console.error('Error actualizando juego:', error);
    res.status(500).json({
      error: 'Error al actualizar estado del juego',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/end/{sessionId}:
 *   post:
 *     summary: Finalizar sesión de juego
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sesión de juego
 *         example: "session_1234567890_abc123"
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               finalScore:
 *                 type: number
 *                 description: Puntuación final
 *                 example: 2500
 *               round:
 *                 type: number
 *                 description: Ronda final
 *                 example: 8
 *               enemiesKilled:
 *                 type: number
 *                 description: Total de enemigos eliminados
 *                 example: 45
 *               bossesKilled:
 *                 type: number
 *                 description: Total de jefes eliminados
 *                 example: 3
 *               coinsCollected:
 *                 type: number
 *                 description: Total de monedas recolectadas
 *                 example: 300
 *               deathReason:
 *                 type: string
 *                 description: Razón de la muerte
 *                 example: "enemy"
 *               gameState:
 *                 type: object
 *                 description: Estado final del juego
 *     responses:
 *       200:
 *         description: Sesión de juego finalizada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Sesión de juego finalizada"
 *                 session:
 *                   $ref: '#/components/schemas/GameSession'
 *                 playerUpdate:
 *                   type: object
 *                   properties:
 *                     experienceGained:
 *                       type: number
 *                       description: Experiencia ganada
 *                     newExperience:
 *                       type: number
 *                       description: Nueva experiencia total
 *                     levelUp:
 *                       type: boolean
 *                       description: Si el jugador subió de nivel
 *                     newLevel:
 *                       type: number
 *                       description: Nuevo nivel del jugador
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Sesión de juego no encontrada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/end/:sessionId', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { 
      finalScore, 
      round, 
      enemiesKilled, 
      bossesKilled, 
      coinsCollected,
      deathReason = 'other',
      gameState 
    } = req.body;
    const player = req.player;

    // Buscar sesión
    const session = await GameSession.findOne({
      sessionId,
      playerId: player._id
    });

    if (!session) {
      return res.status(404).json({
        error: 'Sesión de juego no encontrada'
      });
    }

    // Finalizar sesión
    session.endSession();
    session.score = finalScore || session.score;
    session.round = round || session.round;
    session.enemiesKilled = enemiesKilled || session.enemiesKilled;
    session.bossesKilled = bossesKilled || session.bossesKilled;
    session.coinsCollected = coinsCollected || session.coinsCollected;
    session.deathReason = deathReason;
    session.isGameOver = true;

    if (gameState) {
      session.updateGameState(gameState);
    }

    await session.save();

    // Actualizar estadísticas del jugador
    const playerStats = await PlayerStats.findOne({ playerId: player._id });
    if (playerStats) {
      playerStats.updateStatsFromSession(session.getSessionStats());
      await playerStats.save();
    }

    // Actualizar experiencia del jugador
    const expGained = Math.floor(finalScore / 10) + (enemiesKilled * 2) + (bossesKilled * 10);
    const levelUp = player.addExperience(expGained);
    await player.save();

    res.json({
      message: 'Sesión de juego finalizada',
      session: session.getSessionStats(),
      playerUpdate: {
        experienceGained: expGained,
        newExperience: player.experience,
        levelUp: levelUp.leveledUp,
        newLevel: levelUp.newLevel || player.level
      }
    });

  } catch (error) {
    console.error('Error finalizando sesión:', error);
    res.status(500).json({
      error: 'Error al finalizar sesión de juego',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/sessions:
 *   get:
 *     summary: Obtener sesiones del jugador
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Número máximo de sesiones a retornar
 *         example: 10
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Número de página
 *         example: 1
 *     responses:
 *       200:
 *         description: Sesiones obtenidas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 sessions:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/GameSession'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                       description: Página actual
 *                     limit:
 *                       type: integer
 *                       description: Límite por página
 *                     total:
 *                       type: integer
 *                       description: Total de sesiones
 *                     pages:
 *                       type: integer
 *                       description: Total de páginas
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/sessions', authenticateToken, async (req, res) => {
  try {
    const { limit = 10, page = 1 } = req.query;
    const player = req.player;

    const sessions = await GameSession.find({ playerId: player._id })
      .sort({ startTime: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const totalSessions = await GameSession.countDocuments({ playerId: player._id });

    res.json({
      sessions: sessions.map(session => session.getSessionStats()),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalSessions,
        pages: Math.ceil(totalSessions / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Error obteniendo sesiones:', error);
    res.status(500).json({
      error: 'Error al obtener sesiones',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/session/{sessionId}:
 *   get:
 *     summary: Obtener sesión específica
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sesión de juego
 *         example: "session_1234567890_abc123"
 *     responses:
 *       200:
 *         description: Sesión obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 session:
 *                   $ref: '#/components/schemas/GameSession'
 *                 gameState:
 *                   type: object
 *                   description: Estado completo del juego
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Sesión de juego no encontrada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/session/:sessionId', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const player = req.player;

    const session = await GameSession.findOne({
      sessionId,
      playerId: player._id
    });

    if (!session) {
      return res.status(404).json({
        error: 'Sesión de juego no encontrada'
      });
    }

    res.json({
      session: session.getSessionStats(),
      gameState: session.gameState
    });

  } catch (error) {
    console.error('Error obteniendo sesión:', error);
    res.status(500).json({
      error: 'Error al obtener sesión',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/event/{sessionId}:
 *   post:
 *     summary: Registrar evento del juego
 *     tags: [Eventos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sesión de juego
 *         example: "session_1234567890_abc123"
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - eventType
 *             properties:
 *               eventType:
 *                 type: string
 *                 enum: [enemy_killed, boss_killed, coin_collected, weapon_used, item_used]
 *                 description: Tipo de evento
 *                 example: "enemy_killed"
 *               eventData:
 *                 type: object
 *                 description: Datos específicos del evento
 *                 example:
 *                   enemyType: "bomber"
 *                   weaponId: "pistol"
 *                   ammoUsed: 1
 *                   kill: true
 *                   itemId: "health_potion"
 *     responses:
 *       200:
 *         description: Evento registrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Evento registrado exitosamente"
 *                 session:
 *                   $ref: '#/components/schemas/GameSession'
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Sesión de juego no encontrada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/event/:sessionId', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { eventType, eventData } = req.body;
    const player = req.player;

    const session = await GameSession.findOne({
      sessionId,
      playerId: player._id
    });

    if (!session) {
      return res.status(404).json({
        error: 'Sesión de juego no encontrada'
      });
    }

    // Procesar diferentes tipos de eventos
    switch (eventType) {
      case 'enemy_killed':
        session.addEnemyKill(eventData.enemyType);
        break;
      case 'boss_killed':
        session.addBossKill();
        break;
      case 'coin_collected':
        session.addCoin();
        break;
      case 'weapon_used':
        // Actualizar estadísticas de armas
        if (!session.weaponsUsed.find(w => w.weaponId === eventData.weaponId)) {
          session.weaponsUsed.push({
            weaponId: eventData.weaponId,
            ammoUsed: 0,
            kills: 0
          });
        }
        const weapon = session.weaponsUsed.find(w => w.weaponId === eventData.weaponId);
        weapon.ammoUsed += eventData.ammoUsed || 1;
        if (eventData.kill) weapon.kills += 1;
        break;
      case 'item_used':
        // Actualizar estadísticas de items
        if (!session.itemsUsed.find(i => i.itemId === eventData.itemId)) {
          session.itemsUsed.push({
            itemId: eventData.itemId,
            uses: 0
          });
        }
        const item = session.itemsUsed.find(i => i.itemId === eventData.itemId);
        item.uses += 1;
        break;
    }

    await session.save();

    res.json({
      message: 'Evento registrado exitosamente',
      session: session.getSessionStats()
    });

  } catch (error) {
    console.error('Error registrando evento:', error);
    res.status(500).json({
      error: 'Error al registrar evento',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/game/active-sessions:
 *   get:
 *     summary: Obtener sesiones activas del jugador
 *     tags: [Sesiones de Juego]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Sesiones activas obtenidas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 activeSessions:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       sessionId:
 *                         type: string
 *                         description: ID de la sesión
 *                       startTime:
 *                         type: string
 *                         format: date-time
 *                         description: Hora de inicio
 *                       duration:
 *                         type: number
 *                         description: Duración en segundos
 *                       score:
 *                         type: number
 *                         description: Puntuación actual
 *                       round:
 *                         type: number
 *                         description: Ronda actual
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/active-sessions', authenticateToken, async (req, res) => {
  try {
    const player = req.player;

    const activeSessions = await GameSession.find({
      playerId: player._id,
      isCompleted: false
    }).sort({ startTime: -1 });

    res.json({
      activeSessions: activeSessions.map(session => ({
        sessionId: session.sessionId,
        startTime: session.startTime,
        duration: session.duration,
        score: session.score,
        round: session.round
      }))
    });

  } catch (error) {
    console.error('Error obteniendo sesiones activas:', error);
    res.status(500).json({
      error: 'Error al obtener sesiones activas',
      message: error.message
    });
  }
});

module.exports = router; 