// Configuración para BlobVers Web
const WebConfig = {
    // URLs de la API
    API_BASE_URL: 'https://blobvers-api.onrender.com/api', // ✅ URL correcta de Render
    
    // Configuración del juego
    GAME_WIDTH: 800,
    GAME_HEIGHT: 600,
    
    // Configuración del LÖVE Web Player
    LÖVE_WEBPLAYER_URL: 'https://love2d.org/webplayer',
    
    // Configuración de la interfaz
    UI: {
        loadingText: 'Cargando BlobVers...',
        errorText: 'Error al cargar el juego',
        instructions: [
            'Movimiento: Flechas o WASD',
            'Disparo: Clic del mouse',
            'Objetivo: Sobrevive el mayor tiempo posible',
            'Jefes: Aparecen cada 3 rondas'
        ]
    },
    
    // Funciones de utilidad
    utils: {
        // Verificar si la API está disponible
        async checkAPI() {
            try {
                const response = await fetch(`${WebConfig.API_BASE_URL}/health`);
                return response.ok;
            } catch (error) {
                console.warn('API no disponible:', error);
                return false;
            }
        },
        
        // Mostrar mensaje de estado
        showMessage(message, type = 'info') {
            const messageDiv = document.getElementById('status-message');
            if (messageDiv) {
                messageDiv.textContent = message;
                messageDiv.className = `message ${type}`;
                messageDiv.style.display = 'block';
                
                setTimeout(() => {
                    messageDiv.style.display = 'none';
                }, 3000);
            }
        },
        
        // Configurar comunicación con el iframe del juego
        setupGameCommunication() {
            const iframe = document.getElementById('game-frame');
            if (iframe) {
                // Escuchar mensajes del juego
                window.addEventListener('message', (event) => {
                    if (event.origin !== WebConfig.LÖVE_WEBPLAYER_URL) return;
                    
                    const { type, data } = event.data;
                    
                    switch (type) {
                        case 'GAME_LOADED':
                            WebConfig.utils.showMessage('¡Juego cargado exitosamente!', 'success');
                            break;
                            
                        case 'GAME_ERROR':
                            WebConfig.utils.showMessage('Error en el juego: ' + data.error, 'error');
                            break;
                            
                        case 'SAVE_STATS':
                            WebConfig.utils.saveGameStats(data);
                            break;
                            
                        case 'LOGIN_REQUEST':
                            WebConfig.utils.handleLogin(data);
                            break;
                    }
                });
            }
        },
        
        // Guardar estadísticas del juego
        async saveGameStats(stats) {
            try {
                const response = await fetch(`${WebConfig.API_BASE_URL}/stats/save`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(stats)
                });
                
                if (response.ok) {
                    WebConfig.utils.showMessage('Estadísticas guardadas exitosamente', 'success');
                } else {
                    WebConfig.utils.showMessage('Error al guardar estadísticas', 'error');
                }
            } catch (error) {
                console.error('Error guardando estadísticas:', error);
                WebConfig.utils.showMessage('Error de conexión con la API', 'error');
            }
        },
        
        // Manejar login
        async handleLogin(loginData) {
            try {
                const response = await fetch(`${WebConfig.API_BASE_URL}/auth/login`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(loginData)
                });
                
                if (response.ok) {
                    const userData = await response.json();
                    WebConfig.utils.showMessage('Login exitoso: ' + userData.username, 'success');
                    
                    // Enviar datos de usuario al juego
                    const iframe = document.getElementById('game-frame');
                    if (iframe && iframe.contentWindow) {
                        iframe.contentWindow.postMessage({
                            type: 'LOGIN_SUCCESS',
                            data: userData
                        }, WebConfig.LÖVE_WEBPLAYER_URL);
                    }
                } else {
                    WebConfig.utils.showMessage('Error en el login', 'error');
                }
            } catch (error) {
                console.error('Error en login:', error);
                WebConfig.utils.showMessage('Error de conexión', 'error');
            }
        }
    },
    
    // Inicialización
    init() {
        console.log('Inicializando BlobVers Web...');
        
        // Verificar API al cargar
        WebConfig.utils.checkAPI().then(apiAvailable => {
            if (apiAvailable) {
                console.log('API disponible');
            } else {
                console.warn('API no disponible - algunas funciones estarán limitadas');
            }
        });
        
        // Configurar comunicación del juego
        WebConfig.utils.setupGameCommunication();
        
        // Configurar eventos de la página
        this.setupPageEvents();
    },
    
    // Configurar eventos de la página
    setupPageEvents() {
        // Manejar errores de carga del iframe
        const iframe = document.getElementById('game-frame');
        if (iframe) {
            iframe.addEventListener('error', () => {
                WebConfig.utils.showMessage('Error al cargar el reproductor de LÖVE', 'error');
            });
            
            iframe.addEventListener('load', () => {
                WebConfig.utils.showMessage('Reproductor de LÖVE cargado', 'success');
            });
        }
        
        // Manejar errores generales
        window.addEventListener('error', (event) => {
            console.error('Error en la página:', event.error);
            WebConfig.utils.showMessage('Error en la aplicación', 'error');
        });
    }
};

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
    WebConfig.init();
});

// Exportar para uso global
window.WebConfig = WebConfig; 