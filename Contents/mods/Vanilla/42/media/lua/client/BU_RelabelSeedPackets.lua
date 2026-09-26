----------
--ESTRAL--
----------

require "BU_SeedPacketData"
require "BU_RelabelSeedPacket"
require "ISUI/ISInventoryPane"

local BU_targets = nil

local function BU_packetTargets()
    if not BU_targets then
        BU_targets = {}
        for fullType in pairs(BU.SeedPackets.Empty) do
            BU_targets[#BU_targets + 1] = { fullType = fullType, name = getItemNameFromFullType(fullType) }
        end
        table.sort(BU_targets, function(a, b) return a.name < b.name end)
    end
    return BU_targets
end

local function BU_onRelabel(packets, playerObj, newType, count)
    for i = 1, count do
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, packets[i])
        ISTimedActionQueue.add(BURelabelSeedPacket:new(playerObj, packets[i], newType))
    end
end

local function BU_addTarget(submenu, playerObj, target, sources)
    local n = #sources
    if n == 1 then
        submenu:addOption(target.name, sources, BU_onRelabel, playerObj, target.fullType, 1)
        return
    end

    local option = submenu:addOption(target.name)
    local counts = submenu:getNew(submenu)
    submenu:addSubMenu(option, counts)
    counts:addOption(getText("ContextMenu_BU_RelabelOne"), sources, BU_onRelabel, playerObj, target.fullType, 1)
    if n >= 4 then
        local half = math.floor(n / 2)
        counts:addOption(getText("ContextMenu_BU_RelabelHalf", half), sources, BU_onRelabel, playerObj, target.fullType, half)
    end
    counts:addOption(getText("ContextMenu_BU_RelabelAll", n), sources, BU_onRelabel, playerObj, target.fullType, n)
end

local function BU_onFillInventoryContextMenu(playerNum, context, items)
    local packets = {}
    for _, item in ipairs(ISInventoryPane.getActualItems(items)) do
        if BU.SeedPackets.isEmpty(item:getFullType()) then
            packets[#packets + 1] = item
        end
    end
    if #packets == 0 then return end

    local playerObj = getSpecificPlayer(playerNum)
    local option = context:addOption(getText("ContextMenu_BU_RelabelSeedPacket"))
    if not BU.SeedPackets.hasPencil(playerObj) then
        option.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_BU_RelabelNeedsPencil")
        option.toolTip = tooltip
        return
    end

    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    for _, target in ipairs(BU_packetTargets()) do
        local sources = {}
        for _, packet in ipairs(packets) do
            if packet:getFullType() ~= target.fullType then
                sources[#sources + 1] = packet
            end
        end
        if #sources > 0 then
            BU_addTarget(submenu, playerObj, target, sources)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BU_onFillInventoryContextMenu)
