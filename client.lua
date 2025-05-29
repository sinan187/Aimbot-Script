ESX = exports["es_extended"]:getSharedObject()

-- Initiale Aimbot-Einstellungen
local aimbotAktiviert = true
local zielVerfolgung = 0.5 --standart
local sichtfeld = 30 --standart
local zielKnochen = 31086

RegisterCommand("silentmode", function()
    local spieler = ESX.GetPlayerData()
    if spieler.group == "pi" or spieler.group == "test1" or spieler.group == "test2" or spieler.group == "test3" then
        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "modmenu", {
            title = "Silentmode Steuerung",
            align = "top-left",
            elements = {
                {label = "Aimbot umschalten", value = "aim_toggle"},
                {label = "Zielverfolgung", value = "smooth_edit"},
                {label = "Sichtfeld (FOV)", value = "fov_edit"},
            },
        }, function(data, menu)
            if data.current.value == "aim_toggle" then
                aimbotAktiviert = not aimbotAktiviert
                benachrichtigung("info", aimbotAktiviert and "Aimbot aktiviert" or "Aimbot deaktiviert")
            elseif data.current.value == "smooth_edit" then
                ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "smooth_input", {
                    title = "Zielverfolgungsgeschwindigkeit",
                }, function(input, subMenu)
                    local neuerWert = tonumber(input.value)
                    if neuerWert then
                        zielVerfolgung = neuerWert
                        if neuerWert == 0.0 then
                            benachrichtigung("info", "Zielverfolgung deaktiviert")
                        else
                            benachrichtigung("info", "Zielverfolgung auf " .. neuerWert .. " gesetzt")
                        end
                    else
                        benachrichtigung("error", "Ungültige Eingabe")
                    end
                end, function(_, subMenu) subMenu.close() end)
            elseif data.current.value == "fov_edit" then
                ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "fov_input", {
                    title = "FOV-Wert setzen",
                }, function(input, subMenu)
                    local neuerFOV = tonumber(input.value)
                    if neuerFOV then
                        sichtfeld = neuerFOV
                        benachrichtigung("info", "FOV auf " .. neuerFOV .. " aktualisiert")
                    else
                        benachrichtigung("error", "Ungültige Eingabe")
                    end
                end, function(_, subMenu) subMenu.close() end)
            end
        end, function(_, menu) menu.close() end)
    else
        benachrichtigung("error", "Zugang verweigert.")
    end
end)

function benachrichtigung(typ, nachricht)
    exports['hex_2_hud']:Notify("Silentmode", nachricht, typ, 5000)
end

Citizen.CreateThread(function()
    local wartezeit = 1000

    while true do
        Citizen.Wait(wartezeit)

        if aimbotAktiviert then
            wartezeit = 0
            local eigenerPed = PlayerPedId()
            local eigeneID = PlayerId()

            for _, spielerID in pairs(GetActivePlayers()) do
                local zielPed = GetPlayerPed(spielerID)

                if eigenerPed ~= zielPed and not IsPlayerDead(zielPed) then
                    if IsPlayerFreeAimingAtEntity(eigeneID, zielPed) and zielInnerhalbFOV(zielPed) then
                        zieleAufKnochen(zielPed, zielKnochen)
                    end
                end
            end
        else
            wartezeit = 1000
        end

        zeichneFOV()
    end
end)

function zielInnerhalbFOV(zielPed)
    local zielPosition = GetEntityCoords(zielPed)
    local kameraPosition = GetFinalRenderedCamCoord()
    local kameraRotation = GetFinalRenderedCamRot(2)
    local richtung = zielPosition - kameraPosition
    local entfernung = #richtung
    richtung = richtung / entfernung

    local vektorVorwaerts = rotationZuRichtung(kameraRotation)
    local dotProdukt = vektorVorwaerts.x * richtung.x + vektorVorwaerts.y * richtung.y + vektorVorwaerts.z * richtung.z
    local winkel = math.deg(math.acos(dotProdukt))

    return winkel <= sichtfeld / 2
end

function rotationZuRichtung(rot)
    local radRot = vector3(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
    return vector3(
        -math.sin(radRot.z) * math.abs(math.cos(radRot.x)),
        math.cos(radRot.z) * math.abs(math.cos(radRot.x)),
        math.sin(radRot.x)
    )
end

function zeichneFOV()
    local bildX, bildY = GetActiveScreenResolution()
    local radius = (sichtfeld / GetGameplayCamFov()) * (bildX / 2)

    DrawMarker(28, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, 0.1, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
end

function zieleAufKnochen(ped, bone)
    local function zwischenwert(a, b, t)
        return a + (b - a) * t
    end

    local zielPosition = GetPedBoneCoords(ped, bone)
    local kameraPosition = GetFinalRenderedCamCoord()
    local spielerRot = GetEntityRotation(PlayerPedId(), 2)

    local dx, dy, dz = (zielPosition - kameraPosition).x, (zielPosition - kameraPosition).y, (zielPosition - kameraPosition).z
    local roll = -math.deg(math.atan2(dx, dy)) - spielerRot.z
    local pitch = math.deg(math.atan2(dz, #vector3(dx, dy, 0.0)))
    local yaw = 1.0

    if IsPedInAnyVehicle(ped, false) then
        roll = roll + GetEntityRoll(ped)
    end

    if zielVerfolgung ~= 0.0 then
        local aktuellerRoll = GetGameplayCamRelativeHeading()
        local aktuellerPitch = GetGameplayCamRelativePitch()

        local geglRoll = zwischenwert(aktuellerRoll, roll, zielVerfolgung)
        local geglPitch = zwischenwert(aktuellerPitch, pitch, zielVerfolgung)

        if ped ~= PlayerPedId() and IsEntityOnScreen(ped) and IsAimCamActive() then
            SetGameplayCamRelativeRotation(geglRoll, geglPitch, yaw)
        end
    else
        if ped ~= PlayerPedId() and IsEntityOnScreen(ped) and IsAimCamActive() then
            SetGameplayCamRelativeRotation(roll, pitch, yaw)
        end
    end
end

