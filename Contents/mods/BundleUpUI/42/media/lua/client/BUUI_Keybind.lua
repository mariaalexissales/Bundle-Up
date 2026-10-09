----------
--ESTRAL--
----------

require "BUUI_Panel"

-- MainOptions runs getText on every name and tooltip, so these are keys, not text.
local BUUI_options = PZAPI.ModOptions:create("BundleUpUI", "IGUI_BUUI_Title")
local BUUI_toggleKey = BUUI_options:addKeyBind("togglePanel", "IGUI_BUUI_ToggleKey",
    Keyboard.KEY_K, "IGUI_BUUI_ToggleKeyTooltip")

local BUUI_BATCH = {
    { id = "bundleAll", label = "IGUI_BUUI_BundleAll", empty = "IGUI_BUUI_Empty",
      mode = BUUI.MODE.BUNDLE },
    { id = "unbundleAll", label = "IGUI_BUUI_UnbundleAll", empty = "IGUI_BUUI_EmptyUnbundle",
      mode = BUUI.MODE.UNBUNDLE },
    { id = "mergeAll", label = "IGUI_BUUI_MergeAll", empty = "IGUI_BUUI_EmptyMerge",
      mode = BUUI.MODE.MERGE },
}

for _, batch in ipairs(BUUI_BATCH) do
    batch.option = BUUI_options:addKeyBind(batch.id, batch.label, Keyboard.KEY_NONE,
        "IGUI_BUUI_BatchKeyTooltip")
end

local function BUUI_tellWindow(finished)
    local window = BUUI.getWindow(0)
    if not window then return end

    if finished then
        window:onBatchFinished()
    else
        window:refresh()
    end
end

local function BUUI_batch(player, batch)
    -- stop fires no callback, so the window is told here.
    if BUUI.Queue.isRunning() then
        BUUI.Queue.stop()
        BUUI_tellWindow(true)
        return
    end

    local worked = false

    BUUI.Queue.startAll(player, batch.mode,
        function()
            worked = true
            BUUI_tellWindow(false)
        end,
        function(cancelled)
            BUUI_tellWindow(true)
            if not worked and not cancelled then
                HaloTextHelper.addText(player, getText(batch.empty))
            end
        end)

    -- with nothing to do the batch has already finished inside startAll.
    if BUUI.Queue.isRunning() then BUUI_tellWindow(false) end
end

-- ModOptions.ini is read after this file loads, so the keys are looked up on every press.
local function BUUI_onKeyPressed(key)
    if "Tutorial" == getCore():getGameMode() then return end

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end

    if key == BUUI_toggleKey:getValue() then
        BUUI.togglePanel(player)
        return
    end

    for _, batch in ipairs(BUUI_BATCH) do
        if key == batch.option:getValue() then
            BUUI_batch(player, batch)
            return
        end
    end
end

Events.OnKeyPressed.Add(BUUI_onKeyPressed)
