----------
--ESTRAL--
----------

require "BUUI_Panel"

-- ISEquippedItem keeps TEXTURE_WIDTH as a file-local, so the sidebar scale has to
-- be derived again here. Size 6 means "match the font size" and resolves through
-- a different option entirely.
local function BUUI_textureWidth()
    local size = getCore():getOptionSidebarSize()
    if size == 6 then
        size = getCore():getOptionFontSizeReal() - 1
    end

    if size == 2 then return 64 end
    if size == 3 then return 80 end
    if size == 4 then return 96 end
    if size == 5 then return 128 end
    return 48
end

-- The sidebar is rebuilt wholesale when the size option changes, which leaves the
-- old panel alive for a frame or two. Anything touching a stale panel corrupts the
-- live one's geometry.
local function BUUI_isCurrentPanel(panel)
    if not panel or not panel.playerNum then return false end

    local playerData = getPlayerData(panel.playerNum)
    if playerData and playerData.equipped and playerData.equipped ~= panel then
        return false
    end

    return true
end

-- Cell 0 is the vanilla crafting button itself. Anything already flying out of it
-- claims the cells after that, so measure rather than assume: with Project Cook
-- installed its popup is two cells wide and we land third, without it we land
-- second. Measuring every frame means load order between the mods does not matter.
local function BUUI_cellOffset(panel, textureWidth)
    local cells = 1

    if panel.craftingPopup and panel.craftingPopup.getWidth then
        local width = panel.craftingPopup:getWidth() or 0
        cells = math.max(cells, math.ceil(width / textureWidth))
    end

    return cells
end

BUUI_Popup = ISPanel:derive("BUUI_Popup")

function BUUI_Popup:new(x, y, width, height, chr)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.chr = chr
    o.playerNum = chr:getPlayerNum()
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    return o
end

function BUUI_Popup:setTextures(textureWidth)
    if self.textureWidth == textureWidth then return end

    self.textureWidth = textureWidth
    self.iconOff = getTexture("media/ui/Sidebar/" .. textureWidth .. "/BundleUp_Off_" .. textureWidth .. ".png")
    self.iconOn = getTexture("media/ui/Sidebar/" .. textureWidth .. "/BundleUp_On_" .. textureWidth .. ".png")
end

function BUUI_Popup:render()
    local texture = self.iconOff
    if BUUI.isWindowOpen(self.playerNum) then
        texture = self.iconOn or texture
    end

    -- A missing texture should cost us our icon, not the whole sidebar render pass.
    if texture then
        self:drawTexture(texture, 0, 0, 1, 1, 1, 1)
    end
end

function BUUI_Popup:onMouseMove(dx, dy)
    self:showTooltip(getText("IGUI_BUUI_PanelTooltip"))
    return true
end

function BUUI_Popup:onMouseMoveOutside(dx, dy)
    self:hideTooltip()
    return true
end

function BUUI_Popup:onMouseDown(x, y)
    self:hideTooltip()

    if BUUI.isWindowOpen(self.playerNum) then
        BUUI.getWindow(self.playerNum):onCloseClick()
    else
        BUUI.openPanel(self.chr)
    end

    return true
end

function BUUI_Popup:showTooltip(text)
    if not text then return end

    if not self.tooltip then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:instantiate()
        self.tooltip:setOwner(self)
    end

    self.tooltip:setName(text)
    self.tooltip:setVisible(true)
    self.tooltip:addToUIManager()
    self.tooltip:bringToTop()
end

function BUUI_Popup:hideTooltip()
    if self.tooltip and self.tooltip:isVisible() then
        self.tooltip:removeFromUIManager()
        self.tooltip:setVisible(false)
    end
end

local function BUUI_ensurePopup(panel)
    if not panel or not panel.chr or panel.chr:getPlayerNum() ~= 0 or not panel.craftingBtn then
        return
    end
    if not BUUI_isCurrentPanel(panel) then return end

    local textureWidth = BUUI_textureWidth()
    local textureHeight = textureWidth * 0.75

    if not panel.BUUI_popup then
        panel.BUUI_popup = BUUI_Popup:new(0, 0, textureWidth, textureHeight, panel.chr)
        panel.BUUI_popup.owner = panel
        panel.BUUI_popup:addToUIManager()
        panel.BUUI_popup:setVisible(false)
    end

    local offset = BUUI_cellOffset(panel, textureWidth)
    panel.BUUI_popup:setX(panel:getAbsoluteX() + panel.craftingBtn:getX() + offset * textureWidth)
    panel.BUUI_popup:setY(panel:getAbsoluteY() + panel.craftingBtn:getY())
    panel.BUUI_popup:setWidth(textureWidth)
    panel.BUUI_popup:setHeight(textureHeight)
    panel.BUUI_popup:setTextures(textureWidth)
end

local function BUUI_updateVisibility(panel)
    if not panel or not panel.craftingBtn or not panel.BUUI_popup then return end
    if not BUUI_isCurrentPanel(panel) then return end

    local show = panel.craftingBtn:isMouseOver()
        or panel.BUUI_popup:isMouseOver()
        or BUUI.isWindowOpen(panel.chr:getPlayerNum())

    -- Without this the cursor loses us halfway: travelling right from the crafting
    -- button to our cell crosses whatever else is flying out in between.
    if not show and panel.craftingPopup and panel.craftingPopup.isMouseOver then
        show = panel.craftingPopup:isMouseOver()
    end

    if "Tutorial" == getCore():getGameMode() then
        show = false
    end

    panel.BUUI_popup:setVisible(show)

    if show then
        panel.BUUI_popup:bringToTop()
    else
        panel.BUUI_popup:hideTooltip()
    end
end

local function BUUI_patchSidebar()
    if not ISEquippedItem then
        require "ISUI/ISEquippedItem"
    end
    if not ISEquippedItem or ISEquippedItem.BUUI_PatchApplied then return end

    ISEquippedItem.BUUI_PatchApplied = true
    local originalInitialise = ISEquippedItem.initialise
    local originalPrerender = ISEquippedItem.prerender
    local originalRemove = ISEquippedItem.removeFromUIManager
    local originalCheckSize = ISEquippedItem.checkSidebarSizeOption

    function ISEquippedItem:initialise()
        if originalInitialise then originalInitialise(self) end
        BUUI_ensurePopup(self)
    end

    function ISEquippedItem:prerender()
        if originalPrerender then originalPrerender(self) end
        if not BUUI_isCurrentPanel(self) then return end

        BUUI_ensurePopup(self)
        BUUI_updateVisibility(self)
    end

    function ISEquippedItem:removeFromUIManager()
        if self.BUUI_popup then
            self.BUUI_popup:hideTooltip()
            self.BUUI_popup:removeFromUIManager()
            self.BUUI_popup = nil
        end

        if originalRemove then
            originalRemove(self)
        else
            ISPanel.removeFromUIManager(self)
        end
    end

    function ISEquippedItem:checkSidebarSizeOption()
        if originalCheckSize then originalCheckSize(self) end
        if BUUI_isCurrentPanel(self) then BUUI_ensurePopup(self) end
    end
end

-- Wrapping the sidebar while the UI is still booting can leave it half-built, so
-- the patch waits for the game to be up.
Events.OnGameStart.Add(BUUI_patchSidebar)
