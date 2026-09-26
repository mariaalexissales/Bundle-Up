----------
--ESTRAL--
----------

-- the panel only indexes BundleUp recipes by module. these are guns of marz's own ammo
-- recipes, listed by name so the rest of module Base stays out.
BUUI = BUUI or {}
BUUI.extraRecipes = BUUI.extraRecipes or {}

local GOM_RECIPES = {
    "Base.OpenBoxOf50Bullets",
    "Base.OpenBoxOf20Bullets",
    "Base.OpenBoxOf25Bullets",
    "Base.OpenBoxOf10Bullets",
    "Base.place50BulletsInBox",
    "Base.place20BulletsInBox",
    "Base.place25BulletsInBox",
    "Base.place10BulletsInBox",
    "Base.OpenCartonOfBoxesOfAmmo",
    "Base.PlaceBoxesOfAmmoInCarton",
    "Base.OpenCrateOfBoxesOfAmmo",
    "Base.PlaceBoxesOfAmmoInCrates",
}

for i = 1, #GOM_RECIPES do
    BUUI.extraRecipes[GOM_RECIPES[i]] = true
end
