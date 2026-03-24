local SOUND_PATH = "Interface\\AddOns\\Luststorm_TestBuild\\Sandstorm.mp3"

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
local LUST_DURATION = 40


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

    if debugEvents then
        Print(
            "UpdateState: hasDebuff=" .. tostring(hasDebuff)
            .. ", debuffId=" .. tostring(debuffId)
            .. ", debuffName=" .. tostring(debuffName)
            .. ", isPlaying=" .. tostring(isPlaying)
        )
    end

    -- Only used to stop/reset State now.
    if not hasDebuff then
        lastSeenDebuffId = nil
    end
end

local function StartUpdateTicker()
    return
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterUnitEvent("UNIT_AURA", "player")

local function IsTriggerDebuff(spellId)
    return spellId and TRIGGER_DEBUFF_IDS[spellId] == true
end

frame:SetScript("OnEvent", function(_, event, ...)
    if debugEvents then
        Print("EVENT: " .. tostring(event) .. ", inCombat=" .. tostring(InCombatLockdown()))
    end

    if event == "PLAYER_LOGIN" then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        return
    end

    if event == "UNIT_AURA" then
        local unitTarget, updateInfo = ...
        if unitTarget ~= "player" then
            return
        end

        -- Some clients may not provide updateInfo; do nothing in that case.
        if not updateInfo then
            return
        end

        -- Ignore full aura rebuilds caused by loading screens / zoning.
        if updateInfo.isFullUpdate then
            if debugEvents then
                Print("UNIT_AURA full update ignored")
            end
            return
        end

        -- Clear state if debuff is gone.
        local hasDebuff = FindTriggerDebuff()
        if not hasDebuff then
            lastSeenDebuffId = nil
        end

        if not updateInfo.addedAuras or #updateInfo.addedAuras == 0 then
            return
        end

        for _, aura in ipairs(updateInfo.addedAuras) do
            if aura and IsTriggerDebuff(aura.spellId) then
                if debugEvents then
                    Print("New trigger debuff added: " .. tostring(aura.spellId))
                end

                if aura.spellId ~= lastSeenDebuffId then
                    lastSeenDebuffId = aura.spellId
                    StartLuststorm()
                end
                return
            end
        end

        return
    end
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
