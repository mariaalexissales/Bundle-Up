----------
--ESTRAL--
----------

require "BUUI_Panel"

-- MainOptions runs getText on every name and tooltip, so these are keys, not text.
local BUUI_options = PZAPI.ModOptions:create("BundleUpUI", "IGUI_BUUI_Title")
local BUUI_toggleKey = BUUI_options:addKeyBind("togglePanel", "IGUI_BUUI_ToggleKey",
    Keyboard.KEY_K, "IGUI_BUUI_ToggleKeyTooltip")

local BUUI_BATCH = {
    { id = "bundleAll", mode = BUUI.MODE.BUNDLE },
    { id = "unbundleAll", mode = BUUI.MODE.UNBUNDLE },
    { id = "mergeAll", mode = BUUI.MODE.MERGE },
}

for _, batch in ipairs(BUUI_BATCH) do
    batch.option = BUUI_options:addKeyBind(batch.id, BUUI.LABELS[batch.mode].all, Keyboard.KEY_NONE,
        "IGUI_BUUI_BatchKeyTooltip")
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
            BUUI.runBatch(player, batch.mode)
            return
        end
    end
end

Events.OnKeyPressed.Add(BUUI_onKeyPressed)
