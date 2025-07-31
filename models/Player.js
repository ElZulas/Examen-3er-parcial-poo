const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const playerSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'El nombre de usuario es requerido'],
    unique: true,
    trim: true,
    minlength: [3, 'El nombre de usuario debe tener al menos 3 caracteres'],
    maxlength: [20, 'El nombre de usuario no puede exceder 20 caracteres']
  },
  email: {
    type: String,
    required: [true, 'El email es requerido'],
    unique: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Email inválido']
  },
  password: {
    type: String,
    required: [true, 'La contraseña es requerida'],
    minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
    select: false
  },
  avatar: {
    type: String,
    default: 'default-avatar.png'
  },
  level: {
    type: Number,
    default: 1
  },
  experience: {
    type: Number,
    default: 0
  },
  coins: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: Date.now
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
playerSchema.index({ username: 1 });
playerSchema.index({ email: 1 });
playerSchema.index({ level: -1 });
playerSchema.index({ experience: -1 });

// Middleware para encriptar contraseña antes de guardar
playerSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Método para comparar contraseñas
playerSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Método para obtener datos públicos del jugador
playerSchema.methods.getPublicProfile = function() {
  return {
    id: this._id,
    username: this.username,
    avatar: this.avatar,
    level: this.level,
    experience: this.experience,
    coins: this.coins,
    lastLogin: this.lastLogin,
    createdAt: this.createdAt
  };
};

// Método para agregar experiencia
playerSchema.methods.addExperience = function(exp) {
  this.experience += exp;
  
  // Calcular si sube de nivel (100 exp por nivel)
  const newLevel = Math.floor(this.experience / 100) + 1;
  if (newLevel > this.level) {
    this.level = newLevel;
    return { leveledUp: true, newLevel: this.level };
  }
  
  return { leveledUp: false };
};

// Método para agregar monedas
playerSchema.methods.addCoins = function(amount) {
  this.coins += amount;
  return this.coins;
};

module.exports = mongoose.model('Player', playerSchema); 