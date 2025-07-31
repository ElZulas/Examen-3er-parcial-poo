#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Configurando API de BlobVers...\n');

// Colores para la consola
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logStep(step, message) {
  console.log(`\n${colors.cyan}${step}${colors.reset} ${message}`);
}

function logSuccess(message) {
  console.log(`${colors.green}✅ ${message}${colors.reset}`);
}

function logError(message) {
  console.log(`${colors.red}❌ ${message}${colors.reset}`);
}

function logWarning(message) {
  console.log(`${colors.yellow}⚠️  ${message}${colors.reset}`);
}

// Verificar si Node.js está instalado
function checkNodeVersion() {
  try {
    const version = process.version;
    const major = parseInt(version.slice(1).split('.')[0]);
    
    if (major < 14) {
      logError('Node.js versión 14 o superior es requerida');
      log(`Versión actual: ${version}`, 'yellow');
      process.exit(1);
    }
    
    logSuccess(`Node.js ${version} detectado`);
    return true;
  } catch (error) {
    logError('Node.js no está instalado');
    process.exit(1);
  }
}

// Verificar si npm está disponible
function checkNpm() {
  try {
    execSync('npm --version', { stdio: 'pipe' });
    logSuccess('npm detectado');
    return true;
  } catch (error) {
    logError('npm no está disponible');
    process.exit(1);
  }
}

// Instalar dependencias
function installDependencies() {
  logStep('1', 'Instalando dependencias...');
  
  try {
    execSync('npm install', { stdio: 'inherit' });
    logSuccess('Dependencias instaladas correctamente');
    return true;
  } catch (error) {
    logError('Error instalando dependencias');
    return false;
  }
}

// Crear archivo de configuración
function createConfig() {
  logStep('2', 'Creando archivo de configuración...');
  
  const configContent = `PORT=3000
MONGODB_URI=mongodb://localhost:27017/blobvers
JWT_SECRET=blobvers_jwt_secret_${Date.now()}_${Math.random().toString(36).substr(2, 9)}
NODE_ENV=development`;

  try {
    fs.writeFileSync('config.env', configContent);
    logSuccess('Archivo config.env creado');
    return true;
  } catch (error) {
    logError('Error creando archivo de configuración');
    return false;
  }
}

// Verificar MongoDB
function checkMongoDB() {
  logStep('3', 'Verificando MongoDB...');
  
  try {
    execSync('mongod --version', { stdio: 'pipe' });
    logSuccess('MongoDB detectado localmente');
    return true;
  } catch (error) {
    logWarning('MongoDB no está instalado localmente');
    log('Puedes usar MongoDB Atlas en su lugar', 'blue');
    log('Visita: https://cloud.mongodb.com', 'blue');
    return false;
  }
}

// Crear directorios necesarios
function createDirectories() {
  logStep('4', 'Creando estructura de directorios...');
  
  const dirs = ['models', 'routes'];
  
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir);
      logSuccess(`Directorio ${dir} creado`);
    } else {
      logSuccess(`Directorio ${dir} ya existe`);
    }
  });
}

// Verificar archivos necesarios
function checkFiles() {
  logStep('5', 'Verificando archivos necesarios...');
  
  const requiredFiles = [
    'package.json',
    'server.js',
    'models/Player.js',
    'models/GameSession.js',
    'models/PlayerStats.js',
    'routes/player.js',
    'routes/game.js',
    'routes/stats.js',
    'api_client.lua'
  ];
  
  let allFilesExist = true;
  
  requiredFiles.forEach(file => {
    if (fs.existsSync(file)) {
      logSuccess(`${file} ✓`);
    } else {
      logError(`${file} ✗`);
      allFilesExist = false;
    }
  });
  
  return allFilesExist;
}

// Crear script de inicio
function createStartScript() {
  logStep('6', 'Creando scripts de inicio...');
  
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (!packageJson.scripts) {
    packageJson.scripts = {};
  }
  
  packageJson.scripts.start = 'node server.js';
  packageJson.scripts.dev = 'nodemon server.js';
  
  fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2));
  logSuccess('Scripts de inicio configurados');
}

// Crear archivo .gitignore
function createGitignore() {
  logStep('7', 'Creando .gitignore...');
  
  const gitignoreContent = `# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
config.env

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# nyc test coverage
.nyc_output

# Dependency directories
node_modules/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env

# API tokens
api_token.txt

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db`;

  try {
    fs.writeFileSync('.gitignore', gitignoreContent);
    logSuccess('.gitignore creado');
  } catch (error) {
    logError('Error creando .gitignore');
  }
}

// Mostrar instrucciones finales
function showFinalInstructions() {
  logStep('8', 'Configuración completada!');
  
  console.log(`\n${colors.bright}${colors.green}🎉 ¡API de BlobVers configurada exitosamente!${colors.reset}\n`);
  
  console.log(`${colors.cyan}📋 Próximos pasos:${colors.reset}`);
  console.log(`1. ${colors.yellow}Iniciar MongoDB:${colors.reset}`);
  console.log(`   # Windows`);
  console.log(`   "C:\\Program Files\\MongoDB\\Server\\6.0\\bin\\mongod.exe"`);
  console.log(`   # macOS/Linux`);
  console.log(`   mongod`);
  console.log(`\n2. ${colors.yellow}Iniciar la API:${colors.reset}`);
  console.log(`   npm run dev`);
  console.log(`\n3. ${colors.yellow}Probar la API:${colors.reset}`);
  console.log(`   curl http://localhost:3000`);
  console.log(`\n4. ${colors.yellow}Integrar con tu juego:${colors.reset}`);
  console.log(`   - Copia api_client.lua a tu proyecto LÖVE`);
  console.log(`   - Instala dependencias Lua: luarocks install luasocket lua-cjson`);
  console.log(`   - Sigue las instrucciones en README_API.md`);
  
  console.log(`\n${colors.magenta}📚 Documentación completa:${colors.reset}`);
  console.log(`   README_API.md`);
  
  console.log(`\n${colors.blue}🔗 Endpoints principales:${colors.reset}`);
  console.log(`   - GET  /                    - Estado de la API`);
  console.log(`   - POST /api/player/register  - Registrar jugador`);
  console.log(`   - POST /api/player/login     - Iniciar sesión`);
  console.log(`   - POST /api/game/start       - Iniciar partida`);
  console.log(`   - GET  /api/stats/player     - Estadísticas del jugador`);
  console.log(`   - GET  /api/stats/global     - Estadísticas globales`);
  
  console.log(`\n${colors.green}🚀 ¡Listo para desarrollar!${colors.reset}\n`);
}

// Función principal
function main() {
  console.log(`${colors.bright}${colors.blue}🎮 BlobVers API Setup${colors.reset}\n`);
  
  // Verificaciones iniciales
  checkNodeVersion();
  checkNpm();
  
  // Instalación y configuración
  if (!installDependencies()) {
    process.exit(1);
  }
  
  createConfig();
  checkMongoDB();
  createDirectories();
  
  if (!checkFiles()) {
    logError('Faltan archivos necesarios. Asegúrate de que todos los archivos estén presentes.');
    process.exit(1);
  }
  
  createStartScript();
  createGitignore();
  showFinalInstructions();
}

// Ejecutar setup
if (require.main === module) {
  main();
}

module.exports = {
  checkNodeVersion,
  checkNpm,
  installDependencies,
  createConfig,
  checkMongoDB,
  createDirectories,
  checkFiles,
  createStartScript,
  createGitignore
}; 