-- login_system.lua
local http = require("http")
local json = require("json")

local loginSystem = {
    currentUser = nil,
    isLoggedIn = false,
    loginScene = "login", -- "login", "register", "main"
    inputFields = {
        username = {text = "", active = false, x = 0, y = 0, w = 300, h = 40},
        password = {text = "", active = false, x = 0, y = 0, w = 300, h = 40},
        confirmPassword = {text = "", active = false, x = 0, y = 0, w = 300, h = 40}
    },
    buttons = {
        login = {text = "Iniciar Sesión", x = 0, y = 0, w = 140, h = 40, active = true},
        register = {text = "Registrarse", x = 0, y = 0, w = 140, h = 40, active = true},
        switchToRegister = {text = "¿No tienes cuenta? Regístrate", x = 0, y = 0, w = 200, h = 30, active = true},
        switchToLogin = {text = "¿Ya tienes cuenta? Inicia sesión", x = 0, y = 0, w = 200, h = 30, active = true}
    },
    message = "",
    messageTimer = 0,
    messageColor = {1, 1, 1, 1}
}

-- API base URL
local API_BASE = "http://localhost:3000/api"

function loginSystem:init()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Posicionar campos de entrada
    self.inputFields.username.x = winW/2 - 150
    self.inputFields.username.y = winH/2 - 80
    self.inputFields.password.x = winW/2 - 150
    self.inputFields.password.y = winH/2 - 20
    self.inputFields.confirmPassword.x = winW/2 - 150
    self.inputFields.confirmPassword.y = winH/2 + 40
    
    -- Posicionar botones
    self.buttons.login.x = winW/2 - 160
    self.buttons.login.y = winH/2 + 100
    self.buttons.register.x = winW/2 + 20
    self.buttons.register.y = winH/2 + 100
    self.buttons.switchToRegister.x = winW/2 - 100
    self.buttons.switchToRegister.y = winH/2 + 160
    self.buttons.switchToLogin.x = winW/2 - 100
    self.buttons.switchToLogin.y = winH/2 + 160
end

function loginSystem:update(dt)
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.message = ""
        end
    end
end

function loginSystem:draw()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, winW, winH)
    
    -- Título
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    local title = self.loginScene == "login" and "Iniciar Sesión" or "Registrarse"
    love.graphics.printf(title, 0, winH/2 - 150, winW, "center")
    
    -- Campos de entrada
    for name, field in pairs(self.inputFields) do
        if (self.loginScene == "login" and (name == "username" or name == "password")) or
           (self.loginScene == "register" and (name == "username" or name == "password" or name == "confirmPassword")) then
            -- Fondo del campo
            love.graphics.setColor(0.2, 0.2, 0.3, 1)
            love.graphics.rectangle("fill", field.x, field.y, field.w, field.h, 5, 5)
            
            -- Borde
            if field.active then
                love.graphics.setColor(0.4, 0.6, 1, 1)
            else
                love.graphics.setColor(0.3, 0.3, 0.4, 1)
            end
            love.graphics.rectangle("line", field.x, field.y, field.w, field.h, 5, 5)
            
            -- Texto
            love.graphics.setColor(1, 1, 1, 1)
            local displayText = field.text
            if name == "password" or name == "confirmPassword" then
                displayText = string.rep("*", #field.text)
            end
            love.graphics.printf(displayText, field.x + 10, field.y + 10, field.w - 20, "left")
            
            -- Placeholder
            if field.text == "" then
                love.graphics.setColor(0.6, 0.6, 0.6, 1)
                local placeholder = name == "username" and "Usuario" or 
                                 name == "password" and "Contraseña" or "Confirmar contraseña"
                love.graphics.printf(placeholder, field.x + 10, field.y + 10, field.w - 20, "left")
            end
        end
    end
    
    -- Botones
    for name, button in pairs(self.buttons) do
        if (self.loginScene == "login" and (name == "login" or name == "switchToRegister")) or
           (self.loginScene == "register" and (name == "register" or name == "switchToLogin")) then
            -- Fondo del botón
            if button.active then
                love.graphics.setColor(0.3, 0.5, 0.8, 1)
            else
                love.graphics.setColor(0.2, 0.2, 0.3, 1)
            end
            love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 5, 5)
            
            -- Borde
            love.graphics.setColor(0.4, 0.6, 1, 1)
            love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 5, 5)
            
            -- Texto
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(button.text, button.x, button.y + 10, button.w, "center")
        end
    end
    
    -- Mensaje
    if self.message ~= "" then
        love.graphics.setColor(self.messageColor[1], self.messageColor[2], self.messageColor[3], self.messageColor[4])
        love.graphics.printf(self.message, 0, winH/2 + 200, winW, "center")
    end
end

function loginSystem:mousepressed(x, y, button)
    if button == 1 then
        -- Verificar clics en campos de entrada
        for name, field in pairs(self.inputFields) do
            if (self.loginScene == "login" and (name == "username" or name == "password")) or
               (self.loginScene == "register" and (name == "username" or name == "password" or name == "confirmPassword")) then
                if x >= field.x and x <= field.x + field.w and y >= field.y and y <= field.y + field.h then
                    -- Desactivar todos los campos
                    for _, f in pairs(self.inputFields) do
                        f.active = false
                    end
                    field.active = true
                    return
                end
            end
        end
        
        -- Verificar clics en botones
        for name, button in pairs(self.buttons) do
            if (self.loginScene == "login" and (name == "login" or name == "switchToRegister")) or
               (self.loginScene == "register" and (name == "register" or name == "switchToLogin")) then
                if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
                    if name == "login" then
                        self:attemptLogin()
                    elseif name == "register" then
                        self:attemptRegister()
                    elseif name == "switchToRegister" then
                        self.loginScene = "register"
                        self:clearFields()
                    elseif name == "switchToLogin" then
                        self.loginScene = "login"
                        self:clearFields()
                    end
                    return
                end
            end
        end
    end
end

function loginSystem:keypressed(key)
    if key == "tab" then
        -- Cambiar entre campos
        local fields = {}
        if self.loginScene == "login" then
            fields = {self.inputFields.username, self.inputFields.password}
        else
            fields = {self.inputFields.username, self.inputFields.password, self.inputFields.confirmPassword}
        end
        
        local activeField = nil
        for i, field in ipairs(fields) do
            if field.active then
                activeField = i
                break
            end
        end
        
        if activeField then
            fields[activeField].active = false
            local nextField = activeField % #fields + 1
            fields[nextField].active = true
        else
            fields[1].active = true
        end
    elseif key == "return" then
        if self.loginScene == "login" then
            self:attemptLogin()
        else
            self:attemptRegister()
        end
    elseif key == "escape" then
        -- Desactivar todos los campos
        for _, field in pairs(self.inputFields) do
            field.active = false
        end
    end
end

function loginSystem:textinput(text)
    -- Agregar texto al campo activo
    for _, field in pairs(self.inputFields) do
        if field.active then
            field.text = field.text .. text
            break
        end
    end
end

function loginSystem:keyreleased(key)
    if key == "backspace" then
        -- Eliminar último carácter del campo activo
        for _, field in pairs(self.inputFields) do
            if field.active then
                if #field.text > 0 then
                    field.text = string.sub(field.text, 1, #field.text - 1)
                end
                break
            end
        end
    end
end

function loginSystem:clearFields()
    for _, field in pairs(self.inputFields) do
        field.text = ""
        field.active = false
    end
end

function loginSystem:showMessage(text, color, duration)
    self.message = text
    self.messageColor = color or {1, 1, 1, 1}
    self.messageTimer = duration or 3
end

function loginSystem:attemptLogin()
    local username = self.inputFields.username.text
    local password = self.inputFields.password.text
    
    if username == "" or password == "" then
        self:showMessage("Por favor completa todos los campos", {1, 0.5, 0.5, 1})
        return
    end
    
    -- Simular login exitoso por ahora
    self.currentUser = {
        username = username,
        id = "user_" .. math.random(1000, 9999)
    }
    self.isLoggedIn = true
    self:showMessage("¡Bienvenido " .. username .. "!", {0.5, 1, 0.5, 1})
    
    -- Cambiar a la escena del juego
    return "title"
end

function loginSystem:attemptRegister()
    local username = self.inputFields.username.text
    local password = self.inputFields.password.text
    local confirmPassword = self.inputFields.confirmPassword.text
    
    if username == "" or password == "" or confirmPassword == "" then
        self:showMessage("Por favor completa todos los campos", {1, 0.5, 0.5, 1})
        return
    end
    
    if password ~= confirmPassword then
        self:showMessage("Las contraseñas no coinciden", {1, 0.5, 0.5, 1})
        return
    end
    
    if #password < 6 then
        self:showMessage("La contraseña debe tener al menos 6 caracteres", {1, 0.5, 0.5, 1})
        return
    end
    
    -- Simular registro exitoso por ahora
    self.currentUser = {
        username = username,
        id = "user_" .. math.random(1000, 9999)
    }
    self.isLoggedIn = true
    self:showMessage("¡Cuenta creada exitosamente!", {0.5, 1, 0.5, 1})
    
    -- Cambiar a la escena del juego
    return "title"
end

function loginSystem:saveGameStats(stats)
    if not self.isLoggedIn or not self.currentUser then
        return false
    end
    
    -- Enviar estadísticas a la API
    local success, response = pcall(function()
        local http = require("http")
        local json = require("json")
        
        local url = API_BASE .. "/stats/save"
        local headers = {
            ["Content-Type"] = "application/json"
        }
        
        local body = json.encode(stats)
        
        local response = http.request("POST", url, headers, body)
        
        if response and response.status == 200 then
            print("Estadísticas guardadas exitosamente en MongoDB")
            return true
        else
            print("Error guardando estadísticas: " .. (response and response.body or "Sin respuesta"))
            return false
        end
    end)
    
    if not success then
        print("Error en la conexión con la API: " .. tostring(response))
        return false
    end
    
    return response
end

function loginSystem:loadGameStats()
    if not self.isLoggedIn or not self.currentUser then
        return nil
    end
    
    -- Aquí se cargarían las estadísticas desde la API
    -- Por ahora retornamos estadísticas vacías
    return {
        highScore = 0,
        totalGames = 0,
        totalTime = 0,
        bestRound = 0
    }
end

return loginSystem 