----------
--ESTRAL--
----------

require "TimedActions/ISBaseTimedAction"
require "BU_SeedPacketData"

BURelabelSeedPacket = ISBaseTimedAction:derive("BURelabelSeedPacket")

function BURelabelSeedPacket:isValid()
    -- a server builds this from what the client sent, so an unchecked newType would let a
    -- packet become any item.
    if not (self.item and BU.SeedPackets.isEmpty(self.item:getFullType())
            and BU.SeedPackets.isEmpty(self.newType)) then
        return false
    end
    if not BU.SeedPackets.canWrite(self.character) then return false end
    return isClient() or self.character:getInventory():contains(self.item)
end

function BURelabelSeedPacket:start()
    if isClient() then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    if not self.item then return end

    self.item:setJobType(getText("ContextMenu_BU_RelabelSeedPacket"))
    self.item:setJobDelta(0.0)
    self:setActionAnim("Craft")
end

function BURelabelSeedPacket:update()
    self.item:setJobDelta(self:getJobDelta())
end

function BURelabelSeedPacket:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function BURelabelSeedPacket:perform()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.perform(self)
end

function BURelabelSeedPacket:complete()
    local inventory = self.character:getInventory()
    local packet = instanceItem(self.newType)
    packet:setFavorite(self.item:isFavorite())

    self.character:removeFromHands(self.item)
    inventory:Remove(self.item)
    sendRemoveItemFromContainer(inventory, self.item)
    inventory:AddItem(packet)
    sendAddItemToContainer(inventory, packet)
    return true
end

function BURelabelSeedPacket:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 50
end

function BURelabelSeedPacket:new(character, item, newType)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.newType = newType
    o.stopOnWalk = false
    o.maxTime = o:getDuration()
    return o
end
