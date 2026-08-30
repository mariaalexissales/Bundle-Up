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
    o.bundling = true
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

-- both footer buttons swap label with the tab and one of them turns into Stop, so each
-- is sized for the widest text it can ever hold and the strip never reflows.
local function BUUI_labelWidth(button, ...)
    local widest = 0
    for _, key in ipairs({ ... }) do
        widest = math.max(widest, getTextManager():MeasureStringX(button.font, getText(key)))
    end
    return 24 + widest
end

-- anchors are applied by instantiate(), so they have to be assigned before it runs.
function BUUI_Panel:attach(button, anchors)
    for key, value in pairs(anchors or {}) do button[key] = value end

    button:initialise()
    button:instantiate()
    self:addChild(button)

    return button
end

function BUUI_Panel:createChildren()
    ISCollapsableWindow.createChildren(self)

    local tabY, _, listY, footerY = self:bands()
    local RIGHT = { anchorRight = true, anchorLeft = false }
    local FOOTER = { anchorTop = false, anchorBottom = true, anchorRight = true, anchorLeft = false }

    self.tabBundle = BUUI_Button:new(PAD, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_Bundle"), self, BUUI_Panel.onTab)
    self.tabBundle:sizeToTitle(28)
    self.tabBundle.bundling = true
    self:attach(self.tabBundle)

    self.tabUnbundle = BUUI_Button:new(self.tabBundle:getRight() + 4, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_Unbundle"), self, BUUI_Panel.onTab)
    self.tabUnbundle:sizeToTitle(28)
    self.tabUnbundle.bundling = false
    self:attach(self.tabUnbundle)

    self.refreshButton = BUUI_Button:new(0, tabY, 10, TAB_HEIGHT, getText("IGUI_BUUI_RefreshLabel"), self, BUUI_Panel.onRefresh)
    self.refreshButton:sizeToTitle(20)
    self.refreshButton:setX(self.width - self.refreshButton:getWidth() - PAD)
    self:attach(self.refreshButton, RIGHT)

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
    self.bundleAll:setWidth(BUUI_labelWidth(self.bundleAll,
        "IGUI_BUUI_BundleAll", "IGUI_BUUI_UnbundleAll", "IGUI_BUUI_Stop"))
    self.bundleAll:setX(self.width - self.bundleAll:getWidth() - PAD)
    self:attach(self.bundleAll, FOOTER)

    self.bundleItems = BUUI_Button:new(0, footerY + 4, 10, TAB_HEIGHT, getText("IGUI_BUUI_BundleItems"), self, BUUI_Panel.onBundleItems)
    self.bundleItems:setWidth(BUUI_labelWidth(self.bundleItems,
        "IGUI_BUUI_BundleItems", "IGUI_BUUI_UnbundleItems", "IGUI_BUUI_Stop"))
    self.bundleItems:setX(self.bundleAll:getX() - self.bundleItems:getWidth() - GAP)
    self:attach(self.bundleItems, FOOTER)

    self:refresh()
end

function BUUI_Panel:onTab(button)
    self.bundling = button.bundling
    self:refresh()
end

function BUUI_Panel:onRefresh()
    self:refresh()
end

function BUUI_Panel:refresh()
    -- the auto-refresh rebuilds every row, so a dialled quantity has to be carried
    -- across by key or the timer wipes it before the player reaches the button.
    local dialled = {}
    for _, row in ipairs(self.rows) do
        if row.key then dialled[row.key] = row.quantity end
    end

    local rows, containers = BUUI.resolveRows(self.player, self.bundling)
    self.rows = rows
    self.sourceText = self:describeSources(containers)

    self.ready = 0
    for _, row in ipairs(self.rows) do
        local previous = dialled[row.key]
        if previous then row.quantity = math.min(previous, row.max) end
        if row.ready then self.ready = self.ready + 1 end
    end

    -- The scroll view only reassigns data when the visible range moves, so a
    -- refresh that leaves the row count alone still needs to be forced through.
    self.list:setDataSource(self.rows, true)

    self:updateFooter()
end

-- Split from refresh because a spinner changes what the buttons should say without
-- changing what is in reach, and re-resolving every row on a click of + is far too slow.
function BUUI_Panel:updateFooter()
    if not self.bundleItems then return end

    self.bundleItems.title = getText(self.bundling and "IGUI_BUUI_BundleItems" or "IGUI_BUUI_UnbundleItems")
    self.bundleAll.title = getText(self.bundling and "IGUI_BUUI_BundleAll" or "IGUI_BUUI_UnbundleAll")

    -- only the button that started the batch becomes the stop control, so there is
    -- never a question of which run a Stop would cancel. a batch that outlived the
    -- window it was started from has no button of its own, and falls to Bundle All
    -- rather than leaving a reopened panel with nothing that can cancel it.
    if BUUI.Queue.isRunning() then
        local stop = self.runningButton or self.bundleAll
        stop.title = getText("IGUI_BUUI_Stop")
        self.bundleItems.enable = stop == self.bundleItems
        self.bundleAll.enable = stop == self.bundleAll
        return
    end

    local chosen = 0
    for _, row in ipairs(self.rows) do
        if row.ready and (row.quantity or 0) > 0 then chosen = chosen + 1 end
    end

    self.bundleItems.enable = chosen > 0
    self.bundleAll.enable = (self.ready or 0) > 0
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

function BUUI_Panel:stopBatch()
    BUUI.Queue.stop()
    self.runningButton = nil
    self:refresh()
end

function BUUI_Panel:onBatchFinished()
    self.runningButton = nil
    self:refresh()
end

-- Runs exactly what the player dialled in, on the rows as they stand. Bundle All keeps
-- re-reading the containers between recipes; this deliberately does not.
function BUUI_Panel:onBundleItems()
    if BUUI.Queue.isRunning() then
        self:stopBatch()
        return
    end

    local chosen = {}
    for _, row in ipairs(self.rows) do
        if row.ready and (row.quantity or 0) > 0 then
            chosen[#chosen + 1] = row
        end
    end
    if #chosen == 0 then return end

    self.runningButton = self.bundleItems
    BUUI.Queue.startRows(self.player, chosen,
        function() self:refresh() end,
        function() self:onBatchFinished() end)
    self:refresh()
end

function BUUI_Panel:onBundleAll()
    if BUUI.Queue.isRunning() then
        self:stopBatch()
        return
    end

    self.runningButton = self.bundleAll
    BUUI.Queue.startAll(self.player, self.bundling,
        function() self:refresh() end,
        function() self:onBatchFinished() end)
    self:refresh()
end

function BUUI_Panel:prerender()
    ISCollapsableWindow.prerender(self)

    self.tabBundle.selected = self.bundling
    self.tabUnbundle.selected = not self.bundling

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
        local empty = getText(self.bundling and "IGUI_BUUI_Empty" or "IGUI_BUUI_EmptyUnbundle")
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
