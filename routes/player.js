const express = require('express');
const jwt = require('jsonwebtoken');
const Player = require('../models/Player');
const PlayerStats = require('../models/PlayerStats');
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

// Generar token JWT
const generateToken = (playerId) => {
  return jwt.sign({ playerId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

/**
 * @swagger
 * /api/player/register:
 *   post:
 *     summary: Registrar nuevo jugador
 *     tags: [Autenticación]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nombre de usuario único
 *                 example: "player123"
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email del jugador
 *                 example: "player@example.com"
 *               password:
 *                 type: string
 *                 description: Contraseña del jugador
 *                 example: "password123"
 *     responses:
 *       201:
 *         description: Jugador registrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Jugador registrado exitosamente"
 *                 player:
 *                   $ref: '#/components/schemas/Player'
 *                 token:
 *                   type: string
 *                   description: Token JWT para autenticación
 *       400:
 *         description: Datos requeridos faltantes
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       409:
 *         description: Usuario o email ya existe
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
router.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Validar datos requeridos
    if (!username || !email || !password) {
      return res.status(400).json({
        error: 'Todos los campos son requeridos',
        required: ['username', 'email', 'password']
      });
    }

    // Verificar si el usuario ya existe
    const existingPlayer = await Player.findOne({
      $or: [{ username }, { email }]
    });

    if (existingPlayer) {
      return res.status(409).json({
        error: 'El nombre de usuario o email ya está en uso'
      });
    }

    // Crear nuevo jugador
    const player = new Player({
      username,
      email,
      password
    });

    await player.save();

    // Crear estadísticas iniciales
    const playerStats = new PlayerStats({
      playerId: player._id
    });
    await playerStats.save();

    // Generar token
    const token = generateToken(player._id);

    res.status(201).json({
      message: 'Jugador registrado exitosamente',
      player: player.getPublicProfile(),
      token
    });

  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({
      error: 'Error al registrar jugador',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/player/login:
 *   post:
 *     summary: Iniciar sesión de jugador
 *     tags: [Autenticación]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nombre de usuario o email
 *                 example: "player123"
 *               password:
 *                 type: string
 *                 description: Contraseña del jugador
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Login exitoso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Login exitoso"
 *                 player:
 *                   $ref: '#/components/schemas/Player'
 *                 token:
 *                   type: string
 *                   description: Token JWT para autenticación
 *       400:
 *         description: Datos requeridos faltantes
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Credenciales inválidas
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
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validar datos requeridos
    if (!username || !password) {
      return res.status(400).json({
        error: 'Usuario y contraseña son requeridos'
      });
    }

    // Buscar jugador por username o email
    const player = await Player.findOne({
      $or: [
        { username: username },
        { email: username }
      ]
    }).select('+password');

    if (!player) {
      return res.status(401).json({
        error: 'Credenciales inválidas'
      });
    }

    // Verificar contraseña
    const isPasswordValid = await player.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Credenciales inválidas'
      });
    }

    // Actualizar último login
    player.lastLogin = new Date();
    await player.save();

    // Generar token
    const token = generateToken(player._id);

    res.json({
      message: 'Login exitoso',
      player: player.getPublicProfile(),
      token
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      error: 'Error al iniciar sesión',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/player/profile:
 *   get:
 *     summary: Obtener perfil del jugador
 *     tags: [Perfil]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Perfil del jugador obtenido exitosamente
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
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const player = req.player;
    
    // Obtener estadísticas del jugador
    const playerStats = await PlayerStats.findOne({ playerId: player._id });
    
    res.json({
      player: player.getPublicProfile(),
      stats: playerStats ? playerStats.getSummaryStats() : null
    });

  } catch (error) {
    console.error('Error obteniendo perfil:', error);
    res.status(500).json({
      error: 'Error al obtener perfil',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/player/profile:
 *   put:
 *     summary: Actualizar perfil del jugador
 *     tags: [Perfil]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nuevo nombre de usuario
 *                 example: "newUsername"
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Nuevo email
 *                 example: "newemail@example.com"
 *               avatar:
 *                 type: string
 *                 description: URL del nuevo avatar
 *                 example: "https://example.com/avatar.png"
 *     responses:
 *       200:
 *         description: Perfil actualizado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Perfil actualizado exitosamente"
 *                 player:
 *                   $ref: '#/components/schemas/Player'
 *       400:
 *         description: Datos inválidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Token de acceso requerido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       409:
 *         description: Usuario o email ya existe
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
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { username, email, avatar } = req.body;
    const player = req.player;

    // Verificar si el nuevo username/email ya existe
    if (username || email) {
      const existingPlayer = await Player.findOne({
        $and: [
          { _id: { $ne: player._id } },
          {
            $or: [
              ...(username ? [{ username }] : []),
              ...(email ? [{ email }] : [])
            ]
          }
        ]
      });

      if (existingPlayer) {
        return res.status(409).json({
          error: 'El nombre de usuario o email ya está en uso'
        });
      }
    }

    // Actualizar campos
    if (username) player.username = username;
    if (email) player.email = email;
    if (avatar) player.avatar = avatar;

    await player.save();

    res.json({
      message: 'Perfil actualizado exitosamente',
      player: player.getPublicProfile()
    });

  } catch (error) {
    console.error('Error actualizando perfil:', error);
    res.status(500).json({
      error: 'Error al actualizar perfil',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/player/password:
 *   put:
 *     summary: Cambiar contraseña del jugador
 *     tags: [Perfil]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - currentPassword
 *               - newPassword
 *             properties:
 *               currentPassword:
 *                 type: string
 *                 description: Contraseña actual
 *                 example: "oldPassword123"
 *               newPassword:
 *                 type: string
 *                 description: Nueva contraseña
 *                 example: "newPassword123"
 *     responses:
 *       200:
 *         description: Contraseña actualizada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Contraseña actualizada exitosamente"
 *       400:
 *         description: Datos requeridos faltantes
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Contraseña actual incorrecta
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
router.put('/password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const player = req.player;

    // Validar datos requeridos
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        error: 'Contraseña actual y nueva contraseña son requeridas'
      });
    }

    // Verificar contraseña actual
    const isCurrentPasswordValid = await player.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(401).json({
        error: 'Contraseña actual incorrecta'
      });
    }

    // Actualizar contraseña
    player.password = newPassword;
    await player.save();

    res.json({
      message: 'Contraseña actualizada exitosamente'
    });

  } catch (error) {
    console.error('Error cambiando contraseña:', error);
    res.status(500).json({
      error: 'Error al cambiar contraseña',
      message: error.message
    });
  }
});

/**
 * @swagger
 * /api/player/leaderboard:
 *   get:
 *     summary: Obtener tabla de líderes
 *     tags: [Estadísticas]
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [score, enemies, bosses, rounds]
 *         description: Tipo de ranking
 *         example: "score"
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Número máximo de jugadores a retornar
 *         example: 10
 *     responses:
 *       200:
 *         description: Tabla de líderes obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 type:
 *                   type: string
 *                   description: Tipo de ranking solicitado
 *                 leaderboard:
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
 *                       value:
 *                         type: number
 *                         description: Valor del ranking
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.get('/leaderboard', async (req, res) => {
  try {
    const { type = 'score', limit = 10 } = req.query;
    
    let sortField = 'totalScore';
    if (type === 'enemies') sortField = 'totalEnemiesKilled';
    if (type === 'bosses') sortField = 'totalBossesKilled';
    if (type === 'rounds') sortField = 'bestRound';

    const leaderboard = await PlayerStats.find()
      .sort({ [sortField]: -1 })
      .limit(parseInt(limit))
      .populate('playerId', 'username avatar level')
      .select(`${sortField} playerId`);

    const formattedLeaderboard = leaderboard.map((stat, index) => ({
      rank: index + 1,
      player: {
        id: stat.playerId._id,
        username: stat.playerId.username,
        avatar: stat.playerId.avatar,
        level: stat.playerId.level
      },
      value: stat[sortField]
    }));

    res.json({
      type,
      leaderboard: formattedLeaderboard
    });

  } catch (error) {
    console.error('Error obteniendo leaderboard:', error);
    res.status(500).json({
      error: 'Error al obtener tabla de líderes',
      message: error.message
    });
  }
});

module.exports = router; 