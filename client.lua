local isPointing = false

local function playPointingAnimation()
    local player = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end

    SetPedCurrentWeaponVisible(player, false, true, true, true)
    SetPedConfigFlag(player, 36, true)

    Citizen.InvokeNative(0x2D537BA194896636, player, "task_mp_pointing", 0.5, false, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointingAnimation()
    local player = PlayerPedId()
    Citizen.InvokeNative(0xD01015C7316AE176, player, "Stop")

    if not IsPedInjured(player) then
        ClearPedSecondaryTask(player)
    end

    if not IsPedInAnyVehicle(player, false) then
        SetPedCurrentWeaponVisible(player, true, true, true, true)
    end

    SetPedConfigFlag(player, 36, false)
    ClearPedSecondaryTask(player)
end

local function updatePointingDirection()
    while isPointing do
        local player = PlayerPedId()

        local pitch = GetGameplayCamRelativePitch()
        pitch = math.max(-70.0, math.min(42.0, pitch))
        local normalizedPitch = (pitch + 70.0) / 112.0

        local heading = GetGameplayCamRelativeHeading()
        heading = math.max(-180.0, math.min(180.0, heading))
        local normalizedHeading = (heading + 180.0) / 360.0

        local cosH = math.cos(heading)
        local sinH = math.sin(heading)

        local offsetX = (cosH * -0.2) - (sinH * ((0.4 * heading) + 0.3))
        local offsetY = (sinH * -0.2) + (cosH * ((0.4 * heading) + 0.3))
        local origin = GetOffsetFromEntityInWorldCoords(player, offsetX, offsetY, 0.6)

        local rayHandle = Cast_3dRayPointToPoint(origin.x, origin.y, origin.z - 0.2, origin.x, origin.y, origin.z + 0.2, 0.4, 95, player, 7)
        local _, isBlocked = GetRaycastResult(rayHandle)

        Citizen.InvokeNative(0xD5BB4025AE449A4E, player, "Pitch", normalizedPitch)
        Citizen.InvokeNative(0xD5BB4025AE449A4E, player, "Heading", normalizedHeading * -1.0 + 1.0)
        Citizen.InvokeNative(0xB0A6CFD2C69C1088, player, "isBlocked", isBlocked)
        Citizen.InvokeNative(0xB0A6CFD2C69C1088, player, "isFirstPerson",
            Citizen.InvokeNative(0xEE778F8C7E1142E2,
                Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

        Wait(1)
    end
end

RegisterCommand("point", function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end

    if isPointing then
        stopPointingAnimation()
        isPointing = false
    else
        playPointingAnimation()
        isPointing = true
        CreateThread(updatePointingDirection)
    end
end)

RegisterKeyMapping("point", "~g~[Animations]~s~ Point-Finger", "keyboard", "B")
