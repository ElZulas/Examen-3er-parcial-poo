const mongoose = require('mongoose');

const gameSessionSchema = new mongoose.Schema({
  playerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Player',
    required: [true, 'El ID del jugador es requerido']
  },
  sessionId: {
    type: String,
    required: [true, 'El ID de sesión es requerido'],
    unique: true
  },
  startTime: {
    type: Date,
    default: Date.now
  },
  endTime: {
    type: Date
  },
  duration: {
    type: Number, // en segundos
    default: 0
  },
  score: {
    type: Number,
    default: 0
  },
  round: {
    type: Number,
    default: 1
  },
  enemiesKilled: {
    type: Number,
    default: 0
  },
  bossesKilled: {
    type: Number,
    default: 0
  },
  coinsCollected: {
    type: Number,
    default: 0
  },
  weaponsUsed: [{
    weaponId: String,
    ammoUsed: Number,
    kills: Number
  }],
  itemsUsed: [{
    itemId: String,
    uses: Number
  }],
  gameState: {
    slime: {
      x: Number,
      y: Number,
      hp: Number,
      maxHp: Number
    },
    world: {
      width: Number,
      height: Number
    },
    enemies: [{
      type: String,
      x: Number,
      y: Number,
      hp: Number
    }],
    projectiles: [{
      x: Number,
      y: Number,
      damage: Number
    }]
  },
  isCompleted: {
    type: Boolean,
    default: false
  },
  isGameOver: {
    type: Boolean,
    default: false
  },
  deathReason: {
    type: String,
    enum: ['enemy', 'boss', 'timeout', 'manual', 'other'],
    default: 'other'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Índices para mejorar performance
gameSessionSchema.index({ playerId: 1, startTime: -1 });
gameSessionSchema.index({ sessionId: 1 });
gameSessionSchema.index({ score: -1 });
gameSessionSchema.index({ isCompleted: 1 });

// Método para finalizar la sesión
gameSessionSchema.methods.endSession = function() {
  this.endTime = new Date();
  this.duration = Math.floor((this.endTime - this.startTime) / 1000);
  this.isCompleted = true;
  return this;
};

// Método para actualizar el estado del juego
gameSessionSchema.methods.updateGameState = function(gameState) {
  this.gameState = gameState;
  this.updatedAt = new Date();
  return this;
};

// Método para agregar puntaje
gameSessionSchema.methods.addScore = function(points) {
  this.score += points;
  this.updatedAt = new Date();
  return this.score;
};

// Método para registrar enemigo eliminado
gameSessionSchema.methods.addEnemyKill = function(enemyType) {
  this.enemiesKilled += 1;
  this.updatedAt = new Date();
  return this.enemiesKilled;
};

// Método para registrar jefe eliminado
gameSessionSchema.methods.addBossKill = function() {
  this.bossesKilled += 1;
  this.updatedAt = new Date();
  return this.bossesKilled;
};

// Método para registrar moneda recolectada
gameSessionSchema.methods.addCoin = function() {
  this.coinsCollected += 1;
  this.updatedAt = new Date();
  return this.coinsCollected;
};

// Método para obtener estadísticas de la sesión
gameSessionSchema.methods.getSessionStats = function() {
  return {
    sessionId: this.sessionId,
    duration: this.duration,
    score: this.score,
    round: this.round,
    enemiesKilled: this.enemiesKilled,
    bossesKilled: this.bossesKilled,
    coinsCollected: this.coinsCollected,
    isCompleted: this.isCompleted,
    isGameOver: this.isGameOver,
    deathReason: this.deathReason,
    startTime: this.startTime,
    endTime: this.endTime
  };
};

module.exports = mongoose.model('GameSession', gameSessionSchema); 