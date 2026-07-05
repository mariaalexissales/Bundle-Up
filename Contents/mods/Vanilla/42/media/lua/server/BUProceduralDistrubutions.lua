local BUDistribution = {
    GigamartPots = {
        items = {
            "GlassWine", 6, -- item, chance,
            "Fork", 10,
            "Mugl", 10,
            "Whetstone", 10,
            "Teacup", 10,
            "CDplayer", 10,
        },
        junk = { -- this one can be removed if you don't put anything in it
            "Mov_CoffeeMaker", 4,
            "HandTorch", 8,
        },
    },
    LibraryMilitaryHistory = {
        items = {
            "Book_Music", 20,
			"Book_Music", 10,
            "Doodle", 0.001,
        },
    },
    MechanicShelfElectric = {
        items = {
            "Battery", 10,
			"BatteryBox", 10,
            "Brochure", 2,
			"Broom", 10,
			"Bucket", 10,
        },
    },
}

-- caching for performance reasons
local ProceduralDistributions_list = ProceduralDistributions.list
local table_insert = table.insert

local function insertInDistribution(distrib)
    -- iterate through every given distributions
    for k,v in pairs(distrib) do
        -- cache this distribution list
        local ProceduralDistributions_list_k = ProceduralDistributions_list[k]

        -- insert items
        local items = v.items
        local ProceduralDistributions_list_k_items = ProceduralDistributions_list_k.items
        if items then
            for i = 1,#items do
                table_insert(ProceduralDistributions_list_k_items,items[i])
            end
        end

        -- insert junk
        local junk = v.junk
        local ProceduralDistributions_list_k_junk = ProceduralDistributions_list_k.junk
        if junk then
            for i = 1,#junk do
                table_insert(ProceduralDistributions_list_k_junk,junk[i])
            end
        end
    end
end

insertInDistribution(myDistribution)