const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'BlobVers Game API',
      version: '1.0.0',
      description: 'API completa para el juego BlobVers - Sistema de autenticación, sesiones de juego, estadísticas y logros',
      contact: {
        name: 'BlobVers Team',
        email: 'support@blobvers.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Servidor de desarrollo'
      },
      {
        url: 'https://api.blobvers.com',
        description: 'Servidor de producción'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT para autenticación'
        }
      },
      schemas: {
        Player: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'ID único del jugador'
            },
            username: {
              type: 'string',
              description: 'Nombre de usuario único'
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Email del jugador'
            },
            avatar: {
              type: 'string',
              description: 'URL del avatar del jugador'
            },
            level: {
              type: 'number',
              description: 'Nivel actual del jugador'
            },
            experience: {
              type: 'number',
              description: 'Experiencia acumulada'
            },
            coins: {
              type: 'number',
              description: 'Monedas del jugador'
            },
            lastLogin: {
              type: 'string',
              format: 'date-time',
              description: 'Última vez que el jugador inició sesión'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación de la cuenta'
            }
          }
        },
        GameSession: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'ID único de la sesión'
            },
            playerId: {
              type: 'string',
              description: 'ID del jugador'
            },
            sessionId: {
              type: 'string',
              description: 'ID único de la sesión de juego'
            },
            startTime: {
              type: 'string',
              format: 'date-time',
              description: 'Hora de inicio de la sesión'
            },
            endTime: {
              type: 'string',
              format: 'date-time',
              description: 'Hora de fin de la sesión'
            },
            duration: {
              type: 'number',
              description: 'Duración de la sesión en segundos'
            },
            score: {
              type: 'number',
              description: 'Puntuación final'
            },
            round: {
              type: 'number',
              description: 'Ronda alcanzada'
            },
            enemiesKilled: {
              type: 'number',
              description: 'Enemigos eliminados'
            },
            bossesKilled: {
              type: 'number',
              description: 'Jefes eliminados'
            },
            coinsCollected: {
              type: 'number',
              description: 'Monedas recolectadas'
            },
            isCompleted: {
              type: 'boolean',
              description: 'Si la sesión fue completada'
            },
            isGameOver: {
              type: 'boolean',
              description: 'Si el juego terminó'
            },
            deathReason: {
              type: 'string',
              description: 'Razón de la muerte del jugador'
            }
          }
        },
        PlayerStats: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'ID único de las estadísticas'
            },
            playerId: {
              type: 'string',
              description: 'ID del jugador'
            },
            totalGamesPlayed: {
              type: 'number',
              description: 'Total de juegos jugados'
            },
            totalTimePlayed: {
              type: 'number',
              description: 'Tiempo total jugado en segundos'
            },
            totalScore: {
              type: 'number',
              description: 'Puntuación total acumulada'
            },
            highestScore: {
              type: 'number',
              description: 'Puntuación más alta alcanzada'
            },
            averageScore: {
              type: 'number',
              description: 'Puntuación promedio'
            },
            totalEnemiesKilled: {
              type: 'number',
              description: 'Total de enemigos eliminados'
            },
            totalBossesKilled: {
              type: 'number',
              description: 'Total de jefes eliminados'
            },
            totalCoinsCollected: {
              type: 'number',
              description: 'Total de monedas recolectadas'
            },
            achievements: {
              type: 'array',
              items: {
                type: 'string'
              },
              description: 'Logros desbloqueados'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              description: 'Tipo de error'
            },
            message: {
              type: 'string',
              description: 'Mensaje descriptivo del error'
            }
          }
        }
      }
    },
    tags: [
      {
        name: 'Autenticación',
        description: 'Endpoints para registro y login de jugadores'
      },
      {
        name: 'Perfil',
        description: 'Gestión del perfil del jugador'
      },
      {
        name: 'Sesiones de Juego',
        description: 'Gestión de sesiones de juego activas'
      },
      {
        name: 'Estadísticas',
        description: 'Estadísticas del jugador y globales'
      },
      {
        name: 'Eventos',
        description: 'Registro de eventos durante el juego'
      }
    ]
  },
  apis: ['./routes/*.js', './server.js']
};

const specs = swaggerJsdoc(options);

module.exports = specs; 