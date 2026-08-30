----------
--ESTRAL--
----------

require "BUUI_Spinner"

BUUI_Row = ISPanel:derive("BUUI_Row")

BUUI_Row.HEIGHT = 56

local ICON = 32
local PAD = 8
local ACCENT = 2
local CONTROL_HEIGHT = 20
local LINE_ONE = 8
local LINE_TWO = 30

local COL_NAME = { r = 0.90, g = 0.91, b = 0.90 }
local COL_COUNT = { r = 0.80, g = 0.74, b = 0.50 }
local COL_DIM = { r = 0.58, g = 0.58, b = 0.58 }
local COL_BLOCKED = { r = 0.78, g = 0.45, b = 0.45 }
local COL_READY = { r = 0.48, g = 0.76, b = 0.48 }

function BUUI_Row:new(x, y, width, height, panel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.panel = panel
    o.background = true
    o.backgroundColor = { r = 1, g = 1, b = 1, a = 0.03 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.06 }
    o.row = nil

    return o
end

function BUUI_Row:createChildren()
    ISPanel.createChildren(self)

    local controlY = (BUUI_Row.HEIGHT - CONTROL_HEIGHT) / 2

    self.spinner = BUUI_Spinner:new(0, controlY, 10, CONTROL_HEIGHT, self, BUUI_Row.onQuantity)
    self.spinner:initialise()
    self.spinner:instantiate()
    self:addChild(self.spinner)

    self:layout()
end

function BUUI_Row:layout()
    if not self.spinner then return end

    self.spinner:setX(self.width - self.spinner:getWidth() - PAD)
end

-- Where the text has to stop so it never runs under the spinner.
function BUUI_Row:textLimit()
    return self.spinner:getX() - PAD
end

function BUUI_Row:setRow(row)
    self.row = row
    if not row then return end

    -- setMax re-fires onChange carrying the value left over from whichever row this
    -- recycled widget showed last, which would overwrite the one being restored.
    self.settingRow = true
    self.spinner:setMax(row.max)
    self.spinner:setValue(row.quantity or 1)
    self.settingRow = false
    row.quantity = self.spinner:getValue()

    self:layout()
end

function BUUI_Row:onQuantity(value)
    if self.settingRow then return end

    if self.row then self.row.quantity = value end
    if self.panel then self.panel:updateFooter() end
end

function BUUI_Row:onResize()
    ISPanel.onResize(self)
    self:layout()
end

function BUUI_Row:prerender()
    self.backgroundColor.a = self:isMouseOver() and 0.08 or 0.03
    ISPanel.prerender(self)
end

function BUUI_Row:render()
    ISPanel.render(self)

    local row = self.row
    if not row then return end

    -- The state of a row is the thing a player scans for, so it gets a colour bar
    -- rather than only a word buried in the ingredient list.
    local accent = row.ready and COL_READY or COL_BLOCKED
    self:drawRect(0, 0, ACCENT, self.height, 0.85, accent.r, accent.g, accent.b)

    if row.texture then
        self:drawTextureScaledAspect(row.texture, PAD, (self.height - ICON) / 2, ICON, ICON, 1, 1, 1, 1)
    end

    local textX = PAD + ICON + PAD
    local limit = self:textLimit()

    self:renderName(row, textX, limit)
    self:renderIngredients(row, textX, limit)
end

function BUUI_Row:renderName(row, x, limit)
    local name = NeatTool.truncateText(row.name or "?", limit - x, UIFont.Small)
    self:drawText(name, x, LINE_ONE, COL_NAME.r, COL_NAME.g, COL_NAME.b, 1, UIFont.Small)
    x = x + getTextManager():MeasureStringX(UIFont.Small, name) + 6

    -- A row can stand for several item types the game names identically, so it says
    -- how many of the thing are in reach rather than leaving the player to guess.
    if (row.sourceCount or 1) > 1 then
        if x >= limit then return end

        local count = getText("IGUI_BUUI_Count", tostring(row.sourceCount))
        self:drawText(count, x, LINE_ONE, COL_COUNT.r, COL_COUNT.g, COL_COUNT.b, 1, UIFont.Small)
        x = x + getTextManager():MeasureStringX(UIFont.Small, count) + 10
    end

    if not row.result or x >= limit then return end

    local suffix = NeatTool.truncateText(
        getText("IGUI_BUUI_Makes") .. " " .. row.result, limit - x, UIFont.Small)
    self:drawText(suffix, x, LINE_ONE, COL_DIM.r, COL_DIM.g, COL_DIM.b, 1, UIFont.Small)
end

function BUUI_Row:renderIngredients(row, x, limit)
    for _, input in ipairs(row.inputs) do
        if x >= limit then return end

        local glyph = input.satisfied and self.panel.iconTrue or self.panel.iconFalse
        if glyph then
            self:drawTextureScaledAspect(glyph, x, LINE_TWO + 2, 10, 10, 1, 1, 1, 1)
            x = x + 13
        end

        local shade = input.satisfied and COL_DIM or COL_BLOCKED
        local text = NeatTool.truncateText(
            input.label .. "  " .. tostring(input.have) .. "/" .. tostring(input.need),
            limit - x, UIFont.Small)

        self:drawText(text, x, LINE_TWO, shade.r, shade.g, shade.b, 1, UIFont.Small)
        x = x + getTextManager():MeasureStringX(UIFont.Small, text) + 12
    end
end
