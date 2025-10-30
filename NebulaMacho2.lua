-- ========================================
-- NEBULA SOFTWARE MENU - MACHO VERSION
-- ========================================

local dui = nil
local duiTexture = nil
local duiTxd = nil
local activeMenu = {}
local activeIndex = 1

-- Menu state
local menuInitialized = false
local keybindSetup = false
local menuOpenKey = 305

-- Player states
local playerModStates = {
    noclip = false,
    godMode = false,
    infiniteStamina = false
}

-- Global states
_G.keybindSetupActive = false
_G.inputRecordingActive = false
_G.inputBuffer = ""
_G.inputMaxLength = 100
_G.clientMenuShowing = false
_G.inputActive = false
_G.keyboardInput = ""
_G.isTyping = false

-- UI positioning
local uiPositions = {
    menu = { x = 0.5, y = 0.5 },
    notifications = { x = 0.5, y = 0.1 }
}

local menuOpacity = 1.0
local menuScale = 1.0

-- DUI texture names
local txdName = "NebulaSoftwareTxd"
local txtName = "NebulaSoftwareTex"

-- Notification system
local notificationQueue = {}
local lastNotificationTime = 0
local notificationCooldown = 100

local function sendOptimizedNotification(message, type)
    local currentTime = GetGameTimer()
    
    if currentTime - lastNotificationTime >= notificationCooldown then
        if dui then
            MachoSendDuiMessage(dui, json.encode({
                action = 'notify',
                message = message,
                type = type or 'info'
            }))
        end
        lastNotificationTime = currentTime
    else
        table.insert(notificationQueue, {message = message, type = type})
    end
end

-- Process notification queue
CreateThread(function()
    while true do
        if #notificationQueue > 0 and GetGameTimer() - lastNotificationTime >= notificationCooldown then
            local notification = table.remove(notificationQueue, 1)
            if dui then
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = notification.message,
                    type = notification.type
                }))
            end
            lastNotificationTime = GetGameTimer()
        end
        Wait(50)
    end
end)

-- Main initialization
CreateThread(function()
    -- Create DUI
    dui = MachoCreateDui("https://fiv-ay-sm.vercel.app/")
    
    if not dui then
        print("❌ Failed to create Macho DUI")
        return
    end
    
    print("✅ Macho DUI created successfully")
    
    -- Set theme
    MachoSendDuiMessage(dui, json.encode({
        action = 'setTheme',
        theme = 'blue'
    }))
    
    -- Set banner
    MachoSendDuiMessage(dui, json.encode({
        action = 'setBannerImage',
        url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif'
    }))
    
    -- Hide menu initially
    MachoSendDuiMessage(dui, json.encode({
        action = 'setMenuVisible',
        visible = false
    }))
    
    -- Show DUI
    MachoShowDui(dui)
    
    -- 🎯 DUI Message Handler (هذي الدالة تستقبل الرسائل من HTML)
    function dui_message_handler(raw)
        print('━━━━━━━━━━━━━━━━━━━━━━━━')
        print('🔵 DUI MESSAGE RECEIVED!')
        print('🔵 Raw data:', tostring(raw))
        
        local data
        if type(raw) == 'string' then
            local ok, decoded = pcall(json.decode, raw)
            if ok and decoded then 
                data = decoded
                print('✅ JSON decoded successfully')
            else
                print('❌ JSON decode failed')
                print('━━━━━━━━━━━━━━━━━━━━━━━━')
                return
            end
        else
            data = raw
        end

        if type(data) ~= 'table' then 
            print('❌ Data is not table, type:', type(data))
            print('━━━━━━━━━━━━━━━━━━━━━━━━')
            return 
        end

        local action = data.action or data.type
        print('🔵 Action:', tostring(action))
        print('🔵 Value:', tostring(data.value))
        print('🔵 Checked:', tostring(data.checked))

        -- 🎯 معالجة جميع الأحداث
        if action then
            print('✅ ═══════════════════════════')
            print('✅ WORK: ' .. tostring(action))
            print('✅ ═══════════════════════════')
            
            if action == 'noclip_toggle' then
                local isEnabled = data.checked
                local speed = tonumber(data.value) or 10.0
                print('🚁 Noclip:', isEnabled and 'ON' or 'OFF', '| Speed:', speed)
                playerModStates.noclip = isEnabled
                
                sendOptimizedNotification(
                    'Noclip: <span class="notification-key">' .. (isEnabled and 'ON' or 'OFF') .. '</span>',
                    'success'
                )
                
            elseif action == 'set_health' then
                local healthAmount = tonumber(data.value) or 200
                print('❤️ Setting health to:', healthAmount)
                SetEntityHealth(PlayerPedId(), math.floor(healthAmount))
                
                sendOptimizedNotification(
                    'Health set to <span class="notification-key">' .. math.floor(healthAmount) .. '</span>',
                    'success'
                )
                
            elseif action == 'add_armor' then
                local armorAmount = tonumber(data.value) or 0
                print('🛡️ Setting armor to:', armorAmount)
                SetPedArmour(PlayerPedId(), math.floor(armorAmount))
                
                sendOptimizedNotification(
                    'Armor set to <span class="notification-key">' .. math.floor(armorAmount) .. '</span>',
                    'success'
                )
                
            elseif action == 'god_mode' then
                local isEnabled = data.checked
                local mode = tostring(data.value) or 'Full'
                print('🛡️ God Mode:', isEnabled and 'ON' or 'OFF', '| Mode:', mode)
                playerModStates.godMode = isEnabled
                
                if isEnabled then
                    SetEntityInvincible(PlayerPedId(), true)
                else
                    SetEntityInvincible(PlayerPedId(), false)
                end
                
                sendOptimizedNotification(
                    'God Mode: <span class="notification-key">' .. (isEnabled and 'ON' or 'OFF') .. '</span> - ' .. mode,
                    'success'
                )
                
            elseif action == 'tp_to_waypoint' then
                print('📍 Teleporting to waypoint')
                -- Add teleport code here
                sendOptimizedNotification('Teleported to waypoint', 'success')
                
            elseif action == 'default_style' then
                -- 🎯 معالجة Default Style
                print('━━━━━━━━━━━━━━━━━━━━━━━━')
                print('✅ done')
                print('━━━━━━━━━━━━━━━━━━━━━━━━')
                
                sendOptimizedNotification(
                    'Default Style Applied',
                    'success'
                )
                
            elseif action == 'slide_mode' then
                local isEnabled = data.checked
                local speed = tonumber(data.value) or 10.0
                print('🛷 Slide mode:', isEnabled and 'ON' or 'OFF', '| Speed:', speed)
                sendOptimizedNotification('Slide mode: ' .. (isEnabled and 'ON' or 'OFF'), 'success')
                
            elseif action == 'solo_session' then
                local isEnabled = data.checked
                print('👤 Solo session:', isEnabled and 'ON' or 'OFF')
                sendOptimizedNotification('Solo session: ' .. (isEnabled and 'ON' or 'OFF'), 'success')
                
            elseif action == 'toggle_handcuff' then
                print('🔗 Toggle handcuff')
                sendOptimizedNotification('Handcuff toggled', 'success')
                
            elseif action == 'toggle_drag' then
                print('🚶 Toggle drag')
                sendOptimizedNotification('Drag toggled', 'success')
            end
        end
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━')
    end

    -- تسجيل الـ callback مع Macho
    if type(MachoRegisterDuiCallback) == 'function' then
        local success, err = pcall(function() 
            MachoRegisterDuiCallback(dui, dui_message_handler) 
        end)
        if success then
            print('✅ ═══════════════════════════')
            print('✅ DUI callback registered!')
            print('✅ ═══════════════════════════')
        else
            print('❌ Failed to register callback:', tostring(err))
        end
    else
        print('⚠️ MachoRegisterDuiCallback not available')
        print('⚠️ Using alternative method...')
        
        -- Alternative: Register command-based handler
        RegisterCommand('_dui_msg', function(source, args, rawCommand)
            if #args > 0 then
                local jsonStr = table.concat(args, ' ')
                print('🔵 Command received:', jsonStr)
                dui_message_handler(jsonStr)
            end
        end, false)
        
        print('✅ Alternative message handler registered via command')
    end
    
    -- Control disabling thread
    CreateThread(function()
        while true do
            if _G.isTyping or _G.inputActive then
                for i = 0, 360 do
                    DisableControlAction(0, i, true)
                    DisableControlAction(1, i, true)
                    DisableControlAction(2, i, true)
                end
            end
            Wait(0)
        end
    end)

    -- 🎯 Menu control thread (التحكم بالمنيو)
    CreateThread(function()
        local B_KEY = 29
        local BACKSPACE = 177
        local Q_KEY = 44
        local E_KEY = 38
        local ENTER = 18
        local LEFT_ARROW = 174
        local RIGHT_ARROW = 175
        local UP_ARROW = 172
        local DOWN_ARROW = 173

        print("✅ Menu control thread started")
        
        while true do
            -- Disable controls while typing
            if _G.isTyping or _G.inputActive then
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
            end

            -- Toggle menu with B key
            if IsControlJustPressed(0, B_KEY) and not _G.isTyping then
                print("🔑 B key pressed - toggling menu")
                _G.clientMenuShowing = not _G.clientMenuShowing
                if dui then
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'setMenuVisible',
                        visible = _G.clientMenuShowing
                    }))
                end
            end

            if _G.clientMenuShowing then
                -- Backspace navigation
                if IsControlJustPressed(0, BACKSPACE) and not _G.inputActive then
                    print("🔙 Backspace pressed")
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'navigateBack'
                        }))
                    end
                end

                -- Tab navigation (Q/E)
                if not _G.inputActive then
                    if IsControlJustPressed(0, Q_KEY) then
                        print("⬅️ Q pressed - tab left")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'navigateTab',
                                direction = 'left'
                            }))
                        end
                    elseif IsControlJustPressed(0, E_KEY) then
                        print("➡️ E pressed - tab right")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'navigateTab',
                                direction = 'right'
                            }))
                        end
                    end
                end

                -- 🎯 Enter key (تأكيد الاختيار)
                if not _G.inputActive then
                    if IsControlJustPressed(0, ENTER) then
                        print("━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("⚡ ENTER KEY PRESSED!")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                type = 'enter'
                            }))
                        end
                    end
                end

                -- Arrow key navigation
                if not _G.inputActive then
                    if IsControlJustPressed(0, UP_ARROW) then
                        print("⬆️ Up arrow")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                type = 'moveUp'
                            }))
                        end
                    elseif IsControlJustPressed(0, DOWN_ARROW) then
                        print("⬇️ Down arrow")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                type = 'moveDown'
                            }))
                        end
                    end
                    
                    -- Left/Right for sliders/combos
                    if IsControlJustPressed(0, LEFT_ARROW) then
                        print("⬅️ Left arrow")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                type = 'moveLeft'
                            }))
                        end
                    elseif IsControlJustPressed(0, RIGHT_ARROW) then
                        print("➡️ Right arrow")
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                type = 'moveRight'
                            }))
                        end
                    end
                end
            end
            Wait(0)
        end
    end)

    -- 🎯 Noclip thread
    CreateThread(function()
        while true do
            if playerModStates.noclip then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                FreezeEntityPosition(ped, true)
                SetEntityCollision(ped, false, false)
                SetEntityVisible(ped, false, false)
                
                -- Movement
                local speed = 10.0
                if IsControlPressed(0, 21) then speed = speed * 3 end -- Shift
                
                if IsControlPressed(0, 32) then -- W
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, speed * 0.1, 0.0)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
                if IsControlPressed(0, 33) then -- S
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, -speed * 0.1, 0.0)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
                if IsControlPressed(0, 34) then -- A
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, -speed * 0.1, 0.0, 0.0)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
                if IsControlPressed(0, 35) then -- D
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, speed * 0.1, 0.0, 0.0)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
                if IsControlPressed(0, 22) then -- Space
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, speed * 0.1)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
                if IsControlPressed(0, 36) then -- Ctrl
                    local newCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -speed * 0.1)
                    SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                end
            else
                local ped = PlayerPedId()
                FreezeEntityPosition(ped, false)
                SetEntityCollision(ped, true, true)
                SetEntityVisible(ped, true, false)
            end
            Wait(0)
        end
    end)

    -- Disable mouse in menu
    CreateThread(function()
        while true do
            if _G.clientMenuShowing then
                DisableControlAction(0, 1, true)  -- Mouse
                DisableControlAction(0, 2, true)  -- Mouse
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                
                EnableControlAction(0, 172, true) -- Up
                EnableControlAction(0, 173, true) -- Down
                EnableControlAction(0, 174, true) -- Left
                EnableControlAction(0, 175, true) -- Right
                EnableControlAction(0, 18, true)  -- Enter
                EnableControlAction(0, 177, true) -- Backspace
                EnableControlAction(0, 44, true)  -- Q
                EnableControlAction(0, 38, true)  -- E
            end
            Wait(0)
        end
    end)

    -- DUI Drawing thread
    CreateThread(function()
        while true do
            if duiTexture then
                local alpha = math.floor(255 * menuOpacity)
                DrawSprite(txdName, txtName, uiPositions.menu.x, uiPositions.menu.y, menuScale, menuScale, 0.0, 255, 255, 255, alpha)
            end
            Wait(_G.clientMenuShowing and 0 or 100)
        end
    end)
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ NEBULA MENU LOADED")
    print("✅ Press B to open menu")
    print("━━━━━━━━━━━━━━━━━━━━━━━━")
end)