# 🔧 Configuración de GitHub Pages para BlobVers

## 🎯 Objetivo
Activar GitHub Pages para que tu juego funcione en LÖVE.org

## 📋 Pasos para activar GitHub Pages:

### 1. Ve a tu repositorio en GitHub
```
https://github.com/ElZulas/Examen-3er-parcial-poo
```

### 2. Ve a Settings
- Haz clic en la pestaña "Settings" en la parte superior

### 3. Busca "Pages"
- En el menú lateral izquierdo, busca "Pages"
- O ve directamente a: https://github.com/ElZulas/Examen-3er-parcial-poo/settings/pages

### 4. Configura GitHub Pages
- **Source**: Selecciona "Deploy from a branch"
- **Branch**: Selecciona "main"
- **Folder**: Deja en "/ (root)"
- Haz clic en "Save"

### 5. Espera la activación
- GitHub tardará unos minutos en activar tu sitio
- Verás un mensaje verde que dice "Your site is live at https://elzulas.github.io/Examen-3er-parcial-poo/"

## 🎮 URLs que funcionarán:

### ✅ Link principal (después de activar GitHub Pages):
```
https://love2d.org/webplayer?game=https://elzulas.github.io/Examen-3er-parcial-poo/blobvers.love
```

### ✅ Link alternativo (siempre funciona):
```
https://love2d.org/webplayer?game=https://raw.githubusercontent.com/ElZulas/Examen-3er-parcial-poo/main/blobvers.love
```

## 🔍 Verificar que funciona:

1. **Activa GitHub Pages** siguiendo los pasos arriba
2. **Espera 5-10 minutos** para que se active
3. **Prueba el link**: https://love2d.org/webplayer?game=https://elzulas.github.io/Examen-3er-parcial-poo/blobvers.love
4. **¡Tu juego debería cargar!**

## 🚨 Si no funciona:

### Opción 1: Usar GitHub Raw
```
https://love2d.org/webplayer?game=https://raw.githubusercontent.com/ElZulas/Examen-3er-parcial-poo/main/blobvers.love
```

### Opción 2: Verificar que el archivo existe
- Ve a: https://github.com/ElZulas/Examen-3er-parcial-poo/blob/main/blobvers.love
- Deberías ver el archivo ahí

### Opción 3: Forzar actualización
- Haz un pequeño cambio en cualquier archivo
- Haz commit y push
- Esto fuerza a GitHub a regenerar el sitio

## 📞 ¿Necesitas ayuda?

Si GitHub Pages no se activa después de seguir estos pasos:
1. Verifica que estés en la rama "main"
2. Verifica que el archivo `blobvers.love` esté en la raíz del repositorio
3. Espera más tiempo (a veces tarda hasta 15 minutos)

## 🎉 ¡Listo!

Una vez que GitHub Pages esté activo, tu juego funcionará perfectamente en LÖVE.org y podrás compartir el link con cualquiera. 