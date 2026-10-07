----------
--ESTRAL--
----------

require "BUUI_Panel"

-- MainOptions runs getText on every name and tooltip, so these are keys, not text.
local BUUI_options = PZAPI.ModOptions:create("BundleUpUI", "IGUI_BUUI_Title")
local BUUI_toggleKey = BUUI_options:addKeyBind("togglePanel", "IGUI_BUUI_ToggleKey",
    Keyboard.KEY_K, "IGUI_BUUI_ToggleKeyTooltip")

-- ModOptions.ini is read after this file loads, so the key is looked up on every press.
local function BUUI_onKeyPressed(key)
    if "Tutorial" == getCore():getGameMode() then return end

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end

    if key == BUUI_toggleKey:getValue() then
        BUUI.togglePanel(player)
    end
end

Events.OnKeyPressed.Add(BUUI_onKeyPressed)
