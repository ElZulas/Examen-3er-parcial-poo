const express = require('express');
const jwt = require('jsonwebtoken');
const PlayerStats = require('../models/PlayerStats');
const GameSession = require('../models/GameSession');
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

/**
 * @swagger
 * /api/stats/player:
 *   get:
 *     summary: Obtener estadísticas del jugador
 *     tags: [Estadísticas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: detailed
 *         schema:
 *           type: boolean
 *         description: Si se deben obtener estadísticas detalladas
 *         example: false
 *     responses:
 *       200:
 *         description: Estadísticas del jugador obtenidas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 player:
 *                   $ref: '#/components/schemas/Player'
 *                 stats:
 *                   $ref: '#/components/schemas/PlayerStats'
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Estadísticas del jugador no encontradas
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
router.get('/player', authenticateToken, async (req, res) => {
  try {
    const player = req.player;
    const { detailed = false } = req.query;

    const playerStats = await PlayerStats.findOne({ playerId: player._id });

    if (!playerStats) {
      return res.status(404).json({
        error: 'Estadísticas del jugador no encontradas'
      });
    }

    const stats = detailed ? 
      playerStats.getDetailedStats() : 
      playerStats.getSummaryStats();

    res.json({
      player: player.getPublicProfile(),
      stats
    });

  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({
      error: 'Error al obtener estadísticas',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/stats/global:
 *   get:
 *     summary: Obtener estadísticas globales del juego
 *     tags: [Estadísticas]
 *     responses:
 *       200:
 *         description: Estadísticas globales obtenidas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 globalStats:
 *                   type: object
 *                   properties:
 *                     totalPlayers:
 *                       type: integer
 *                       description: Total de jugadores registrados
 *                     totalGamesPlayed:
 *                       type: integer
 *                       description: Total de juegos jugados
 *                     totalTimePlayed:
 *                       type: number
 *                       description: Tiempo total jugado en segundos
 *                     totalScore:
 *                       type: number
 *                       description: Puntuación total acumulada
 *                     totalEnemiesKilled:
 *                       type: integer
 *                       description: Total de enemigos eliminados
 *                     totalBossesKilled:
 *                       type: integer
 *                       description: Total de jefes eliminados
 *                     totalCoinsCollected:
 *                       type: integer
 *                       description: Total de monedas recolectadas
 *                     averageScore:
 *                       type: number
 *                       description: Puntuación promedio
 *                     averageGameDuration:
 *                       type: number
 *                       description: Duración promedio de juego
 *                 topScores:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       rank:
 *                         type: integer
 *                         description: Posición en el ranking
 *                       player:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             description: ID del jugador
 *                           username:
 *                             type: string
 *                             description: Nombre de usuario
 *                           avatar:
 *                             type: string
 *                             description: URL del avatar
 *                           level:
 *                             type: integer
 *                             description: Nivel del jugador
 *                       highestScore:
 *                         type: number
 *                         description: Puntuación más alta
 *                 topKillers:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       rank:
 *                         type: integer
 *                         description: Posición en el ranking
 *                       player:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             description: ID del jugador
 *                           username:
 *                             type: string
 *                             description: Nombre de usuario
 *                           avatar:
 *                             type: string
 *                             description: URL del avatar
 *                           level:
 *                             type: integer
 *                             description: Nivel del jugador
 *                       totalEnemiesKilled:
 *                         type: integer
 *                         description: Total de enemigos eliminados
 *                 topBossKillers:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       rank:
 *                         type: integer
 *                         description: Posición en el ranking
 *                       player:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             description: ID del jugador
 *                           username:
 *                             type: string
 *                             description: Nombre de usuario
 *                           avatar:
 *                             type: string
 *                             description: URL del avatar
 *                           level:
 *                             type: integer
 *                             description: Nivel del jugador
 *                       totalBossesKilled:
 *                         type: integer
 *                         description: Total de jefes eliminados
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/global', async (req, res) => {
  try {
    // Estadísticas agregadas de todos los jugadores
    const globalStats = await PlayerStats.aggregate([
      {
        $group: {
          _id: null,
          totalPlayers: { $sum: 1 },
          totalGamesPlayed: { $sum: '$totalGamesPlayed' },
          totalTimePlayed: { $sum: '$totalTimePlayed' },
          totalScore: { $sum: '$totalScore' },
          totalEnemiesKilled: { $sum: '$totalEnemiesKilled' },
          totalBossesKilled: { $sum: '$totalBossesKilled' },
          totalCoinsCollected: { $sum: '$totalCoinsCollected' },
          averageScore: { $avg: '$averageScore' },
          averageGameDuration: { $avg: '$averageGameDuration' }
        }
      }
    ]);

    // Top 10 puntajes más altos
    const topScores = await PlayerStats.find()
      .sort({ highestScore: -1 })
      .limit(10)
      .populate('playerId', 'username avatar level');

    // Top 10 jugadores con más enemigos eliminados
    const topKillers = await PlayerStats.find()
      .sort({ totalEnemiesKilled: -1 })
      .limit(10)
      .populate('playerId', 'username avatar level');

    // Top 10 jugadores con más jefes eliminados
    const topBossKillers = await PlayerStats.find()
      .sort({ totalBossesKilled: -1 })
      .limit(10)
      .populate('playerId', 'username avatar level');

    res.json({
      globalStats: globalStats[0] || {
        totalPlayers: 0,
        totalGamesPlayed: 0,
        totalTimePlayed: 0,
        totalScore: 0,
        totalEnemiesKilled: 0,
        totalBossesKilled: 0,
        totalCoinsCollected: 0,
        averageScore: 0,
        averageGameDuration: 0
      },
      topScores: topScores.map((stat, index) => ({
        rank: index + 1,
        player: {
          id: stat.playerId._id,
          username: stat.playerId.username,
          avatar: stat.playerId.avatar,
          level: stat.playerId.level
        },
        highestScore: stat.highestScore
      })),
      topKillers: topKillers.map((stat, index) => ({
        rank: index + 1,
        player: {
          id: stat.playerId._id,
          username: stat.playerId.username,
          avatar: stat.playerId.avatar,
          level: stat.playerId.level
        },
        totalEnemiesKilled: stat.totalEnemiesKilled
      })),
      topBossKillers: topBossKillers.map((stat, index) => ({
        rank: index + 1,
        player: {
          id: stat.playerId._id,
          username: stat.playerId.username,
          avatar: stat.playerId.avatar,
          level: stat.playerId.level
        },
        totalBossesKilled: stat.totalBossesKilled
      }))
    });

  } catch (error) {
    console.error('Error obteniendo estadísticas globales:', error);
    res.status(500).json({
      error: 'Error al obtener estadísticas globales',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/stats/analytics:
 *   get:
 *     summary: Obtener análisis detallado de estadísticas
 *     tags: [Estadísticas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [7d, 30d, 90d]
 *         description: Período de análisis
 *         example: "30d"
 *     responses:
 *       200:
 *         description: Análisis obtenido exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 period:
 *                   type: string
 *                   description: Período analizado
 *                 startDate:
 *                   type: string
 *                   format: date-time
 *                   description: Fecha de inicio del análisis
 *                 endDate:
 *                   type: string
 *                   format: date-time
 *                   description: Fecha de fin del análisis
 *                 dailyStats:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       _id:
 *                         type: string
 *                         description: Fecha en formato YYYY-MM-DD
 *                       gamesPlayed:
 *                         type: integer
 *                         description: Juegos jugados en ese día
 *                       totalScore:
 *                         type: number
 *                         description: Puntuación total del día
 *                       totalEnemiesKilled:
 *                         type: integer
 *                         description: Enemigos eliminados en el día
 *                       totalBossesKilled:
 *                         type: integer
 *                         description: Jefes eliminados en el día
 *                       totalCoinsCollected:
 *                         type: integer
 *                         description: Monedas recolectadas en el día
 *                       averageDuration:
 *                         type: number
 *                         description: Duración promedio de juego del día
 *                 enemyStats:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       _id:
 *                         type: string
 *                         description: ID del arma
 *                       totalAmmoUsed:
 *                         type: integer
 *                         description: Total de munición usada
 *                       totalKills:
 *                         type: integer
 *                         description: Total de eliminaciones
 *                       timesUsed:
 *                         type: integer
 *                         description: Veces que se usó el arma
 *                 performanceStats:
 *                   type: object
 *                   properties:
 *                     totalGames:
 *                       type: integer
 *                       description: Total de juegos en el período
 *                     averageScore:
 *                       type: number
 *                       description: Puntuación promedio
 *                     averageDuration:
 *                       type: number
 *                       description: Duración promedio
 *                     bestScore:
 *                       type: number
 *                       description: Mejor puntuación del período
 *                     longestGame:
 *                       type: number
 *                       description: Juego más largo del período
 *                     totalEnemiesKilled:
 *                       type: integer
 *                       description: Total de enemigos eliminados
 *                     totalBossesKilled:
 *                       type: integer
 *                       description: Total de jefes eliminados
 *                     totalCoinsCollected:
 *                       type: integer
 *                       description: Total de monedas recolectadas
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
router.get('/analytics', authenticateToken, async (req, res) => {
  try {
    const player = req.player;
    const { period = '30d' } = req.query;

    // Calcular fecha de inicio basada en el período
    const now = new Date();
    let startDate;
    switch (period) {
      case '7d':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case '30d':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case '90d':
        startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    }

    // Estadísticas por día
    const dailyStats = await GameSession.aggregate([
      {
        $match: {
          playerId: player._id,
          startTime: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$startTime' }
          },
          gamesPlayed: { $sum: 1 },
          totalScore: { $sum: '$score' },
          totalEnemiesKilled: { $sum: '$enemiesKilled' },
          totalBossesKilled: { $sum: '$bossesKilled' },
          totalCoinsCollected: { $sum: '$coinsCollected' },
          averageDuration: { $avg: '$duration' }
        }
      },
      {
        $sort: { '_id': 1 }
      }
    ]);

    // Estadísticas por tipo de enemigo
    const enemyStats = await GameSession.aggregate([
      {
        $match: {
          playerId: player._id,
          startTime: { $gte: startDate }
        }
      },
      {
        $unwind: '$weaponsUsed'
      },
      {
        $group: {
          _id: '$weaponsUsed.weaponId',
          totalAmmoUsed: { $sum: '$weaponsUsed.ammoUsed' },
          totalKills: { $sum: '$weaponsUsed.kills' },
          timesUsed: { $sum: 1 }
        }
      }
    ]);

    // Estadísticas de rendimiento
    const performanceStats = await GameSession.aggregate([
      {
        $match: {
          playerId: player._id,
          startTime: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: null,
          totalGames: { $sum: 1 },
          averageScore: { $avg: '$score' },
          averageDuration: { $avg: '$duration' },
          bestScore: { $max: '$score' },
          longestGame: { $max: '$duration' },
          totalEnemiesKilled: { $sum: '$enemiesKilled' },
          totalBossesKilled: { $sum: '$bossesKilled' },
          totalCoinsCollected: { $sum: '$coinsCollected' }
        }
      }
    ]);

    res.json({
      period,
      startDate,
      endDate: now,
      dailyStats,
      enemyStats,
      performanceStats: performanceStats[0] || {
        totalGames: 0,
        averageScore: 0,
        averageDuration: 0,
        bestScore: 0,
        longestGame: 0,
        totalEnemiesKilled: 0,
        totalBossesKilled: 0,
        totalCoinsCollected: 0
      }
    });

  } catch (error) {
    console.error('Error obteniendo análisis:', error);
    res.status(500).json({
      error: 'Error al obtener análisis',
      message: error.message
    });
  }
});

// GET /api/stats/achievements - Obtener logros del jugador
router.get('/achievements', authenticateToken, async (req, res) => {
  try {
    const player = req.player;

    const playerStats = await PlayerStats.findOne({ playerId: player._id });

    if (!playerStats) {
      return res.status(404).json({
        error: 'Estadísticas del jugador no encontradas'
      });
    }

    // Definir logros disponibles
    const availableAchievements = [
      {
        id: 'first_game',
        name: 'Primera Partida',
        description: 'Completa tu primera partida',
        condition: (stats) => stats.totalGamesPlayed >= 1
      },
      {
        id: 'score_1000',
        name: 'Puntaje Alto',
        description: 'Alcanza 1000 puntos en una partida',
        condition: (stats) => stats.highestScore >= 1000
      },
      {
        id: 'score_5000',
        name: 'Maestro del Puntaje',
        description: 'Alcanza 5000 puntos en una partida',
        condition: (stats) => stats.highestScore >= 5000
      },
      {
        id: 'enemies_100',
        name: 'Cazador de Enemigos',
        description: 'Elimina 100 enemigos en total',
        condition: (stats) => stats.totalEnemiesKilled >= 100
      },
      {
        id: 'enemies_500',
        name: 'Exterminador',
        description: 'Elimina 500 enemigos en total',
        condition: (stats) => stats.totalEnemiesKilled >= 500
      },
      {
        id: 'bosses_10',
        name: 'Cazador de Jefes',
        description: 'Derrota 10 jefes en total',
        condition: (stats) => stats.totalBossesKilled >= 10
      },
      {
        id: 'bosses_50',
        name: 'Destructor de Jefes',
        description: 'Derrota 50 jefes en total',
        condition: (stats) => stats.totalBossesKilled >= 50
      },
      {
        id: 'coins_1000',
        name: 'Recolector',
        description: 'Recolecta 1000 monedas en total',
        condition: (stats) => stats.totalCoinsCollected >= 1000
      },
      {
        id: 'round_10',
        name: 'Sobreviviente',
        description: 'Completa la ronda 10',
        condition: (stats) => stats.bestRound >= 10
      },
      {
        id: 'round_20',
        name: 'Veterano',
        description: 'Completa la ronda 20',
        condition: (stats) => stats.bestRound >= 20
      },
      {
        id: 'games_50',
        name: 'Jugador Dedicado',
        description: 'Juega 50 partidas',
        condition: (stats) => stats.totalGamesPlayed >= 50
      },
      {
        id: 'time_1h',
        name: 'Jugador Tiempo',
        description: 'Juega por 1 hora en total',
        condition: (stats) => stats.totalTimePlayed >= 3600
      }
    ];

    // Verificar logros desbloqueados
    const unlockedAchievements = [];
    const lockedAchievements = [];

    availableAchievements.forEach(achievement => {
      const isUnlocked = achievement.condition(playerStats.getSummaryStats());
      const hasAchievement = playerStats.achievements.some(a => a.id === achievement.id);
      
      if (isUnlocked && !hasAchievement) {
        // Agregar logro desbloqueado
        playerStats.addAchievement({
          id: achievement.id,
          name: achievement.name,
          description: achievement.description
        });
      }
      
      if (hasAchievement || isUnlocked) {
        unlockedAchievements.push({
          ...achievement,
          unlockedAt: playerStats.achievements.find(a => a.id === achievement.id)?.unlockedAt
        });
      } else {
        lockedAchievements.push(achievement);
      }
    });

    await playerStats.save();

    res.json({
      unlocked: unlockedAchievements,
      locked: lockedAchievements,
      totalUnlocked: unlockedAchievements.length,
      totalAvailable: availableAchievements.length
    });

  } catch (error) {
    console.error('Error obteniendo logros:', error);
    res.status(500).json({
      error: 'Error al obtener logros',
      message: error.message
    });
  }
});

// GET /api/stats/compare - Comparar estadísticas con otros jugadores
router.get('/compare', authenticateToken, async (req, res) => {
  try {
    const player = req.player;
    const { metric = 'totalScore' } = req.query;

    const playerStats = await PlayerStats.findOne({ playerId: player._id });

    if (!playerStats) {
      return res.status(404).json({
        error: 'Estadísticas del jugador no encontradas'
      });
    }

    // Obtener estadísticas globales para comparación
    const globalStats = await PlayerStats.aggregate([
      {
        $group: {
          _id: null,
          average: { $avg: `$${metric}` },
          median: { $avg: `$${metric}` },
          max: { $max: `$${metric}` },
          min: { $min: `$${metric}` },
          totalPlayers: { $sum: 1 }
        }
      }
    ]);

    // Obtener ranking del jugador
    const playerRank = await PlayerStats.countDocuments({
      [metric]: { $gt: playerStats[metric] }
    });

    const globalData = globalStats[0] || {
      average: 0,
      median: 0,
      max: 0,
      min: 0,
      totalPlayers: 0
    };

    const playerValue = playerStats[metric] || 0;
    const percentile = globalData.totalPlayers > 0 ? 
      Math.round(((globalData.totalPlayers - playerRank) / globalData.totalPlayers) * 100) : 0;

    res.json({
      metric,
      playerValue,
      globalStats: globalData,
      ranking: {
        rank: playerRank + 1,
        totalPlayers: globalData.totalPlayers,
        percentile
      },
      comparison: {
        vsAverage: playerValue - globalData.average,
        vsMax: playerValue - globalData.max,
        percentageOfMax: globalData.max > 0 ? (playerValue / globalData.max) * 100 : 0
      }
    });

  } catch (error) {
    console.error('Error comparando estadísticas:', error);
    res.status(500).json({
      error: 'Error al comparar estadísticas',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/stats/save:
 *   post:
 *     summary: Guardar estadísticas del juego
 *     tags: [Estadísticas]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nombre de usuario
 *               highScore:
 *                 type: number
 *                 description: Puntuación más alta
 *               lastScore:
 *                 type: number
 *                 description: Última puntuación
 *               totalGames:
 *                 type: integer
 *                 description: Total de juegos jugados
 *               totalTime:
 *                 type: number
 *                 description: Tiempo total jugado
 *               enemiesKilled:
 *                 type: integer
 *                 description: Enemigos eliminados
 *               bossesKilled:
 *                 type: integer
 *                 description: Jefes eliminados
 *               roundsCompleted:
 *                 type: integer
 *                 description: Rondas completadas
 *               coinsCollected:
 *                 type: integer
 *                 description: Monedas recolectadas
 *               lastGameDate:
 *                 type: string
 *                 description: Fecha de la última partida
 *               bestRound:
 *                 type: integer
 *                 description: Mejor ronda alcanzada
 *     responses:
 *       200:
 *         description: Estadísticas guardadas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Mensaje de confirmación
 *                 stats:
 *                   $ref: '#/components/schemas/PlayerStats'
 *       400:
 *         description: Datos inválidos
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
router.post('/save', async (req, res) => {
  try {
    const {
      username,
      highScore,
      lastScore,
      totalGames,
      totalTime,
      enemiesKilled,
      bossesKilled,
      roundsCompleted,
      coinsCollected,
      lastGameDate,
      bestRound
    } = req.body;

    // Validar datos requeridos
    if (!username) {
      return res.status(400).json({
        error: 'Nombre de usuario requerido'
      });
    }

    // Buscar o crear jugador
    let player = await Player.findOne({ username });
    if (!player) {
      player = new Player({
        username,
        email: username + '@blobvers.local',
        level: 1,
        experience: 0,
        coins: 0
      });
      await player.save();
    }

    // Buscar o crear estadísticas del jugador
    let playerStats = await PlayerStats.findOne({ playerId: player._id });
    if (!playerStats) {
      playerStats = new PlayerStats({
        playerId: player._id,
        totalGamesPlayed: 0,
        totalTimePlayed: 0,
        totalScore: 0,
        highestScore: 0,
        averageScore: 0,
        totalEnemiesKilled: 0,
        totalBossesKilled: 0,
        totalCoinsCollected: 0,
        bestRound: 0,
        achievements: []
      });
    }

    // Actualizar estadísticas
    playerStats.totalGamesPlayed = totalGames || playerStats.totalGamesPlayed;
    playerStats.totalTimePlayed = totalTime || playerStats.totalTimePlayed;
    playerStats.totalScore = (playerStats.totalScore || 0) + (lastScore || 0);
    playerStats.highestScore = math.max(highScore || 0, playerStats.highestScore || 0);
    playerStats.totalEnemiesKilled = enemiesKilled || playerStats.totalEnemiesKilled || 0;
    playerStats.totalBossesKilled = bossesKilled || playerStats.totalBossesKilled || 0;
    playerStats.totalCoinsCollected = coinsCollected || playerStats.totalCoinsCollected || 0;
    playerStats.bestRound = math.max(bestRound || 0, playerStats.bestRound || 0);
    
    // Calcular puntuación promedio
    if (playerStats.totalGamesPlayed > 0) {
      playerStats.averageScore = playerStats.totalScore / playerStats.totalGamesPlayed;
    }

    await playerStats.save();

    res.json({
      message: 'Estadísticas guardadas exitosamente',
      stats: playerStats.getSummaryStats()
    });

  } catch (error) {
    console.error('Error guardando estadísticas:', error);
    res.status(500).json({
      error: 'Error al guardar estadísticas',
      message: error.message
    });
  }
});

module.exports = router; 