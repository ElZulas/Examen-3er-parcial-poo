# 🚀 Guía de Deployment en Render - Paso a Paso

## 📋 Preparación

### 1. Verificar archivos
Asegúrate de que tienes estos archivos:
- ✅ `public/blobvers.love` (archivo del juego)
- ✅ `public/index.html` (página web)
- ✅ `public/web_config.js` (configuración)
- ✅ `render.yaml` (configuración de Render)
- ✅ `server.js` (API Node.js)
- ✅ `package.json` (dependencias)

### 2. Crear repositorio en GitHub
```bash
# En tu terminal:
git init
git add .
git commit -m "Initial commit: BlobVers game with API"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/blobvers-game.git
git push -u origin main
```

## 🌐 Deployment en Render

### Paso 1: Crear cuenta en Render
1. Ve a [render.com](https://render.com)
2. Regístrate con tu cuenta de GitHub
3. Confirma tu email

### Paso 2: Desplegar la API
1. **Crear nuevo servicio**:
   - Click en "New +"
   - Selecciona "Web Service"
   - Conecta tu repositorio de GitHub

2. **Configurar API**:
   - **Name**: `blobvers-api`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

3. **Variables de entorno**:
   - `NODE_ENV`: `production`
   - `PORT`: `3000`
   - `MONGODB_URI`: `mongodb+srv://mufasaelrey13:T1pAXTfRafTsHenc@cluster0.fpufnee.mongodb.net/blobvers?retryWrites=true&w=majority&appName=Cluster0`
   - `JWT_SECRET`: `tu_jwt_secret_super_seguro_aqui`

4. **Desplegar**:
   - Click en "Create Web Service"
   - Espera a que termine el deployment

### Paso 3: Desplegar el Juego Web
1. **Crear nuevo servicio**:
   - Click en "New +"
   - Selecciona "Static Site"
   - Conecta el mismo repositorio

2. **Configurar sitio estático**:
   - **Name**: `blobvers-game`
   - **Build Command**: `echo "No build needed"`
   - **Publish Directory**: `public`

3. **Desplegar**:
   - Click en "Create Static Site"
   - Espera a que termine el deployment

## 🔧 Configuración Post-Deployment

### Paso 4: Actualizar URLs
1. **Obtener URLs de Render**:
   - API: `https://blobvers-api.onrender.com`
   - Juego: `https://blobvers-game.onrender.com`

2. **Actualizar configuración**:
   - Edita `public/web_config.js`
   - Cambia `API_BASE_URL` a tu URL de la API

3. **Redeploy**:
   - Sube los cambios a GitHub
   - Render actualizará automáticamente

## 🧪 Pruebas

### Paso 5: Verificar funcionamiento
1. **Probar API**:
   ```
   https://blobvers-api.onrender.com/api-docs
   ```

2. **Probar juego**:
   ```
   https://blobvers-game.onrender.com
   ```

3. **Verificar conexión**:
   - Abre la consola del navegador (F12)
   - Verifica que no hay errores
   - Prueba el login y guardado de estadísticas

## 🐛 Solución de Problemas

### Error: "API no responde"
1. Verifica las variables de entorno en Render
2. Revisa los logs en Render Dashboard
3. Confirma que MongoDB Atlas está funcionando

### Error: "Juego no carga"
1. Verifica que `blobvers.love` existe en `public/`
2. Revisa la consola del navegador
3. Confirma que el LÖVE Web Player está disponible

### Error: "CORS"
1. Verifica que la URL de la API es correcta
2. Confirma que el servidor está configurado para CORS
3. Revisa los logs de la API

## 📱 URLs Finales

Una vez desplegado, tendrás:

- **🎮 Juego Web**: `https://blobvers-game.onrender.com`
- **🔧 API**: `https://blobvers-api.onrender.com`
- **📚 Swagger**: `https://blobvers-api.onrender.com/api-docs`

## 🎉 ¡Listo!

Tu juego LÖVE ahora está disponible en la web con:
- ✅ Sistema de login/registro
- ✅ Guardado de estadísticas en MongoDB
- ✅ API completa con Swagger
- ✅ Diseño responsive
- ✅ Funciona en móviles y desktop

¡Los jugadores pueden acceder desde cualquier dispositivo con un navegador web! 