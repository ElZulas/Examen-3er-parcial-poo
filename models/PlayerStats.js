const mongoose = require('mongoose');

const playerStatsSchema = new mongoose.Schema({
  playerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Player',
    required: [true, 'El ID del jugador es requerido'],
    unique: true
  },
  // Estadísticas generales
  totalGamesPlayed: {
    type: Number,
    default: 0
  },
  totalTimePlayed: {
    type: Number, // en segundos
    default: 0
  },
  totalScore: {
    type: Number,
    default: 0
  },
  highestScore: {
    type: Number,
    default: 0
  },
  averageScore: {
    type: Number,
    default: 0
  },
  
  // Estadísticas de combate
  totalEnemiesKilled: {
    type: Number,
    default: 0
  },
  totalBossesKilled: {
    type: Number,
    default: 0
  },
  totalCoinsCollected: {
    type: Number,
    default: 0
  },
  totalRoundsCompleted: {
    type: Number,
    default: 0
  },
  bestRound: {
    type: Number,
    default: 0
  },
  
  // Estadísticas por tipo de enemigo
  enemiesKilledByType: {
    bomber: { type: Number, default: 0 },
    blader: { type: Number, default: 0 },
    archer: { type: Number, default: 0 }
  },
  
  // Estadísticas por tipo de jefe
  bossesKilledByType: {
    shooter: { type: Number, default: 0 },
    swordsman: { type: Number, default: 0 },
    summoner: { type: Number, default: 0 }
  },
  
  // Estadísticas de armas
  weaponsUsed: {
    basic: {
      timesUsed: { type: Number, default: 0 },
      totalAmmoUsed: { type: Number, default: 0 },
      totalKills: { type: Number, default: 0 }
    },
    double: {
      timesUsed: { type: Number, default: 0 },
      totalAmmoUsed: { type: Number, default: 0 },
      totalKills: { type: Number, default: 0 }
    }
  },
  
  // Estadísticas de items
  itemsUsed: {
    mult4: {
      timesUsed: { type: Number, default: 0 },
      totalBonusScore: { type: Number, default: 0 }
    }
  },
  
  // Logros y records
  achievements: [{
    id: String,
    name: String,
    description: String,
    unlockedAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Fechas importantes
  firstGameDate: {
    type: Date
  },
  lastGameDate: {
    type: Date
  },
  
  // Estadísticas de tiempo
  averageGameDuration: {
    type: Number, // en segundos
    default: 0
  },
  longestGameDuration: {
    type: Number, // en segundos
    default: 0
  },
  
  // Estadísticas de rendimiento
  killDeathRatio: {
    type: Number,
    default: 0
  },
  coinsPerMinute: {
    type: Number,
    default: 0
  },
  scorePerMinute: {
    type: Number,
    default: 0
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
playerStatsSchema.index({ playerId: 1 });
playerStatsSchema.index({ totalScore: -1 });
playerStatsSchema.index({ highestScore: -1 });
playerStatsSchema.index({ totalEnemiesKilled: -1 });

// Método para actualizar estadísticas después de una sesión
playerStatsSchema.methods.updateStatsFromSession = function(sessionStats) {
  // Actualizar estadísticas básicas
  this.totalGamesPlayed += 1;
  this.totalTimePlayed += sessionStats.duration;
  this.totalScore += sessionStats.score;
  this.totalEnemiesKilled += sessionStats.enemiesKilled;
  this.totalBossesKilled += sessionStats.bossesKilled;
  this.totalCoinsCollected += sessionStats.coinsCollected;
  this.totalRoundsCompleted += sessionStats.round;
  
  // Actualizar records
  if (sessionStats.score > this.highestScore) {
    this.highestScore = sessionStats.score;
  }
  
  if (sessionStats.round > this.bestRound) {
    this.bestRound = sessionStats.round;
  }
  
  if (sessionStats.duration > this.longestGameDuration) {
    this.longestGameDuration = sessionStats.duration;
  }
  
  // Actualizar fechas
  if (!this.firstGameDate) {
    this.firstGameDate = sessionStats.startTime;
  }
  this.lastGameDate = sessionStats.endTime;
  
  // Calcular promedios
  this.averageScore = Math.round(this.totalScore / this.totalGamesPlayed);
  this.averageGameDuration = Math.round(this.totalTimePlayed / this.totalGamesPlayed);
  
  // Calcular ratios
  if (this.totalTimePlayed > 0) {
    this.coinsPerMinute = Math.round((this.totalCoinsCollected / (this.totalTimePlayed / 60)) * 100) / 100;
    this.scorePerMinute = Math.round((this.totalScore / (this.totalTimePlayed / 60)) * 100) / 100;
  }
  
  this.updatedAt = new Date();
  return this;
};

// Método para agregar logro
playerStatsSchema.methods.addAchievement = function(achievement) {
  // Verificar si ya tiene el logro
  const hasAchievement = this.achievements.some(a => a.id === achievement.id);
  if (!hasAchievement) {
    this.achievements.push(achievement);
    this.updatedAt = new Date();
  }
  return this;
};

// Método para obtener estadísticas resumidas
playerStatsSchema.methods.getSummaryStats = function() {
  return {
    totalGamesPlayed: this.totalGamesPlayed,
    totalTimePlayed: this.totalTimePlayed,
    totalScore: this.totalScore,
    highestScore: this.highestScore,
    averageScore: this.averageScore,
    totalEnemiesKilled: this.totalEnemiesKilled,
    totalBossesKilled: this.totalBossesKilled,
    totalCoinsCollected: this.totalCoinsCollected,
    bestRound: this.bestRound,
    achievementsCount: this.achievements.length,
    averageGameDuration: this.averageGameDuration,
    coinsPerMinute: this.coinsPerMinute,
    scorePerMinute: this.scorePerMinute
  };
};

// Método para obtener estadísticas detalladas
playerStatsSchema.methods.getDetailedStats = function() {
  return {
    ...this.getSummaryStats(),
    enemiesKilledByType: this.enemiesKilledByType,
    bossesKilledByType: this.bossesKilledByType,
    weaponsUsed: this.weaponsUsed,
    itemsUsed: this.itemsUsed,
    achievements: this.achievements,
    firstGameDate: this.firstGameDate,
    lastGameDate: this.lastGameDate
  };
};

module.exports = mongoose.model('PlayerStats', playerStatsSchema); 