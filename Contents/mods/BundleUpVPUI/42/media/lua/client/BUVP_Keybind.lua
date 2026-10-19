----------
--ESTRAL--
----------

require "BUVP_Tab"

local function BUVP_modActive(id)
    local mods = getActivatedMods()
    for i = 0, mods:size() - 1 do
        if tostring(mods:get(i)) == id then return true end
    end
    return false
end

-- MainOptions runs getText on every name and tooltip, so these are keys, not text.
-- K is Viewpoint's Build key, so the toggle ships unbound.
local BUVP_options = PZAPI.ModOptions:create("BundleUpVPUI", "IGUI_BUVP_Title")
BUVP.toggleKey = BUVP_options:addKeyBind("togglePanel", "IGUI_BUUI_ToggleKey",
    Keyboard.KEY_NONE, "IGUI_BUUI_ToggleKeyTooltip")

-- with the NeatUI panel on too, its page already has the batch keys and they run the
-- same batches, so a second set would only fire twice.
local BUVP_BATCH = {}
if not BUVP_modActive("BundleUpUI") then
    for _, batch in ipairs({
        { id = "bundleAll", mode = BUUI.MODE.BUNDLE },
        { id = "unbundleAll", mode = BUUI.MODE.UNBUNDLE },
        { id = "mergeAll", mode = BUUI.MODE.MERGE },
    }) do
        batch.option = BUVP_options:addKeyBind(batch.id, BUUI.LABELS[batch.mode].all, Keyboard.KEY_NONE,
            "IGUI_BUUI_BatchKeyTooltip")
        BUVP_BATCH[#BUVP_BATCH + 1] = batch
    end
end

-- ModOptions.ini is read after this file loads, so the keys are looked up on every press.
local function BUVP_onKeyPressed(key)
    if "Tutorial" == getCore():getGameMode() then return end

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end

    -- the open hub handles its tabs' keys itself, so toggling here too would undo it.
    if key == BUVP.toggleKey:getValue() then
        if not ViewpointUI.Hub.isOpen() then ViewpointUI.Hub.open(BUVP.TAB_ID) end
        return
    end

    for _, batch in ipairs(BUVP_BATCH) do
        if key == batch.option:getValue() then
            BUUI.runBatch(player, batch.mode)
            return
        end
    end
end

Events.OnKeyPressed.Add(BUVP_onKeyPressed)
