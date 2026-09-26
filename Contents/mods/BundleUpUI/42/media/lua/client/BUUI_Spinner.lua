----------
--ESTRAL--
----------

require "BUUI_Button"

BUUI_Spinner = ISPanel:derive("BUUI_Spinner")

local BUTTON = 20
local ENTRY = 34
local GAP = 3
local ICON = 10
local MAX_TITLE_PAD = 12

function BUUI_Spinner:new(x, y, width, height, target, onChange)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.background = false
    o.target = target
    o.onChange = onChange
    o.value = 1
    o.max = 1

    return o
end

local function BUUI_iconButton(spinner, x, texture, onClick)
    local button = BUUI_Button:new(x, 0, BUTTON, BUTTON, "", spinner, onClick)
    button.image = getTexture(texture)
    button.forcedWidthImage = ICON
    button.forcedHeightImage = ICON
    button:initialise()
    button:instantiate()
    spinner:addChild(button)
    return button
end

function BUUI_Spinner:createChildren()
    ISPanel.createChildren(self)

    self.less = BUUI_iconButton(self, 0, "media/ui/Entity/BTN_Minus_Icon_48x48.png", BUUI_Spinner.onLess)

    self.entry = ISTextEntryBox:new("1", BUTTON + GAP, 0, ENTRY, BUTTON)
    self.entry.font = UIFont.Small
    self.entry:initialise()
    self.entry:instantiate()
    self.entry:setOnlyNumbers(true)
    self.entry.onLostFocus = BUUI_Spinner.onTextChange
    self.entry.target = self
    self:addChild(self.entry)

    self.more = BUUI_iconButton(self, BUTTON + ENTRY + GAP * 2,
        "media/ui/Entity/BTN_Plus_Icon_48x48.png", BUUI_Spinner.onMore)

    self.maxButton = BUUI_Button:new(BUTTON * 2 + ENTRY + GAP * 3, 0, BUTTON, BUTTON,
        getText("IGUI_BUUI_Max"), self, BUUI_Spinner.onMax)
    self.maxButton:sizeToTitle(MAX_TITLE_PAD)
    self.maxButton:initialise()
    self.maxButton:instantiate()
    self:addChild(self.maxButton)

    self:setWidth(self.maxButton:getRight())
end

function BUUI_Spinner:setMax(max)
    self.max = max or 0
    self:setValue(self.value)
end

function BUUI_Spinner:setValue(value)
    value = tonumber(value) or 1
    value = PZMath.clamp(value, 0, self.max)

    self.value = value
    if self.entry and self.entry:getInternalText() ~= tostring(value) then
        self.entry:setText(tostring(value))
    end

    if self.onChange then self.onChange(self.target, value) end
end

function BUUI_Spinner:getValue()
    return self.value
end

function BUUI_Spinner:onLess()
    self:setValue(self.value - 1)
end

function BUUI_Spinner:onMore()
    self:setValue(self.value + 1)
end

function BUUI_Spinner:onMax()
    self:setValue(self.max)
end

function BUUI_Spinner.onTextChange(box)
    if box and box.target then
        box.target:setValue(box:getInternalText())
    end
end
