BUInv = BUInv or {}

PACK_FLAVORS = {
    ["BundleUp.BlueberryPack"]    = "SodaBlueberry",
    ["BundleUp.BubblegumPack"]    = "SodaBubblegum",
    ["BundleUp.SodaCanPack_Pop"]          = "SodaPop",
    ["BundleUp.SodaCanPack_Lime"]         = "SodaLime",
    ["BundleUp.SodaCanPack_Grape"]        = "SodaGrape",
    ["BundleUp.SodaCanPack_Pineapple"]    = "SodaPineapple",
    ["BundleUp.SodaCanPack_Strawberry"]   = "SodaStrawberry",
}

---@param craftRecipeData CraftRecipeData
---@param character IsoGameCharacter
function BUInv.unpackSodaPack(craftRecipeData, character)
    local sodaPack = craftRecipeData:getAllConsumedItems():get(0)
    local sodaFluid = PACK_FLAVORS[sodaPack:getFullType()]

    local sodaType = Fluid.Get(sodaFluid)
    local inventory = character:getInventory()
    -- put the soda in the cans
    for i = 1, 6 do
        local can = inventory:AddItem("Base.SodaCan")
        can:Empty()
        can:AddFluid(sodaType, 1.0)
    end
end
