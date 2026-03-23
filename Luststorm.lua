local SOUND_PATH = "Interface\\AddOns\\Luststorm\\Sandstorm.mp3"

local TRIGGER_DEBUFF_IDS = {
    [57723] = true,   -- Exhaustion
    [57724] = true,   -- Sated
    [80354] = true,   -- Temporal Displacement
    [95809] = true,   -- Insanity
    [160455] = true,  -- Fatigued
    [264689] = true,  -- Fatigued
    [390435] = true,  -- Exhaustion
}

local LUST_BUFF_NAMES = {
    "Bloodlust",
    "Heroism",
    "Time Warp",
    "Primal Rage",
    "Fury of the Aspects",
}

local frame = CreateFrame("Frame")

local isPlaying = false
local soundHandle = nil
local manualTestMode = false
local updateTicker = nil
local lastSeenDebuffId = nil
local debugEvents = false
local lustStopTimer = nil
local LUST_DURATION = 40
local suppressExistingDebuff = true
local waitingForDebuffClear = false
local startupCheckTimer = nil
local zoneSuppressActive = false
local zoneSuppressTimer = nil
local sawDebuffDuringZoneSuppress = false

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Luststorm:|r " .. tostring(msg))
end

local function FindTriggerDebuff()
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then
        return false, nil, nil
    end

    for spellId in pairs(TRIGGER_DEBUFF_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
        if aura then
            local name = aura.name or tostring(spellId)
            return true, spellId, name
        end
    end

    return false, nil, nil
end

local LUST_BUFF_IDS = {
    [2825] = "Bloodlust",
    [32182] = "Heroism",
    [80353] = "Time Warp",
    [264667] = "Primal Rage",
    [390386] = "Fury of the Aspects",
}

local function PlayerHasLustBuff()
    return false, nil
end

local function StopLuststorm()
    if lustStopTimer then
        lustStopTimer:Cancel()
        lustStopTimer = nil
    end

    if soundHandle then
        StopSound(soundHandle, 0)
        soundHandle = nil
    end

    isPlaying = false
end

local function StartLuststorm()
    if isPlaying then
        return
    end

    local willPlay, handle = PlaySoundFile(SOUND_PATH, "Master")

    if debugEvents then
        Print("StartLuststorm: willPlay=" .. tostring(willPlay) .. ", handle=" .. tostring(handle) .. ", inCombat=" .. tostring(InCombatLockdown()))
    end

    if willPlay then
        soundHandle = handle
        isPlaying = true

        if lustStopTimer then
            lustStopTimer:Cancel()
        end

        lustStopTimer = C_Timer.NewTimer(LUST_DURATION, function()
            if debugEvents then
                Print("lust timer expired, stopping sound")
            end
            StopLuststorm()
        end)
    else
        soundHandle = nil
        isPlaying = false
    end
end

local function UpdateState()
    if manualTestMode then
        return
    end

    local hasDebuff, debuffId, debuffName = FindTriggerDebuff()

    if zoneSuppressActive then
        if hasDebuff then
            sawDebuffDuringZoneSuppress = true
            lastSeenDebuffId = debuffId
        end
        return
    end

    if debugEvents then
        Print(
            "UpdateState: hasDebuff=" .. tostring(hasDebuff)
            .. ", debuffId=" .. tostring(debuffId)
            .. ", debuffName=" .. tostring(debuffName)
            .. ", isPlaying=" .. tostring(isPlaying)
            .. ", lastSeenDebuffId=" .. tostring(lastSeenDebuffId)
            .. ", suppressExistingDebuff=" .. tostring(suppressExistingDebuff)
            .. ", waitingForDebuffClear=" .. tostring(waitingForDebuffClear)
            .. ", sawDebuffDuringZoneSuppress=" .. tostring(sawDebuffDuringZoneSuppress)
        )
    end

    if waitingForDebuffClear then
        if hasDebuff then
            lastSeenDebuffId = debuffId
            return
        else
            waitingForDebuffClear = false
            suppressExistingDebuff = false
            lastSeenDebuffId = nil
            if debugEvents then
                Print("old debuff cleared; addon re-armed")
            end
            return
        end
    end

    -- Fresh new lust-related debuff: start playback
    if hasDebuff and debuffId ~= lastSeenDebuffId then
        lastSeenDebuffId = debuffId
        StartLuststorm()
    end

    -- Reset tracking once debuff is gone
    if not hasDebuff then
        lastSeenDebuffId = nil
    end
end

local function StartUpdateTicker()
    if updateTicker then
        return
    end

    updateTicker = C_Timer.NewTicker(0.1, function()
        UpdateState()
    end)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterUnitEvent("UNIT_AURA", "player")

local function BeginStartupSuppression()
    suppressExistingDebuff = true
    waitingForDebuffClear = false
    lastSeenDebuffId = nil

    if startupCheckTimer then
        startupCheckTimer:Cancel()
        startupCheckTimer = nil
    end

    startupCheckTimer = C_Timer.NewTimer(2, function()
        local hasDebuff, debuffId = FindTriggerDebuff()

        if hasDebuff then
            waitingForDebuffClear = true
            lastSeenDebuffId = debuffId
            if debugEvents then
                Print("startup check: existing debuff found, waiting for clear")
            end
        else
            suppressExistingDebuff = false
            waitingForDebuffClear = false
            lastSeenDebuffId = nil
            if debugEvents then
                Print("startup check: no existing debuff, addon armed")
            end
        end
    end)
end

local function BeginZoneSuppression()
    suppressExistingDebuff = true
    waitingForDebuffClear = false
    sawDebuffDuringZoneSuppress = false
    lastSeenDebuffId = nil
    zoneSuppressActive = true

    if zoneSuppressTimer then
        zoneSuppressTimer:Cancel()
        zoneSuppressTimer = nil
    end

    zoneSuppressTimer = C_Timer.NewTimer(5, function()
        zoneSuppressActive = false

        local hasDebuff, debuffId = FindTriggerDebuff()

        -- If we saw the debuff at any point during the zone-load window,
        -- treat it as old and wait for it to clear completely.
        if sawDebuffDuringZoneSuppress or hasDebuff then
            waitingForDebuffClear = true
            lastSeenDebuffId = debuffId
            if debugEvents then
                Print("zone suppression ended: old debuff detected, waiting for clear")
            end
        else
            suppressExistingDebuff = false
            waitingForDebuffClear = false
            lastSeenDebuffId = nil
            if debugEvents then
                Print("zone suppression ended: addon armed")
            end
        end
    end)
end

frame:SetScript("OnEvent", function(_, event)
    if debugEvents then
        Print("EVENT: " .. tostring(event) .. ", inCombat=" .. tostring(InCombatLockdown()))
    end

    if event == "PLAYER_LOGIN" then
        StartUpdateTicker()
        BeginStartupSuppression()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        BeginStartupSuppression()
        return
    end

    UpdateState()
end)

SLASH_LUSTSTORM1 = "/luststorm"
SLASH_LUSTSTORM2 = "/lstorm"

SlashCmdList.LUSTSTORM = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "test" then
        manualTestMode = true
        StopLuststorm()
        StartLuststorm()
        Print("test playback started.")

    elseif msg == "stop" then
        manualTestMode = false
        StopLuststorm()
        Print("playback stopped.")

    elseif msg == "resume" then
        manualTestMode = false
        UpdateState()
        Print("live detection resumed.")

    elseif msg == "status" then
        local hasDebuff, debuffId, debuffName = FindTriggerDebuff()
        local hasBuff, buffName = PlayerHasLustBuff()

        Print(
            "playing=" .. tostring(isPlaying)
            .. ", testMode=" .. tostring(manualTestMode)
            .. ", hasDebuff=" .. tostring(hasDebuff)
            .. ", debuffId=" .. tostring(debuffId)
            .. ", debuffName=" .. tostring(debuffName)
            .. ", hasBuff=" .. tostring(hasBuff)
            .. ", buffName=" .. tostring(buffName)
            .. ", inCombat=" .. tostring(InCombatLockdown())
        )

    elseif msg == "debug" then
        debugEvents = not debugEvents
        Print("debug " .. (debugEvents and "enabled" or "disabled"))

    else
        Print("commands: /luststorm test | stop | resume | status | debug")
    end
end
