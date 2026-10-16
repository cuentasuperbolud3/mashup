--[[
    Dragon Ball: Sparking! ZERO Abilities for GTA V Enhanced
    Mashup para Melty.gg
    
    Requiere: Script Hook V, Ultimate ASI Loader, Melty Framework
]]

-- Configuración de habilidades
local ABILITIES = {
    KAMEHAMEHA = {
        name = "Kamehameha",
        key = 69, -- KEY_E
        cooldown = 30000, -- 30 segundos en milisegundos
        lastUsed = 0,
        damage = 500,
        range = 100.0
    },
    INSTANT_TRANSMISSION = {
        name = "Instant Transmission",
        key = 81, -- KEY_Q
        cooldown = 15000,
        lastUsed = 0,
        range = 200.0
    },
    KI_BLAST = {
        name = "Ki Blast",
        key = -1, -- MOUSE_RIGHT (código especial)
        cooldown = 2000,
        lastUsed = 0,
        damage = 50,
        speed = 150.0
    }
}

-- Estado del jugador
local playerState = {
    isSuperSaiyan = false,
    kiLevel = 100,
    maxKi = 100,
    transformations = {
        superSaiyan = false,
        superSaiyan2 = false,
        superSaiyan3 = false
    }
}

-- Función para verificar si una habilidad está disponible
function CanUseAbility(ability)
    local currentTime = GetGameTimer()
    return (currentTime - ability.lastUsed) >= ability.cooldown
end

-- Función para cargar efectos visuales de Ki
function LoadKiEffects()
    RequestScriptAudioBank("AUDIO/MELTY_DBZ_SOUNDS", false)
    
    -- Cargar particle effects
    RequestNamedPtfxAsset("melty_dbz_fx")
    while not HasNamedPtfxAssetLoaded("melty_dbz_fx") do
        Wait(0)
    end
end

-- Función para ejecutar Kamehameha
function ExecuteKamehameha()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    
    -- Efecto visual
    UseParticleFxAsset("melty_dbz_fx")
    local ptfx = StartNetworkedParticleFxNonLoopedAtCoord(
        "kamehameha_beam",
        playerCoords.x + forwardVector.x * 2,
        playerCoords.y + forwardVector.y * 2,
        playerCoords.z,
        0.0, 0.0, GetEntityHeading(playerPed),
        2.0, false, false, false
    )
    
    -- Efecto de audio
    PlaySoundFromEntity(-1, "kamehameha_charge", playerPed, "MELTY_DBZ_SOUNDS", true, 0)
    
    -- Esperar carga
    Wait(1500)
    
    -- Daño en área
    local targetCoords = playerCoords + forwardVector * ABILITIES.KAMEHAMEHA.range
    AddExplosion(
        targetCoords.x, targetCoords.y, targetCoords.z,
        2, -- Tipo de explosión
        ABILITIES.KAMEHAMEHA.damage,
        true, -- Audible
        false, -- Invisible
        0.5 -- Camera shake
    )
    
    ABILITIES.KAMEHAMEHA.lastUsed = GetGameTimer()
end

-- Función para ejecutar Teletransportación
function ExecuteInstantTransmission()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Obtener posición del cursor o marcador
    local success, groundZ = GetGroundZFor_3dCoord(
        playerCoords.x, playerCoords.y, playerCoords.z + 10.0, false
    )
    
    if success then
        -- Efecto visual de teletransportación
        UseParticleFxAsset("melty_dbz_fx")
        StartNetworkedParticleFxNonLoopedOnPedBone(
            "instant_transmission",
            playerPed,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            1.0, false, false, false,
            0 -- SKEL_Spine3
        )
        
        -- Teletransportar
        SetEntityCoords(playerPed, playerCoords.x + 50.0, playerCoords.y, groundZ, false, false, false, false)
        
        ABILITIES.INSTANT_TRANSMISSION.lastUsed = GetGameTimer()
    end
end

-- Función para ejecutar Ki Blast
function ExecuteKiBlast()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    
    -- Crear proyectil
    local projectileHash = GetHashKey("WEAPON_RPG")
    
    -- Efecto visual de Ki
    UseParticleFxAsset("melty_dbz_fx")
    local ptfx = StartNetworkedParticleFxNonLoopedAtCoord(
        "ki_blast",
        playerCoords.x + forwardVector.x,
        playerCoords.y + forwardVector.y,
        playerCoords.z,
        0.0, 0.0, GetEntityHeading(playerPed),
        0.5, false, false, false
    )
    
    -- Disparar proyectil
    ShootSingleBulletBetweenCoords(
        playerCoords.x, playerCoords.y, playerCoords.z,
        playerCoords.x + forwardVector.x * 100,
        playerCoords.y + forwardVector.y * 100,
        playerCoords.z,
        ABILITIES.KI_BLAST.damage,
        true,
        projectileHash,
        playerPed,
        true,
        false,
        ABILITIES.KI_BLAST.speed
    )
    
    ABILITIES.KI_BLAST.lastUsed = GetGameTimer()
end

-- Función para transformación Super Saiyan
function ToggleSuperSaiyan()
    local playerPed = PlayerPedId()
    
    if not playerState.transformations.superSaiyan then
        -- Activar transformación
        playerState.transformations.superSaiyan = true
        
        -- Efecto visual
        UseParticleFxAsset("melty_dbz_fx")
        local ptfxHandle = StartNetworkedParticleFxLoopedOnPedBone(
            "super_saiyan_aura",
            playerPed,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            1.0, false, false, false,
            0
        )
        
        -- Aumentar stats
        SetPlayerMaxArmour(PlayerId(), 200)
        SetEntityHealth(playerPed, 200)
        
        -- Efecto de audio
        PlaySoundFromEntity(-1, "power_up", playerPed, "MELTY_DBZ_SOUNDS", true, 0)
    else
        -- Desactivar transformación
        playerState.transformations.superSaiyan = false
        StopParticleFxLooped(ptfxHandle, false)
        
        -- Restaurar stats
        SetPlayerMaxArmour(PlayerId(), 100)
    end
end

-- Thread principal
Citizen.CreateThread(function()
    LoadKiEffects()
    
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        
        -- Verificar input de Kamehameha
        if IsControlJustPressed(0, 38) then -- KEY_E
            if CanUseAbility(ABILITIES.KAMEHAMEHA) then
                ExecuteKamehameha()
            else
                -- Mostrar cooldown
                local remaining = ABILITIES.KAMEHAMEHA.cooldown - (GetGameTimer() - ABILITIES.KAMEHAMEHA.lastUsed)
                SetNotificationTextEntry("STRING")
                AddTextComponentString("~r~Kamehameha en cooldown: " .. math.ceil(remaining/1000) .. "s")
                DrawNotification(false, true)
            end
        end
        
        -- Verificar input de Teletransportación
        if IsControlJustPressed(0, 44) then -- KEY_Q
            if CanUseAbility(ABILITIES.INSTANT_TRANSMISSION) then
                ExecuteInstantTransmission()
            end
        end
        
        -- Verificar input de Ki Blast
        if IsDisabledControlJustPressed(0, 25) then -- MOUSE_RIGHT
            if CanUseAbility(ABILITIES.KI_BLAST) then
                ExecuteKiBlast()
            end
        end
        
        -- Verificar input de transformación
        if IsControlJustPressed(0, 23) then -- KEY_F
            ToggleSuperSaiyan()
        end
    end
end)

-- Evento de limpieza
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Limpiar efectos
        StopAllParticleFxLoops()
    end
end)