----------
--ESTRAL--
----------

require "ISUI/ISButton"

BUUI_Button = ISButton:derive("BUUI_Button")

-- NeatUI's button art is a dark translucent bar with two bright end caps. The caps
-- take a tint and the body does not, so state is carried by tinting the caps and
-- filling the body behind them.
local BUUI_TEXTURES = nil

local function BUUI_textures()
    if BUUI_TEXTURES == nil then
        BUUI_TEXTURES = {
            left = getTexture("media/ui/NeatUI/Button/Button_FULL_L.png"),
            middle = getTexture("media/ui/NeatUI/Button/Button_FULL_M.png"),
            right = getTexture("media/ui/NeatUI/Button/Button_FULL_R.png"),
        }
    end
    return BUUI_TEXTURES
end

local STATES = {
    disabled = { cap = { 0.45, 0.45, 0.45 }, alpha = 0.45, fill = nil,
                 text = { 0.42, 0.42, 0.42 } },
    normal   = { cap = { 0.72, 0.72, 0.72 }, alpha = 0.85, fill = { 1, 1, 1, 0.03 },
                 text = { 0.84, 0.84, 0.84 } },
    hover    = { cap = { 1.00, 1.00, 1.00 }, alpha = 1.00, fill = { 1, 1, 1, 0.10 },
                 text = { 1.00, 1.00, 1.00 } },
    pressed  = { cap = { 0.85, 0.85, 0.85 }, alpha = 1.00, fill = { 0, 0, 0, 0.25 },
                 text = { 0.92, 0.92, 0.92 } },
    selected = { cap = { 0.98, 0.82, 0.45 }, alpha = 1.00, fill = { 0.98, 0.82, 0.45, 0.12 },
                 text = { 1.00, 0.93, 0.74 } },
}

function BUUI_Button:new(x, y, width, height, title, target, onclick)
    local o = ISButton:new(x, y, width, height, title, target, onclick)
    setmetatable(o, self)
    self.__index = self

    o.font = UIFont.Small
    o.selected = false

    -- The vanilla rect-and-border chrome would sit under the NeatUI art.
    o.displayBackground = false

    return o
end

-- Sizes the button to its own label, which is what keeps the strip from overflowing
-- when a translation is longer than the English original.
function BUUI_Button:sizeToTitle(padding)
    self:setWidth(getTextManager():MeasureStringX(self.font, self.title) + (padding or 20))
    return self
end

function BUUI_Button:state()
    if not self.enable then return STATES.disabled end
    if self.pressed then return STATES.pressed end
    if self.selected then return STATES.selected end
    if self.mouseOver and self:isMouseOver() then return STATES.hover end
    return STATES.normal
end

function BUUI_Button:prerender()
    ISButton.prerender(self)

    local state = self:state()
    self.textColor = self.textColor or {}
    self.textColor.r, self.textColor.g, self.textColor.b = state.text[1], state.text[2], state.text[3]
    self.textColor.a = 1

    if state.fill then
        self:drawRect(0, 0, self.width, self.height, state.fill[4], state.fill[1], state.fill[2], state.fill[3])
    end

    local textures = BUUI_textures()
    if NeatTool and NeatTool.ThreePatch then
        NeatTool.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height,
            textures.left, textures.middle, textures.right,
            state.alpha, state.cap[1], state.cap[2], state.cap[3])
    end
end
