----------
--ESTRAL--
----------

require "BUProceduralDistributions"
require "BUGoM_Packs"

if not (BU and BU.addLoot and BUGoM) then return end

local function BUGoM_marz(key)
    local sv = SandboxVars and SandboxVars.MarzGuns
    return sv == nil or sv[key] ~= false
end

-- guns of marz gates these behind its own options, so the packs follow them.
local function BUGoM_highCapOn() return BUGoM_marz("SpawnHighCapMags") end
local function BUGoM_explosivesOn() return BUGoM_marz("SpawnExplosives") end

local MAG_BOX_WEIGHTS = {
    GunStoreMagsAmmo        = 0.05,
    GunStoreAmmunition      = 0.03,
    ArmyStorageAmmunition   = 0.03,
    ArmySurplusAmmoBoxes    = 0.025,
    SWATStorageAmmunition   = 0.025,
    PoliceStorageAmmunition = 0.02,
}

local MAG_CARTON_WEIGHTS = {
    GunStoreMagsAmmo        = 0.008,
    GunStoreAmmunition      = 0.005,
    ArmyStorageAmmunition   = 0.005,
    ArmySurplusAmmoBoxes    = 0.004,
    SWATStorageAmmunition   = 0.004,
    PoliceStorageAmmunition = 0.003,
}

local GRENADE_CARTON_WEIGHTS = {
    ArmyStorageGuns   = 0.02,
    ArmyBunkerStorage = 0.02,
}

local REPAIR_BOX_WEIGHTS = {
    GunStoreAccessories = 0.3,
    GunStoreCounter     = 0.2,
    ToolStoreMisc       = 0.15,
    StoreShelfMechanics = 0.15,
    ArmyBunkerStorage   = 0.15,
}

local REPAIR_CARTON_WEIGHTS = {
    ArmyBunkerStorage = 0.05,
    CrateTools        = 0.05,
    CrateMechanics    = 0.05,
}

local magBoxes, magCartons, highCapBoxes, highCapCartons = {}, {}, {}, {}
local function BUGoM_sortMags(list, tiers)
    for i = 1, #list do
        local short = list[i]
        local boxes, cartons = magBoxes, magCartons
        if BUGoM.HighCap[short] then
            boxes, cartons = highCapBoxes, highCapCartons
        end
        boxes[#boxes + 1] = BUGoM.packName(short, tiers[1][1])
        cartons[#cartons + 1] = BUGoM.packName(short, tiers[2][1])
    end
end
BUGoM_sortMags(BUGoM.Magazines, BUGoM.Tiers.Magazine)
BUGoM_sortMags(BUGoM.Drums, BUGoM.Tiers.Drum)

BU.addLoot("SpawnGoMMagazines", magBoxes, MAG_BOX_WEIGHTS)
BU.addLoot("SpawnGoMMagazines", magCartons, MAG_CARTON_WEIGHTS)
BU.addLoot("SpawnGoMMagazines", highCapBoxes, MAG_BOX_WEIGHTS, BUGoM_highCapOn)
BU.addLoot("SpawnGoMMagazines", highCapCartons, MAG_CARTON_WEIGHTS, BUGoM_highCapOn)

local grenadeCartons = {}
for i = 1, #BUGoM.Grenades do
    grenadeCartons[i] = BUGoM.packName(BUGoM.Grenades[i].short, "Carton")
end
BU.addLoot("SpawnGoMGrenades", grenadeCartons, GRENADE_CARTON_WEIGHTS, BUGoM_explosivesOn)

BU.addLoot("SpawnGoMRepairPacks", { BUGoM.packName("RepairPack", "Box") }, REPAIR_BOX_WEIGHTS)
BU.addLoot("SpawnGoMRepairPacks", { BUGoM.packName("RepairPack", "Carton") }, REPAIR_CARTON_WEIGHTS)
