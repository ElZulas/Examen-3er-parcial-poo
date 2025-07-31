@echo off
echo Creando archivo .love para BlobVers...
echo.

REM Verificar si existe el directorio public
if not exist "public" mkdir public

REM Crear archivo ZIP primero
echo Comprimiendo archivos del juego...
powershell -command "Compress-Archive -Path 'main.lua', 'login_system.lua', 'blob.lua', 'imagenes' -DestinationPath 'public/blobvers.zip' -Force"

if %errorlevel% equ 0 (
    REM Renombrar .zip a .love
    echo Renombrando archivo...
    powershell -command "Rename-Item -Path 'public/blobvers.zip' -NewName 'blobvers.love'"
    
    if %errorlevel% equ 0 (
        echo.
        echo ✅ Archivo blobvers.love creado exitosamente en public/
        echo.
        echo 📁 Archivos incluidos:
        echo   - main.lua
        echo   - login_system.lua  
        echo   - blob.lua
        echo   - imagenes/
        echo.
        echo 🚀 Listo para desplegar en Render!
        echo.
        echo 📋 Próximos pasos:
        echo   1. Sube tu código a GitHub
        echo   2. Conecta el repo a Render
        echo   3. ¡Tu juego estará online!
    ) else (
        echo.
        echo ❌ Error al renombrar el archivo
    )
) else (
    echo.
    echo ❌ Error al crear el archivo ZIP
    echo.
    echo 💡 Asegúrate de que todos los archivos del juego estén en el directorio raíz
)

pause 