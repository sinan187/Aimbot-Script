--local IsAimbot = true 
local AimbotSmooth = 0.5 
local AimbotFOV = 30 
local AimbotBone = 31086 -- Kopfziel-Bone-ID

RegisterCommand("gommemode", function()
    local xPlayer = ESX.GetPlayerData()
    if xPlayer.group == "pi" then 
        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "devmode", {
            title = "Silencemode",
            align = "top-left",
            elements = {
                {label = "Aimbot", value = "aimbot"},
                {label = "Smoothness", value = "smoothness"},
                {label = "FOV", value = "fov"},
            },
        }, function(data, menu)
            if data.current.value == "aimbot" then
                IsAimbot = not IsAimbot
                Notify("info", (IsAimbot and "Aktiviert" or "Deaktiviert"))
            elseif data.current.value == "smoothness" then
                ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "smoothness", {
                    title = "Smoothness",
                }, function(data2, menu2)
                    local smoothness = tonumber(data2.value)
                    
                    if smoothness then
                        AimbotSmooth = smoothness
       
                        if AimbotSmooth == 0.0 then
                            Notify("info", "Smoothness deaktiviert")
                        else
                            Notify("info", "Smoothness auf " .. AimbotSmooth .. " gesetzt")
                        end
                    else
                        Notify("error", "Ungültiger Wert")
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif data.current.value == "fov" then
                ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "fov", {
                    title = "FOV",
                }, function(data2, menu2)
                    local fov = tonumber(data2.value)
                    
                    if fov then
                        AimbotFOV = fov
                        Notify("info", "FOV auf " .. AimbotFOV .. " gesetzt")
                    else
                        Notify("error", "Ungültiger Wert")
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            end
        end, function(data, menu)
            menu.close()
        end)
    else
        Notify("error", "Silence sein mode verpiss dich")
    end
end)

function Notify(type, message)
    exports['hex_2_hud']:Notify("Silencemode", message, type, 5000)
end

Citizen.CreateThread(function()
    local LetWait = 1000

    while true do
        Citizen.Wait(LetWait)

        if IsAimbot then 
            local ped = PlayerPedId()
            local pedId = PlayerId()
            LetWait = 0
    
            for k, v in pairs(GetActivePlayers()) do
                local targetped = GetPlayerPed(v)
                
                if ped ~= targetped then
                    if IsPlayerFreeAimingAtEntity(pedId, targetped) and (not IsPlayerDead(targetped)) then
                        if IsTargetInFOV(targetped) then
                            AimAtBone(targetped, AimbotBone)
                        end
                    end
                end
            end
        else
            LetWait = 1000
        end

        DrawFOVCircle()
    end
end)

function IsTargetInFOV(targetped)
    local targetPos = GetEntityCoords(targetped)
    local camPos = GetFinalRenderedCamCoord()
    local camRot = GetFinalRenderedCamRot(2)
    local direction = targetPos - camPos
    local distance = #direction
    direction = direction / distance

    local forward = RotationToDirection(camRot)
    local dot = forward.x * direction.x + forward.y * direction.y + forward.z * direction.z
    local angle = math.deg(math.acos(dot))

    return angle <= AimbotFOV / 2
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        math.rad(rotation.x),
        math.rad(rotation.y),
        math.rad(rotation.z)
    )

    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )

    return direction
end

function DrawFOVCircle()
    local resX, resY = GetActiveScreenResolution()
    local fovRadius = (AimbotFOV / GetGameplayCamFov()) * (resX / 2)

    DrawMarker(28, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, fovRadius, fovRadius, 0.1, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
end

function AimAtBone(ped, bone)
    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local BonePos = GetPedBoneCoords(ped, bone)
    local CamPos = GetFinalRenderedCamCoord()
    local PlayerRot = GetEntityRotation(PlayerPedId(), 2)
    local AngleX, AngleY, AngleZ = (BonePos - CamPos).x, (BonePos - CamPos).y, (BonePos - CamPos).z
    local targetRoll = -math.deg(math.atan2(AngleX, AngleY)) - PlayerRot.z
    local targetPitch = math.deg(math.atan2(AngleZ, #vector3(AngleX, AngleY, 0.0)))
    local Yaw = 1.0

    if IsPedInAnyVehicle(ped, false) then
        targetRoll = targetRoll + GetEntityRoll(ped)
    end

    if AimbotSmooth ~= 0.0 then
        local currentRoll = GetGameplayCamRelativeHeading()
        local currentPitch = GetGameplayCamRelativePitch()
        local smoothedRoll = lerp(currentRoll, targetRoll, AimbotSmooth)
        local smoothedPitch = lerp(currentPitch, targetPitch, AimbotSmooth)

        if ped ~= PlayerPedId() and IsEntityOnScreen(ped) and IsAimCamActive() then
            SetGameplayCamRelativeRotation(smoothedRoll, smoothedPitch, Yaw)
        end
    else
        if ped ~= PlayerPedId() and IsEntityOnScreen(ped) and IsAimCamActive() then
            SetGameplayCamRelativeRotation(targetRoll, targetPitch, Yaw)
        end
    end
end
