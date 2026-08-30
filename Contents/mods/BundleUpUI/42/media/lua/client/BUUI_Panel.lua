----------
--ESTRAL--
----------

require "ISUI/ISCollapsableWindow"
require "BUUI_Button"
require "BUUI_Index"
require "BUUI_Queue"
require "BUUI_Row"

BUUI = BUUI or {}
BUUI.players = BUUI.players or {}

BUUI_Panel = ISCollapsableWindow:derive("BUUI_Panel")

local PAD = 8
local GAP = 6
local TAB_HEIGHT = 22
local BAR_HEIGHT = 22
local FOOTER_HEIGHT = 30
local REFRESH_TICKS = 90

local COL_BAR = { r = 0, g = 0, b = 0, a = 0.35 }
local COL_FRAME = { r = 1, g = 1, b = 1, a = 0.09 }
local COL_WELL = { r = 0, g = 0, b = 0, a = 0.25 }
local COL_TEXT = { r = 0.68, g = 0.68, b = 0.68 }
local COL_EMPTY = { r = 0.50, g = 0.50, b = 0.50 }

function BUUI.getWindow(playerNum)
    local data = BUUI.players[playerNum]
    return data and data.instance or nil
end

function BUUI.isWindowOpen(playerNum)
    return BUUI.getWindow(playerNum) ~= nil
end

function BUUI_Panel:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.playerNum = player:getPlayerNum()
    o.title = getText("IGUI_BUUI_Title")
    o.direction = "pack"
    o.rows = {}
    o.ticks = 0
    o.resizable = true
    o.minimumWidth = 600
    o.minimumHeight = 320

    o.iconTrue = getTexture("media/ui/NeatUI/ICON/Icon_True.png")
    o.iconFalse = getTexture("media/ui/NeatUI/ICON/Icon_False.png")

    return o
end

-- One place computes the vertical bands so createChildren and onResize cannot drift.
--
-- A resizable ISCollapsableWindow reserves the bottom of itself: render paints a
-- status bar across it and createChildren lays a second ISResizeWidget over the
-- whole bottom edge, which swallows clicks. Anything drawn there is both covered
-- up and unclickable, and because the strip is pinned to the edge it follows the
-- window on resize. The footer sits above it.
function BUUI_Panel:bands()
    local tabY = self:titleBarHeight() + PAD
    local barY = tabY + TAB_HEIGHT + GAP
    local listY = barY + BAR_HEIGHT + GAP
    local footerY = self.height - self:resizeWidgetHeight() - FOOTER_HEIGHT
    return tabY, barY, listY, footerY
end

function BUUI_Panel:createChildren()
    ISCollapsableWindow.createChildren(self)

    local tabY, _, listY, footerY = self:bands()

    self.tabBundle = BUUI_Button:new(PAD, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_Bundle"), self, BUUI_Panel.onTab)
    self.tabBundle:sizeToTitle(28)
    self.tabBundle.internal = "pack"
    self.tabBundle:initialise()
    self.tabBundle:instantiate()
    self:addChild(self.tabBundle)

    self.tabUnbundle = BUUI_Button:new(self.tabBundle:getRight() + 4, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_Unbundle"), self, BUUI_Panel.onTab)
    self.tabUnbundle:sizeToTitle(28)
    self.tabUnbundle.internal = "unpack"
    self.tabUnbundle:initialise()
    self.tabUnbundle:instantiate()
    self:addChild(self.tabUnbundle)

    self.refreshButton = BUUI_Button:new(0, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_RefreshLabel"), self, BUUI_Panel.onRefresh)
    self.refreshButton:sizeToTitle(20)
    self.refreshButton:setX(self.width - self.refreshButton:getWidth() - PAD)
    self.refreshButton.anchorRight = true
    self.refreshButton.anchorLeft = false
    self.refreshButton:initialise()
    self.refreshButton:instantiate()
    self:addChild(self.refreshButton)

    -- The scroll view paints nothing of its own, so it sits one pixel inside the
    -- frame the panel draws for it.
    self.list = NIVirtualScrollView:new(PAD + 1, listY + 1, self.width - PAD * 2 - 2, footerY - listY - GAP - 2)
    self.list:initialise()
    self.list:instantiate()
    self.list:setOnCreateItem(function()
        local row = BUUI_Row:new(0, 0, self.list:getWidth(), BUUI_Row.HEIGHT, self)
        row:instantiate()
        return row
    end)
    self.list:setOnUpdateItem(function(widget, data)
        widget:setWidth(self.list:getWidth())
        widget:setRow(data)
    end)
    self.list:setConfig(BUUI_Row.HEIGHT, 4)
    self:addChild(self.list)

    self.bundleAll = BUUI_Button:new(0, footerY + 4, 10, TAB_HEIGHT, getText("IGUI_BUUI_BundleAll"), self, BUUI_Panel.onBundleAll)
    self.bundleAll:setWidth(24 + math.max(
        getTextManager():MeasureStringX(self.bundleAll.font, getText("IGUI_BUUI_BundleAll")),
        getTextManager():MeasureStringX(self.bundleAll.font, getText("IGUI_BUUI_Stop"))))
    self.bundleAll:setX(self.width - self.bundleAll:getWidth() - PAD)
    self.bundleAll.anchorTop = false
    self.bundleAll.anchorBottom = true
    self.bundleAll.anchorRight = true
    self.bundleAll.anchorLeft = false
    self.bundleAll:initialise()
    self.bundleAll:instantiate()
    self:addChild(self.bundleAll)

    self:refresh()
end

function BUUI_Panel:onTab(button)
    self.direction = button.internal
    self:refresh()
end

function BUUI_Panel:onRefresh()
    self:refresh()
end

function BUUI_Panel:refresh()
    local rows, containers = BUUI.resolveRows(self.player, self.direction)
    self.rows = rows
    self.sourceText = self:describeSources(containers)

    -- The scroll view only reassigns data when the visible range moves, so a
    -- refresh that leaves the row count alone still needs to be forced through.
    self.list:setDataSource(self.rows, true)

    self.ready = 0
    for _, row in ipairs(self.rows) do
        if row.ready then self.ready = self.ready + 1 end
    end

    local running = BUUI.Queue.isRunning()
    self.bundleAll.title = running and getText("IGUI_BUUI_Stop") or getText("IGUI_BUUI_BundleAll")
    self.bundleAll.enable = running or self.ready > 0
end

-- Naming the containers is what makes the panel legible when the player is stood
-- between a crate, a shelf and their own bag: it says where the rows came from.
-- Labels follow the inventory UI's own convention so they read the same and come
-- out translated: a bag is named by the item holding it, everything else by its
-- container type. The player's own inventory has neither, so it would otherwise
-- print its raw type of "none".
local function BUUI_containerName(container)
    local holder = container:getContainingItem()
    if holder then return holder:getName() end

    local kind = container:getType()
    if not kind or kind == "" or kind == "none" then
        return getText("IGUI_BUUI_Inventory")
    end

    return getTextOrNull("IGUI_ContainerTitle_" .. tostring(kind)) or tostring(kind)
end

function BUUI_Panel:describeSources(containers)
    local names, seen = {}, {}

    for i = 0, containers:size() - 1 do
        local name = BUUI_containerName(containers:get(i))
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    if #names == 0 then return getText("IGUI_BUUI_NoSources") end

    local shown = {}
    for i = 1, math.min(3, #names) do shown[i] = names[i] end

    local text = getText("IGUI_BUUI_Sources") .. " " .. table.concat(shown, ", ")
    if #names > 3 then
        text = text .. " (+" .. tostring(#names - 3) .. ")"
    end

    return text
end

function BUUI_Panel:bundleRow(row)
    if BUUI.Queue.isRunning() then return end

    BUUI.Queue.startRow(self.player, row,
        function() self:refresh() end,
        function() self:refresh() end)
    self:refresh()
end

function BUUI_Panel:onBundleAll()
    if BUUI.Queue.isRunning() then
        BUUI.Queue.stop()
        self:refresh()
        return
    end

    BUUI.Queue.startAll(self.player, self.direction,
        function() self:refresh() end,
        function() self:refresh() end)
    self:refresh()
end

function BUUI_Panel:prerender()
    ISCollapsableWindow.prerender(self)

    self.tabBundle.selected = self.direction == "pack"
    self.tabUnbundle.selected = self.direction == "unpack"

    local _, barY, listY, footerY = self:bands()
    local inner = self.width - PAD * 2
    local listHeight = footerY - listY - GAP

    self:drawRect(PAD, barY, inner, BAR_HEIGHT, COL_BAR.a, COL_BAR.r, COL_BAR.g, COL_BAR.b)

    self:drawRect(PAD, listY, inner, listHeight, COL_WELL.a, COL_WELL.r, COL_WELL.g, COL_WELL.b)
    self:drawRectBorder(PAD, listY, inner, listHeight, COL_FRAME.a, COL_FRAME.r, COL_FRAME.g, COL_FRAME.b)

    self:drawRect(PAD, footerY, inner, 1, COL_FRAME.a, COL_FRAME.r, COL_FRAME.g, COL_FRAME.b)
end

function BUUI_Panel:render()
    ISCollapsableWindow.render(self)

    local _, barY, listY, footerY = self:bands()

    self:drawText(self.sourceText or "", PAD + GAP, barY + 4, COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, UIFont.Small)

    if #self.rows == 0 then
        local empty = getText("IGUI_BUUI_Empty")
        local width = getTextManager():MeasureStringX(UIFont.Small, empty)
        local height = footerY - listY - GAP
        self:drawText(empty, (self.width - width) / 2, listY + height / 2 - 8,
            COL_EMPTY.r, COL_EMPTY.g, COL_EMPTY.b, 1, UIFont.Small)
    end

    local blocked = #self.rows - (self.ready or 0)
    local summary = getText("IGUI_BUUI_Summary", tostring(self.ready or 0), tostring(blocked))
    self:drawText(summary, PAD, footerY + 9, COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, UIFont.Small)
end

function BUUI_Panel:update()
    ISCollapsableWindow.update(self)

    -- Containers open, close and empty while the panel is up, so the list keeps
    -- itself current instead of going stale until the player clicks refresh.
    -- Resolving a row means probing the recipe, which is far too expensive to do
    -- every frame against a crate holding a hundred distinct carton families.
    -- While a batch is running the queue's own progress callback covers this.
    if BUUI.Queue.isRunning() then return end

    self.ticks = self.ticks + 1
    if self.ticks >= REFRESH_TICKS then
        self.ticks = 0
        self:refresh()
    end
end

function BUUI_Panel:onResize()
    ISCollapsableWindow.onResize(self)

    if not self.list then return end

    local _, _, listY, footerY = self:bands()
    local listHeight = footerY - listY - GAP - 2

    self.list:setWidth(self.width - PAD * 2 - 2)
    self.list:setHeight(listHeight)

    -- setConfig tears down and rebuilds the whole widget pool, and onResize fires
    -- on every frame of a drag, so only reconfigure when the height actually moved.
    if self.listHeight ~= listHeight then
        self.listHeight = listHeight
        self.list:setConfig(BUUI_Row.HEIGHT, 4)
    end

    self.list:setDataSource(self.rows, true)
end

function BUUI_Panel:onCloseClick()
    self:close()
end

function BUUI_Panel:close()
    local data = BUUI.players[self.playerNum]
    if data and data.instance == self then
        data.x = self:getX()
        data.y = self:getY()
        data.instance = nil
    end

    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
end

function BUUI.openPanel(player)
    local playerNum = player:getPlayerNum()

    if BUUI.isWindowOpen(playerNum) then
        local existing = BUUI.getWindow(playerNum)
        existing:setVisible(true)
        existing:bringToTop()
        return
    end

    local data = BUUI.players[playerNum]
    if not data then
        data = {}
        BUUI.players[playerNum] = data
    end

    local width, height = 720, 560
    local x = data.x or 0
    local y = data.y or (getCore():getScreenHeight() - height - 40)

    local window = BUUI_Panel:new(x, y, width, height, player)
    window:initialise()
    window:instantiate()
    window:addToUIManager()

    data.instance = window
end

Events.OnPlayerDeath.Add(function(player)
    local playerNum = player:getPlayerNum()
    if BUUI.isWindowOpen(playerNum) then
        BUUI.getWindow(playerNum):close()
    end
end)
