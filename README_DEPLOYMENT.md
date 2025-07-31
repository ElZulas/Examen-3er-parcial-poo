# 🚀 Guía de Deployment Web - BlobVers

## 📋 Resumen

Esta guía te ayudará a desplegar tu juego LÖVE **BlobVers** en la web usando **Render** y el **LÖVE Web Player**.

## 🎯 ¿Qué logramos?

- ✅ **Juego web**: Tu juego Lua funcionando en navegadores
- ✅ **API integrada**: Conexión con tu servidor Node.js/MongoDB
- ✅ **Login system**: Sistema de autenticación web
- ✅ **Estadísticas**: Guardado de puntuaciones en MongoDB Atlas
- ✅ **Diseño responsive**: Funciona en móviles y desktop

## 📁 Estructura del proyecto

```
blobvers-newlua-copia/
├── public/                    # Archivos para web
│   ├── index.html            # Página principal
│   └── blobvers.love         # Archivo del juego
├── render.yaml               # Configuración de Render
├── create_love_file.bat      # Script para crear .love
├── main.lua                  # Juego principal
├── login_system.lua          # Sistema de login
├── server.js                 # API Node.js
└── ... (otros archivos)
```

## 🛠️ Pasos para deployment

### 1. Crear archivo .love

```bash
# En Windows, ejecuta:
create_love_file.bat
```

Esto creará `public/blobvers.love` con todos los archivos necesarios.

### 2. Configurar Render

1. **Crear cuenta en Render**:
   - Ve a [render.com](https://render.com)
   - Regístrate con tu GitHub

2. **Conectar repositorio**:
   - Crea un repositorio en GitHub
   - Sube tu código
   - Conecta el repo a Render

3. **Configurar deployment**:
   - Render detectará automáticamente `render.yaml`
   - Desplegará como sitio estático

### 3. Variables de entorno (Opcional)

Si quieres cambiar la URL de la API:

```yaml
# En render.yaml, agregar:
envVars:
  - key: API_URL
    value: https://tu-api-render.onrender.com
```

## 🌐 URLs importantes

- **Juego web**: `https://tu-app.onrender.com`
- **API**: `https://tu-api-render.onrender.com`
- **Swagger**: `https://tu-api-render.onrender.com/api-docs`

## 🔧 Personalización

### Cambiar colores del tema

Edita `public/index.html`:

```css
body {
    background: linear-gradient(135deg, #tu-color1 0%, #tu-color2 100%);
}
```

### Cambiar tamaño del juego

```html
<iframe 
    width="800"    <!-- Cambiar ancho -->
    height="600"   <!-- Cambiar alto -->
    ...>
```

## 🐛 Solución de problemas

### Error: "No se puede cargar el juego"

1. **Verificar archivo .love**:
   ```bash
   # El archivo debe existir y ser válido
   ls -la public/blobvers.love
   ```

2. **Verificar conexión a internet**:
   - El LÖVE Web Player requiere conexión
   - Verificar firewall/proxy

### Error: "API no responde"

1. **Verificar servidor API**:
   ```bash
   curl https://tu-api-render.onrender.com/api/health
   ```

2. **Verificar variables de entorno**:
   - Asegúrate de que la URL de la API sea correcta

## 📱 Compatibilidad

- ✅ **Chrome/Edge**: Soporte completo
- ✅ **Firefox**: Soporte completo  
- ✅ **Safari**: Soporte completo
- ✅ **Móviles**: Responsive design
- ⚠️ **Internet Explorer**: No soportado

## 🎮 Características del juego web

- **Login/Register**: Sistema completo de autenticación
- **Estadísticas**: Guardado automático en MongoDB
- **Controles**: Teclado y mouse
- **Puntuaciones**: Sistema de high scores
- **Responsive**: Adaptable a diferentes pantallas

## 🔄 Actualizaciones

Para actualizar el juego:

1. Modifica los archivos Lua
2. Ejecuta `create_love_file.bat`
3. Sube los cambios a GitHub
4. Render desplegará automáticamente

## 📞 Soporte

Si tienes problemas:

1. Verifica los logs en Render Dashboard
2. Revisa la consola del navegador (F12)
3. Verifica que el archivo .love sea válido
4. Confirma que la API esté funcionando

## 🎉 ¡Listo!

Una vez desplegado, tu juego estará disponible en:
`https://tu-app.onrender.com`

¡Los jugadores podrán acceder desde cualquier dispositivo con un navegador web! 