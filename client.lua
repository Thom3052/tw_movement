local crouchCommand = "tw_crouch" -- command name for keybinding
local crouched = false
local lastThirdView = 1 -- fallback third-person view to restore (1/2/3)
local crouchAnimSet = "move_ped_crouched"
local crouchStrafeSet = "move_ped_crouched_strafing"
local blockRoll = true
local crouchSetsLoaded = false
local aimWasActive = false
local storedThirdView = 1
local camContexts = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
local autoHolsterWhenNotAiming = false -- set true to auto-holster when not aiming
local defaultThirdView = 1 -- fallback third-person view if none captured
local forceThirdViewMode = 1 -- hard fallback view to enforce when not aiming (1=close TP, 2=far, 3=first-person near but here used as TP fallback)
local enforceThirdUntil = 0 -- timer to keep forcing third-person after aim ends
local hideReticle = true -- remove crosshair while script active
local skipFirstPersonWhenUnarmed = true -- don't force FP if unarmed melee

local function loadSet(set)
    if not HasAnimSetLoaded(set) then
        RequestAnimSet(set)
        while not HasAnimSetLoaded(set) do
            Wait(0)
        end
    end
end

local function forceFirstPerson()
    for i = 1, #camContexts do
        SetCamViewModeForContext(camContexts[i], 4)
    end
    SetFollowPedCamViewMode(4)
end

local function restoreThirdPerson(viewMode)
    local mode = viewMode or lastThirdView or defaultThirdView or forceThirdViewMode
    if mode == 4 then
        mode = forceThirdViewMode
    end
    for i = 1, #camContexts do
        SetCamViewModeForContext(camContexts[i], mode)
    end
    SetFollowPedCamViewMode(mode)
end

local function ensureCrouchSets(ped)
    if not crouchSetsLoaded then
        loadSet(crouchAnimSet)
        loadSet(crouchStrafeSet)
        crouchSetsLoaded = true
    end
    SetPedMovementClipset(ped, crouchAnimSet, 0.15)
    SetPedStrafeClipset(ped, crouchStrafeSet)
    SetPedWeaponMovementClipset(ped, "move_ped_crouched")
    SetPedMoveRateOverride(ped, 1.0)
end

local function applyCrouchMovement(enable)
    local ped = PlayerPedId()
    if enable then
        loadSet(crouchAnimSet)
        loadSet(crouchStrafeSet)
        SetPedMovementClipset(ped, crouchAnimSet, 0.25)
        SetPedStrafeClipset(ped, crouchStrafeSet)
        SetPedWeaponMovementClipset(ped, "move_ped_crouched")
    else
        ResetPedMovementClipset(ped, 0.25)
        ResetPedStrafeClipset(ped)
        ResetPedWeaponMovementClipset(ped)
    end
end

local function toggleCrouch()
    crouched = not crouched
    applyCrouchMovement(crouched)
    if not crouched then
        crouchSetsLoaded = false
    end
    if blockRoll then
        SetPedUsingActionMode(PlayerPedId(), false, -1, "DEFAULT_ACTION")
    end
end

-- Keybinding: users can rebind "Toggle Crouch" in FiveM keybinds (Settings > Key Bindings > FiveM)
RegisterCommand(crouchCommand, function()
    if not IsPauseMenuActive() then
        toggleCrouch()
    end
end, false)
RegisterKeyMapping(crouchCommand, "Hurk aan/uit", "keyboard", "LCONTROL")

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        -- force first-person only while actively aiming/shooting; otherwise force third-person
        -- deliberately ignore IsPlayerFreeAiming to avoid sticky aim when crouched
        local aimPressed = IsControlPressed(0, 25) or IsControlPressed(0, 24)
        local aimJustReleased = IsControlJustReleased(0, 25) or IsControlJustReleased(0, 24)
        local aiming = aimPressed or IsPedShooting(ped)
        local weapon = GetSelectedPedWeapon(ped)
        local isUnarmed = (weapon == `WEAPON_UNARMED`)
        if aiming then
            if not aimWasActive then
                local camMode = GetFollowPedCamViewMode()
                if camMode ~= 4 then
                    storedThirdView = camMode
                    lastThirdView = camMode
                else
                    storedThirdView = (lastThirdView ~= 4) and lastThirdView or forceThirdViewMode
                end
                aimWasActive = true
            end
            if not (skipFirstPersonWhenUnarmed and isUnarmed) then
                forceFirstPerson() -- force every frame while aiming/shooting/holding aim
                if crouched then
                    SetFirstPersonAimCamNearClipThisUpdate(0.01)
                end
                if hideReticle then
                    HideHudComponentThisFrame(14) -- crosshair
                end
            end
        else
            if aimWasActive or aimJustReleased then
                enforceThirdUntil = GetGameTimer() + 800
            end
            if enforceThirdUntil > GetGameTimer() or crouched then
                restoreThirdPerson(forceThirdViewMode)
            end
            if aimWasActive or aimJustReleased then
                ClearPedSecondaryTask(ped)
                SetPedUsingActionMode(ped, false, -1, "DEFAULT_ACTION")
            end
            aimWasActive = false
            -- refresh stored/last view if player cycles camera while not aiming
            local camMode = GetFollowPedCamViewMode()
            if camMode ~= 4 then
                lastThirdView = camMode
                storedThirdView = camMode
            end

            -- kill lingering weapon idle/holster anim without removing the weapon
            ClearPedSecondaryTask(ped)
            SetPedUsingActionMode(ped, false, -1, "DEFAULT_ACTION")

            if autoHolsterWhenNotAiming and not IsPedInAnyVehicle(ped) then
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                    ClearPedTasks(ped)
                end
            end
        end

        -- monkeypunch/melee block (always)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)

        if crouched then
            -- keep crouch clipsets active every frame to avoid reverting after aim/holster
            ensureCrouchSets(ped)
            SetPedUsingActionMode(ped, false, -1, "DEFAULT_ACTION")

            DisableControlAction(0, 22, true) -- jump while crouched
            if blockRoll then
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end
        end
    end
end)

