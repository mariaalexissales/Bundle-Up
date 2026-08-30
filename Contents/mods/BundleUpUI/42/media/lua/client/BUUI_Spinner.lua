----------
--ESTRAL--
----------

require "BUUI_Button"

BUUI_Spinner = ISPanel:derive("BUUI_Spinner")

local BUTTON = 20
local ENTRY = 34
local GAP = 3

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

function BUUI_Spinner:createChildren()
    ISPanel.createChildren(self)

    self.less = BUUI_Button:new(0, 0, BUTTON, BUTTON, "", self, BUUI_Spinner.onLess)
    self.less.image = getTexture("media/ui/Entity/BTN_Minus_Icon_48x48.png")
    self.less.forcedWidthImage = 10
    self.less.forcedHeightImage = 10
    self.less:initialise()
    self.less:instantiate()
    self:addChild(self.less)

    self.entry = ISTextEntryBox:new("1", BUTTON + GAP, 0, ENTRY, BUTTON)
    self.entry.font = UIFont.Small
    self.entry:initialise()
    self.entry:instantiate()
    self.entry:setOnlyNumbers(true)
    self.entry.onLostFocus = BUUI_Spinner.onTextChange
    self.entry.target = self
    self:addChild(self.entry)

    self.more = BUUI_Button:new(BUTTON + ENTRY + GAP * 2, 0, BUTTON, BUTTON, "", self, BUUI_Spinner.onMore)
    self.more.image = getTexture("media/ui/Entity/BTN_Plus_Icon_48x48.png")
    self.more.forcedWidthImage = 10
    self.more.forcedHeightImage = 10
    self.more:initialise()
    self.more:instantiate()
    self:addChild(self.more)

    self.maxButton = BUUI_Button:new(BUTTON * 2 + ENTRY + GAP * 3, 0, BUTTON, BUTTON, getText("IGUI_BUUI_Max"), self, BUUI_Spinner.onMax)
    self.maxButton:sizeToTitle(12)
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

    -- Zero only reads as a real choice when there is genuinely nothing to make.
    if value == 0 and self.max > 0 then value = 1 end

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
