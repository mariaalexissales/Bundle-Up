----------
--ESTRAL--
----------

require "ViewpointUI/API"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"
require "BUUI_Model"

BUVP = BUVP or {}

local VPUI = ViewpointUI
local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region

local TAB_ID = "bundleup"
local REFRESH_MS = 1500
local ICON = "media/ui/Sidebar/48/BundleUp_On_48.png"

local MODES = {
    { id = BUUI.MODE.BUNDLE, label = "IGUI_BUUI_Bundle" },
    { id = BUUI.MODE.UNBUNDLE, label = "IGUI_BUUI_Unbundle" },
    { id = BUUI.MODE.MERGE, label = "IGUI_BUUI_Merge" },
}

local Tab = {}
Tab.__index = Tab

local function BUVP_fit(text, font, maxW)
    text = tostring(text or "")
    local tm = getTextManager()
    if maxW <= 0 then return "" end
    if tm:MeasureStringX(font, text) <= maxW then return text end
    local cut = text
    while #cut > 1 and tm:MeasureStringX(font, cut .. "..") > maxW do cut = string.sub(cut, 1, #cut - 1) end
    return cut .. ".."
end

local function BUVP_inside(r, x, y)
    return x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h
end

local function BUVP_dial(x, y, w, h)
    local small = Theme.smallFont()
    local gap = Theme.px(3)
    local size = Theme.fontHeight(small) + Theme.px(8)
    local valueW = Theme.textWidth(Theme.font(), "0000") + Theme.px(10)
    local maxW = Theme.textWidth(small, getText("IGUI_BUUI_Max")) + Theme.px(14)
    local top = y + math.floor((h - size) / 2)

    local right = x + w - Theme.px(10)
    local max = { x = right - maxW, y = top, w = maxW, h = size }
    local more = { x = max.x - gap - size, y = top, w = size, h = size }
    local value = { x = more.x - gap - valueW, y = top, w = valueW, h = size }
    local less = { x = value.x - gap - size, y = top, w = size, h = size }
    return { less = less, value = value, more = more, max = max }
end

function Tab:rowAt(x, y)
    local list = self.list
    local i = list:indexAt(x, y)
    local rect = i and list.rects[i]
    if not rect then return nil end
    return list.rows[i], BUVP_dial(list.x + rect.x, list.y + rect.y - list.scroll, rect.w, rect.h)
end

function Tab:drawButton(ui, r, label, enabled, font)
    local hover = enabled and BUVP_inside(r, self.mx or -1, self.my or -1)
    local bg = hover and C.panelHi or C.panel
    ui:drawRect(r.x, r.y, r.w, r.h, bg.a, bg.r, bg.g, bg.b)
    ui:drawRectBorder(r.x, r.y, r.w, r.h, 0.25, C.edge.r, C.edge.g, C.edge.b)
    local c = enabled and C.text or C.off
    local tw = Theme.textWidth(font, label)
    ui:drawText(label, r.x + math.floor((r.w - tw) / 2), r.y + math.floor((r.h - Theme.fontHeight(font)) / 2),
        c.r, c.g, c.b, 1, font)
end

function Tab:drawDial(ui, row, dial)
    local small = Theme.smallFont()
    local live = (row.max or 0) > 0
    self:drawButton(ui, dial.less, "-", live, small)
    self:drawButton(ui, dial.more, "+", live, small)
    self:drawButton(ui, dial.max, getText("IGUI_BUUI_Max"), live, small)

    local v = dial.value
    ui:drawRect(v.x, v.y, v.w, v.h, 0.5, 0, 0, 0)
    ui:drawRectBorder(v.x, v.y, v.w, v.h, 0.25, C.edge.r, C.edge.g, C.edge.b)
    local font = Theme.font()
    local text = tostring(row.quantity or 0)
    local c = live and C.text or C.off
    ui:drawText(text, v.x + math.floor((v.w - Theme.textWidth(font, text)) / 2),
        v.y + math.floor((v.h - Theme.fontHeight(font)) / 2), c.r, c.g, c.b, 1, font)
end

function Tab:drawRow(ui, row, x, y, w, h)
    local font, small = Theme.font(), Theme.smallFont()
    local pad = Theme.px(8)

    local accent = row.ready and C.good or C.danger
    ui:drawRect(x, y, Theme.px(2), h - 1, 0.85, accent.r, accent.g, accent.b)

    local icon = h - Theme.px(14)
    if row.texture then
        ui:drawTextureScaledAspect(row.texture, x + pad, y + math.floor((h - icon) / 2), icon, icon, 1, 1, 1, 1)
    end

    local dial = BUVP_dial(x, y, w, h)
    self:drawDial(ui, row, dial)

    local textX = x + pad + icon + pad
    local limit = dial.less.x - pad
    local lineOne = y + Theme.px(5)
    local lineTwo = lineOne + Theme.fontHeight(font) + Theme.px(2)

    local name = BUVP_fit(row.name or "?", font, limit - textX)
    ui:drawText(name, textX, lineOne, C.text.r, C.text.g, C.text.b, 1, font)
    local cx = textX + Theme.textWidth(font, name) + Theme.px(6)

    if (row.sourceCount or 1) > 1 and cx < limit then
        local count = getText("IGUI_BUUI_Count", tostring(row.sourceCount))
        ui:drawText(count, cx, lineOne, C.accent.r, C.accent.g, C.accent.b, 1, font)
        cx = cx + Theme.textWidth(font, count) + Theme.px(10)
    end

    if row.result and cx < limit then
        local makes = BUVP_fit(getText("IGUI_BUUI_Makes") .. " " .. row.result, small, limit - cx)
        ui:drawText(makes, cx, lineOne + Theme.fontHeight(font) - Theme.fontHeight(small),
            C.dim.r, C.dim.g, C.dim.b, 1, small)
    end

    local ix = textX
    local mark = Theme.px(6)
    for _, input in ipairs(row.inputs or {}) do
        if ix >= limit then break end

        local shade = input.satisfied and C.good or C.danger
        ui:drawRect(ix, lineTwo + math.floor((Theme.fontHeight(small) - mark) / 2), mark, mark,
            0.9, shade.r, shade.g, shade.b)
        ix = ix + mark + Theme.px(4)

        local c = input.satisfied and C.dim or C.danger
        local text = BUVP_fit(input.label .. "  " .. tostring(input.have) .. "/" .. tostring(input.need),
            small, limit - ix)
        ui:drawText(text, ix, lineTwo, c.r, c.g, c.b, 1, small)
        ix = ix + Theme.textWidth(small, text) + Theme.px(12)
    end
end

function Tab.create(screen)
    local self = setmetatable({}, Tab)
    self.screen = screen
    self.mode = BUUI.MODE.BUNDLE
    self.rows = {}
    self.ready = 0
    self.skipped = 0
    self.nextRead = 0
    self.dirty = true

    self.modes = Region.TabBar.new(function(id)
        self.mode = id
        self:refresh()
    end)

    self.list = Region.List.new({
        rowHeight = function()
            return Theme.fontHeight(Theme.font()) + Theme.fontHeight(Theme.smallFont()) + Theme.px(16)
        end,
        drawRow = function(ui, row, x, y, w, h) self:drawRow(ui, row, x, y, w, h) end,
    })

    local B = Region.Button
    self.refreshButton = B.new({ label = getText("IGUI_BUUI_RefreshLabel"),
        onClick = function() self:refresh() end })
    self.itemsButton = B.new({ label = "", accent = true,
        onClick = function() self:onItems() end,
        enabled = function() return self:footerEnabled(self.itemsButton) end })
    self.allButton = B.new({ label = "",
        onClick = function() self:onAll() end,
        enabled = function() return self:footerEnabled(self.allButton) end })

    BUVP.tab = self
    return self
end

function Tab:open()
    self.player = VPUI.Util.player()
    self.dirty = true
    self.nextRead = 0
end

function Tab:refresh(scan)
    self.player = self.player or VPUI.Util.player()
    if not self.player then return end

    BUUI.refreshView(self, scan)
    for _, row in ipairs(self.rows) do
        if row.quantity == nil then row.quantity = math.min(1, row.max or 0) end
    end

    self.list.spec.emptyText = getText(BUUI.LABELS[self.mode].empty)
    self.list:setRows(self.rows)
    self.dirty = false
end

function Tab:refreshIfShown()
    if VPUI.Hub.activeId() == TAB_ID then
        self:refresh()
    else
        self.dirty = true
    end
end

function Tab:batchFinished()
    self.running = nil
    self:refreshIfShown()
end

-- only the button that started the batch becomes Stop. a batch from a hotkey or the
-- other panel has none here, and falls to All so it can still be cancelled.
function Tab:stopButton()
    return self.running or self.allButton
end

function Tab:footerEnabled(button)
    if BUUI.Queue.isRunning() then return button == self:stopButton() end
    if button == self.itemsButton then return #BUUI.chosenRows(self) > 0 end
    return (self.ready or 0) > 0
end

function Tab:stopBatch()
    BUUI.Queue.stop()
    self.running = nil
    self:refresh()
end

function Tab:onItems()
    if BUUI.Queue.isRunning() then
        self:stopBatch()
        return
    end

    local chosen = BUUI.chosenRows(self)
    if #chosen == 0 or not self.player then return end

    self.running = self.itemsButton
    BUUI.Queue.startRows(self.player, chosen,
        function() self:refreshIfShown() end,
        function() self:batchFinished() end)
    self:refresh()
end

function Tab:onAll()
    if BUUI.Queue.isRunning() then
        self:stopBatch()
        return
    end
    if not self.player then return end

    self.running = self.allButton
    BUUI.Queue.startAll(self.player, self.mode,
        function() self:refreshIfShown() end,
        function() self:batchFinished() end)
    self:refresh()
end

function Tab:update(now)
    if BUUI.Queue.isRunning() then return end

    -- the other panel's Stop ends a batch without telling the views.
    if self.running then
        self.running = nil
        self.dirty = true
    end

    if self.dirty then
        self.nextRead = now + REFRESH_MS
        self:refresh()
        return
    end

    if now < self.nextRead then return end
    self.nextRead = now + REFRESH_MS

    if not self.player then return end
    local changed, scan = BUUI.pollView(self)
    if changed then self:refresh(scan) end
end

function Tab:setQuantity(key, value)
    for _, row in ipairs(self.rows) do
        if row.key == key then
            row.quantity = math.max(0, math.min(row.max or 0, value))
            return
        end
    end
end

function Tab:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }

    local font, small = Theme.font(), Theme.smallFont()
    local tabH = Theme.fontHeight(UIFont.Medium) + Theme.px(12)
    local btnH = Theme.fontHeight(font) + Theme.px(10)
    local gap = Theme.px(8)

    local tabs = {}
    for _, mode in ipairs(MODES) do tabs[#tabs + 1] = { id = mode.id, label = getText(mode.label) } end
    self.modes:setTabs(tabs, self.mode)

    local refreshW = self.refreshButton:preferredWidth()
    self.refreshButton:layout(x + w - refreshW, y + math.floor((tabH - btnH) / 2), refreshW, btnH)
    self.modes:layout(x, y, w - refreshW - gap, tabH)

    self.sourcesY = y + tabH + Theme.px(6)
    self.sourcesH = Theme.fontHeight(small) + Theme.px(8)

    local footerY = y + h - btnH
    self.footerY = footerY
    self.footerH = btnH

    local listY = self.sourcesY + self.sourcesH + Theme.px(6)
    self.list:layout(x, listY, w, footerY - gap - listY)

    -- both footer buttons swap label with the tab and one turns into Stop, so each is
    -- sized for the widest text it can hold and the strip never reflows.
    local function widest(field)
        local most = Theme.textWidth(font, getText("IGUI_BUUI_Stop"))
        for _, labels in pairs(BUUI.LABELS) do
            most = math.max(most, Theme.textWidth(font, getText(labels[field])))
        end
        return most + Theme.px(24)
    end
    self.itemsButton.font, self.allButton.font = font, font
    local allW, itemsW = widest("all"), widest("items")
    self.allButton:layout(x + w - allW, footerY, allW, btnH)
    self.itemsButton:layout(self.allButton.x - gap - itemsW, footerY, itemsW, btnH)
end

function Tab:render(ui, mx, my)
    if not self.area then return end
    self.mx, self.my = mx, my

    local a = self.area
    local small = Theme.smallFont()

    self.modes.active = self.mode
    self.modes:draw(ui, mx, my)
    self.refreshButton:draw(ui, mx, my)

    ui:drawRect(a.x, self.sourcesY, a.w, self.sourcesH, C.panel.a, C.panel.r, C.panel.g, C.panel.b)
    ui:drawText(BUVP_fit(self.sourceText or "", small, a.w - Theme.px(16)), a.x + Theme.px(8),
        self.sourcesY + Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, small)

    self.list:draw(ui, mx, my)

    local labels = BUUI.LABELS[self.mode]
    self.itemsButton.label = getText(labels.items)
    self.allButton.label = getText(labels.all)
    if BUUI.Queue.isRunning() then self:stopButton().label = getText("IGUI_BUUI_Stop") end
    self.itemsButton:draw(ui, mx, my)
    self.allButton:draw(ui, mx, my)

    local blocked = #self.rows - (self.ready or 0)
    local summary = getText("IGUI_BUUI_Summary", tostring(self.ready or 0), tostring(blocked))
    ui:drawText(summary, a.x, self.footerY + math.floor((self.footerH - Theme.fontHeight(small)) / 2),
        C.dim.r, C.dim.g, C.dim.b, 1, small)
end

function Tab:mouseDown(x, y, mods)
    if self.refreshButton:mouseDown(x, y) then return true end
    if self.itemsButton:mouseDown(x, y) then return true end
    if self.allButton:mouseDown(x, y) then return true end
    if self.modes:mouseDown(x, y) then return true end

    local row, dial = self:rowAt(x, y)
    if not row or (row.max or 0) < 1 then return false end

    local quantity = row.quantity or 0
    if BUVP_inside(dial.less, x, y) then
        self:setQuantity(row.key, quantity - 1)
    elseif BUVP_inside(dial.more, x, y) then
        self:setQuantity(row.key, quantity + 1)
    elseif BUVP_inside(dial.max, x, y) then
        self:setQuantity(row.key, row.max)
    elseif BUVP_inside(dial.value, x, y) then
        local key = row.key
        self.screen:openAmount(x, y, {
            title = row.name, max = row.max, initial = math.max(1, quantity),
            onConfirm = function(n) self:setQuantity(key, n) end,
        })
        if self.screen.amount then self.screen.amount.ok.label = getText("IGUI_BUVP_Set") end
    end
    return true
end

function Tab:mouseUp()
    self.list:mouseUp()
end

function Tab:wheel(x, y, del)
    local row, dial = self:rowAt(x, y)
    if row and (row.max or 0) > 0 and BUVP_inside(dial.value, x, y) then
        self:setQuantity(row.key, (row.quantity or 0) - del)
        return true
    end
    return self.list:wheel(x, y, del)
end

BUUI.addView(function(finished)
    local tab = BUVP.tab
    if not tab then return end
    if finished then tab.running = nil end
    tab:refreshIfShown()
end)

VPUI.Hub.register({
    id = TAB_ID,
    label = getText("IGUI_BUUI_Title"),
    icon = ICON,
    order = 25,
    key = function() return BUVP.toggleKey and BUVP.toggleKey:getValue() or 0 end,
    create = Tab.create,
})

BUVP.TAB_ID = TAB_ID
