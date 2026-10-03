local function MuvaUIFactory()
-- Fase K: forward-declare tabel INTERNAL sbg LOCAL. Sebelumnya dideklarasi
-- GLOBAL (Signal={} tanpa local) -> bocor nama ke blob (rename_locals menjaga
-- global) + polusi _G (dumpable via getgenv, bisa tabrakan skrip lain). Sbg
-- local, rename_locals menyamarkannya otomatis. Satu blok forward-declare (bukan
-- per-baris) supaya referensi-silang antar-tabel (mis. Theme pakai Color.fromHex,
-- Flag pakai Signal.new) tetap resolve. Nama API PUBLIK (di Library yg
-- dikembalikan) TAK terpengaruh. Batas 200-local aman (blok terbesar 45+17).
local Signal, Color, Tween, Icons, Flag, Theme, Layout, Section, Tab, Window,
      Dialog, Popup, Toast, KeySystem, LoadingScreen, ConfigSystem, Library
Signal = {}
Signal.__index = Signal
function Signal.new()
return setmetatable({ _listeners = {} }, Signal)
end
function Signal:Connect(fn)
local id = #self._listeners + 1
self._listeners[id] = fn
return {
Disconnect = function()
self._listeners[id] = nil
end
}
end
function Signal:Fire(...)
for _, fn in pairs(self._listeners) do
pcall(fn, ...)
end
end
function Signal:DisconnectAll()
self._listeners = {}
end
Color = {}
function Color.fromHex(hex)
hex = hex:gsub("#", "")
local r = tonumber(hex:sub(1,2), 16) / 255
local g = tonumber(hex:sub(3,4), 16) / 255
local b = tonumber(hex:sub(5,6), 16) / 255
return Color3.new(r, g, b)
end
function Color.toHex(color)
local r = math.floor(color.R * 255 + 0.5)
local g = math.floor(color.G * 255 + 0.5)
local b = math.floor(color.B * 255 + 0.5)
return string.format("#%02X%02X%02X", r, g, b)
end
function Color.toRGB(color)
return
math.floor(color.R * 255 + 0.5),
math.floor(color.G * 255 + 0.5),
math.floor(color.B * 255 + 0.5)
end
function Color.darken(color, amount)
local h, s, v = Color3.toHSV(color)
return Color3.fromHSV(h, s, math.max(0, v - amount))
end
function Color.lighten(color, amount)
local h, s, v = Color3.toHSV(color)
return Color3.fromHSV(h, s, math.min(1, v + amount))
end
function Color.toTransparency(alpha)
return 1 - math.clamp(alpha, 0, 1)
end
function Color.lerp(a, b, t)
return a:Lerp(b, t)
end
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
Tween = {}
local TAP_MOVE_MAX = 6
local function pointInGui(gui, p)
local pos  = gui.AbsolutePosition
local size = gui.AbsoluteSize
if size.X <= 0 or size.Y <= 0 then return false end
return p.X >= pos.X and p.X <= pos.X + size.X
and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end
function Tween.bindTap(gui, onTap)
gui.Active = true
local armed, startPos = false, nil
gui.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
armed    = true
startPos = Vector2.new(input.Position.X, input.Position.Y)
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
if not armed then return end
armed = false
if not startPos then return end
local endPos = Vector2.new(input.Position.X, input.Position.Y)
local d = endPos - startPos
if math.abs(d.X) >= TAP_MOVE_MAX or math.abs(d.Y) >= TAP_MOVE_MAX then
return
end
if not pointInGui(gui, endPos) then return end
onTap()
end)
end
local _D, _F, _S, _SP
local function getInfos()
if not _D then
_D  = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
_F  = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
_SP = TweenInfo.new(0.3,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
end
end
function Tween.play(instance, props, tweenInfo)
getInfos()
local t = TweenService:Create(instance, tweenInfo or _D, props)
t:Play()
return t
end
function Tween.fast(instance, props)
getInfos()
return Tween.play(instance, props, _F)
end
function Tween.slow(instance, props)
getInfos()
return Tween.play(instance, props, _S)
end
function Tween.spring(instance, props)
getInfos()
return Tween.play(instance, props, _SP)
end
function Tween.fadeIn(obj, duration)
local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
Tween.play(obj, { BackgroundTransparency = 0 }, info)
elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
Tween.play(obj, { TextTransparency = 0, BackgroundTransparency = 0 }, info)
elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
Tween.play(obj, { ImageTransparency = 0, BackgroundTransparency = 0 }, info)
end
end
function Tween.fadeOut(obj, duration)
local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
Tween.play(obj, { BackgroundTransparency = 1 }, info)
elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
Tween.play(obj, { TextTransparency = 1, BackgroundTransparency = 1 }, info)
elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
Tween.play(obj, { ImageTransparency = 1, BackgroundTransparency = 1 }, info)
end
end
Icons = {}
Icons.Data = {
x                  = { 16898613869, 869, 906 },
check              = { 16898612819, 710, 869 },
search             = { 16898613699, 918, 857 },
menu               = { 16898613613, 49,  820 },
info               = { 16898613509, 612, 869 },
["circle-check"]   = { 16898612819, 869, 955 },
["circle-x"]       = { 16898613044, 820, 306 },
["triangle-alert"] = { 16898613869, 967, 0   },
["arrow-right"]    = { 16898612629, 453, 820 },
["chevron-right"]  = { 16898612819, 869, 759 },
loader             = { 16898613509, 771, 906 },
mouse              = { 16898613613, 563, 918 },
inbox              = { 16898613509, 918, 563 },
lock               = { 16898613509, 918, 857 },
zap                = { 16898613869, 918, 906 },
["file-text"]      = { 16898613353, 869, 355 },
}
function Icons.new(name, px, color)
local d = Icons.Data[name]
local img = Instance.new("ImageLabel")
img.Name                   = "Ico_" .. tostring(name)
img.BackgroundTransparency = 1
img.Size                   = UDim2.fromOffset(px, px)
if d then
img.Image           = "rbxassetid://" .. tostring(d[1])
img.ImageRectOffset = Vector2.new(d[2], d[3])
img.ImageRectSize   = Vector2.new(48, 48)
end
if color then img.ImageColor3 = color end
return img
end
Flag = {}
Flag.__index = Flag
function Flag.new(id, defaultValue)
return setmetatable({
ID       = id,
Value    = defaultValue,
_signal  = Signal.new(),
}, Flag)
end
function Flag:Set(value)
self.Value = value
end
function Flag:SetAndFire(value)
self.Value = value
self._signal:Fire(value)
end
function Flag:OnChanged(fn)
return self._signal:Connect(fn)
end
function Flag:_fire(value)
self.Value = value
self._signal:Fire(value)
end
Theme = {}
Theme.__index = Theme
Theme.Colors = {
BG0         = Color.fromHex("#08090d"),
BG1         = Color.fromHex("#0c0e14"),
BG2         = Color.fromHex("#13151c"),
BG3         = Color.fromHex("#1b1e27"),
BG4         = Color.fromHex("#272b37"),
Border0     = Color.fromHex("#1c1f29"),
Border1     = Color.fromHex("#2a2e3b"),
Border2     = Color.fromHex("#3a3f50"),
Text0       = Color.fromHex("#f7f8fa"),
Text1       = Color.fromHex("#dfe2ea"),
Text2       = Color.fromHex("#aab0c0"),
Text3       = Color.fromHex("#7a8194"),
Text4       = Color.fromHex("#565d6e"),
Success     = Color.fromHex("#34d399"),
Error       = Color.fromHex("#fb7185"),
Warn        = Color.fromHex("#fbbf24"),
Info        = Color.fromHex("#60a5fa"),
}
Theme._accent     = Color.fromHex("#a06bff")
Theme._accentDark = Color.fromHex("#6d3df0")
Theme._listeners  = {}
function Theme:GetAccent()
return self._accent
end
function Theme:GetAccentDark()
return self._accentDark
end
function Theme:AccentTrans(alpha)
return Color.toTransparency(alpha)
end
function Theme:SetAccent(color)
self._accent     = color
self._accentDark = Color.darken(color, 0.15)
for _, fn in pairs(self._listeners) do
pcall(fn, color, self._accentDark)
end
end
function Theme:OnAccentChanged(fn)
local id = #self._listeners + 1
self._listeners[id] = fn
return function()
self._listeners[id] = nil
end
end
function Theme:Accent()       return self._accent end
function Theme:AccentDark()   return self._accentDark end
function Theme:BG(level)      return self.Colors["BG"     .. (level or 0)] end
function Theme:Text(level)    return self.Colors["Text"   .. (level or 0)] end
function Theme:Border(level)  return self.Colors["Border" .. (level or 0)] end
Layout = {}
Layout.CARD_H     = 46
Layout.CARD_RADIUS= 10
Layout.PAD_X      = 14
Layout.PAD_Y      = 9
Layout.GAP_CARD   = 6
Layout.TITLE_SIZE = 15
Layout.DESC_SIZE  = 13
Layout.VALUE_SIZE = 14
Layout.CODE_SIZE  = 13
Layout.GAP_INFO   = 2
Layout.TOGGLE_W   = 44
Layout.TOGGLE_RES = 62
Layout.CTRL_H     = 28
Layout.CTRL_W     = 130
Layout.GAP_ROW    = 8
Layout.CARD_MIN_H = 46
Layout.BTN_H      = 30
Layout.BTN_MIN_W  = 72
Layout.BTN_MAX_W  = 200
Layout.BTN_PAD_X  = 12
Layout.FONT_TITLE = Enum.Font.GothamMedium
Layout.FONT_BODY  = Enum.Font.Gotham
Layout.FONT_BOLD  = Enum.Font.GothamBold
function Layout.applyAutoHeight(frame, minH)
frame.AutomaticSize = Enum.AutomaticSize.Y
local c = Instance.new("UISizeConstraint")
c.Name    = "AutoHeightConstraint"
c.MinSize = Vector2.new(0, minH or Layout.CARD_MIN_H)
c.MaxSize = Vector2.new(math.huge, math.huge)
c.Parent  = frame
return c
end
function Layout.lockHeight(frame, h)
frame.AutomaticSize = Enum.AutomaticSize.None
frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, h)
local c = frame:FindFirstChild("AutoHeightConstraint")
if c then
c.MinSize = Vector2.new(0, h)
c.MaxSize = Vector2.new(math.huge, h)
end
end
function Layout.fitButton(btn, minW, maxW)
local w = maxW or Layout.BTN_MAX_W
btn.AutomaticSize = Enum.AutomaticSize.Y
btn.TextWrapped   = true
btn.Size          = UDim2.fromOffset(w, Layout.BTN_H)
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, Layout.BTN_PAD_X)
pad.PaddingRight  = UDim.new(0, Layout.BTN_PAD_X)
pad.PaddingTop    = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.Parent        = btn
local c = Instance.new("UISizeConstraint")
c.MinSize = Vector2.new(w, Layout.BTN_H)
c.MaxSize = Vector2.new(w, math.huge)
c.Parent  = btn
return c
end
Section = {}
Section.__index = Section
function Section.new(opts, parentFrame, flags)
local self = setmetatable({}, Section)
self._flags      = flags
self._components = {}
self._collapsed  = true
self._frame = Instance.new("Frame")
self._frame.Name                    = "Section_" .. (opts.Title or "Untitled")
self._frame.BackgroundTransparency  = 1
self._frame.Size                    = UDim2.new(1, 0, 0, 0)
self._frame.AutomaticSize           = Enum.AutomaticSize.Y
self._frame.Parent                  = parentFrame
local outerLayout = Instance.new("UIListLayout")
outerLayout.FillDirection  = Enum.FillDirection.Vertical
outerLayout.SortOrder      = Enum.SortOrder.LayoutOrder
outerLayout.Padding        = UDim.new(0, 0)
outerLayout.Parent         = self._frame
self._content = Instance.new("Frame")
self._content.Name                   = "Content"
self._content.BackgroundTransparency = 1
self._content.Size                   = UDim2.new(1, 0, 0, 0)
self._content.AutomaticSize          = Enum.AutomaticSize.Y
self._content.LayoutOrder            = 1
self._content.Parent                 = self._frame
local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection  = Enum.FillDirection.Vertical
contentLayout.SortOrder      = Enum.SortOrder.LayoutOrder
contentLayout.Padding        = UDim.new(0, Layout.GAP_CARD)
contentLayout.Parent         = self._content
local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop    = UDim.new(0, Layout.GAP_CARD)
contentPad.PaddingBottom = UDim.new(0, Layout.GAP_CARD)
contentPad.Parent        = self._content
if opts.Title then
self:_buildSeparator(opts.Title)
end
return self
end
function Section:_buildSeparator(label)
local row = Instance.new("TextButton")
row.Name                    = "Separator"
row.BackgroundColor3        = Theme:BG(2)
row.BackgroundTransparency  = 0.15
row.BorderSizePixel         = 0
row.AutoButtonColor         = false
row.Text                    = ""
row.Size                    = UDim2.new(1, 0, 0, 36)
row.LayoutOrder             = 0
row.Parent                  = self._frame
local rowCorner = Instance.new("UICorner")
rowCorner.CornerRadius      = UDim.new(0, 8)
rowCorner.Parent            = row
local rowStroke = Instance.new("UIStroke")
rowStroke.Color             = Theme:Border(0)
rowStroke.Thickness         = 1
rowStroke.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
rowStroke.Parent            = row
task.defer(function()
if rowStroke and rowStroke.Parent then rowStroke.Thickness = 1.0001; rowStroke.Thickness = 1 end
end)
local rowPad = Instance.new("UIPadding")
rowPad.PaddingLeft  = UDim.new(0, 12)
rowPad.PaddingRight = UDim.new(0, 12)
rowPad.Parent       = row
local GLOW_FADE = NumberSequence.new({
NumberSequenceKeypoint.new(0,    1),
NumberSequenceKeypoint.new(0.18, 0.45),
NumberSequenceKeypoint.new(0.5,  0),
NumberSequenceKeypoint.new(0.82, 0.45),
NumberSequenceKeypoint.new(1,    1),
})
local glowParts = {}
local function mkGlowLayer(height, baseTrans, z, color)
local g = Instance.new("Frame")
g.Name                   = "OpenGlow" .. height
g.BackgroundColor3       = color
g.BackgroundTransparency = baseTrans
g.BorderSizePixel        = 0
g.AnchorPoint            = Vector2.new(0.5, 0.5)
g.Position               = UDim2.new(0.5, 0, 1, -1)
g.Size                   = UDim2.new(1, 0, 0, height)
g.ZIndex                 = z
g.Parent                 = row
local grad = Instance.new("UIGradient")
grad.Transparency = GLOW_FADE
grad.Parent       = g
glowParts[#glowParts + 1] = g
return g
end
local glowCore = mkGlowLayer(2,  0,    3, Color.lighten(Theme:Accent(), 0.3))
local glowMid  = mkGlowLayer(6,  0.72, 2, Theme:Accent())
local glowWide = mkGlowLayer(14, 0.88, 1, Theme:Accent())
local function setOpenGlow(visible)
for _, g in ipairs(glowParts) do g.Visible = visible end
end
local bar = Instance.new("Frame")
bar.Name                   = "AccentBar"
bar.Size                   = UDim2.new(0, 3, 0, 16)
bar.Position               = UDim2.new(0, 0, 0.5, -8)
bar.BackgroundColor3       = Theme:Accent()
bar.BorderSizePixel        = 0
bar.Parent                 = row
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius     = UDim.new(1, 0)
barCorner.Parent           = bar
local lbl = Instance.new("TextLabel")
lbl.Name                   = "Label"
lbl.Size                   = UDim2.new(1, -28, 1, 0)
lbl.Position               = UDim2.new(0, 12, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text                   = label:upper()
lbl.TextColor3             = Theme:Text(2)
lbl.Font                   = Enum.Font.GothamBold
lbl.TextSize               = 13
lbl.TextXAlignment         = Enum.TextXAlignment.Left
lbl.TextYAlignment         = Enum.TextYAlignment.Center
lbl.Parent                 = row
local arrow = Instance.new("TextLabel")
arrow.Name                   = "Arrow"
arrow.BackgroundTransparency = 1
arrow.Size                   = UDim2.new(0, 20, 1, 0)
arrow.Position               = UDim2.new(1, -20, 0, 0)
arrow.Text                   = self._collapsed and "+" or "-"
arrow.Font                   = Enum.Font.GothamBold
arrow.TextSize               = 17
arrow.TextColor3             = self._collapsed and Theme:Text(3) or Theme:Accent()
arrow.TextXAlignment         = Enum.TextXAlignment.Center
arrow.Parent                 = row
local content = self._content
content.Visible = not self._collapsed
lbl.TextColor3  = self._collapsed and Theme:Text(2) or Theme:Accent()
rowStroke.Color = self._collapsed and Theme:Border(0) or Theme:Border(1)
setOpenGlow(not self._collapsed)
Theme:OnAccentChanged(function(accent)
bar.BackgroundColor3      = accent
glowCore.BackgroundColor3 = Color.lighten(accent, 0.3)
glowMid.BackgroundColor3  = accent
glowWide.BackgroundColor3 = accent
if not self._collapsed then lbl.TextColor3 = accent end
end)
row.MouseEnter:Connect(function()
Tween.fast(rowStroke, { Thickness = 1 })
rowStroke.Color = Theme:Accent()
end)
row.MouseLeave:Connect(function()
rowStroke.Color = self._collapsed and Theme:Border(0) or Theme:Border(1)
end)
row.MouseButton1Click:Connect(function()
self._collapsed = not self._collapsed
if self._collapsed then
arrow.Text       = "+"
arrow.TextColor3 = Theme:Text(3)
lbl.TextColor3   = Theme:Text(2)
rowStroke.Color  = Theme:Border(0)
content.Visible  = false
setOpenGlow(false)
else
arrow.Text       = "-"
arrow.TextColor3 = Theme:Accent()
lbl.TextColor3   = Theme:Accent()
rowStroke.Color  = Theme:Border(1)
content.Visible  = true
setOpenGlow(true)
end
end)
end
function Section:_makeCard(layoutOrder)
local card = Instance.new("Frame")
card.Name                   = "Card"
card.BackgroundColor3       = Theme:BG(2)
card.BackgroundTransparency = 0.15
card.BorderSizePixel        = 0
card.Size                   = UDim2.new(1, 0, 0, Layout.CARD_MIN_H)
card.LayoutOrder            = layoutOrder or #self._components + 10
card.Parent                 = self._content
Layout.applyAutoHeight(card, Layout.CARD_MIN_H)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, Layout.CARD_RADIUS)
corner.Parent       = card
local stroke = Instance.new("UIStroke")
stroke.Color            = Theme:Border(0)
stroke.Thickness        = 1
stroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
stroke.Parent           = card
task.defer(function()
if stroke and stroke.Parent then stroke.Thickness = 1.0001; stroke.Thickness = 1 end
end)
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, Layout.PAD_X)
pad.PaddingRight  = UDim.new(0, Layout.PAD_X)
pad.PaddingTop    = UDim.new(0, Layout.PAD_Y)
pad.PaddingBottom = UDim.new(0, Layout.PAD_Y)
pad.Parent        = card
return card, stroke
end
function Section:_makeInfoBlock(parent, titleText, descText, reserveRight)
local reserve = reserveRight or Layout.TOGGLE_RES
local info = Instance.new("Frame")
info.BackgroundTransparency = 1
info.Size                   = UDim2.new(1, -reserve, 0, 0)
info.AutomaticSize          = Enum.AutomaticSize.Y
info.Parent                 = parent
local infoL = Instance.new("UIListLayout")
infoL.FillDirection     = Enum.FillDirection.Vertical
infoL.VerticalAlignment = Enum.VerticalAlignment.Center
infoL.Padding           = UDim.new(0, Layout.GAP_INFO)
infoL.Parent            = info
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
titleLbl.Text                   = titleText or ""
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.TextYAlignment         = Enum.TextYAlignment.Top
titleLbl.TextWrapped            = true
titleLbl.Parent                 = info
local descLbl = nil
if descText then
descLbl = Instance.new("TextLabel")
descLbl.BackgroundTransparency = 1
descLbl.Size                   = UDim2.new(1, 0, 0, Layout.DESC_SIZE)
descLbl.AutomaticSize          = Enum.AutomaticSize.Y
descLbl.Text                   = descText
descLbl.Font                   = Layout.FONT_BODY
descLbl.TextSize               = Layout.DESC_SIZE
descLbl.TextColor3             = Theme:Text(3)
descLbl.TextXAlignment         = Enum.TextXAlignment.Left
descLbl.TextYAlignment         = Enum.TextYAlignment.Top
descLbl.TextWrapped            = true
descLbl.LineHeight             = 1.25
descLbl.Parent                 = info
end
return info, titleLbl, descLbl
end
function Section:_registerFlag(id, default)
if not id then return nil end
local flag = Flag.new(id, default)
self._flags[id] = flag
return flag
end
Section.AddToggle        = nil
Section.AddCheckbox      = nil
Section.AddSlider        = nil
Section.AddNumberInput   = nil
Section.AddTextInput     = nil
Section.AddTextarea      = nil
Section.AddDropdown      = nil
Section.AddMultiDropdown = nil
Section.AddKeybind       = nil
Section.AddColorPicker   = nil
Section.AddButton        = nil
Section.AddBadge         = nil
Section.AddTag           = nil
Section.AddProgressBar   = nil
Section.AddInfoDisplay   = nil
Section.AddParagraph     = nil
Section.AddCodeBlock     = nil
Section.AddDivider       = nil
Section.AddAvatar        = nil
Section.AddTable         = nil
Section.AddSeparator     = nil
Section.AddHStack        = nil
Section.AddVStack        = nil
Section.AddSpace         = nil
Section.AddAccordion     = nil
Section.AddWebhook       = nil
Tab = {}
Tab.__index = Tab
function Tab.new(opts, contentParent, flags)
local self = setmetatable({}, Tab)
self._flags    = flags
self._sections = {}
self._state    = nil
self._frame = Instance.new("ScrollingFrame")
self._frame.Name                   = "Tab_" .. (opts.Title or "Tab")
self._frame.BackgroundTransparency = 1
self._frame.Size                   = UDim2.new(1, 0, 1, 0)
self._frame.CanvasSize             = UDim2.new(0, 0, 0, 0)
self._frame.AutomaticCanvasSize    = Enum.AutomaticSize.Y
self._frame.ScrollBarThickness     = 3
self._frame.ScrollBarImageColor3   = Theme:BG(4)
self._frame.BorderSizePixel        = 0
self._frame.Visible                = false
self._frame.Parent                 = contentParent
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder     = Enum.SortOrder.LayoutOrder
layout.Padding       = UDim.new(0, 8)
layout.Parent        = self._frame
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 12)
pad.PaddingRight  = UDim.new(0, 12)
pad.PaddingTop    = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent        = self._frame
self._stateFrame = Instance.new("Frame")
self._stateFrame.Name                   = "StateOverlay"
self._stateFrame.BackgroundTransparency = 1
self._stateFrame.Size                   = UDim2.new(1, 0, 1, 0)
self._stateFrame.Position               = UDim2.new(0, 0, 0, 0)
self._stateFrame.Visible                = false
self._stateFrame.ZIndex                 = 10
self._stateFrame.Parent                 = self._frame
return self
end
function Tab:Show()
self._frame.Visible = true
end
function Tab:Hide()
self._frame.Visible = false
end
function Tab:AddSection(opts)
local section = Section.new(opts, self._frame, self._flags)
section._frame.LayoutOrder = #self._sections + 1
table.insert(self._sections, section)
return section
end
local STATE_ICONS = {
Empty     = "inbox",
Error     = "triangle-alert",
NoResults = "search",
Loading   = nil,
Locked    = "lock",
Warning   = "zap",
}
local STATE_COLORS = {
Empty     = function() return Theme:Text(3) end,
Error     = function() return Theme.Colors.Error end,
NoResults = function() return Theme:Text(3) end,
Loading   = function() return Theme:Text(3) end,
Locked    = function() return Theme:Accent() end,
Warning   = function() return Theme.Colors.Warn end,
}
function Tab:SetState(stateType, opts)
for _, sec in ipairs(self._sections) do
sec._frame.Visible = false
end
for _, child in ipairs(self._stateFrame:GetChildren()) do
child:Destroy()
end
self._stateFrame.Visible = true
local layout = Instance.new("UIListLayout")
layout.FillDirection        = Enum.FillDirection.Vertical
layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
layout.VerticalAlignment    = Enum.VerticalAlignment.Center
layout.Padding              = UDim.new(0, 6)
layout.Parent               = self._stateFrame
local colorFn = STATE_COLORS[stateType]
local color = colorFn and colorFn() or Theme:Accent()
if stateType == "Loading" then
local spinWrap = Instance.new("Frame")
spinWrap.BackgroundTransparency = 1
spinWrap.Size                   = UDim2.fromOffset(32, 32)
spinWrap.Parent                 = self._stateFrame
local spinner = Icons.new("loader", 22, Theme:Accent())
spinner.Name        = "Spinner"
spinner.AnchorPoint = Vector2.new(0.5, 0.5)
spinner.Position    = UDim2.new(0.5, 0, 0.5, 0)
spinner.Parent      = spinWrap
Tween.play(spinner, { Rotation = 360 },
TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1))
else
local iconName = STATE_ICONS[stateType]
if iconName then
local ico = Icons.new(iconName, 24, color)
ico.Parent = self._stateFrame
end
end
if opts.Title then
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(1, -24, 0, 0)
title.AutomaticSize          = Enum.AutomaticSize.Y
title.Text                   = opts.Title
title.TextSize               = 12
title.Font                   = Enum.Font.GothamBold
title.TextColor3             = color
title.TextXAlignment         = Enum.TextXAlignment.Center
title.TextWrapped            = true
title.Parent                 = self._stateFrame
end
local bodyText = opts.Body
if stateType == "NoResults" and opts.Query then
bodyText = 'Tidak ada hasil untuk "' .. opts.Query .. '"'
end
if bodyText then
local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Size                   = UDim2.new(1, -32, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.Y
body.Text                   = bodyText
body.TextSize               = 10
body.Font                   = Enum.Font.Gotham
body.TextColor3             = Theme:Text(3)
body.TextXAlignment         = Enum.TextXAlignment.Center
body.TextWrapped            = true
body.Parent                 = self._stateFrame
end
if opts.Action then
local btn = Instance.new("TextButton")
btn.Size                   = UDim2.fromOffset(90, 26)
btn.BackgroundColor3       = color
btn.BorderSizePixel        = 0
btn.Text                   = opts.Action.Text or "Action"
btn.TextSize               = 11
btn.Font                   = Enum.Font.GothamBold
btn.TextColor3             = Color.fromHex("#ffffff")
btn.AutoButtonColor        = false
btn.Parent                 = self._stateFrame
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent       = btn
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Color.lighten(color, 0.08) })
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundColor3 = color })
end)
btn.MouseButton1Click:Connect(function()
if opts.Action.Callback then pcall(opts.Action.Callback) end
end)
end
self._state = stateType
end
function Tab:ClearState()
for _, child in ipairs(self._stateFrame:GetChildren()) do
child:Destroy()
end
self._stateFrame.Visible = false
for _, sec in ipairs(self._sections) do
sec._frame.Visible = true
end
self._state = nil
end
Window = {}
Window.__index = Window
local UserInputService = game:GetService("UserInputService")
function Window.new(opts, screenGui, flags)
local self = setmetatable({}, Window)
self._flags = flags; self._tabs = {}; self._activeTab = nil; self._opts = opts
local accent = opts.Accent or Theme:Accent()
Theme:SetAccent(accent)
local win = Instance.new("CanvasGroup")
win.Name = "MuvaWindow"
win.BackgroundTransparency = 1
win.BorderSizePixel  = 0
win.Size        = UDim2.fromOffset(opts.Size and opts.Size.X or 580, opts.Size and opts.Size.Y or 400)
win.Position    = UDim2.new(0.5, 0, 0.5, 0)
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.ClipsDescendants = false
win.GroupTransparency = 1
win.Parent   = screenGui
self._win    = win
self._baseSize = Vector2.new(
opts.Size and opts.Size.X or 580,
opts.Size and opts.Size.Y or 400
)
local uiScale = Instance.new("UIScale")
uiScale.Scale  = 1
uiScale.Parent = win
self._uiScale  = uiScale
self._fitWindow = function()
local cam = workspace.CurrentCamera
if not cam then return end
local vp = cam.ViewportSize
if vp.X <= 0 or vp.Y <= 0 then return end
local base = self._baseSize
local maxW = vp.X * 0.94
local maxH = vp.Y * 0.94
local scale = math.min(1, maxW / base.X, maxH / base.Y)
scale = math.max(0.5, scale)
uiScale.Scale = scale
local narrow = (vp.X / scale) < 560
if self._setSidebarMode then self:_setSidebarMode(narrow) end
if self._maximized then return end
local curX = win.Size.X.Offset
local curY = win.Size.Y.Offset
local capX = math.max(base.X, math.floor(maxW / scale))
local capY = math.max(base.Y, math.floor(maxH / scale))
local clampedX = math.min(curX, capX)
local clampedY = math.min(curY, capY)
clampedX = math.max(clampedX, base.X)
clampedY = math.max(clampedY, base.Y)
if clampedX ~= curX or clampedY ~= curY then
win.Size = UDim2.fromOffset(clampedX, clampedY)
end
end
self._fitWindow()
task.spawn(function()
local cam = workspace.CurrentCamera
if cam then
self._viewportConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(self._fitWindow)
end
end)
local WIN_PANEL_TRANS = 0
pcall(function() if getgenv then getgenv().MuvaUI_PanelTrans = WIN_PANEL_TRANS end end)
local titlebar = Instance.new("Frame")
titlebar.Name = "Titlebar"
titlebar.BackgroundTransparency = 1
titlebar.BorderSizePixel  = 0
titlebar.Size     = UDim2.new(1, 0, 0, 46)
titlebar.Position = UDim2.new(0, 0, 0, 0)
titlebar.ZIndex   = 2
titlebar.Parent = win
self._titlebar = titlebar
local tbDivider = Instance.new("Frame")
tbDivider.BackgroundColor3 = Color.fromHex("#272b37")
tbDivider.BorderSizePixel  = 0
tbDivider.Size = UDim2.new(1, 0, 0, 1)
tbDivider.Position = UDim2.new(0, 0, 1, -1)
tbDivider.Parent = titlebar
local tbLeft = Instance.new("Frame")
tbLeft.BackgroundTransparency = 1
tbLeft.Size     = UDim2.new(0.65, 0, 1, 0)
tbLeft.Position = UDim2.new(0, 0, 0, 0)
tbLeft.Parent   = titlebar
local tbLeftLayout = Instance.new("UIListLayout")
tbLeftLayout.FillDirection     = Enum.FillDirection.Horizontal
tbLeftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tbLeftLayout.Padding = UDim.new(0, 10)
tbLeftLayout.Parent  = tbLeft
local tbLeftPad = Instance.new("UIPadding")
tbLeftPad.PaddingLeft = UDim.new(0, 14)
tbLeftPad.Parent      = tbLeft
local hamburger = Instance.new("TextButton")
hamburger.BackgroundTransparency = 1
hamburger.AutoButtonColor = false
hamburger.Size       = UDim2.fromOffset(22, 46)
hamburger.Text       = ""
hamburger.Parent = tbLeft
self._logo = hamburger
local hamIco = Icons.new("menu", 18, Color.fromHex("#7a8194"))
hamIco.AnchorPoint = Vector2.new(0.5, 0.5)
hamIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
hamIco.Parent      = hamburger
hamburger.MouseEnter:Connect(function() hamIco.ImageColor3 = Theme:Accent() end)
hamburger.MouseLeave:Connect(function() hamIco.ImageColor3 = Color.fromHex("#7a8194") end)
hamburger.MouseButton1Click:Connect(function()
if self._toggleDrawer then self:_toggleDrawer() end
end)
local titleStack = Instance.new("Frame")
titleStack.BackgroundTransparency = 1
titleStack.Size         = UDim2.fromOffset(0, 46)
titleStack.AutomaticSize = Enum.AutomaticSize.X
titleStack.Parent       = tbLeft
local titleStackLayout = Instance.new("UIListLayout")
titleStackLayout.FillDirection       = Enum.FillDirection.Vertical
titleStackLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
titleStackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
titleStackLayout.Padding = UDim.new(0, 1)
titleStackLayout.Parent  = titleStack
local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size          = UDim2.fromOffset(0, 20)
titleLabel.AutomaticSize = Enum.AutomaticSize.X
titleLabel.Text          = opts.Title or "MuvaUI"
titleLabel.Font          = Enum.Font.GothamBold
titleLabel.TextSize      = 16
titleLabel.TextColor3    = Color.fromHex("#f0f0f0")
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent        = titleStack
if opts.SubTitle then
local subLabel = Instance.new("TextLabel")
subLabel.BackgroundTransparency = 1
subLabel.Size          = UDim2.fromOffset(0, 14)
subLabel.AutomaticSize = Enum.AutomaticSize.X
subLabel.Text          = opts.SubTitle
subLabel.Font          = Enum.Font.Gotham
subLabel.TextSize      = 12
subLabel.TextColor3    = Color.fromHex("#f0f0f0")
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Parent        = titleStack
end
local tbRight = Instance.new("Frame")
tbRight.BackgroundTransparency = 1
tbRight.Size        = UDim2.fromOffset(0, 46)
tbRight.AutomaticSize = Enum.AutomaticSize.X
tbRight.Position    = UDim2.new(1, -12, 0, 0)
tbRight.AnchorPoint = Vector2.new(1, 0)
tbRight.Parent      = titlebar
local tbRightLayout = Instance.new("UIListLayout")
tbRightLayout.FillDirection       = Enum.FillDirection.Horizontal
tbRightLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
tbRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
tbRightLayout.Padding = UDim.new(0, 6)
tbRightLayout.Parent  = tbRight
self._badgeLbl = nil
local ctrlFrame = Instance.new("Frame")
ctrlFrame.BackgroundTransparency = 1
ctrlFrame.Size        = UDim2.fromOffset(0, 46)
ctrlFrame.AutomaticSize = Enum.AutomaticSize.X
ctrlFrame.Parent      = tbRight
local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection     = Enum.FillDirection.Horizontal
ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ctrlLayout.Padding = UDim.new(0, 4)
ctrlLayout.Parent  = ctrlFrame
local btnMin = self:_makeCtrlBtn(ctrlFrame, "_", Color.fromHex("#2a2a2e"), Color.fromHex("#aaaaaa"))
local btnMax = self:_makeCtrlBtn(ctrlFrame, "[  ]", Color.fromHex("#2a2a2e"), Color.fromHex("#aaaaaa"))
btnMax.TextSize = 11
btnMax.Size     = UDim2.fromOffset(36, 28)
self._btnMax = btnMax
local btnClose = self:_makeCtrlBtn(ctrlFrame, "X", Color.fromHex("#c0392b"), Color.fromHex("#ffffff"))
btnMin.MouseButton1Click:Connect(function()   if self._suppressClick then return end self:_minimize() end)
btnMax.MouseButton1Click:Connect(function()   if self._suppressClick then return end self:_toggleMaximize() end)
btnClose.MouseButton1Click:Connect(function() if self._suppressClick then return end self:_close() end)
local body = Instance.new("Frame")
body.BackgroundColor3 = Color.fromHex("#0b0d12")
body.BackgroundTransparency = WIN_PANEL_TRANS
body.BorderSizePixel  = 0
body.Position         = UDim2.new(0, 0, 0, 0)
body.Size             = UDim2.new(1, 0, 1, 0)
body.ClipsDescendants = false
body.ZIndex           = 0
body.Parent           = win
local bodyGrad = Instance.new("UIGradient")
bodyGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color.fromHex("#c4c8d4"))
bodyGrad.Rotation = 90
bodyGrad.Parent = body
local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 12)
bodyCorner.Parent       = body
local catcher = Instance.new("TextButton")
catcher.Name                   = "InputCatcher"
catcher.BackgroundTransparency = 1
catcher.BorderSizePixel        = 0
catcher.AutoButtonColor        = false
catcher.Text                   = ""
catcher.Size                   = UDim2.new(1, 0, 1, 0)
catcher.Position               = UDim2.new(0, 0, 0, 0)
catcher.ZIndex                 = 0
catcher.Parent                 = body
local bodyInner = body
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.BackgroundColor3       = Theme:BG(2)
sidebar.BackgroundTransparency = 0.15
sidebar.BorderSizePixel  = 0
sidebar.Position         = UDim2.new(0, 0, 0, 46)
sidebar.Size             = UDim2.new(0, 160, 1, -46)
sidebar.ClipsDescendants = false
sidebar.Parent           = bodyInner
self._sidebar            = sidebar
local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 12)
sidebarCorner.Parent       = sidebar
local sbRightLeg = Instance.new("Frame")
sbRightLeg.BackgroundTransparency = 1
sbRightLeg.BorderSizePixel  = 0
sbRightLeg.Size             = UDim2.new(0, 12, 1, 0)
sbRightLeg.Position         = UDim2.new(1, -12, 0, 0)
sbRightLeg.ZIndex           = 0
sbRightLeg.Parent           = sidebar
local sbTopLeg = Instance.new("Frame")
sbTopLeg.BackgroundTransparency = 1
sbTopLeg.BorderSizePixel  = 0
sbTopLeg.Size             = UDim2.new(1, 0, 0, 12)
sbTopLeg.Position         = UDim2.new(0, 0, 0, 0)
sbTopLeg.ZIndex           = 0
sbTopLeg.Parent           = sidebar
local sbDivider = Instance.new("Frame")
sbDivider.BackgroundColor3 = Color.fromHex("#1c1f29")
sbDivider.BorderSizePixel  = 0
sbDivider.Size     = UDim2.new(0, 1, 1, -46)
sbDivider.Position = UDim2.new(0, 160, 0, 46)
sbDivider.ZIndex   = 2
sbDivider.Parent   = bodyInner
local searchOuter = Instance.new("Frame")
searchOuter.BackgroundTransparency = 1
searchOuter.Size     = UDim2.new(1, 0, 0, 40)
searchOuter.Position = UDim2.new(0, 0, 0, 0)
searchOuter.Parent   = sidebar
local searchOuterPad = Instance.new("UIPadding")
searchOuterPad.PaddingLeft   = UDim.new(0, 8)
searchOuterPad.PaddingRight  = UDim.new(0, 8)
searchOuterPad.PaddingTop    = UDim.new(0, 7)
searchOuterPad.PaddingBottom = UDim.new(0, 5)
searchOuterPad.Parent = searchOuter
local searchWrap = Instance.new("Frame")
searchWrap.BackgroundColor3       = Color.fromHex("#272b37")
searchWrap.BackgroundTransparency = 0.88
searchWrap.BorderSizePixel  = 0
searchWrap.Size   = UDim2.new(1, 0, 1, 0)
searchWrap.Parent = searchOuter
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 7)
searchCorner.Parent = searchWrap
local searchStroke = Instance.new("UIStroke")
searchStroke.Color        = Theme:Accent()
searchStroke.Transparency = 0.4
searchStroke.Thickness    = 1
searchStroke.Parent       = searchWrap
task.defer(function()
if searchStroke and searchStroke.Parent then searchStroke.Thickness = 1.0001; searchStroke.Thickness = 1 end
end)
local searchRowLayout = Instance.new("UIListLayout")
searchRowLayout.FillDirection     = Enum.FillDirection.Horizontal
searchRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
searchRowLayout.Padding = UDim.new(0, 5)
searchRowLayout.Parent  = searchWrap
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft  = UDim.new(0, 7)
searchPad.PaddingRight = UDim.new(0, 7)
searchPad.Parent = searchWrap
local searchIcon = Icons.new("search", 14, Color.fromHex("#666666"))
searchIcon.Parent = searchWrap
local searchBox = Instance.new("TextBox")
searchBox.BackgroundTransparency = 1
searchBox.BorderSizePixel   = 0
searchBox.Size = UDim2.new(1, -20, 1, 0)
searchBox.PlaceholderText   = "Search..."
searchBox.PlaceholderColor3 = Color.fromHex("#666666")
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize   = 13
searchBox.TextColor3 = Color.fromHex("#c0c0c0")
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchWrap
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
self:_filterTabs(searchBox.Text)
end)
local navScroll = Instance.new("ScrollingFrame")
navScroll.BackgroundTransparency = 1
navScroll.BorderSizePixel        = 0
navScroll.Position            = UDim2.new(0, 0, 0, 40)
navScroll.Size                = UDim2.new(1, 0, 1, -46)
navScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
navScroll.ScrollBarThickness  = 2
navScroll.ScrollBarImageColor3 = Color.fromHex("#272b37")
navScroll.Parent      = sidebar
self._navScroll       = navScroll
local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.SortOrder     = Enum.SortOrder.LayoutOrder
navLayout.Parent        = navScroll
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 160, 0, 46)
content.Size     = UDim2.new(1, -160, 1, -46)
content.ClipsDescendants = false
content.Parent   = bodyInner
self._content    = content
local backdrop = Instance.new("TextButton")
backdrop.Name                   = "DrawerBackdrop"
backdrop.BackgroundColor3       = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel        = 0
backdrop.AutoButtonColor        = false
backdrop.Text                   = ""
backdrop.Size                   = UDim2.new(1, 0, 1, -46)
backdrop.Position               = UDim2.new(0, 0, 0, 46)
backdrop.Visible                = false
backdrop.ZIndex                 = 3
backdrop.Parent                 = bodyInner
self._drawerNarrow = false
self._drawerOpen   = false
function self:_setSidebarMode(narrow)
if self._drawerNarrow == narrow then return end
self._drawerNarrow = narrow
if narrow then
content.Position = UDim2.new(0, 0, 0, 46)
content.Size     = UDim2.new(1, 0, 1, -46)
sbDivider.Visible = false
sidebar.ZIndex    = 5
sidebar.Position  = UDim2.new(0, -200, 0, 46)
hamburger.Visible = true
self._drawerOpen  = false
backdrop.Visible  = false
backdrop.BackgroundTransparency = 1
else
content.Position  = UDim2.new(0, 160, 0, 46)
content.Size      = UDim2.new(1, -160, 1, -46)
sbDivider.Visible = true
sidebar.ZIndex    = 1
sidebar.Position  = UDim2.new(0, 0, 0, 46)
hamburger.Visible = false
backdrop.Visible  = false
end
end
function self:_toggleDrawer()
if not self._drawerNarrow then return end
self._drawerOpen = not self._drawerOpen
if self._drawerOpen then
backdrop.Visible = true
Tween.fast(backdrop, { BackgroundTransparency = 0.5 })
Tween.play(sidebar, { Position = UDim2.new(0, 0, 0, 46) },
TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
else
Tween.fast(backdrop, { BackgroundTransparency = 1 })
Tween.play(sidebar, { Position = UDim2.new(0, -200, 0, 46) },
TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.2, function()
if not self._drawerOpen then backdrop.Visible = false end
end)
end
end
backdrop.MouseButton1Click:Connect(function()
if self._drawerOpen then self:_toggleDrawer() end
end)
hamburger.Visible = false
if opts.Draggable ~= false then self:_buildDrag(titlebar, win, screenGui) end
if opts.Resizable ~= false then self:_buildResizeHandle(win) end
if self._fitWindow then pcall(self._fitWindow) end
return self
end
function Window:_makeCtrlBtn(parent, symbol, bgColor, textColor)
local btn = Instance.new("TextButton")
btn.BackgroundColor3       = bgColor
btn.BackgroundTransparency = 1
btn.BorderSizePixel  = 0
btn.Size = UDim2.fromOffset(28, 28)
btn.Text = symbol
btn.Font = Enum.Font.GothamBold
btn.TextSize   = 13
btn.TextColor3 = Color.fromHex("#7a8194")
btn.AutoButtonColor = false
btn.Parent = parent
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 7)
corner.Parent = btn
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundTransparency = 0 })
btn.TextColor3 = textColor
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundTransparency = 1 })
btn.TextColor3 = Color.fromHex("#7a8194")
end)
btn.MouseButton1Down:Connect(function()
Tween.fast(btn, { BackgroundTransparency = 0.3 })
end)
btn.MouseButton1Up:Connect(function()
Tween.fast(btn, { BackgroundTransparency = 0 })
end)
return btn
end
function Window:_buildDrag(titlebar, win, screenGui)
local pending, dragging, dragStart, startPos = false, false, nil, nil
local DRAG_THRESHOLD = 6
titlebar.Active = true
self._suppressClick = false
self._dragConns = self._dragConns or {}
for _, c in ipairs(self._dragConns) do pcall(function() c:Disconnect() end) end
self._dragConns = {}
titlebar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
pending   = true
dragging  = false
dragStart = input.Position
startPos  = win.Position
end
end)
table.insert(self._dragConns, UserInputService.InputChanged:Connect(function(input)
if not win.Parent then return end
if not pending then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement
and input.UserInputType ~= Enum.UserInputType.Touch then return end
local delta = input.Position - dragStart
if not dragging then
if math.abs(delta.X) < DRAG_THRESHOLD and math.abs(delta.Y) < DRAG_THRESHOLD then
return
end
dragging = true
self._suppressClick = true
end
local s = (self._uiScale and self._uiScale.Scale) or 1
if s <= 0 then s = 1 end
win.Position = UDim2.new(
startPos.X.Scale, startPos.X.Offset + delta.X * s,
startPos.Y.Scale, startPos.Y.Offset + delta.Y * s
)
end))
table.insert(self._dragConns, UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
pending  = false
dragging = false
task.defer(function() self._suppressClick = false end)
end
end))
end
function Window:_buildResizeHandle(win)
local handle = Instance.new("TextButton")
handle.Size = UDim2.fromOffset(18, 18)
handle.Position = UDim2.new(1, -18, 1, -18)
handle.BackgroundTransparency = 1
handle.Text = ""
handle.ZIndex = 10
handle.Parent = win
local resizing, resizeStart, startSize = false, nil, nil
handle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
resizing     = true
resizeStart  = input.Position
startSize    = win.Size
end
end)
UserInputService.InputChanged:Connect(function(input)
if not win.Parent then return end
if resizing
and (input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - resizeStart
local s = (self._uiScale and self._uiScale.Scale) or 1
if s <= 0 then s = 1 end
win.Size = UDim2.fromOffset(
math.max(420, startSize.X.Offset + delta.X * s),
math.max(300, startSize.Y.Offset + delta.Y * s)
)
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
resizing = false
end
end)
end
function Window:_minimize()
self:Hide()
end
function Window:_restore()
self:Show()
end
function Window:_toggleMaximize()
if not self._maximized then
self._savedSize = self._win.Size
self._savedPos  = self._win.Position
self._maximized = true
local cam = workspace.CurrentCamera
local s   = (self._uiScale and self._uiScale.Scale) or 1
if s <= 0 then s = 1 end
if cam then
local vp = cam.ViewportSize
local w  = math.floor((vp.X * 0.96) / s)
local h  = math.floor((vp.Y * 0.96) / s)
Tween.slow(self._win, {
Size     = UDim2.fromOffset(w, h),
Position = UDim2.new(0.5, 0, 0.5, 0),
})
else
Tween.slow(self._win, { Position = UDim2.new(0.5, 0, 0.5, 0) })
end
else
self._maximized = false
Tween.slow(self._win, { Size = self._savedSize, Position = self._savedPos })
if self._fitWindow then task.delay(0.05, self._fitWindow) end
end
end
function Window:_close()
self:Hide()
end
function Window:Hide()
Tween.play(self._win, { GroupTransparency = 1 },
TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
task.delay(0.22, function()
self._win.Visible = false
end)
end
function Window:Show()
local win     = self._win
local origPos = win.Position
win.GroupTransparency = 1
win.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset,
origPos.Y.Scale, origPos.Y.Offset + 28)
win.Visible  = true
Tween.play(win, {
GroupTransparency = 0,
Position          = origPos,
}, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end
function Window:_filterTabs(query)
query = query:lower()
for _, child in ipairs(self._navScroll:GetChildren()) do
if child:IsA("TextButton") then
local lbl = child:FindFirstChild("Label")
if lbl then
child.Visible = query == "" or lbl.Text:lower():find(query, 1, true) ~= nil
end
end
end
end
function Window:AddTab(opts)
local tab    = Tab.new(opts, self._content, self._flags)
local navBtn = self:_makeNavButton(opts, #self._tabs + 1, tab)
table.insert(self._tabs, tab)
if #self._tabs == 1 then self:_selectTab(tab, navBtn) end
return tab
end
function Window:_makeNavButton(opts, order, tab)
local btn = Instance.new("TextButton")
btn.Name = "NavBtn_" .. (opts.Title or "Tab")
btn.BackgroundTransparency = 1
btn.Size        = UDim2.new(1, 0, 0, 40)
btn.LayoutOrder = order
btn.BorderSizePixel = 0
btn.Text = ""
btn.AutoButtonColor = false
btn.Parent = self._navScroll
local accentBar = Instance.new("Frame")
accentBar.Name = "AccentBar"
accentBar.Size             = UDim2.new(0, 4, 0, 20)
accentBar.Position         = UDim2.new(0, 0, 0.5, -10)
accentBar.AnchorPoint      = Vector2.new(0, 0)
accentBar.BackgroundColor3       = Theme:Accent()
accentBar.BackgroundTransparency = 1
accentBar.BorderSizePixel  = 0
accentBar.Parent = btn
local accentBarCorner = Instance.new("UICorner")
accentBarCorner.CornerRadius = UDim.new(0, 2)
accentBarCorner.Parent       = accentBar
local icon = nil
if type(opts.Icon) == "table" and opts.Icon.Image then
icon = Instance.new("ImageLabel")
icon.Name                   = "Icon"
icon.BackgroundTransparency = 1
icon.Size                   = UDim2.fromOffset(16, 16)
icon.Position               = UDim2.new(0, 14, 0.5, -8)
icon.Image                  = opts.Icon.Image
if opts.Icon.RectOffset then icon.ImageRectOffset = opts.Icon.RectOffset end
if opts.Icon.RectSize   then icon.ImageRectSize   = opts.Icon.RectSize end
icon.ImageColor3            = Theme:Accent()
icon.Parent                 = btn
Theme:OnAccentChanged(function(a)
icon.ImageColor3 = a
end)
end
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size     = UDim2.new(1, icon and -46 or -28, 1, 0)
label.Position = UDim2.new(0, icon and 38 or 16, 0, 0)
label.Text     = opts.Title or "Tab"
label.Font     = Enum.Font.GothamMedium
label.TextSize = 14
label.TextColor3     = Color.fromHex("#7a8194")
label.TextXAlignment = Enum.TextXAlignment.Left
label.Name   = "Label"
label.Parent = btn
btn.MouseEnter:Connect(function()
local bar = btn:FindFirstChild("AccentBar")
if bar and bar.BackgroundTransparency == 1 then
btn.BackgroundColor3 = Color.fromHex("#1b1e27")
Tween.fast(btn, { BackgroundTransparency = 0.85 })
end
end)
btn.MouseLeave:Connect(function()
local bar = btn:FindFirstChild("AccentBar")
if bar and bar.BackgroundTransparency == 1 then
Tween.fast(btn, { BackgroundTransparency = 1 })
end
end)
btn.MouseButton1Click:Connect(function()
self:_selectTab(tab, btn)
end)
return btn
end
function Window:_selectTab(tab, navBtn)
for _, t in ipairs(self._tabs) do t:Hide() end
for _, child in ipairs(self._navScroll:GetChildren()) do
if child:IsA("TextButton") then
child.BackgroundTransparency = 1
local bar = child:FindFirstChild("AccentBar")
local lbl = child:FindFirstChild("Label")
local ico = child:FindFirstChild("Icon")
if bar then bar.BackgroundTransparency = 1 end
if lbl then lbl.TextColor3 = Color.fromHex("#7a8194"); lbl.Font = Enum.Font.GothamMedium end
if ico then ico.ImageColor3 = Theme:Accent() end
end
end
tab:Show()
navBtn.BackgroundTransparency = 1
local bar = navBtn:FindFirstChild("AccentBar")
local lbl = navBtn:FindFirstChild("Label")
local ico = navBtn:FindFirstChild("Icon")
if bar then bar.BackgroundTransparency = 0; bar.BackgroundColor3 = Theme:Accent() end
if lbl then lbl.TextColor3 = Color.fromHex("#d4b3fa"); lbl.Font = Enum.Font.GothamBold end
if ico then ico.ImageColor3 = Color.lighten(Theme:Accent(), 0.15) end
self._activeTab = tab
end
function Window:Dialog(opts)  Dialog.show(opts, self._win.Parent) end
function Window:Popup(opts)   Popup.show(opts, self._win) end
function Window:OnClose(fn)    self._onClose    = fn end
function Window:OnMinimize(fn) self._onMinimize = fn end
function Window:OnRestore(fn)  self._onRestore  = fn end
Section.AddToggle = function(self, opts)
assert(type(opts) == "table", "AddToggle: opts must be a table")
local flag = self:_registerFlag(opts.ID, opts.Default or false)
local card, stroke = self:_makeCard()
local layout = Instance.new("UIListLayout")
layout.FillDirection        = Enum.FillDirection.Horizontal
layout.VerticalAlignment    = Enum.VerticalAlignment.Center
layout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
layout.Padding              = UDim.new(0, 8)
layout.SortOrder            = Enum.SortOrder.LayoutOrder
layout.Parent               = card
local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, Layout.TOGGLE_RES)
info.LayoutOrder = 1
local TRACK_H, KNOB, PAD = 24, 18, 3
local KNOB_ON  = Layout.TOGGLE_W - KNOB - PAD
local KNOB_OFF = PAD
local track = Instance.new("Frame")
track.Size              = UDim2.fromOffset(Layout.TOGGLE_W, TRACK_H)
track.BackgroundColor3  = Theme:BG(4)
track.BorderSizePixel   = 0
track.LayoutOrder       = 2
track.Parent            = card
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent       = track
local trackStroke = Instance.new("UIStroke")
trackStroke.Color     = Theme:Border(1)
trackStroke.Thickness = 1
trackStroke.Parent    = track
local knob = Instance.new("Frame")
knob.Size             = UDim2.fromOffset(KNOB, KNOB)
knob.Position         = UDim2.fromOffset(KNOB_OFF, PAD)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.BorderSizePixel  = 0
knob.ZIndex           = 2
knob.Parent           = track
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent       = knob
local hitbox = Instance.new("TextButton")
hitbox.Name                   = "ToggleHitbox"
hitbox.BackgroundTransparency = 1
hitbox.AutoButtonColor        = false
hitbox.Text                   = ""
hitbox.AnchorPoint            = Vector2.new(0.5, 0.5)
hitbox.Position               = UDim2.new(0.5, 0, 0.5, 0)
hitbox.Size                   = UDim2.new(1, 16, 1, 16)
hitbox.ZIndex                 = 3
hitbox.Parent                 = track
local value = opts.Default or false
local function updateVisual(val, animated)
if val then
if animated then
Tween.play(track, { BackgroundColor3 = Theme:Accent() })
Tween.play(knob,  { Position = UDim2.fromOffset(KNOB_ON, PAD) })
else
track.BackgroundColor3 = Theme:Accent()
knob.Position          = UDim2.fromOffset(KNOB_ON, PAD)
end
trackStroke.Color = Theme:Accent()
else
if animated then
Tween.play(track, { BackgroundColor3 = Theme:BG(4) })
Tween.play(knob,  { Position = UDim2.fromOffset(KNOB_OFF, PAD) })
else
track.BackgroundColor3 = Theme:BG(4)
knob.Position          = UDim2.fromOffset(KNOB_OFF, PAD)
end
trackStroke.Color = Theme:Border(1)
end
end
updateVisual(value, false)
Tween.bindTap(hitbox, function()
value = not value
updateVisual(value, true)
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
Theme:OnAccentChanged(function(accent)
if value then
track.BackgroundColor3 = accent
trackStroke.Color      = accent
end
end)
if flag then
flag:OnChanged(function(v)
value = v
updateVisual(v, true)
end)
end
table.insert(self._components, card)
return card
end
Section.AddCheckbox = function(self, opts)
assert(type(opts) == "table", "AddCheckbox: opts must be a table")
local flag = self:_registerFlag(opts.ID, opts.Default or false)
local card, stroke = self:_makeCard()
local row = Instance.new("UIListLayout")
row.FillDirection       = Enum.FillDirection.Horizontal
row.VerticalAlignment   = Enum.VerticalAlignment.Center
row.Padding             = UDim.new(0, 8)
row.Parent              = card
local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 36)
local box = Instance.new("Frame")
box.Size             = UDim2.fromOffset(20, 20)
box.BackgroundColor3 = Theme:BG(1)
box.BorderSizePixel  = 0
box.LayoutOrder      = 99
box.Parent           = card
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 4)
boxCorner.Parent       = box
local boxStroke = Instance.new("UIStroke")
boxStroke.Color     = Theme:Border(1)
boxStroke.Thickness = 1
boxStroke.Parent    = box
local check = Icons.new("check", 12, Color3.new(1, 1, 1))
check.AnchorPoint       = Vector2.new(0.5, 0.5)
check.Position          = UDim2.new(0.5, 0, 0.5, 0)
check.ImageTransparency = 1
check.Parent            = box
local hitbox = Instance.new("TextButton")
hitbox.Name                   = "CheckboxHitbox"
hitbox.BackgroundTransparency = 1
hitbox.AutoButtonColor        = false
hitbox.Text                   = ""
hitbox.AnchorPoint            = Vector2.new(0.5, 0.5)
hitbox.Position               = UDim2.new(0.5, 0, 0.5, 0)
hitbox.Size                   = UDim2.new(1, 20, 1, 20)
hitbox.ZIndex                 = 3
hitbox.Parent                 = box
local value = opts.Default or false
local function updateVisual(val, animated)
if val then
if animated then
Tween.fast(box,   { BackgroundColor3 = Theme:Accent() })
Tween.fast(check, { ImageTransparency = 0 })
else
box.BackgroundColor3    = Theme:Accent()
check.ImageTransparency = 0
end
boxStroke.Color = Theme:Accent()
else
if animated then
Tween.fast(box,   { BackgroundColor3 = Theme:BG(1) })
Tween.fast(check, { ImageTransparency = 1 })
else
box.BackgroundColor3    = Theme:BG(1)
check.ImageTransparency = 1
end
boxStroke.Color = Theme:Border(1)
end
end
updateVisual(value, false)
Tween.bindTap(hitbox, function()
value = not value
updateVisual(value, true)
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
Theme:OnAccentChanged(function(accent)
if value then
box.BackgroundColor3 = accent
boxStroke.Color      = accent
end
end)
if flag then
flag:OnChanged(function(v)
value = v
updateVisual(v, true)
end)
end
table.insert(self._components, card)
return card
end
local UserInputService = game:GetService("UserInputService")
Section.AddSlider = function(self, opts)
assert(type(opts) == "table", "AddSlider: opts must be a table")
local min     = opts.Min     or 0
local max     = opts.Max     or 100
local step    = opts.Step    or 1
local suffix  = opts.Suffix  or ""
local default = math.clamp(opts.Default or min, min, max)
local flag    = self:_registerFlag(opts.ID, default)
local card, stroke = self:_makeCard()
Layout.lockHeight(card, 42)
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIListLayout") or c:IsA("UIPadding") then c:Destroy() end
end
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -62, 0, 15)
titleLbl.Position               = UDim2.new(0, 12, 0, 6)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Parent                 = card
local valueLbl = Instance.new("TextLabel")
valueLbl.BackgroundTransparency = 1
valueLbl.Size                   = UDim2.fromOffset(50, 15)
valueLbl.Position               = UDim2.new(1, -62, 0, 6)
valueLbl.Font                   = Layout.FONT_BOLD
valueLbl.TextSize               = Layout.TITLE_SIZE
valueLbl.TextColor3             = Theme:Accent()
valueLbl.TextXAlignment         = Enum.TextXAlignment.Right
valueLbl.Parent                 = card
local track = Instance.new("Frame")
track.Size             = UDim2.new(1, -24, 0, 4)
track.Position         = UDim2.new(0, 12, 0, 28)
track.BackgroundColor3 = Theme:BG(4)
track.BorderSizePixel  = 0
track.Parent           = card
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent       = track
local fill = Instance.new("Frame")
fill.Size             = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Theme:Accent()
fill.BorderSizePixel  = 0
fill.Parent           = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent       = fill
local knob = Instance.new("Frame")
knob.Size             = UDim2.fromOffset(13, 13)
knob.Position         = UDim2.new(0, 0, 0.5, -6)
knob.BackgroundColor3 = Theme:Accent()
knob.BorderSizePixel  = 0
knob.ZIndex           = 3
knob.Parent           = track
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent       = knob
local value = default
local function snapStep(v)
return math.clamp(math.round((v - min) / step) * step + min, min, max)
end
local function updateVisual(val)
local pct = (val - min) / (max - min)
fill.Size     = UDim2.new(pct, 0, 1, 0)
knob.Position = UDim2.new(pct, -6, 0.5, -6)
valueLbl.Text = tostring(val) .. suffix
end
updateVisual(value)
local dragging = false
local function calcValue(inputX)
local abs  = track.AbsolutePosition.X
local size = track.AbsoluteSize.X
local pct  = math.clamp((inputX - abs) / size, 0, 1)
return snapStep(min + pct * (max - min))
end
local hitbox = Instance.new("TextButton")
hitbox.Size                   = UDim2.new(1, 0, 1, 14)
hitbox.Position               = UDim2.new(0, 0, 0, -5)
hitbox.BackgroundTransparency = 1
hitbox.Text                   = ""
hitbox.ZIndex                 = 4
hitbox.Parent                 = track
hitbox.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
value    = calcValue(input.Position.X)
updateVisual(value)
end
end)
UserInputService.InputChanged:Connect(function(input)
if dragging
and (input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch) then
value = calcValue(input.Position.X)
updateVisual(value)
end
end)
UserInputService.InputEnded:Connect(function(input)
if (input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch) and dragging then
dragging = false
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end
end)
hitbox.InputEnded:Connect(function(input)
if (input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
Theme:OnAccentChanged(function(accent)
fill.BackgroundColor3  = accent
knob.BackgroundColor3  = accent
valueLbl.TextColor3    = accent
end)
if flag then
flag:OnChanged(function(v)
value = math.clamp(v, min, max)
updateVisual(value)
end)
end
table.insert(self._components, card)
return card
end
Section.AddNumberInput = function(self, opts)
assert(type(opts) == "table", "AddNumberInput: opts must be a table")
local min     = opts.Min     or 0
local max     = opts.Max     or math.huge
local step    = opts.Step    or 1
local default = math.clamp(opts.Default or 0, min, max)
local flag    = self:_registerFlag(opts.ID, default)
local card, stroke = self:_makeCard()
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 8)
row.Parent            = card
local info = self:_makeInfoBlock(card, opts.Title, nil, 110)
local controls = Instance.new("Frame")
controls.BackgroundColor3 = Theme:BG(1)
controls.BorderSizePixel  = 0
controls.Size             = UDim2.fromOffset(100, 28)
controls.ClipsDescendants = true
controls.LayoutOrder      = 99
controls.Parent           = card
local ctrlCorner = Instance.new("UICorner")
ctrlCorner.CornerRadius = UDim.new(0, 6)
ctrlCorner.Parent       = controls
local ctrlStroke = Instance.new("UIStroke")
ctrlStroke.Color        = Theme:Accent()
ctrlStroke.Transparency = 0.4
ctrlStroke.Thickness    = 1
ctrlStroke.Parent       = controls
local btnMinus = Instance.new("TextButton")
btnMinus.Size                   = UDim2.fromOffset(26, 28)
btnMinus.Position               = UDim2.new(0, 0, 0, 0)
btnMinus.BackgroundColor3       = Theme:BG(3)
btnMinus.BorderSizePixel        = 0
btnMinus.Text                   = "-"
btnMinus.Font                   = Enum.Font.GothamBold
btnMinus.TextSize               = 14
btnMinus.TextColor3             = Theme:Text(2)
btnMinus.AutoButtonColor        = false
btnMinus.Parent                 = controls
local valBox = Instance.new("TextBox")
valBox.Size                   = UDim2.new(1, -52, 1, 0)
valBox.Position               = UDim2.new(0, 26, 0, 0)
valBox.BackgroundTransparency = 1
valBox.BorderSizePixel        = 0
valBox.Text                   = tostring(default)
valBox.Font                   = Enum.Font.Gotham
valBox.TextSize               = 14
valBox.TextColor3             = Theme:Text(0)
valBox.TextXAlignment         = Enum.TextXAlignment.Center
valBox.ClearTextOnFocus       = false
valBox.Parent                 = controls
local btnPlus = Instance.new("TextButton")
btnPlus.Size                   = UDim2.fromOffset(26, 28)
btnPlus.Position               = UDim2.new(1, -26, 0, 0)
btnPlus.BackgroundColor3       = Theme:BG(3)
btnPlus.BorderSizePixel        = 0
btnPlus.Text                   = "+"
btnPlus.Font                   = Enum.Font.GothamBold
btnPlus.TextSize               = 14
btnPlus.TextColor3             = Theme:Text(2)
btnPlus.AutoButtonColor        = false
btnPlus.Parent                 = controls
local value = default
local function setValue(v)
value        = math.clamp(v, min, max)
valBox.Text  = tostring(value)
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end
btnMinus.MouseButton1Click:Connect(function()
setValue(value - step)
end)
btnPlus.MouseButton1Click:Connect(function()
setValue(value + step)
end)
valBox.FocusLost:Connect(function()
local n = tonumber(valBox.Text)
if n then
setValue(n)
else
valBox.Text = tostring(value)
end
end)
for _, btn in ipairs({ btnMinus, btnPlus }) do
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Theme:BG(4) })
btn.TextColor3 = Theme:Text(0)
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Theme:BG(3) })
btn.TextColor3 = Theme:Text(2)
end)
end
valBox.Focused:Connect(function()
ctrlStroke.Color = Theme:Accent()
Tween.fast(ctrlStroke, { Transparency = 0 })
end)
valBox.FocusLost:Connect(function()
ctrlStroke.Color = Theme:Accent()
Tween.fast(ctrlStroke, { Transparency = 0.4 })
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
value       = math.clamp(v, min, max)
valBox.Text = tostring(value)
end)
end
table.insert(self._components, card)
return card
end
Section.AddTextInput = function(self, opts)
assert(type(opts) == "table", "AddTextInput: opts must be a table")
local flag = self:_registerFlag(opts.ID, opts.Default or "")
local card, stroke = self:_makeCard()
Layout.lockHeight(card, Layout.CARD_MIN_H)
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIPadding") or c:IsA("UIListLayout") then c:Destroy() end
end
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(0.45, -8, 1, 0)
title.Position               = UDim2.new(0, Layout.PAD_X, 0, 0)
title.Text                   = opts.Title or ""
title.Font                   = Layout.FONT_TITLE
title.TextSize               = Layout.TITLE_SIZE
title.TextColor3             = Theme:Text(1)
title.TextXAlignment         = Enum.TextXAlignment.Left
title.Parent                 = card
local CTRL = Layout.CTRL_H
local wrapSize
if type(opts.Width) == "string" and opts.Width:match("%%$") then
local pct = tonumber(opts.Width:match("([%d%.]+)")) or 55
wrapSize = UDim2.new(pct / 100, 0, 0, CTRL)
else
local px = type(opts.Width) == "number" and opts.Width or Layout.CTRL_W
wrapSize = UDim2.new(0, px, 0, CTRL)
end
local INPUT_FILL = 0.85
local wrap = Instance.new("Frame")
wrap.BackgroundColor3       = Theme:BG(4)
wrap.BackgroundTransparency = INPUT_FILL
wrap.BorderSizePixel  = 0
wrap.Size             = wrapSize
wrap.Position         = UDim2.new(1, -Layout.PAD_X, 0.5, 0)
wrap.AnchorPoint      = Vector2.new(1, 0.5)
wrap.ClipsDescendants = true
wrap.Parent           = card
local wrapCorner = Instance.new("UICorner")
wrapCorner.CornerRadius = UDim.new(0, 6)
wrapCorner.Parent       = wrap
local wrapStroke = Instance.new("UIStroke")
wrapStroke.Color        = Theme:Accent()
wrapStroke.Transparency = 0.22
wrapStroke.Thickness    = 1
wrapStroke.Parent       = wrap
task.defer(function()
if wrapStroke and wrapStroke.Parent then wrapStroke.Thickness = 1.0001; wrapStroke.Thickness = 1 end
end)
local halo = Instance.new("Frame")
halo.Name                   = "InputHalo"
halo.BackgroundTransparency = 1
halo.AnchorPoint            = Vector2.new(1, 0.5)
halo.Position               = UDim2.new(1, -Layout.PAD_X + 2, 0.5, 0)
halo.Size                   = UDim2.new(wrapSize.X.Scale, wrapSize.X.Offset + 4, 0, CTRL + 4)
halo.ZIndex                 = 0
halo.Parent                 = card
local haloCorner = Instance.new("UICorner")
haloCorner.CornerRadius = UDim.new(0, 8)
haloCorner.Parent       = halo
local haloStroke = Instance.new("UIStroke")
haloStroke.Color        = Theme:Accent()
haloStroke.Transparency = 0.85
haloStroke.Thickness    = 2
haloStroke.Parent       = halo
task.defer(function()
if haloStroke and haloStroke.Parent then haloStroke.Thickness = 2.0001; haloStroke.Thickness = 2 end
end)
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 9)
pad.PaddingRight  = UDim.new(0, 9)
pad.Parent        = wrap
local defaultAlign = opts.Align == "Left" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
local box = Instance.new("TextBox")
box.BackgroundTransparency = 1
box.BorderSizePixel        = 0
box.Size                   = UDim2.new(1, 0, 1, 0)
box.Text                   = opts.Default or ""
box.PlaceholderText        = opts.Placeholder or ""
box.PlaceholderColor3      = Theme:Text(4)
box.Font                   = Enum.Font.Gotham
box.TextSize               = Layout.VALUE_SIZE
box.TextColor3             = Theme:Text(0)
box.TextXAlignment         = defaultAlign
box.ClearTextOnFocus       = opts.ClearOnFocus or false
box.Parent                 = wrap
local function updateOverflow()
local fits = box.TextBounds.X <= (box.AbsoluteSize.X - 2)
box.TextXAlignment = fits and defaultAlign or Enum.TextXAlignment.Right
end
box:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
box:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
task.defer(updateOverflow)
box.Focused:Connect(function()
wrapStroke.Color = Theme:Accent()
Tween.fast(wrapStroke, { Transparency = 0 })
Tween.fast(haloStroke, { Transparency = 0.6 })
end)
box.FocusLost:Connect(function()
wrapStroke.Color = Theme:Accent()
Tween.fast(wrapStroke, { Transparency = 0.22 })
Tween.fast(haloStroke, { Transparency = 0.85 })
if flag then flag:_fire(box.Text) end
if opts.Callback then pcall(opts.Callback, box.Text) end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
box.Text = tostring(v)
end)
end
table.insert(self._components, card)
return card
end
Section.AddTextarea = function(self, opts)
assert(type(opts) == "table", "AddTextarea: opts must be a table")
local flag = self:_registerFlag(opts.ID, opts.Default or "")
local card, stroke = self:_makeCard()
Layout.lockHeight(card, 102)
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.SortOrder     = Enum.SortOrder.LayoutOrder
col.Padding       = UDim.new(0, 5)
col.Parent        = card
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(1, 0, 0, 15)
title.Text                   = opts.Title or ""
title.Font                   = Layout.FONT_TITLE
title.TextSize               = Layout.TITLE_SIZE
title.TextColor3             = Theme:Text(1)
title.TextXAlignment         = Enum.TextXAlignment.Left
title.LayoutOrder            = 1
title.Parent                 = card
local wrap = Instance.new("Frame")
wrap.BackgroundColor3 = Theme:BG(1)
wrap.BorderSizePixel  = 0
wrap.Size             = UDim2.new(1, 0, 0, 64)
wrap.ClipsDescendants = true
wrap.LayoutOrder      = 2
wrap.Parent           = card
local wrapCorner = Instance.new("UICorner")
wrapCorner.CornerRadius = UDim.new(0, 6)
wrapCorner.Parent       = wrap
local wrapStroke = Instance.new("UIStroke")
wrapStroke.Color        = Theme:Accent()
wrapStroke.Transparency = 0.22
wrapStroke.Thickness    = 1
wrapStroke.Parent       = wrap
task.defer(function()
if wrapStroke and wrapStroke.Parent then wrapStroke.Thickness = 1.0001; wrapStroke.Thickness = 1 end
end)
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 9)
pad.PaddingRight  = UDim.new(0, 9)
pad.PaddingTop    = UDim.new(0, 7)
pad.PaddingBottom = UDim.new(0, 7)
pad.Parent        = wrap
local box = Instance.new("TextBox")
box.BackgroundTransparency = 1
box.BorderSizePixel        = 0
box.Size                   = UDim2.new(1, 0, 1, 0)
box.Text                   = opts.Default or ""
box.PlaceholderText        = opts.Placeholder or ""
box.PlaceholderColor3      = Theme:Text(4)
box.Font                   = Enum.Font.Gotham
box.TextSize               = Layout.VALUE_SIZE
box.TextColor3             = Theme:Text(0)
box.TextXAlignment         = Enum.TextXAlignment.Left
box.TextYAlignment         = Enum.TextYAlignment.Top
box.MultiLine              = true
box.ClearTextOnFocus       = false
box.TextWrapped            = true
box.Parent                 = wrap
box.Focused:Connect(function()
wrapStroke.Color = Theme:Accent()
Tween.fast(wrapStroke, { Transparency = 0 })
end)
box.FocusLost:Connect(function()
wrapStroke.Color = Theme:Accent()
Tween.fast(wrapStroke, { Transparency = 0.22 })
if flag then flag:_fire(box.Text) end
if opts.Callback then pcall(opts.Callback, box.Text) end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
box.Text = tostring(v)
end)
end
table.insert(self._components, card)
return card
end
Section.AddDropdown = function(self, opts)
assert(type(opts) == "table", "AddDropdown: opts must be a table")
local items   = opts.Options or opts.Items or {}
local default = opts.Default  or (items[1] or "")
local flag    = self:_registerFlag(opts.ID, default)
local card, stroke = self:_makeCard(opts.LayoutOrder)
card.ClipsDescendants = false
Layout.lockHeight(card, Layout.CARD_MIN_H)
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIPadding") then c:Destroy() end
end
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(1, -(Layout.CTRL_W + Layout.PAD_X * 2 + 8), 1, 0)
title.Position               = UDim2.new(0, Layout.PAD_X, 0, 0)
title.Text                   = opts.Title or ""
title.Font                   = Layout.FONT_TITLE
title.TextSize               = Layout.TITLE_SIZE
title.TextColor3             = Theme:Text(1)
title.TextXAlignment         = Enum.TextXAlignment.Left
title.TextTruncate           = Enum.TextTruncate.AtEnd
title.Parent                 = card
local trigger = Instance.new("TextButton")
trigger.BackgroundColor3       = Theme:BG(4)
trigger.BackgroundTransparency = 0.85
trigger.BorderSizePixel  = 0
trigger.Size             = UDim2.new(0, Layout.CTRL_W, 0, Layout.CTRL_H)
trigger.AnchorPoint      = Vector2.new(1, 0.5)
trigger.Position         = UDim2.new(1, -Layout.PAD_X, 0.5, 0)
trigger.Text             = ""
trigger.AutoButtonColor  = false
trigger.Parent           = card
local trigCorner = Instance.new("UICorner")
trigCorner.CornerRadius = UDim.new(0, 6)
trigCorner.Parent       = trigger
local trigStroke = Instance.new("UIStroke")
trigStroke.Color          = Theme:Accent()
trigStroke.Transparency   = 0.35
trigStroke.Thickness      = 1
trigStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
trigStroke.Parent         = trigger
task.defer(function()
if trigStroke and trigStroke.Parent then trigStroke.Thickness = 1.0001; trigStroke.Thickness = 1 end
end)
local trigPad = Instance.new("UIPadding")
trigPad.PaddingLeft  = UDim.new(0, 8)
trigPad.PaddingRight = UDim.new(0, 20)
trigPad.Parent       = trigger
local valLbl = Instance.new("TextLabel")
valLbl.BackgroundTransparency = 1
valLbl.Size                   = UDim2.new(1, 0, 1, 0)
valLbl.Text                   = default
valLbl.Font                   = Layout.FONT_BODY
valLbl.TextSize               = 13
valLbl.TextColor3             = Theme:Text(2)
valLbl.TextXAlignment         = Enum.TextXAlignment.Left
valLbl.TextTruncate           = Enum.TextTruncate.AtEnd
valLbl.Parent                 = trigger
local arrow = Icons.new("chevron-right", 12, Theme:Accent())
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.Position    = UDim2.new(1, 10, 0.5, 0)
arrow.Parent      = trigger
Theme:OnAccentChanged(function(a) arrow.ImageColor3 = a end)
local selected = default
local open     = false
local allBtns  = {}
local panel, blocker, list, searchBox
local closeMenu, buildItems
local PANEL_TOP = 50
local function winRoot()
return card:FindFirstAncestorWhichIsA("CanvasGroup")
end
local function ensurePanel(win)
if panel and panel.Parent then return end
blocker = Instance.new("TextButton")
blocker.Name                   = "DropPanelBlocker"
blocker.BackgroundColor3       = Color3.new(0, 0, 0)
blocker.BackgroundTransparency = 1
blocker.BorderSizePixel        = 0
blocker.AutoButtonColor        = false
blocker.Text                   = ""
blocker.Size                   = UDim2.new(1, 0, 1, 0)
blocker.ZIndex                 = 40
blocker.Visible                = false
blocker.Parent                 = win
blocker.MouseButton1Click:Connect(function() closeMenu() end)
panel = Instance.new("Frame")
panel.Name                   = "DropPanel"
panel.BackgroundColor3       = Theme:BG(1)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel        = 0
panel.AnchorPoint            = Vector2.new(1, 0)
panel.Position               = UDim2.new(1, -6, 0, PANEL_TOP)
panel.ZIndex                 = 41
panel.ClipsDescendants       = true
panel.Visible                = false
panel.Parent                 = win
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent       = panel
local pStroke = Instance.new("UIStroke")
pStroke.Color        = Theme:Accent()
pStroke.Transparency = 0.35
pStroke.Thickness    = 1
pStroke.Parent       = panel
task.defer(function()
if pStroke and pStroke.Parent then pStroke.Thickness = 1.0001; pStroke.Thickness = 1 end
end)
local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.Size                   = UDim2.new(1, 0, 0, 40)
header.ZIndex                 = 42
header.Parent                 = panel
local hLbl = Instance.new("TextLabel")
hLbl.BackgroundTransparency = 1
hLbl.Size                   = UDim2.new(1, -50, 1, 0)
hLbl.Position               = UDim2.new(0, 14, 0, 0)
hLbl.Text                   = opts.Title or ""
hLbl.Font                   = Enum.Font.GothamBold
hLbl.TextSize               = 15
hLbl.TextColor3             = Theme:Accent()
hLbl.TextXAlignment         = Enum.TextXAlignment.Left
hLbl.TextTruncate           = Enum.TextTruncate.AtEnd
hLbl.ZIndex                 = 42
hLbl.Parent                 = header
local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundTransparency = 1
closeBtn.Size                   = UDim2.fromOffset(30, 30)
closeBtn.Position               = UDim2.new(1, -36, 0, 5)
closeBtn.Text                   = ""
closeBtn.AutoButtonColor        = false
closeBtn.ZIndex                 = 42
closeBtn.Parent                 = header
local closeIco = Icons.new("x", 14, Theme:Text(3))
closeIco.AnchorPoint = Vector2.new(0.5, 0.5)
closeIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
closeIco.ZIndex      = 42
closeIco.Parent      = closeBtn
closeBtn.MouseEnter:Connect(function() closeIco.ImageColor3 = Theme:Text(0) end)
closeBtn.MouseLeave:Connect(function() closeIco.ImageColor3 = Theme:Text(3) end)
closeBtn.MouseButton1Click:Connect(function() closeMenu() end)
local hDiv = Instance.new("Frame")
hDiv.BackgroundColor3 = Theme:Border(1)
hDiv.BorderSizePixel  = 0
hDiv.Size             = UDim2.new(1, 0, 0, 1)
hDiv.Position         = UDim2.new(0, 0, 1, -1)
hDiv.ZIndex           = 42
hDiv.Parent           = header
local sWrap = Instance.new("Frame")
sWrap.BackgroundColor3       = Theme:BG(4)
sWrap.BackgroundTransparency = 0.7
sWrap.BorderSizePixel        = 0
sWrap.Size                   = UDim2.new(1, -20, 0, 30)
sWrap.Position               = UDim2.new(0, 10, 0, 47)
sWrap.ZIndex                 = 42
sWrap.Parent                 = panel
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 7)
sCorner.Parent       = sWrap
local sBox = Instance.new("TextBox")
sBox.BackgroundTransparency = 1
sBox.BorderSizePixel        = 0
sBox.Size                   = UDim2.new(1, -16, 1, 0)
sBox.Position               = UDim2.new(0, 8, 0, 0)
sBox.PlaceholderText        = "Search..."
sBox.PlaceholderColor3      = Theme:Text(4)
sBox.Text                   = ""
sBox.Font                   = Enum.Font.Gotham
sBox.TextSize               = 13
sBox.TextColor3             = Theme:Text(0)
sBox.ClearTextOnFocus       = false
sBox.ZIndex                 = 42
sBox.Parent                 = sWrap
searchBox = sBox
sBox:GetPropertyChangedSignal("Text"):Connect(function()
if not open then return end
buildItems(sBox.Text ~= "" and sBox.Text or nil)
end)
list = Instance.new("ScrollingFrame")
list.BackgroundTransparency  = 1
list.BorderSizePixel         = 0
list.Size                    = UDim2.new(1, 0, 1, -84)
list.Position                = UDim2.new(0, 0, 0, 84)
list.CanvasSize              = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize     = Enum.AutomaticSize.Y
list.ScrollBarThickness      = 3
list.ScrollBarImageColor3    = Theme:Accent()
list.ZIndex                  = 42
list.Parent                  = panel
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
listLayout.Parent        = list
local listPad = Instance.new("UIPadding")
listPad.PaddingBottom = UDim.new(0, 8)
listPad.Parent        = list
end
buildItems = function(filter)
for _, b in ipairs(allBtns) do b:Destroy() end
allBtns = {}
for _, item in ipairs(items) do
if not filter or item:lower():find(filter:lower(), 1, true) then
local row = Instance.new("TextButton")
row.BackgroundTransparency = 1
row.BorderSizePixel        = 0
row.Size                   = UDim2.new(1, 0, 0, 32)
row.AutomaticSize          = Enum.AutomaticSize.Y
row.Text                   = ""
row.AutoButtonColor        = false
row.ZIndex                 = 43
row.Parent                 = list
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 14)
pad.PaddingRight  = UDim.new(0, 12)
pad.PaddingTop    = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent        = row
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(1, -18, 0, 15)
lbl.AutomaticSize          = Enum.AutomaticSize.Y
lbl.Text                   = item
lbl.Font                   = item == selected and Enum.Font.GothamBold or Enum.Font.Gotham
lbl.TextSize               = 13
lbl.TextColor3             = item == selected and Theme:Accent() or Theme:Text(2)
lbl.TextXAlignment         = Enum.TextXAlignment.Left
lbl.TextYAlignment         = Enum.TextYAlignment.Top
lbl.TextWrapped            = true
lbl.ZIndex                 = 43
lbl.Parent                 = row
if item == selected then
local check = Icons.new("check", 14, Theme:Accent())
check.Position = UDim2.new(1, -14, 0.5, -7)
check.ZIndex   = 43
check.Parent   = row
end
row.MouseEnter:Connect(function()
row.BackgroundTransparency = 0.85
row.BackgroundColor3       = Theme:BG(4)
end)
row.MouseLeave:Connect(function()
row.BackgroundTransparency = 1
end)
row.MouseButton1Click:Connect(function()
selected    = item
valLbl.Text = item
if flag then flag:_fire(item) end
if opts.Callback then pcall(opts.Callback, item) end
closeMenu()
end)
table.insert(allBtns, row)
end
end
end
closeMenu = function()
if not open then return end
open = false
if panel then
Tween.play(panel, { Position = UDim2.new(1, 20, 0, PANEL_TOP) },
TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.16, function()
if not open and panel then panel.Visible = false end
end)
end
if blocker then
Tween.fast(blocker, { BackgroundTransparency = 1 })
task.delay(0.16, function()
if not open and blocker then blocker.Visible = false end
end)
end
Tween.fast(arrow, { Rotation = 0 })
trigStroke.Color = Theme:Accent()
Tween.fast(trigStroke, { Transparency = 0.35 })
if searchBox then searchBox.Text = "" end
end
local function openMenu()
local win = winRoot()
if not win then return end
ensurePanel(win)
open = true
local w = math.floor(math.clamp(win.Size.X.Offset * 0.46, 200, 320))
panel.Size     = UDim2.new(0, w, 1, -(PANEL_TOP + 8))
panel.Position = UDim2.new(1, 20, 0, PANEL_TOP)
buildItems(nil)
blocker.Visible = true
Tween.fast(blocker, { BackgroundTransparency = 0.55 })
panel.Visible = true
Tween.play(panel, { Position = UDim2.new(1, -6, 0, PANEL_TOP) },
TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
Tween.fast(arrow, { Rotation = 90 })
trigStroke.Color = Theme:Accent()
Tween.fast(trigStroke, { Transparency = 0 })
end
trigger.MouseButton1Click:Connect(function()
if open then closeMenu() else openMenu() end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
selected    = v
valLbl.Text = v
end)
end
card.Destroying:Connect(function()
if panel then pcall(function() panel:Destroy() end) end
if blocker then pcall(function() blocker:Destroy() end) end
end)
table.insert(self._components, card)
return card
end
Section.AddMultiDropdown = function(self, opts)
assert(type(opts) == "table", "AddMultiDropdown: opts must be a table")
local items    = opts.Options or opts.Items or {}
local defaults = opts.Default or {}
local flag     = self:_registerFlag(opts.ID, defaults)
local card, stroke = self:_makeCard()
card.ClipsDescendants = false
Layout.lockHeight(card, Layout.CARD_MIN_H)
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIPadding") then c:Destroy() end
end
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(1, -(Layout.CTRL_W + Layout.PAD_X * 2 + 8), 1, 0)
title.Position               = UDim2.new(0, Layout.PAD_X, 0, 0)
title.Text                   = opts.Title or ""
title.Font                   = Layout.FONT_TITLE
title.TextSize               = Layout.TITLE_SIZE
title.TextColor3             = Theme:Text(1)
title.TextXAlignment         = Enum.TextXAlignment.Left
title.TextTruncate           = Enum.TextTruncate.AtEnd
title.Parent                 = card
local trigger = Instance.new("TextButton")
trigger.BackgroundColor3       = Theme:BG(4)
trigger.BackgroundTransparency = 0.85
trigger.BorderSizePixel  = 0
trigger.Size             = UDim2.new(0, Layout.CTRL_W, 0, Layout.CTRL_H)
trigger.AnchorPoint      = Vector2.new(1, 0.5)
trigger.Position         = UDim2.new(1, -Layout.PAD_X, 0.5, 0)
trigger.AutomaticSize    = Enum.AutomaticSize.None
trigger.Text             = ""
trigger.AutoButtonColor  = false
trigger.Parent           = card
local trigCorner = Instance.new("UICorner")
trigCorner.CornerRadius = UDim.new(0, 6)
trigCorner.Parent       = trigger
local trigStroke = Instance.new("UIStroke")
trigStroke.Color          = Theme:Accent()
trigStroke.Transparency   = 0.35
trigStroke.Thickness      = 1
trigStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
trigStroke.Parent         = trigger
task.defer(function()
if trigStroke and trigStroke.Parent then trigStroke.Thickness = 1.0001; trigStroke.Thickness = 1 end
end)
local trigPad = Instance.new("UIPadding")
trigPad.PaddingLeft   = UDim.new(0, 8)
trigPad.PaddingRight  = UDim.new(0, 20)
trigPad.Parent        = trigger
local summaryLbl = Instance.new("TextLabel")
summaryLbl.BackgroundTransparency = 1
summaryLbl.Size                   = UDim2.new(1, 0, 1, 0)
summaryLbl.Text                   = "Select options..."
summaryLbl.Font                   = Enum.Font.Gotham
summaryLbl.TextSize               = 13
summaryLbl.TextColor3             = Theme:Text(4)
summaryLbl.TextXAlignment         = Enum.TextXAlignment.Left
summaryLbl.TextTruncate           = Enum.TextTruncate.AtEnd
summaryLbl.Parent                 = trigger
local arrow = Icons.new("chevron-right", 12, Theme:Accent())
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.Position    = UDim2.new(1, 10, 0.5, 0)
arrow.Parent      = trigger
Theme:OnAccentChanged(function(a) arrow.ImageColor3 = a end)
local selected = {}
for _, v in ipairs(defaults) do selected[v] = true end
local open    = false
local allRows = {}
local panel, blocker, list, searchBox, countLbl, selectAllBtn, selectAllLbl
local closeMenu, buildRows, refreshSelectAll
local PANEL_TOP = 50
local function winRoot()
return card:FindFirstAncestorWhichIsA("CanvasGroup")
end
local _origIndex = {}
for i, item in ipairs(items) do _origIndex[item] = i end
local function orderedItems(filter)
local picked, rest = {}, {}
for _, item in ipairs(items) do
if not filter or item:lower():find(filter:lower(), 1, true) then
if selected[item] then table.insert(picked, item)
else table.insert(rest, item) end
end
end
local out = {}
for _, v in ipairs(picked) do out[#out + 1] = v end
for _, v in ipairs(rest)   do out[#out + 1] = v end
return out
end
local function refreshSummary()
local activeList = {}
for _, item in ipairs(items) do
if selected[item] then table.insert(activeList, item) end
end
local count = #activeList
if count == 0 then
summaryLbl.Text       = "Select options..."
summaryLbl.TextColor3 = Theme:Text(4)
elseif count == 1 then
summaryLbl.Text       = activeList[1]
summaryLbl.TextColor3 = Theme:Accent()
elseif count == 2 then
summaryLbl.Text       = activeList[1] .. ", " .. activeList[2]
summaryLbl.TextColor3 = Theme:Accent()
else
summaryLbl.Text       = activeList[1] .. ", " .. activeList[2] .. ", +" .. (count - 2) .. " more"
summaryLbl.TextColor3 = Theme:Accent()
end
if countLbl then
countLbl.Text = count > 0 and (count .. " selected") or ""
end
end
refreshSelectAll = function(filter)
if not selectAllLbl then return end
local anyVisible, allOn = false, true
for _, item in ipairs(items) do
if not filter or item:lower():find(filter:lower(), 1, true) then
anyVisible = true
if not selected[item] then allOn = false end
end
end
selectAllLbl.Text = (anyVisible and allOn) and "Deselect All" or "Select All"
end
local function ensurePanel(win)
if panel and panel.Parent then return end
blocker = Instance.new("TextButton")
blocker.Name                   = "DropPanelBlocker"
blocker.BackgroundColor3       = Color3.new(0, 0, 0)
blocker.BackgroundTransparency = 1
blocker.BorderSizePixel        = 0
blocker.AutoButtonColor        = false
blocker.Text                   = ""
blocker.Size                   = UDim2.new(1, 0, 1, 0)
blocker.ZIndex                 = 40
blocker.Visible                = false
blocker.Parent                 = win
blocker.MouseButton1Click:Connect(function() closeMenu() end)
panel = Instance.new("Frame")
panel.Name                   = "DropPanel"
panel.BackgroundColor3       = Theme:BG(1)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel        = 0
panel.AnchorPoint            = Vector2.new(1, 0)
panel.Position               = UDim2.new(1, -6, 0, PANEL_TOP)
panel.ZIndex                 = 41
panel.ClipsDescendants       = true
panel.Visible                = false
panel.Parent                 = win
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent       = panel
local pStroke = Instance.new("UIStroke")
pStroke.Color        = Theme:Accent()
pStroke.Transparency = 0.35
pStroke.Thickness    = 1
pStroke.Parent       = panel
task.defer(function()
if pStroke and pStroke.Parent then pStroke.Thickness = 1.0001; pStroke.Thickness = 1 end
end)
local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.Size                   = UDim2.new(1, 0, 0, 40)
header.ZIndex                 = 42
header.Parent                 = panel
local hLbl = Instance.new("TextLabel")
hLbl.BackgroundTransparency = 1
hLbl.Size                   = UDim2.new(1, -50, 0, 22)
hLbl.Position               = UDim2.new(0, 14, 0, 3)
hLbl.Text                   = opts.Title or ""
hLbl.Font                   = Enum.Font.GothamBold
hLbl.TextSize               = 15
hLbl.TextColor3             = Theme:Accent()
hLbl.TextXAlignment         = Enum.TextXAlignment.Left
hLbl.TextTruncate           = Enum.TextTruncate.AtEnd
hLbl.ZIndex                 = 42
hLbl.Parent                 = header
countLbl = Instance.new("TextLabel")
countLbl.BackgroundTransparency = 1
countLbl.Size                   = UDim2.new(1, -50, 0, 13)
countLbl.Position               = UDim2.new(0, 14, 0, 24)
countLbl.Text                   = ""
countLbl.Font                   = Enum.Font.Gotham
countLbl.TextSize               = 12
countLbl.TextColor3             = Theme:Text(3)
countLbl.TextXAlignment         = Enum.TextXAlignment.Left
countLbl.ZIndex                 = 42
countLbl.Parent                 = header
local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundTransparency = 1
closeBtn.Size                   = UDim2.fromOffset(30, 30)
closeBtn.Position               = UDim2.new(1, -36, 0, 5)
closeBtn.Text                   = ""
closeBtn.AutoButtonColor        = false
closeBtn.ZIndex                 = 42
closeBtn.Parent                 = header
local closeIco = Icons.new("x", 14, Theme:Text(3))
closeIco.AnchorPoint = Vector2.new(0.5, 0.5)
closeIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
closeIco.ZIndex      = 42
closeIco.Parent      = closeBtn
closeBtn.MouseEnter:Connect(function() closeIco.ImageColor3 = Theme:Text(0) end)
closeBtn.MouseLeave:Connect(function() closeIco.ImageColor3 = Theme:Text(3) end)
closeBtn.MouseButton1Click:Connect(function() closeMenu() end)
local hDiv = Instance.new("Frame")
hDiv.BackgroundColor3 = Theme:Border(1)
hDiv.BorderSizePixel  = 0
hDiv.Size             = UDim2.new(1, 0, 0, 1)
hDiv.Position         = UDim2.new(0, 0, 1, -1)
hDiv.ZIndex           = 42
hDiv.Parent           = header
local sWrap = Instance.new("Frame")
sWrap.BackgroundColor3       = Theme:BG(4)
sWrap.BackgroundTransparency = 0.7
sWrap.BorderSizePixel        = 0
sWrap.Size                   = UDim2.new(1, -20, 0, 30)
sWrap.Position               = UDim2.new(0, 10, 0, 47)
sWrap.ZIndex                 = 42
sWrap.Parent                 = panel
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 7)
sCorner.Parent       = sWrap
local sBox = Instance.new("TextBox")
sBox.BackgroundTransparency = 1
sBox.BorderSizePixel        = 0
sBox.Size                   = UDim2.new(1, -16, 1, 0)
sBox.Position               = UDim2.new(0, 8, 0, 0)
sBox.PlaceholderText        = "Search..."
sBox.PlaceholderColor3      = Theme:Text(4)
sBox.Text                   = ""
sBox.Font                   = Enum.Font.Gotham
sBox.TextSize               = 13
sBox.TextColor3             = Theme:Text(0)
sBox.ClearTextOnFocus       = false
sBox.ZIndex                 = 42
sBox.Parent                 = sWrap
searchBox = sBox
sBox:GetPropertyChangedSignal("Text"):Connect(function()
if not open then return end
local f = sBox.Text ~= "" and sBox.Text or nil
buildRows(f)
refreshSelectAll(f)
end)
selectAllBtn = Instance.new("TextButton")
selectAllBtn.BackgroundColor3       = Theme:BG(4)
selectAllBtn.BackgroundTransparency = 0.7
selectAllBtn.BorderSizePixel        = 0
selectAllBtn.Size                   = UDim2.new(1, -20, 0, 26)
selectAllBtn.Position               = UDim2.new(0, 10, 0, 81)
selectAllBtn.Text                   = ""
selectAllBtn.AutoButtonColor        = false
selectAllBtn.ZIndex                 = 42
selectAllBtn.Parent                 = panel
local saCorner = Instance.new("UICorner")
saCorner.CornerRadius = UDim.new(0, 7)
saCorner.Parent       = selectAllBtn
local saStroke = Instance.new("UIStroke")
saStroke.Color        = Theme:Accent()
saStroke.Transparency = 0.5
saStroke.Thickness    = 1
saStroke.Parent       = selectAllBtn
selectAllLbl = Instance.new("TextLabel")
selectAllLbl.BackgroundTransparency = 1
selectAllLbl.Size                   = UDim2.new(1, 0, 1, 0)
selectAllLbl.Text                   = "Select All"
selectAllLbl.Font                   = Enum.Font.GothamMedium
selectAllLbl.TextSize               = 12
selectAllLbl.TextColor3             = Theme:Accent()
selectAllLbl.ZIndex                 = 42
selectAllLbl.Parent                 = selectAllBtn
selectAllBtn.MouseEnter:Connect(function() selectAllBtn.BackgroundTransparency = 0.5 end)
selectAllBtn.MouseLeave:Connect(function() selectAllBtn.BackgroundTransparency = 0.7 end)
selectAllBtn.MouseButton1Click:Connect(function()
local f = searchBox and searchBox.Text ~= "" and searchBox.Text or nil
local visible = {}
for _, item in ipairs(items) do
if not f or item:lower():find(f:lower(), 1, true) then
visible[#visible + 1] = item
end
end
local allOn = (#visible > 0)
for _, item in ipairs(visible) do
if not selected[item] then allOn = false; break end
end
local target = not allOn
for _, item in ipairs(visible) do selected[item] = target end
refreshSummary()
refreshSelectAll(f)
local vals = {}
for k, v in pairs(selected) do if v then table.insert(vals, k) end end
if flag then flag:_fire(vals) end
if opts.Callback then pcall(opts.Callback, vals) end
buildRows(f)
end)
list = Instance.new("ScrollingFrame")
list.BackgroundTransparency  = 1
list.BorderSizePixel         = 0
list.Size                    = UDim2.new(1, 0, 1, -116)
list.Position                = UDim2.new(0, 0, 0, 116)
list.CanvasSize              = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize     = Enum.AutomaticSize.Y
list.ScrollBarThickness      = 3
list.ScrollBarImageColor3    = Theme:Accent()
list.ZIndex                  = 42
list.Parent                  = panel
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
listLayout.Parent        = list
local listPad = Instance.new("UIPadding")
listPad.PaddingBottom = UDim.new(0, 8)
listPad.Parent        = list
end
buildRows = function(filter)
for _, r in ipairs(allRows) do r:Destroy() end
allRows = {}
local order = 0
for _, item in ipairs(orderedItems(filter)) do
do
order = order + 1
local row = Instance.new("TextButton")
row.BackgroundTransparency = 1
row.BorderSizePixel        = 0
row.Size                   = UDim2.new(1, 0, 0, 32)
row.AutomaticSize          = Enum.AutomaticSize.Y
row.LayoutOrder            = order
row.Text                   = ""
row.AutoButtonColor        = false
row.ZIndex                 = 43
row.Parent                 = list
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 12)
pad.PaddingRight  = UDim.new(0, 12)
pad.PaddingTop    = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent        = row
local check = Instance.new("Frame")
check.Size             = UDim2.fromOffset(16, 16)
check.Position         = UDim2.new(0, 0, 0.5, -8)
check.BackgroundColor3 = selected[item] and Theme:Accent() or Theme:BG(1)
check.BorderSizePixel  = 0
check.ZIndex           = 43
check.Parent           = row
local checkCorner = Instance.new("UICorner")
checkCorner.CornerRadius = UDim.new(0, 4)
checkCorner.Parent       = check
local checkStroke = Instance.new("UIStroke")
checkStroke.Color     = selected[item] and Theme:Accent() or Theme:Border(1)
checkStroke.Thickness = 1
checkStroke.Parent    = check
local checkMark = Icons.new("check", 12, Color3.new(1, 1, 1))
checkMark.AnchorPoint       = Vector2.new(0.5, 0.5)
checkMark.Position          = UDim2.new(0.5, 0, 0.5, 0)
checkMark.ImageTransparency = selected[item] and 0 or 1
checkMark.ZIndex            = 44
checkMark.Parent            = check
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(1, -26, 0, 15)
lbl.AutomaticSize          = Enum.AutomaticSize.Y
lbl.Position               = UDim2.new(0, 24, 0, 0)
lbl.Text                   = item
lbl.Font                   = Enum.Font.Gotham
lbl.TextSize               = 13
lbl.TextColor3             = selected[item] and Theme:Accent() or Theme:Text(2)
lbl.TextXAlignment         = Enum.TextXAlignment.Left
lbl.TextYAlignment         = Enum.TextYAlignment.Top
lbl.TextWrapped            = true
lbl.ZIndex                 = 43
lbl.Parent                 = row
row.MouseEnter:Connect(function()
row.BackgroundTransparency = 0.85
row.BackgroundColor3       = Theme:BG(4)
end)
row.MouseLeave:Connect(function()
row.BackgroundTransparency = 1
end)
row.MouseButton1Click:Connect(function()
selected[item] = not selected[item]
check.BackgroundColor3      = selected[item] and Theme:Accent() or Theme:BG(1)
checkStroke.Color           = selected[item] and Theme:Accent() or Theme:Border(1)
checkMark.ImageTransparency = selected[item] and 0 or 1
lbl.TextColor3              = selected[item] and Theme:Accent() or Theme:Text(2)
refreshSummary()
if refreshSelectAll then refreshSelectAll(filter) end
local vals = {}
for k, v in pairs(selected) do if v then table.insert(vals, k) end end
if flag then flag:_fire(vals) end
if opts.Callback then pcall(opts.Callback, vals) end
buildRows(filter)
end)
table.insert(allRows, row)
end
end
end
closeMenu = function()
if not open then return end
open = false
if panel then
Tween.play(panel, { Position = UDim2.new(1, 20, 0, PANEL_TOP) },
TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.16, function()
if not open and panel then panel.Visible = false end
end)
end
if blocker then
Tween.fast(blocker, { BackgroundTransparency = 1 })
task.delay(0.16, function()
if not open and blocker then blocker.Visible = false end
end)
end
Tween.fast(arrow, { Rotation = 0 })
trigStroke.Color = Theme:Accent()
Tween.fast(trigStroke, { Transparency = 0.35 })
if searchBox then searchBox.Text = "" end
end
local function openMenu()
local win = winRoot()
if not win then return end
ensurePanel(win)
open = true
local w = math.floor(math.clamp(win.Size.X.Offset * 0.46, 200, 320))
panel.Size     = UDim2.new(0, w, 1, -(PANEL_TOP + 8))
panel.Position = UDim2.new(1, 20, 0, PANEL_TOP)
buildRows(nil)
refreshSummary()
refreshSelectAll(nil)
blocker.Visible = true
Tween.fast(blocker, { BackgroundTransparency = 0.55 })
panel.Visible = true
Tween.play(panel, { Position = UDim2.new(1, -6, 0, PANEL_TOP) },
TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
Tween.fast(arrow, { Rotation = 90 })
trigStroke.Color = Theme:Accent()
Tween.fast(trigStroke, { Transparency = 0 })
end
trigger.MouseButton1Click:Connect(function()
if open then closeMenu() else openMenu() end
end)
refreshSummary()
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
if type(v) ~= "table" then return end
selected = {}
for _, item in ipairs(v) do selected[item] = true end
refreshSummary()
if refreshSelectAll then refreshSelectAll(nil) end
if open then buildRows(nil) end
end)
end
card.Destroying:Connect(function()
if panel then pcall(function() panel:Destroy() end) end
if blocker then pcall(function() blocker:Destroy() end) end
end)
table.insert(self._components, card)
return card
end
local UserInputService = game:GetService("UserInputService")
local KEY_LABELS = {
Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
KeypadZero = "KP0", KeypadOne = "KP1", KeypadTwo = "KP2",
KeypadThree = "KP3", KeypadFour = "KP4", KeypadFive = "KP5",
KeypadSix = "KP6", KeypadSeven = "KP7", KeypadEight = "KP8",
KeypadNine = "KP9",
KeypadPlus = "KP+", KeypadMinus = "KP-", KeypadAsterisk = "KP*",
KeypadSlash = "KP/", KeypadPeriod = "KP.", KeypadEnter = "KP-ENT",
LeftShift = "L.SHIFT", RightShift = "R.SHIFT",
LeftControl = "L.CTRL", RightControl = "R.CTRL",
LeftAlt = "L.ALT", RightAlt = "R.ALT",
LeftMeta = "L.WIN", RightMeta = "R.WIN",
Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT",
Home = "HOME", End = "END",
PageUp = "PGUP", PageDown = "PGDN",
Insert = "INS", Delete = "DEL",
Return = "ENTER", BackSpace = "BKSP", Tab = "TAB",
Space = "SPACE", Escape = "ESC", CapsLock = "CAPS",
Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]",
BackSlash = "\\", Semicolon = ";", Quote = "'",
Comma = ",", Period = ".", Slash = "/",
Backquote = "`",
}
Section.AddKeybind = function(self, opts)
assert(type(opts) == "table", "AddKeybind: opts must be a table")
local default = opts.Default or Enum.KeyCode.Unknown
local flag    = self:_registerFlag(opts.ID, default)
local card, stroke = self:_makeCard()
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 8)
row.Parent            = card
local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 80)
local keyBtn = Instance.new("TextButton")
keyBtn.BackgroundTransparency = 1
keyBtn.BorderSizePixel        = 0
keyBtn.Size                   = UDim2.fromOffset(68, 26)
keyBtn.LayoutOrder            = 99
keyBtn.AutoButtonColor        = false
keyBtn.Font                   = Layout.FONT_BOLD
keyBtn.TextSize               = Layout.TITLE_SIZE
keyBtn.TextColor3             = Theme:Accent()
keyBtn.TextXAlignment         = Enum.TextXAlignment.Right
keyBtn.Parent                 = card
local keyStroke = Instance.new("UIStroke")
keyStroke.Color     = Theme:Accent()
keyStroke.Thickness = 0
keyStroke.Parent    = keyBtn
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 5)
keyCorner.Parent       = keyBtn
local function keyName(kc)
if kc == Enum.KeyCode.Unknown then return "NONE" end
return KEY_LABELS[kc.Name] or kc.Name:upper()
end
local value    = default
local listening = false
keyBtn.Text = keyName(value)
local function setListening(state)
listening = state
if state then
keyBtn.Text          = "..."
keyBtn.TextColor3    = Theme:Text(3)
keyStroke.Thickness  = 1
keyStroke.Color      = Theme:Accent()
else
keyBtn.Text          = keyName(value)
keyBtn.TextColor3    = Theme:Accent()
keyStroke.Thickness  = 0
end
end
keyBtn.MouseButton1Click:Connect(function()
setListening(not listening)
end)
UserInputService.InputBegan:Connect(function(input, gpe)
if not listening then return end
if input.UserInputType == Enum.UserInputType.Keyboard then
if input.KeyCode == Enum.KeyCode.Escape then
setListening(false)
return
end
value = input.KeyCode
setListening(false)
if flag then flag:_fire(value) end
if opts.Callback then pcall(opts.Callback, value) end
end
end)
keyBtn.MouseEnter:Connect(function()
if not listening then
Tween.fast(keyBtn, { TextColor3 = Color.lighten(Theme:Accent(), 0.15) })
end
end)
keyBtn.MouseLeave:Connect(function()
if not listening then
Tween.fast(keyBtn, { TextColor3 = Theme:Accent() })
end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
Theme:OnAccentChanged(function(accent)
keyBtn.TextColor3 = accent
end)
if flag then
flag:OnChanged(function(v)
value     = v
keyBtn.Text = keyName(v)
end)
end
table.insert(self._components, card)
return card
end
local PRESETS = {
"#A855F7","#8B5CF6","#6366F1","#3B82F6","#06B6D4","#22C55E",
"#EAB308","#F97316","#EF4444","#EC4899","#F43F5E","#14B8A6",
"#FFFFFF","#D4D4D8","#A1A1AA","#71717A","#52525B","#27272A",
"#FDE68A","#BBF7D0","#BAE6FD","#E9D5FF","#FECACA","#FED7AA",
}
Section.AddColorPicker = function(self, opts)
assert(type(opts) == "table", "AddColorPicker: opts must be a table")
local default = opts.Default or Color.fromHex("#A855F7")
local flag    = self:_registerFlag(opts.ID, default)
local card, stroke = self:_makeCard()
card.ClipsDescendants = false
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 8)
row.Parent            = card
local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 46)
local previewBtn = Instance.new("TextButton")
previewBtn.BackgroundColor3 = default
previewBtn.BorderSizePixel  = 0
previewBtn.Size             = UDim2.fromOffset(30, 30)
previewBtn.LayoutOrder      = 99
previewBtn.Text             = ""
previewBtn.AutoButtonColor  = false
previewBtn.Parent           = card
local pvCorner = Instance.new("UICorner")
pvCorner.CornerRadius = UDim.new(0, 7)
pvCorner.Parent       = previewBtn
local pvStroke = Instance.new("UIStroke")
pvStroke.Color     = Theme:Border(1)
pvStroke.Thickness = 2
pvStroke.Parent    = previewBtn
local palette = Instance.new("Frame")
palette.BackgroundColor3 = Theme:BG(3)
palette.BorderSizePixel  = 0
palette.Size             = UDim2.fromOffset(188, 0)
palette.AutomaticSize    = Enum.AutomaticSize.Y
palette.Visible          = false
palette.ZIndex = 3
palette.Parent           = card
local palCorner = Instance.new("UICorner")
palCorner.CornerRadius = UDim.new(0, 10)
palCorner.Parent       = palette
local palStroke = Instance.new("UIStroke")
palStroke.Color     = Theme:Border(2)
palStroke.Thickness = 1
palStroke.Parent    = palette
local palPad = Instance.new("UIPadding")
palPad.PaddingLeft   = UDim.new(0, 10)
palPad.PaddingRight  = UDim.new(0, 10)
palPad.PaddingTop    = UDim.new(0, 10)
palPad.PaddingBottom = UDim.new(0, 10)
palPad.Parent        = palette
local grid = Instance.new("Frame")
grid.BackgroundTransparency = 1
grid.Size                   = UDim2.new(1, 0, 0, 0)
grid.AutomaticSize          = Enum.AutomaticSize.Y
grid.Parent                 = palette
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.fromOffset(26, 26)
gridLayout.CellPadding = UDim2.fromOffset(5, 5)
gridLayout.Parent      = grid
local value = default
local selectedStroke = nil
local function selectColor(c, hex, swStroke)
value = c
previewBtn.BackgroundColor3 = c
if selectedStroke then
selectedStroke.Thickness = 0
end
selectedStroke = swStroke
if selectedStroke then
selectedStroke.Color     = Color3.new(1, 1, 1)
selectedStroke.Thickness = 2
end
if flag then flag:_fire(c) end
if opts.Callback then pcall(opts.Callback, c) end
end
for _, hex in ipairs(PRESETS) do
local sw = Instance.new("TextButton")
sw.BackgroundColor3 = Color.fromHex(hex)
sw.BorderSizePixel  = 0
sw.Size             = UDim2.fromOffset(26, 26)
sw.Text             = ""
sw.AutoButtonColor  = false
sw.ZIndex           = 62
sw.Parent           = grid
local swCorner = Instance.new("UICorner")
swCorner.CornerRadius = UDim.new(0, 5)
swCorner.Parent       = sw
local swStroke = Instance.new("UIStroke")
swStroke.Thickness = 0
swStroke.Parent    = sw
if Color.toHex(default):lower() == hex:lower() then
selectedStroke           = swStroke
swStroke.Color           = Color3.new(1, 1, 1)
swStroke.Thickness       = 2
end
sw.MouseButton1Click:Connect(function()
selectColor(Color.fromHex(hex), hex, swStroke)
end)
sw.MouseEnter:Connect(function()
Tween.fast(sw, { Size = UDim2.fromOffset(28, 28) })
end)
sw.MouseLeave:Connect(function()
Tween.fast(sw, { Size = UDim2.fromOffset(26, 26) })
end)
end
local open   = false
local _palSG = nil
local function closePalette()
open = false
palette.Visible = false
palette.Parent  = card
if _palSG then
pcall(function() _palSG:Destroy() end)
_palSG = nil
end
pvStroke.Color = Theme:Border(1)
end
local function openPalette()
open = true
pvStroke.Color = Theme:Accent()
local absPos  = previewBtn.AbsolutePosition
local absSize = previewBtn.AbsoluteSize
local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)
if CoreGui then
for _, v in ipairs(CoreGui:GetChildren()) do
if v.Name == "MuvaUI_ColorPicker" then
pcall(function() v:Destroy() end)
end
end
end
local sg = Instance.new("ScreenGui")
sg.Name           = "MuvaUI_ColorPicker"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder   = 9
sg.IgnoreGuiInset = false
if CoreGui then pcall(function() sg.Parent = CoreGui end) end
if not sg.Parent then
pcall(function()
sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end)
end
_palSG = sg
local blocker = Instance.new("TextButton")
blocker.BackgroundTransparency = 1
blocker.BorderSizePixel        = 0
blocker.Size                   = UDim2.new(1, 0, 1, 0)
blocker.Text                   = ""
blocker.AutoButtonColor        = false
blocker.ZIndex = 3
blocker.Parent                 = sg
blocker.MouseButton1Click:Connect(function() closePalette() end)
palette.Parent = sg
local palW    = 188
local screenW = workspace.CurrentCamera.ViewportSize.X
local posX    = absPos.X - palW - 6
if posX < 0 then posX = absPos.X + absSize.X + 6 end
if posX + palW > screenW then posX = absPos.X end
palette.Position = UDim2.fromOffset(posX, absPos.Y)
palette.Visible  = true
end
local function isCardVisible()
local p = card.Parent
while p do
local ok, visible = pcall(function() return p.Visible end)
if ok and visible == false then return false end
p = p.Parent
end
return true
end
game:GetService("RunService").Heartbeat:Connect(function()
if open and not isCardVisible() then closePalette() end
end)
previewBtn.MouseButton1Click:Connect(function()
if open then closePalette() else openPalette() end
end)
previewBtn.MouseEnter:Connect(function()
Tween.fast(previewBtn, { Size = UDim2.fromOffset(32, 32) })
pvStroke.Color = Theme:Accent()
end)
previewBtn.MouseLeave:Connect(function()
Tween.fast(previewBtn, { Size = UDim2.fromOffset(30, 30) })
if not open then pvStroke.Color = Theme:Border(1) end
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag:OnChanged(function(v)
value = v
previewBtn.BackgroundColor3 = v
end)
end
table.insert(self._components, card)
return card
end
local STYLES = {
Default = { tint = function() return Theme:Accent() end },
Ghost   = { tint = function() return Theme:Text(2)  end },
Success = { tint = function() return Theme.Colors.Success end },
Danger  = { tint = function() return Theme.Colors.Error   end },
Warn    = { tint = function() return Theme.Colors.Warn    end },
}
Section.AddButton = function(self, opts)
assert(type(opts) == "table", "AddButton: opts must be a table")
local style = STYLES[opts.Style] or STYLES.Default
local card, stroke = self:_makeCard()
local layout = Instance.new("UIListLayout")
layout.FillDirection       = Enum.FillDirection.Horizontal
layout.VerticalAlignment   = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.Padding             = UDim.new(0, 8)
layout.SortOrder           = Enum.SortOrder.LayoutOrder
layout.Parent              = card
local info = self:_makeInfoBlock(card, opts.Title or "Button", opts.Desc, 38)
info.LayoutOrder = 1
local mouseIco = Icons.new("mouse", 18, style.tint())
mouseIco.LayoutOrder = 2
mouseIco.Parent      = card
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
mouseIco.ImageColor3 = Color.lighten(style.tint(), 0.15)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
mouseIco.ImageColor3 = style.tint()
end)
Tween.bindTap(card, function()
local tint = style.tint()
mouseIco.ImageColor3 = Color.lighten(tint, 0.35)
Tween.fast(card, { BackgroundColor3 = Theme:BG(4) })
task.delay(0.12, function()
if mouseIco.Parent then mouseIco.ImageColor3 = tint end
if card.Parent then Tween.fast(card, { BackgroundColor3 = Theme:BG(2) }) end
end)
if opts.Callback then pcall(opts.Callback) end
end)
if not opts.Style or opts.Style == "Default" then
Theme:OnAccentChanged(function(accent)
mouseIco.ImageColor3 = accent
end)
end
table.insert(self._components, card)
return card
end
local BADGE_COLORS = {
Purple = { bg = Color.fromHex("#1a0a2e"), text = Color.fromHex("#A855F7"), border = Color.fromHex("#2e1050") },
Green  = { bg = Color.fromHex("#0a1a0e"), text = Color.fromHex("#22c55e"), border = Color.fromHex("#0e2e18") },
Red    = { bg = Color.fromHex("#1a0a0a"), text = Color.fromHex("#ef4444"), border = Color.fromHex("#3b1010") },
Yellow = { bg = Color.fromHex("#1a1500"), text = Color.fromHex("#eab308"), border = Color.fromHex("#2e2600") },
Blue   = { bg = Color.fromHex("#0a1220"), text = Color.fromHex("#60a5fa"), border = Color.fromHex("#0e1e38") },
}
Section.AddBadge = function(self, opts)
assert(type(opts) == "table", "AddBadge: opts must be a table")
local colors = BADGE_COLORS[opts.Color] or BADGE_COLORS.Purple
local card, stroke = self:_makeCard()
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 8)
row.Parent            = card
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -80, 1, 0)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Parent                 = card
local badge = Instance.new("Frame")
badge.BackgroundColor3 = colors.bg
badge.BorderSizePixel  = 0
badge.Size             = UDim2.fromOffset(0, 20)
badge.AutomaticSize    = Enum.AutomaticSize.X
badge.LayoutOrder      = 99
badge.Parent           = card
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 4)
badgeCorner.Parent       = badge
local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color     = colors.border
badgeStroke.Thickness = 1
badgeStroke.Parent    = badge
local badgePad = Instance.new("UIPadding")
badgePad.PaddingLeft  = UDim.new(0, 7)
badgePad.PaddingRight = UDim.new(0, 7)
badgePad.Parent       = badge
local badgeLbl = Instance.new("TextLabel")
badgeLbl.BackgroundTransparency = 1
badgeLbl.Size                   = UDim2.new(1, 0, 1, 0)
badgeLbl.Text                   = opts.Value or ""
badgeLbl.Font                   = Enum.Font.GothamBold
badgeLbl.TextSize               = 12
badgeLbl.TextColor3             = colors.text
badgeLbl.Parent                 = badge
local obj = { _badge = badge, _lbl = badgeLbl }
function obj:SetValue(v)
badgeLbl.Text = tostring(v)
end
table.insert(self._components, card)
return obj
end
Section.AddTag = function(self, opts)
assert(type(opts) == "table", "AddTag: opts must be a table")
local removable = opts.Removable ~= false
local tags      = {}
for _, v in ipairs(opts.Tags or {}) do table.insert(tags, v) end
local card, stroke = self:_makeCard()
card.Size          = UDim2.new(1, 0, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.SortOrder     = Enum.SortOrder.LayoutOrder
col.Padding       = UDim.new(0, 5)
col.Parent        = card
if opts.Title then
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
titleLbl.Text                   = opts.Title
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.LayoutOrder            = 1
titleLbl.Parent                 = card
end
local container = Instance.new("Frame")
container.BackgroundTransparency = 1
container.Size                   = UDim2.new(1, 0, 0, 0)
container.AutomaticSize          = Enum.AutomaticSize.Y
container.LayoutOrder            = 2
container.Parent                 = card
local flowLayout = Instance.new("UIListLayout")
flowLayout.FillDirection     = Enum.FillDirection.Horizontal
flowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
flowLayout.Wraps             = true
flowLayout.Padding           = UDim.new(0, 5)
flowLayout.Parent            = container
local tagObjects = {}
local function removeTag(tag, tagFrame)
for i, t in ipairs(tags) do
if t == tag then table.remove(tags, i) break end
end
Tween.fast(tagFrame, { Size = UDim2.fromOffset(0, 22) })
task.delay(0.15, function() tagFrame:Destroy() end)
if opts.Callback then pcall(opts.Callback, tags) end
end
local function buildTag(tag)
local frame = Instance.new("Frame")
frame.BackgroundColor3 = Theme:BG(4)
frame.BorderSizePixel  = 0
frame.Size             = UDim2.fromOffset(0, 22)
frame.AutomaticSize    = Enum.AutomaticSize.X
frame.Parent           = container
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 20)
fCorner.Parent       = frame
local fStroke = Instance.new("UIStroke")
fStroke.Color     = Theme:Border(1)
fStroke.Thickness = 1
fStroke.Parent    = frame
local fPad = Instance.new("UIPadding")
fPad.PaddingLeft  = UDim.new(0, 8)
fPad.PaddingRight = UDim.new(0, removable and 4 or 8)
fPad.Parent       = frame
local fRow = Instance.new("UIListLayout")
fRow.FillDirection     = Enum.FillDirection.Horizontal
fRow.VerticalAlignment = Enum.VerticalAlignment.Center
fRow.Padding           = UDim.new(0, 4)
fRow.Parent            = frame
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.fromOffset(0, 22)
lbl.AutomaticSize          = Enum.AutomaticSize.X
lbl.Text                   = tag
lbl.Font                   = Enum.Font.Gotham
lbl.TextSize               = 13
lbl.TextColor3             = Theme:Accent()
lbl.Parent                 = frame
if removable then
local xBtn = Instance.new("TextButton")
xBtn.BackgroundTransparency = 1
xBtn.BorderSizePixel        = 0
xBtn.Size                   = UDim2.fromOffset(14, 22)
xBtn.Text                   = ""
xBtn.AutoButtonColor        = false
xBtn.Parent                 = frame
local xIco = Icons.new("x", 10, Theme:Text(3))
xIco.AnchorPoint = Vector2.new(0.5, 0.5)
xIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
xIco.Parent      = xBtn
xBtn.MouseEnter:Connect(function() xIco.ImageColor3 = Theme:Text(0) end)
xBtn.MouseLeave:Connect(function() xIco.ImageColor3 = Theme:Text(3) end)
xBtn.MouseButton1Click:Connect(function() removeTag(tag, frame) end)
end
Theme:OnAccentChanged(function(accent) lbl.TextColor3 = accent end)
table.insert(tagObjects, frame)
return frame
end
for _, tag in ipairs(tags) do buildTag(tag) end
table.insert(self._components, card)
return card
end
Section.AddProgressBar = function(self, opts)
assert(type(opts) == "table", "AddProgressBar: opts must be a table")
local min     = opts.Min   or 0
local max     = opts.Max   or 100
local initial = math.clamp(opts.Value or 0, min, max)
local card, stroke = self:_makeCard()
Layout.lockHeight(card, 46)
local titleRow = Instance.new("Frame")
titleRow.BackgroundTransparency = 1
titleRow.Size                   = UDim2.new(1, 0, 0, 16)
titleRow.Parent                 = card
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -40, 1, 0)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Parent                 = titleRow
local pctLbl = Instance.new("TextLabel")
pctLbl.BackgroundTransparency = 1
pctLbl.Size                   = UDim2.fromOffset(40, 16)
pctLbl.Position               = UDim2.new(1, -40, 0, 0)
pctLbl.Font                   = Layout.FONT_BOLD
pctLbl.TextSize               = Layout.TITLE_SIZE
pctLbl.TextColor3             = Theme:Accent()
pctLbl.TextXAlignment         = Enum.TextXAlignment.Right
pctLbl.Parent                 = titleRow
local track = Instance.new("Frame")
track.BackgroundColor3 = Theme:BG(4)
track.BorderSizePixel  = 0
track.Size             = UDim2.new(1, 0, 0, 5)
track.Position         = UDim2.new(0, 0, 0, 24)
track.Parent           = card
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent       = track
local fill = Instance.new("Frame")
fill.BackgroundColor3 = Theme:Accent()
fill.BorderSizePixel  = 0
fill.Size             = UDim2.new(0, 0, 1, 0)
fill.Parent           = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent       = fill
local fillGrad = Instance.new("UIGradient")
fillGrad.Color    = ColorSequence.new(Theme:AccentDark(), Theme:Accent())
fillGrad.Rotation = 90
fillGrad.Parent   = fill
local function updateVisual(v, animated)
local pct = (v - min) / (max - min)
local pctStr = tostring(math.floor(pct * 100)) .. "%"
pctLbl.Text = pctStr
if animated then
Tween.slow(fill, { Size = UDim2.new(pct, 0, 1, 0) })
else
fill.Size = UDim2.new(pct, 0, 1, 0)
end
end
updateVisual(initial, false)
Theme:OnAccentChanged(function(accent)
fill.BackgroundColor3 = accent
pctLbl.TextColor3     = accent
fillGrad.Color        = ColorSequence.new(Theme:AccentDark(), accent)
end)
local obj = {}
function obj:SetValue(v)
local clamped = math.clamp(v, min, max)
updateVisual(clamped, true)
end
table.insert(self._components, card)
return obj
end
local BADGE_COLORS = {
Purple = Color.fromHex("#A855F7"),
Green  = Color.fromHex("#22c55e"),
Red    = Color.fromHex("#ef4444"),
Yellow = Color.fromHex("#eab308"),
Blue   = Color.fromHex("#60a5fa"),
}
local BADGE_BG = {
Purple = Color.fromHex("#1a0a2e"),
Green  = Color.fromHex("#0a1a0e"),
Red    = Color.fromHex("#1a0a0a"),
Yellow = Color.fromHex("#1a1500"),
Blue   = Color.fromHex("#0a1220"),
}
Section.AddInfoDisplay = function(self, opts)
assert(type(opts) == "table", "AddInfoDisplay: opts must be a table")
local card, stroke = self:_makeCard()
card.Size          = UDim2.new(1, 0, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIPadding") then c:Destroy() end
end
local outerPad = Instance.new("UIPadding")
outerPad.PaddingLeft   = UDim.new(0, 12)
outerPad.PaddingRight  = UDim.new(0, 12)
outerPad.PaddingTop    = UDim.new(0, 8)
outerPad.PaddingBottom = UDim.new(0, 8)
outerPad.Parent        = card
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.SortOrder     = Enum.SortOrder.LayoutOrder
col.Padding       = UDim.new(0, 0)
col.Parent        = card
if opts.Title then
local hdr = Instance.new("TextLabel")
hdr.BackgroundTransparency = 1
hdr.Size                   = UDim2.new(1, 0, 0, 20)
hdr.Text                   = opts.Title
hdr.Font                   = Layout.FONT_BOLD
hdr.TextSize               = Layout.VALUE_SIZE
hdr.TextColor3             = Theme:Accent()
hdr.TextXAlignment         = Enum.TextXAlignment.Left
hdr.LayoutOrder            = 1
hdr.Parent                 = card
Theme:OnAccentChanged(function(a) hdr.TextColor3 = a end)
end
local rowObjects = {}
local function buildRow(rowOpts, isLast, order)
local row = Instance.new("Frame")
row.BackgroundTransparency = 1
row.Size                   = UDim2.new(1, 0, 0, 24)
row.LayoutOrder            = 1 + (order or 1)
row.Parent                 = card
if not isLast then
local div = Instance.new("Frame")
div.BackgroundColor3 = Theme:Border(0)
div.BorderSizePixel  = 0
div.Size             = UDim2.new(1, 0, 0, 1)
div.Position         = UDim2.new(0, 0, 1, -1)
div.Parent           = row
end
local keyLbl = Instance.new("TextLabel")
keyLbl.BackgroundTransparency = 1
keyLbl.Size                   = UDim2.new(0.5, 0, 1, 0)
keyLbl.Position               = UDim2.new(0, 0, 0, 0)
keyLbl.Text                   = rowOpts.Key or ""
keyLbl.Font                   = Layout.FONT_BODY
keyLbl.TextSize               = Layout.VALUE_SIZE
keyLbl.TextColor3             = Theme:Text(3)
keyLbl.TextXAlignment         = Enum.TextXAlignment.Left
keyLbl.Parent                 = row
if rowOpts.Badge then
local badgeColor = BADGE_COLORS[rowOpts.Badge] or BADGE_COLORS.Purple
local badgeBg    = BADGE_BG[rowOpts.Badge]    or BADGE_BG.Purple
local badgeFrame = Instance.new("Frame")
badgeFrame.BackgroundColor3 = badgeBg
badgeFrame.BorderSizePixel  = 0
badgeFrame.Size             = UDim2.fromOffset(0, 18)
badgeFrame.AutomaticSize    = Enum.AutomaticSize.X
badgeFrame.Position         = UDim2.new(1, 0, 0.5, -9)
badgeFrame.AnchorPoint      = Vector2.new(1, 0)
badgeFrame.Parent           = row
local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 4)
bCorner.Parent       = badgeFrame
local bPad = Instance.new("UIPadding")
bPad.PaddingLeft  = UDim.new(0, 6)
bPad.PaddingRight = UDim.new(0, 6)
bPad.Parent       = badgeFrame
local bLbl = Instance.new("TextLabel")
bLbl.BackgroundTransparency = 1
bLbl.Size                   = UDim2.new(1, 0, 1, 0)
bLbl.Text                   = rowOpts.Value or ""
bLbl.Font                   = Enum.Font.GothamBold
bLbl.TextSize               = 12
bLbl.TextColor3             = badgeColor
bLbl.Parent                 = badgeFrame
rowObjects[rowOpts.Key] = { frame = badgeFrame, lbl = bLbl }
else
local valLbl = Instance.new("TextLabel")
valLbl.BackgroundTransparency = 1
valLbl.Size                   = UDim2.new(0.5, 0, 1, 0)
valLbl.Position               = UDim2.new(0.5, 0, 0, 0)
valLbl.Text                   = tostring(rowOpts.Value or "")
valLbl.Font                   = Layout.FONT_BODY
valLbl.TextSize               = Layout.VALUE_SIZE
valLbl.TextColor3             = Theme:Text(2)
valLbl.TextXAlignment         = Enum.TextXAlignment.Right
valLbl.TextTruncate           = Enum.TextTruncate.AtEnd
valLbl.Parent                 = row
rowObjects[rowOpts.Key] = { lbl = valLbl }
end
return row
end
local rows = opts.Rows or {}
for i, rowOpts in ipairs(rows) do
buildRow(rowOpts, i == #rows, i)
end
local obj = {}
function obj:SetRow(key, value)
local r = rowObjects[key]
if r and r.lbl then r.lbl.Text = tostring(value) end
end
table.insert(self._components, card)
return obj
end
Section.AddParagraph = function(self, opts)
assert(type(opts) == "table", "AddParagraph: opts must be a table")
local card, stroke = self:_makeCard()
card.Size          = UDim2.new(1, 0, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.Padding       = UDim.new(0, 4)
col.Parent        = card
if opts.Title then
local hdr = Instance.new("TextLabel")
hdr.BackgroundTransparency = 1
hdr.Size                   = UDim2.new(1, 0, 0, 0)
hdr.AutomaticSize          = Enum.AutomaticSize.Y
hdr.Text                   = opts.Title
hdr.Font                   = Layout.FONT_BOLD
hdr.TextSize               = 17
hdr.TextColor3             = Theme:Text(0)
hdr.TextXAlignment         = Enum.TextXAlignment.Left
hdr.TextWrapped            = true
hdr.Parent                 = card
end
local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Size                   = UDim2.new(1, 0, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.Y
body.Text                   = opts.Body or ""
body.Font                   = Layout.FONT_BODY
body.TextSize               = 14
body.TextColor3             = Theme:Text(2)
body.TextXAlignment         = Enum.TextXAlignment.Left
body.TextYAlignment         = Enum.TextYAlignment.Top
body.TextWrapped            = true
body.RichText               = false
body.LineHeight             = 1.4
body.Parent                 = card
table.insert(self._components, card)
return card
end
Section.AddCodeBlock = function(self, opts)
assert(type(opts) == "table", "AddCodeBlock: opts must be a table")
local card, stroke = self:_makeCard()
card.Size             = UDim2.new(1, 0, 0, 0)
card.AutomaticSize    = Enum.AutomaticSize.Y
card.BackgroundColor3 = Theme:BG(0)
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.Padding       = UDim.new(0, 0)
col.Parent        = card
local header = Instance.new("Frame")
header.BackgroundColor3 = Theme:BG(1)
header.BorderSizePixel  = 0
header.Size             = UDim2.new(1, 0, 0, 26)
header.Parent           = card
local headerDiv = Instance.new("Frame")
headerDiv.BackgroundColor3 = Theme:Border(0)
headerDiv.BorderSizePixel  = 0
headerDiv.Size             = UDim2.new(1, 0, 0, 1)
headerDiv.Position         = UDim2.new(0, 0, 1, -1)
headerDiv.Parent           = header
local langLbl = Instance.new("TextLabel")
langLbl.BackgroundTransparency = 1
langLbl.Size                   = UDim2.new(1, -60, 1, 0)
langLbl.Position               = UDim2.new(0, 10, 0, 0)
langLbl.Text                   = (opts.Language or "lua"):upper()
langLbl.Font                   = Enum.Font.GothamBold
langLbl.TextSize               = 12
langLbl.TextColor3             = Theme:Text(3)
langLbl.TextXAlignment         = Enum.TextXAlignment.Left
langLbl.Parent                 = header
local copyBtn = Instance.new("TextButton")
copyBtn.BackgroundColor3 = Theme:BG(3)
copyBtn.BorderSizePixel  = 0
copyBtn.Size             = UDim2.fromOffset(50, 18)
copyBtn.Position         = UDim2.new(1, -58, 0.5, -9)
copyBtn.Text             = "Copy"
copyBtn.Font             = Enum.Font.Gotham
copyBtn.TextSize         = 9
copyBtn.TextColor3       = Theme:Text(2)
copyBtn.AutoButtonColor  = false
copyBtn.Parent           = header
local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 4)
copyCorner.Parent       = copyBtn
local code = Instance.new("TextLabel")
code.BackgroundTransparency = 1
code.Size                   = UDim2.new(1, 0, 0, 0)
code.AutomaticSize          = Enum.AutomaticSize.Y
code.Text                   = opts.Code or ""
code.Font                   = Enum.Font.Code
code.TextSize               = Layout.CODE_SIZE
code.TextColor3             = Color.fromHex("#a8c4a2")
code.TextXAlignment         = Enum.TextXAlignment.Left
code.TextYAlignment         = Enum.TextYAlignment.Top
code.TextWrapped            = true
code.RichText               = false
code.Parent                 = card
local codePad = Instance.new("UIPadding")
codePad.PaddingLeft   = UDim.new(0, 12)
codePad.PaddingRight  = UDim.new(0, 12)
codePad.PaddingTop    = UDim.new(0, 8)
codePad.PaddingBottom = UDim.new(0, 8)
codePad.Parent        = code
if opts.Copyable ~= false then
copyBtn.MouseButton1Click:Connect(function()
pcall(function()
setclipboard(opts.Code or "")
end)
copyBtn.Text       = "Copied!"
copyBtn.TextColor3 = Theme:Accent()
task.delay(1.5, function()
copyBtn.Text       = "Copy"
copyBtn.TextColor3 = Theme:Text(2)
end)
end)
end
copyBtn.MouseEnter:Connect(function()
Tween.fast(copyBtn, { BackgroundColor3 = Theme:BG(4) })
copyBtn.TextColor3 = Theme:Text(0)
end)
copyBtn.MouseLeave:Connect(function()
Tween.fast(copyBtn, { BackgroundColor3 = Theme:BG(3) })
copyBtn.TextColor3 = Theme:Text(2)
end)
table.insert(self._components, card)
return card
end
Section.AddDivider = function(self, opts)
opts = opts or {}
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, opts.Label and 16 or 8)
frame.LayoutOrder            = #self._components + 10
frame.Parent                 = self._frame
if opts.Label then
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 6)
row.Parent            = frame
local lineL = Instance.new("Frame")
lineL.BackgroundColor3 = Theme:Border(0)
lineL.BorderSizePixel  = 0
lineL.Size             = UDim2.new(0.15, 0, 0, 1)
lineL.Parent           = frame
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(0, 0, 1, 0)
lbl.AutomaticSize          = Enum.AutomaticSize.X
lbl.Text                   = opts.Label:upper()
lbl.Font                   = Enum.Font.GothamBold
lbl.TextSize               = 12
lbl.TextColor3             = Theme:Text(4)
lbl.Parent                 = frame
local lineR = Instance.new("Frame")
lineR.BackgroundColor3 = Theme:Border(0)
lineR.BorderSizePixel  = 0
lineR.Size             = UDim2.new(1, 0, 0, 1)
lineR.Parent           = frame
else
local line = Instance.new("Frame")
line.BackgroundColor3 = Theme:Border(0)
line.BorderSizePixel  = 0
line.Size             = UDim2.new(1, 0, 0, 1)
line.Position         = UDim2.new(0, 0, 0.5, 0)
line.Parent           = frame
end
table.insert(self._components, frame)
return frame
end
local Players = game:GetService("Players")
local SIZE_MAP = { Small = 26, sm = 26, Medium = 36, md = 36, Large = 48, lg = 48 }
local TEXT_MAP = { Small = 10, sm = 10, Medium = 13, md = 13, Large = 18, lg = 18 }
Section.AddAvatar = function(self, opts)
assert(type(opts) == "table", "AddAvatar: opts must be a table")
local sz   = SIZE_MAP[opts.Size] or SIZE_MAP.Medium
local txsz = TEXT_MAP[opts.Size] or TEXT_MAP.Medium
local card, stroke = self:_makeCard()
card.Size = UDim2.new(1, 0, 0, math.max(50, sz + 20))
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 10)
row.Parent            = card
local circle = Instance.new("Frame")
circle.BackgroundColor3 = Theme:Accent()
circle.BorderSizePixel  = 0
circle.Size             = UDim2.fromOffset(sz, sz)
circle.Parent           = card
local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent       = circle
local circleStroke = Instance.new("UIStroke")
circleStroke.Color     = Theme:Accent()
circleStroke.Thickness = 2
circleStroke.Parent    = circle
local initials = Instance.new("TextLabel")
initials.BackgroundTransparency = 1
initials.Size                   = UDim2.new(1, 0, 1, 0)
initials.Font                   = Enum.Font.GothamBold
initials.TextSize               = txsz
initials.TextColor3             = Color3.new(1, 1, 1)
initials.ZIndex                 = 2
initials.Parent                 = circle
local img = Instance.new("ImageLabel")
img.BackgroundTransparency = 1
img.Size                   = UDim2.new(1, 0, 1, 0)
img.Image                  = ""
img.ScaleType              = Enum.ScaleType.Crop
img.ZIndex                 = 3
img.Visible                = false
img.Parent                 = circle
local imgCorner = Instance.new("UICorner")
imgCorner.CornerRadius = UDim.new(1, 0)
imgCorner.Parent       = img
if opts.UserId then
local initial = "?"
pcall(function()
local name = Players:GetNameFromUserIdAsync(opts.UserId)
initial = name:sub(1, 1):upper()
end)
initials.Text = initial
task.spawn(function()
local ok, thumb = pcall(function()
return Players:GetUserThumbnailAsync(
opts.UserId,
Enum.ThumbnailType.HeadShot,
Enum.ThumbnailSize.Size100x100
)
end)
if ok and thumb then
img.Image   = thumb
img.Visible = true
end
end)
else
initials.Text = opts.Label and opts.Label:sub(1,1):upper() or "?"
end
if opts.Label then
local info = Instance.new("Frame")
info.BackgroundTransparency = 1
info.Size                   = UDim2.new(1, -(sz + 10), 1, 0)
info.Parent                 = card
local infoL = Instance.new("UIListLayout")
infoL.FillDirection     = Enum.FillDirection.Vertical
infoL.VerticalAlignment = Enum.VerticalAlignment.Center
infoL.Padding           = UDim.new(0, 2)
infoL.Parent            = info
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
lbl.Text                   = opts.Label
lbl.Font                   = Layout.FONT_TITLE
lbl.TextSize               = Layout.TITLE_SIZE
lbl.TextColor3             = Theme:Text(1)
lbl.TextXAlignment         = Enum.TextXAlignment.Left
lbl.Parent                 = info
end
Theme:OnAccentChanged(function(accent)
circle.BackgroundColor3 = accent
circleStroke.Color      = accent
end)
table.insert(self._components, card)
return card
end
Section.AddTable = function(self, opts)
assert(type(opts) == "table", "AddTable: opts must be a table")
local columns    = opts.Columns   or {}
local pageSize   = opts.PageSize  or 20
local searchable = opts.Searchable ~= false
local card, stroke = self:_makeCard()
card.Size             = UDim2.new(1, 0, 0, 0)
card.AutomaticSize    = Enum.AutomaticSize.Y
card.BackgroundColor3 = Theme:BG(0)
card.ClipsDescendants = false
for _, c in ipairs(card:GetChildren()) do
if c:IsA("UIPadding") then c:Destroy() end
end
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.SortOrder     = Enum.SortOrder.LayoutOrder
col.Parent        = card
local toolbar = Instance.new("Frame")
toolbar.BackgroundColor3 = Theme:BG(1)
toolbar.BorderSizePixel  = 0
toolbar.Size             = UDim2.new(1, 0, 0, 34)
toolbar.LayoutOrder      = 1
toolbar.Parent           = card
local tbDiv = Instance.new("Frame")
tbDiv.BackgroundColor3 = Theme:Border(0)
tbDiv.BorderSizePixel  = 0
tbDiv.Size             = UDim2.new(1, 0, 0, 1)
tbDiv.Position         = UDim2.new(0, 0, 1, -1)
tbDiv.Parent           = toolbar
local tbPad = Instance.new("UIPadding")
tbPad.PaddingLeft   = UDim.new(0, 10)
tbPad.PaddingRight  = UDim.new(0, 10)
tbPad.PaddingTop    = UDim.new(0, 6)
tbPad.PaddingBottom = UDim.new(0, 6)
tbPad.Parent        = toolbar
local searchBox = nil
if searchable then
searchBox = Instance.new("TextBox")
searchBox.BackgroundColor3  = Theme:BG(2)
searchBox.BorderSizePixel   = 0
searchBox.Size              = UDim2.new(0.6, 0, 1, 0)
searchBox.PlaceholderText   = "Search..."
searchBox.PlaceholderColor3 = Theme:Text(4)
searchBox.Text              = ""
searchBox.Font              = Enum.Font.Gotham
searchBox.TextSize          = 11
searchBox.TextColor3        = Theme:Text(0)
searchBox.ClearTextOnFocus  = false
searchBox.Parent            = toolbar
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 5)
sCorner.Parent       = searchBox
local sStroke = Instance.new("UIStroke")
sStroke.Color     = Theme:Border(1)
sStroke.Thickness = 1
sStroke.Parent    = searchBox
local sPad = Instance.new("UIPadding")
sPad.PaddingLeft  = UDim.new(0, 8)
sPad.PaddingRight = UDim.new(0, 8)
sPad.Parent       = searchBox
searchBox.Focused:Connect(function() sStroke.Color = Theme:Accent() end)
searchBox.FocusLost:Connect(function() sStroke.Color = Theme:Border(1) end)
end
local countLbl = Instance.new("TextLabel")
countLbl.BackgroundTransparency = 1
countLbl.Size                   = UDim2.new(searchable and 0.4 or 1, 0, 1, 0)
countLbl.Position               = UDim2.new(searchable and 0.6 or 0, 0, 0, 0)
countLbl.Text                   = "0 rows"
countLbl.Font                   = Enum.Font.Gotham
countLbl.TextSize               = 13
countLbl.TextColor3             = Theme:Text(3)
countLbl.TextXAlignment         = Enum.TextXAlignment.Right
countLbl.Parent                 = toolbar
local header = Instance.new("Frame")
header.BackgroundColor3 = Theme:BG(1)
header.BorderSizePixel  = 0
header.Size             = UDim2.new(1, 0, 0, 28)
header.LayoutOrder      = 2
header.Parent           = card
local headerDiv = Instance.new("Frame")
headerDiv.BackgroundColor3 = Color.fromHex("#2a2a3a")
headerDiv.BorderSizePixel  = 0
headerDiv.Size             = UDim2.new(1, 0, 0, 1)
headerDiv.Position         = UDim2.new(0, 0, 1, -1)
headerDiv.Parent           = header
local headerRow = Instance.new("UIListLayout")
headerRow.FillDirection = Enum.FillDirection.Horizontal
headerRow.SortOrder     = Enum.SortOrder.LayoutOrder
headerRow.Parent        = header
local body = Instance.new("ScrollingFrame")
body.BackgroundTransparency = 1
body.BorderSizePixel        = 0
body.Size                   = UDim2.new(1, 0, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.None
body.CanvasSize             = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize    = Enum.AutomaticSize.Y
body.ScrollBarThickness     = 2
body.ScrollBarImageColor3   = Theme:BG(4)
body.LayoutOrder            = 3
body.Parent                 = card
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
bodyLayout.Parent        = body
local allRows   = opts.Rows or {}
local sortCol   = nil
local sortAsc   = true
local headerBtns = {}
local colWidth = 1 / math.max(#columns, 1)
for i, colDef in ipairs(columns) do
local cell = Instance.new("TextButton")
cell.BackgroundTransparency = 1
cell.BorderSizePixel        = 0
cell.Size                   = UDim2.new(colWidth, 0, 1, 0)
cell.LayoutOrder            = i
cell.Text                   = ""
cell.AutoButtonColor        = false
cell.Parent                 = header
local pad = Instance.new("UIPadding")
pad.PaddingLeft  = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 4)
pad.Parent       = cell
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(1, -12, 1, 0)
lbl.Text                   = (colDef.Label or colDef.Key):upper()
lbl.Font                   = Enum.Font.GothamBold
lbl.TextSize               = 12
lbl.TextColor3             = Theme:Accent()
lbl.TextXAlignment         = Enum.TextXAlignment.Left
lbl.Parent                 = cell
local arrow = Instance.new("TextLabel")
arrow.BackgroundTransparency = 1
arrow.Size                   = UDim2.fromOffset(10, 28)
arrow.Position               = UDim2.new(1, -10, 0, 0)
arrow.Text                   = ""
arrow.Font                   = Enum.Font.GothamBold
arrow.TextSize               = 8
arrow.TextColor3             = Theme:Accent()
arrow.Parent                 = cell
headerBtns[i] = { cell = cell, arrow = arrow, key = colDef.Key }
if colDef.Sortable ~= false then
cell.MouseButton1Click:Connect(function()
if sortCol == i then
sortAsc = not sortAsc
else
sortCol = i
sortAsc = true
end
for j, h in ipairs(headerBtns) do
h.arrow.Text = j == sortCol and (sortAsc and "^" or "v") or ""
end
renderRows()
end)
cell.MouseEnter:Connect(function()
lbl.TextColor3 = Theme:Text(0)
end)
cell.MouseLeave:Connect(function()
lbl.TextColor3 = Theme:Accent()
end)
end
Theme:OnAccentChanged(function(a) lbl.TextColor3 = a end)
end
local function makeRowFrame(rowData, rowIndex)
local rowFrame = Instance.new("Frame")
rowFrame.BackgroundColor3 = rowIndex % 2 == 0 and Theme:BG(0) or Theme:BG(1)
rowFrame.BorderSizePixel  = 0
rowFrame.Size             = UDim2.new(1, 0, 0, 28)
rowFrame.LayoutOrder      = rowIndex
local rowDiv = Instance.new("Frame")
rowDiv.BackgroundColor3 = Theme:Border(0)
rowDiv.BorderSizePixel  = 0
rowDiv.Size             = UDim2.new(1, 0, 0, 1)
rowDiv.Position         = UDim2.new(0, 0, 1, -1)
rowDiv.Parent           = rowFrame
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.SortOrder     = Enum.SortOrder.LayoutOrder
rowLayout.Parent        = rowFrame
rowFrame.Active = true
rowFrame.MouseEnter:Connect(function()
Tween.fast(rowFrame, { BackgroundColor3 = Theme:BG(3) })
end)
rowFrame.MouseLeave:Connect(function()
rowFrame.BackgroundColor3 = rowIndex % 2 == 0 and Theme:BG(0) or Theme:BG(1)
end)
for i, colDef in ipairs(columns) do
local cell = Instance.new("TextLabel")
cell.BackgroundTransparency = 1
cell.BorderSizePixel        = 0
cell.Size                   = UDim2.new(colWidth, 0, 1, 0)
cell.LayoutOrder            = i
cell.Font                   = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
cell.TextSize               = 13
cell.TextColor3             = i == 1 and Theme:Text(0) or Theme:Text(2)
cell.TextXAlignment         = Enum.TextXAlignment.Left
cell.TextWrapped            = false
cell.ClipsDescendants       = true
cell.Parent                 = rowFrame
local pad = Instance.new("UIPadding")
pad.PaddingLeft  = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 4)
pad.Parent       = cell
local v = rowData[colDef.Key]
cell.Text = tostring(v ~= nil and v or "")
end
return rowFrame
end
function renderRows()
for _, child in ipairs(body:GetChildren()) do
if child:IsA("Frame") then child:Destroy() end
end
local query   = searchBox and searchBox.Text:lower() or ""
local filtered = {}
for _, row in ipairs(allRows) do
if query == "" then
table.insert(filtered, row)
else
for _, v in pairs(row) do
if tostring(v):lower():find(query, 1, true) then
table.insert(filtered, row)
break
end
end
end
end
if sortCol then
local key = columns[sortCol] and columns[sortCol].Key
if key then
table.sort(filtered, function(a, b)
local av, bv = tostring(a[key] or ""), tostring(b[key] or "")
local an, bn = tonumber(av), tonumber(bv)
if an and bn then
return sortAsc and an < bn or an > bn
end
return sortAsc and av < bv or av > bv
end)
end
end
local visible = math.min(#filtered, pageSize)
for i = 1, visible do
local f = makeRowFrame(filtered[i], i)
f.Parent = body
end
local rowH     = 28
local maxShow  = math.min(visible, 8)
body.Size      = UDim2.new(1, 0, 0, maxShow * rowH)
if #filtered == #allRows then
countLbl.Text = #allRows .. " row" .. (#allRows ~= 1 and "s" or "")
else
countLbl.Text = visible .. " / " .. #allRows
end
end
if searchBox then
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
renderRows()
end)
end
renderRows()
local obj = {}
function obj:SetRows(rows)
allRows = rows or {}
renderRows()
end
function obj:AppendRow(row)
table.insert(allRows, row)
renderRows()
end
function obj:Clear()
allRows = {}
renderRows()
end
table.insert(self._components, card)
return obj
end
Section.AddSeparator = function(self, opts)
opts = opts or {}
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, 18)
frame.LayoutOrder            = #self._components + 10
frame.Parent                 = self._frame
if opts.Label then
local bar = Instance.new("Frame")
bar.BackgroundColor3 = Theme:Accent()
bar.BorderSizePixel  = 0
bar.Size             = UDim2.fromOffset(3, 12)
bar.Position         = UDim2.new(0, 0, 0.5, -6)
bar.Parent           = frame
local barC = Instance.new("UICorner")
barC.CornerRadius = UDim.new(0, 2)
barC.Parent       = bar
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size                   = UDim2.new(0, 0, 1, 0)
lbl.AutomaticSize          = Enum.AutomaticSize.X
lbl.Position               = UDim2.new(0, 8, 0, 0)
lbl.Text                   = opts.Label:upper()
lbl.Font                   = Enum.Font.GothamBold
lbl.TextSize               = 12
lbl.TextColor3             = Theme:Text(3)
lbl.Parent                 = frame
local line = Instance.new("Frame")
line.BackgroundColor3 = Theme:Border(0)
line.BorderSizePixel  = 0
line.Size             = UDim2.new(1, -16, 0, 1)
line.Position         = UDim2.new(0, 16, 0.5, 0)
line.Parent           = frame
lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
line.Size     = UDim2.new(1, -(lbl.AbsoluteSize.X + 14), 0, 1)
line.Position = UDim2.new(0, lbl.AbsoluteSize.X + 14, 0.5, 0)
end)
Theme:OnAccentChanged(function(accent) bar.BackgroundColor3 = accent end)
else
local line = Instance.new("Frame")
line.BackgroundColor3 = Theme:Border(0)
line.BorderSizePixel  = 0
line.Size             = UDim2.new(1, 0, 0, 1)
line.Position         = UDim2.new(0, 0, 0.5, 0)
line.Parent           = frame
end
table.insert(self._components, frame)
return frame
end
Section.AddHStack = function(self, opts)
opts = opts or {}
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, 0)
frame.AutomaticSize          = Enum.AutomaticSize.Y
frame.LayoutOrder            = #self._components + 10
frame.Parent                 = self._frame
local layout = Instance.new("UIListLayout")
layout.FillDirection        = Enum.FillDirection.Horizontal
layout.VerticalAlignment    = Enum.VerticalAlignment.Center
layout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
layout.Wraps                = opts.Wrap ~= false
layout.Padding              = UDim.new(0, opts.Gap or 6)
layout.Parent               = frame
local stack = setmetatable({}, { __index = self })
stack._frame      = frame
stack._components = {}
stack._flags      = self._flags
table.insert(self._components, frame)
return stack
end
Section.AddVStack = function(self, opts)
opts = opts or {}
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, 0)
frame.AutomaticSize          = Enum.AutomaticSize.Y
frame.LayoutOrder            = #self._components + 10
frame.Parent                 = self._frame
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder     = Enum.SortOrder.LayoutOrder
layout.Padding       = UDim.new(0, opts.Gap or 4)
layout.Parent        = frame
local stack = setmetatable({}, { __index = self })
stack._frame      = frame
stack._components = {}
stack._flags      = self._flags
table.insert(self._components, frame)
return stack
end
Section.AddSpace = function(self, height)
height = height or 8
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, height)
frame.LayoutOrder            = #self._components + 10
frame.Parent                 = self._frame
table.insert(self._components, frame)
return frame
end
Section.AddAccordion = function(self, opts)
assert(type(opts) == "table", "AddAccordion: opts must be a table")
local open = opts.Open ~= false and opts.Open or false
local frame = Instance.new("Frame")
frame.BackgroundColor3 = Theme:BG(2)
frame.BorderSizePixel  = 0
frame.Size             = UDim2.new(1, 0, 0, 0)
frame.AutomaticSize    = Enum.AutomaticSize.Y
frame.ClipsDescendants = false
frame.LayoutOrder      = #self._components + 10
frame.Parent           = self._frame
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 7)
frameCorner.Parent       = frame
local frameStroke = Instance.new("UIStroke")
frameStroke.Color     = Theme:Border(0)
frameStroke.Thickness = 1
frameStroke.Parent    = frame
local outerLayout = Instance.new("UIListLayout")
outerLayout.FillDirection = Enum.FillDirection.Vertical
outerLayout.SortOrder     = Enum.SortOrder.LayoutOrder
outerLayout.Parent        = frame
local header = Instance.new("TextButton")
header.BackgroundColor3 = Theme:BG(1)
header.BorderSizePixel  = 0
header.Size             = UDim2.new(1, 0, 0, 34)
header.Text             = ""
header.AutoButtonColor  = false
header.LayoutOrder      = 1
header.Parent           = frame
local headerPad = Instance.new("UIPadding")
headerPad.PaddingLeft  = UDim.new(0, 11)
headerPad.PaddingRight = UDim.new(0, 11)
headerPad.Parent       = header
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -20, 1, 0)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Enum.Font.GothamMedium
titleLbl.TextSize               = 14
titleLbl.TextColor3             = open and Theme:Accent() or Theme:Text(2)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Parent                 = header
local arrowLbl = Instance.new("TextLabel")
arrowLbl.BackgroundTransparency = 1
arrowLbl.Size                   = UDim2.fromOffset(16, 34)
arrowLbl.Position               = UDim2.new(1, -16, 0, 0)
arrowLbl.Text                   = "v"
arrowLbl.Font                   = Enum.Font.GothamBold
arrowLbl.TextSize               = 12
arrowLbl.TextColor3             = open and Theme:Accent() or Theme:Text(3)
arrowLbl.Rotation               = open and 180 or 0
arrowLbl.Parent                 = header
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Size                   = UDim2.new(1, 0, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.Y
body.Visible                = open
body.LayoutOrder            = 2
body.Parent                 = frame
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
bodyLayout.Padding       = UDim.new(0, 4)
bodyLayout.Parent        = body
local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft   = UDim.new(0, 8)
bodyPad.PaddingRight  = UDim.new(0, 8)
bodyPad.PaddingTop    = UDim.new(0, 6)
bodyPad.PaddingBottom = UDim.new(0, 8)
bodyPad.Parent        = body
header.MouseButton1Click:Connect(function()
open = not open
body.Visible = open
Tween.fast(arrowLbl, { Rotation = open and 180 or 0 })
titleLbl.TextColor3 = open and Theme:Accent() or Theme:Text(2)
arrowLbl.TextColor3 = open and Theme:Accent() or Theme:Text(3)
frameStroke.Color   = open and Theme:Border(1) or Theme:Border(0)
end)
header.MouseEnter:Connect(function()
Tween.fast(header, { BackgroundColor3 = Theme:BG(3) })
end)
header.MouseLeave:Connect(function()
Tween.fast(header, { BackgroundColor3 = Theme:BG(1) })
end)
Theme:OnAccentChanged(function(accent)
if open then
titleLbl.TextColor3 = accent
arrowLbl.TextColor3 = accent
end
end)
local acc = setmetatable({}, { __index = self })
acc._frame      = body
acc._components = {}
acc._flags      = self._flags
table.insert(self._components, frame)
return acc
end
Dialog = {}
function Dialog.show(opts, screenGui)
opts = opts or {}
local overlay = Instance.new("Frame")
overlay.BackgroundColor3       = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel        = 0
overlay.Size                   = UDim2.new(1, 0, 1, 0)
overlay.ZIndex = 1
overlay.Parent                 = screenGui
local modal = Instance.new("Frame")
modal.BackgroundColor3 = Theme:BG(2)
modal.BorderSizePixel  = 0
modal.Size             = UDim2.fromOffset(340, 0)
modal.AutomaticSize    = Enum.AutomaticSize.Y
modal.Position         = UDim2.new(0.5, -170, 0.5, 0)
modal.AnchorPoint      = Vector2.new(0, 0.5)
modal.ZIndex = 1
modal.Parent           = screenGui
local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 12)
modalCorner.Parent       = modal
local modalStroke = Instance.new("UIStroke")
modalStroke.Color     = Theme:Border(2)
modalStroke.Thickness = 1
modalStroke.Parent    = modal
local modalLayout = Instance.new("UIListLayout")
modalLayout.FillDirection = Enum.FillDirection.Vertical
modalLayout.SortOrder     = Enum.SortOrder.LayoutOrder
modalLayout.Padding       = UDim.new(0, 0)
modalLayout.Parent        = modal
local bodySection = Instance.new("Frame")
bodySection.BackgroundTransparency = 1
bodySection.Size                   = UDim2.new(1, 0, 0, 0)
bodySection.AutomaticSize          = Enum.AutomaticSize.Y
bodySection.LayoutOrder            = 1
bodySection.ZIndex = 1
bodySection.Parent                 = modal
local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft   = UDim.new(0, 20)
bodyPad.PaddingRight  = UDim.new(0, 20)
bodyPad.PaddingTop    = UDim.new(0, 20)
bodyPad.PaddingBottom = UDim.new(0, 16)
bodyPad.Parent        = bodySection
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
bodyLayout.Padding       = UDim.new(0, 8)
bodyLayout.Parent        = bodySection
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, 20)
titleLbl.Text                   = opts.Title or "Confirm"
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 16
titleLbl.TextColor3             = Theme:Text(0)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.LayoutOrder            = 1
titleLbl.ZIndex = 1
titleLbl.Parent                 = bodySection
local bodyLbl = Instance.new("TextLabel")
bodyLbl.BackgroundTransparency = 1
bodyLbl.Size                   = UDim2.new(1, 0, 0, 0)
bodyLbl.AutomaticSize          = Enum.AutomaticSize.Y
bodyLbl.Text                   = opts.Body or ""
bodyLbl.Font                   = Enum.Font.Gotham
bodyLbl.TextSize               = 13
bodyLbl.TextColor3             = Theme:Text(3)
bodyLbl.TextXAlignment         = Enum.TextXAlignment.Left
bodyLbl.TextWrapped            = true
bodyLbl.LineHeight             = 1.4
bodyLbl.LayoutOrder            = 2
bodyLbl.ZIndex = 1
bodyLbl.Parent                 = bodySection
local div = Instance.new("Frame")
div.BackgroundColor3 = Theme:Border(1)
div.BorderSizePixel  = 0
div.Size             = UDim2.new(1, 0, 0, 1)
div.LayoutOrder      = 2
div.ZIndex = 1
div.Parent           = modal
local btnSection = Instance.new("Frame")
btnSection.BackgroundTransparency = 1
btnSection.Size                   = UDim2.new(1, 0, 0, 56)
btnSection.LayoutOrder            = 3
btnSection.ZIndex = 1
btnSection.Parent                 = modal
local btnPad = Instance.new("UIPadding")
btnPad.PaddingLeft   = UDim.new(0, 16)
btnPad.PaddingRight  = UDim.new(0, 16)
btnPad.PaddingTop    = UDim.new(0, 12)
btnPad.PaddingBottom = UDim.new(0, 12)
btnPad.Parent        = btnSection
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection       = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
btnLayout.Padding             = UDim.new(0, 8)
btnLayout.Parent              = btnSection
local function closeDialog()
Tween.fast(overlay, { BackgroundTransparency = 1 })
Tween.play(modal, {
BackgroundTransparency = 1,
Position = UDim2.new(0.5, -170, 0.5, 10),
}, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.14, function()
pcall(function() overlay:Destroy() end)
pcall(function() modal:Destroy() end)
end)
end
local STYLE_COLORS = {
Default = { bg = Theme:Accent(),            text = Color3.new(1,1,1)  },
Danger  = { bg = Color.fromHex("#ef4444"),  text = Color3.new(1,1,1)  },
Success = { bg = Color.fromHex("#22c55e"),  text = Color3.new(1,1,1)  },
Ghost   = { bg = Theme:BG(4),               text = Theme:Text(2)      },
Warn    = { bg = Color.fromHex("#eab308"),  text = Color3.new(0,0,0)  },
}
local buttons = opts.Buttons or {
{ Text = "Cancel", Style = "Ghost",   Callback = nil },
{ Text = "OK",     Style = "Default", Callback = nil },
}
for _, bOpts in ipairs(buttons) do
local colors = STYLE_COLORS[bOpts.Style] or STYLE_COLORS.Ghost
local btn = Instance.new("TextButton")
btn.BackgroundColor3 = colors.bg
btn.BorderSizePixel  = 0
btn.Size             = UDim2.fromOffset(90, 32)
btn.Text             = bOpts.Text or "OK"
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 12
btn.TextColor3       = colors.text
btn.AutoButtonColor  = false
btn.ZIndex = 1
btn.Parent           = btnSection
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 7)
bc.Parent       = btn
local bs = Instance.new("UIStroke")
bs.Color     = Color.darken(colors.bg, 0.15)
bs.Thickness = 1
bs.Parent    = btn
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Color.lighten(colors.bg, 0.08) })
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundColor3 = colors.bg })
end)
btn.MouseButton1Click:Connect(function()
closeDialog()
if bOpts.Callback then pcall(bOpts.Callback) end
end)
end
overlay.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
closeDialog()
end
end)
modal.BackgroundTransparency = 1
modal.Position = UDim2.new(0.5, -170, 0.5, 16)
Tween.play(modal, {
BackgroundTransparency = 0,
Position = UDim2.new(0.5, -170, 0.5, 0),
}, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end
Popup = {}
local POPUP_STYLES = {
Default = { accent = function() return Theme:Accent() end,           icon = "info" },
Success = { accent = function() return Color.fromHex("#22c55e") end,  icon = "circle-check" },
Error   = { accent = function() return Color.fromHex("#ef4444") end,  icon = "circle-x" },
Warn    = { accent = function() return Color.fromHex("#eab308") end,  icon = "triangle-alert" },
}
function Popup.show(opts, parentWin)
opts = opts or {}
local style = POPUP_STYLES[opts.Style] or POPUP_STYLES.Default
local screenGui = parentWin
while screenGui and not screenGui:IsA("ScreenGui") do
screenGui = screenGui.Parent
end
if not screenGui then return end
local card = Instance.new("Frame")
card.BackgroundColor3       = Theme:BG(2)
card.BackgroundTransparency = 1
card.BorderSizePixel        = 0
card.Size                   = UDim2.fromOffset(300, 0)
card.AutomaticSize          = Enum.AutomaticSize.Y
card.Position               = UDim2.new(0.5, -150, 0.5, 12)
card.AnchorPoint            = Vector2.new(0, 0.5)
card.ZIndex = 1
card.Parent                 = screenGui
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 10)
cardCorner.Parent       = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = style.accent()
cardStroke.Thickness = 1
cardStroke.Parent    = card
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Vertical
cardLayout.SortOrder     = Enum.SortOrder.LayoutOrder
cardLayout.Padding       = UDim.new(0, 0)
cardLayout.Parent        = card
local bodySection = Instance.new("Frame")
bodySection.BackgroundTransparency = 1
bodySection.Size                   = UDim2.new(1, 0, 0, 0)
bodySection.AutomaticSize          = Enum.AutomaticSize.Y
bodySection.LayoutOrder            = 1
bodySection.ZIndex = 1
bodySection.Parent                 = card
local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft   = UDim.new(0, 16)
bodyPad.PaddingRight  = UDim.new(0, 16)
bodyPad.PaddingTop    = UDim.new(0, 16)
bodyPad.PaddingBottom = UDim.new(0, 12)
bodyPad.Parent        = bodySection
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
bodyLayout.Padding       = UDim.new(0, 6)
bodyLayout.Parent        = bodySection
local titleRow = Instance.new("Frame")
titleRow.BackgroundTransparency = 1
titleRow.Size                   = UDim2.new(1, 0, 0, 20)
titleRow.LayoutOrder            = 1
titleRow.ZIndex = 1
titleRow.Parent                 = bodySection
local titleLayout = Instance.new("UIListLayout")
titleLayout.FillDirection     = Enum.FillDirection.Horizontal
titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
titleLayout.Padding           = UDim.new(0, 6)
titleLayout.Parent            = titleRow
local iconImg = Icons.new(style.icon, 16, style.accent())
iconImg.ZIndex = 1
iconImg.Parent = titleRow
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -24, 1, 0)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 14
titleLbl.TextColor3             = Theme:Text(0)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.ZIndex = 1
titleLbl.Parent                 = titleRow
if opts.Body and opts.Body ~= "" then
local bodyLbl = Instance.new("TextLabel")
bodyLbl.BackgroundTransparency = 1
bodyLbl.Size                   = UDim2.new(1, 0, 0, 0)
bodyLbl.AutomaticSize          = Enum.AutomaticSize.Y
bodyLbl.Text                   = opts.Body
bodyLbl.Font                   = Enum.Font.Gotham
bodyLbl.TextSize               = 12
bodyLbl.TextColor3             = Theme:Text(3)
bodyLbl.TextXAlignment         = Enum.TextXAlignment.Left
bodyLbl.TextWrapped            = true
bodyLbl.LineHeight             = 1.35
bodyLbl.LayoutOrder            = 2
bodyLbl.ZIndex = 1
bodyLbl.Parent                 = bodySection
end
local buttons = opts.Buttons or {}
if #buttons > 0 then
local divLine = Instance.new("Frame")
divLine.BackgroundColor3 = Theme:Border(1)
divLine.BorderSizePixel  = 0
divLine.Size             = UDim2.new(1, 0, 0, 1)
divLine.LayoutOrder      = 2
divLine.ZIndex = 1
divLine.Parent           = card
local btnSection = Instance.new("Frame")
btnSection.BackgroundTransparency = 1
btnSection.Size                   = UDim2.new(1, 0, 0, 48)
btnSection.LayoutOrder            = 3
btnSection.ZIndex = 1
btnSection.Parent                 = card
local btnPad = Instance.new("UIPadding")
btnPad.PaddingLeft   = UDim.new(0, 12)
btnPad.PaddingRight  = UDim.new(0, 12)
btnPad.PaddingTop    = UDim.new(0, 10)
btnPad.PaddingBottom = UDim.new(0, 10)
btnPad.Parent        = btnSection
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection       = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
btnLayout.Padding             = UDim.new(0, 6)
btnLayout.Parent              = btnSection
local STYLE_COLORS = {
Default = { bg = Theme:Accent(),           text = Color3.new(1,1,1) },
Danger  = { bg = Color.fromHex("#ef4444"), text = Color3.new(1,1,1) },
Success = { bg = Color.fromHex("#22c55e"), text = Color3.new(1,1,1) },
Ghost   = { bg = Theme:BG(4),              text = Theme:Text(2)     },
Warn    = { bg = Color.fromHex("#eab308"), text = Color3.new(0,0,0) },
}
local function closePopup()
Tween.play(card, {
BackgroundTransparency = 1,
Position = UDim2.new(0.5, -150, 0.5, 20),
}, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.12, function()
pcall(function() card:Destroy() end)
end)
end
for _, bOpts in ipairs(buttons) do
local colors = STYLE_COLORS[bOpts.Style] or STYLE_COLORS.Ghost
local btn = Instance.new("TextButton")
btn.BackgroundColor3 = colors.bg
btn.BorderSizePixel  = 0
btn.Size             = UDim2.fromOffset(80, 28)
btn.Text             = bOpts.Text or "OK"
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 11
btn.TextColor3       = colors.text
btn.AutoButtonColor  = false
btn.ZIndex = 1
btn.Parent           = btnSection
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 6)
bc.Parent       = btn
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Color.lighten(colors.bg, 0.08) })
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundColor3 = colors.bg })
end)
btn.MouseButton1Click:Connect(function()
closePopup()
if bOpts.Callback then pcall(bOpts.Callback) end
end)
end
else
local duration = opts.Duration or 3
local function closePopup()
Tween.play(card, {
BackgroundTransparency = 1,
Position = UDim2.new(0.5, -150, 0.5, 20),
}, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.12, function()
pcall(function() card:Destroy() end)
end)
end
task.delay(duration, closePopup)
end
Tween.play(card, {
BackgroundTransparency = 0,
Position = UDim2.new(0.5, -150, 0.5, 0),
}, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end
Toast = {}
local TOAST_STYLES = {
Info    = { color = function() return Theme:Accent() end,           icon = "info" },
Success = { color = function() return Color.fromHex("#22c55e") end, icon = "circle-check" },
Error   = { color = function() return Color.fromHex("#ef4444") end, icon = "circle-x" },
Warn    = { color = function() return Color.fromHex("#eab308") end, icon = "triangle-alert" },
}
local TOAST_TYPE_ALIAS = {
info = "Info", success = "Success", ok = "Success",
error = "Error", err = "Error",
warn = "Warn", warning = "Warn",
}
local function resolveStyle(t)
local key = TOAST_TYPE_ALIAS[string.lower(tostring(t or "info"))] or "Info"
return TOAST_STYLES[key]
end
local _container  = nil
local _orderCount = 0
local function getContainer(screenGui)
if _container and _container.Parent and _container.Parent.Parent then
return _container
end
_container = nil
local sg = nil
if screenGui and screenGui.Parent then sg = screenGui end
if not sg then
local host = nil
pcall(function()
if type(gethui) == "function" then host = gethui() end
end)
if not host then
pcall(function() host = game:GetService("CoreGui") end)
end
sg = Instance.new("ScreenGui")
sg.Name           = "MuvaUI_Toasts"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder   = 1000
sg.IgnoreGuiInset = true
if host then pcall(function() sg.Parent = host end) end
if not sg.Parent then
pcall(function()
sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end)
end
end
local c = Instance.new("Frame")
c.Name                   = "ToastContainer"
c.BackgroundTransparency = 1
c.Size                   = UDim2.new(1, 0, 1, 0)
c.Position               = UDim2.new(0, 0, 0, 0)
c.ZIndex                 = 100
c.ClipsDescendants       = false
c.Parent                 = sg
local layout = Instance.new("UIListLayout")
layout.FillDirection        = Enum.FillDirection.Vertical
layout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
layout.VerticalAlignment    = Enum.VerticalAlignment.Bottom
layout.SortOrder            = Enum.SortOrder.LayoutOrder
layout.Padding              = UDim.new(0, 6)
layout.Parent               = c
local pad = Instance.new("UIPadding")
pad.PaddingBottom = UDim.new(0, 24)
pad.PaddingRight  = UDim.new(0, 16)
pad.Parent        = c
_container = c
return c
end
function Toast.show(opts, screenGui)
opts = opts or {}
local style   = resolveStyle(opts.Type)
local color   = style.color()
local hasBody = opts.Body and opts.Body ~= ""
local toastH  = hasBody and 60 or 42
local container = getContainer(screenGui)
_orderCount = _orderCount + 1
local toast = Instance.new("Frame")
toast.Name             = "Toast"
toast.BackgroundColor3 = Color.fromHex("#1c1c20")
toast.BorderSizePixel  = 0
toast.Size             = UDim2.fromOffset(280, toastH)
toast.LayoutOrder      = _orderCount
toast.ClipsDescendants = false
toast.Parent           = container
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 9)
toastCorner.Parent       = toast
local toastStroke = Instance.new("UIStroke")
toastStroke.Color     = Color.fromHex("#2a2a2e")
toastStroke.Thickness = 1
toastStroke.Parent    = toast
local bar = Instance.new("Frame")
bar.BackgroundColor3 = color
bar.BorderSizePixel  = 0
bar.Size             = UDim2.new(0, 3, 1, -12)
bar.Position         = UDim2.new(0, 0, 0, 6)
bar.ZIndex = 1
bar.Parent           = toast
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 2)
barCorner.Parent       = bar
local iconImg = Icons.new(style.icon, 16, color)
iconImg.Position = UDim2.new(0, 14, 0.5, -8)
iconImg.ZIndex   = 1
iconImg.Parent   = toast
local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundTransparency = 1
closeBtn.BorderSizePixel        = 0
closeBtn.Size                   = UDim2.fromOffset(18, 18)
closeBtn.Position               = UDim2.new(1, -22, 0, 7)
closeBtn.Text                   = ""
closeBtn.ZIndex = 1
closeBtn.AutoButtonColor        = false
closeBtn.Parent                 = toast
local closeIco = Icons.new("x", 12, Color.fromHex("#555555"))
closeIco.AnchorPoint = Vector2.new(0.5, 0.5)
closeIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
closeIco.ZIndex      = 1
closeIco.Parent      = closeBtn
closeBtn.MouseEnter:Connect(function() closeIco.ImageColor3 = Color.fromHex("#cccccc") end)
closeBtn.MouseLeave:Connect(function() closeIco.ImageColor3 = Color.fromHex("#555555") end)
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -56, 0, 16)
titleLbl.Position               = hasBody
and UDim2.new(0, 36, 0, 12)
or  UDim2.new(0, 36, 0.5, -8)
titleLbl.Text                   = opts.Title or ""
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 13
titleLbl.TextColor3             = Color.fromHex("#f0f0f0")
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.ZIndex = 1
titleLbl.Parent                 = toast
if hasBody then
local msgLbl = Instance.new("TextLabel")
msgLbl.BackgroundTransparency = 1
msgLbl.Size                   = UDim2.new(1, -56, 0, 24)
msgLbl.Position               = UDim2.new(0, 36, 0, 30)
msgLbl.Text                   = opts.Body
msgLbl.Font                   = Enum.Font.Gotham
msgLbl.TextSize               = 12
msgLbl.TextColor3             = Color.fromHex("#999999")
msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
msgLbl.TextWrapped            = true
msgLbl.ZIndex = 1
msgLbl.Parent                 = toast
end
local dismissed = false
local function dismiss()
if dismissed then return end
dismissed = true
Tween.play(toast, {
BackgroundTransparency = 1,
Size = UDim2.fromOffset(280, 0),
}, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.2, function() pcall(function() toast:Destroy() end) end)
end
closeBtn.MouseButton1Click:Connect(dismiss)
toast.BackgroundTransparency = 1
Tween.play(toast, {
BackgroundTransparency = 0,
}, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
local duration = opts.Duration or 3.5
if duration > 0 then
task.delay(duration, dismiss)
end
end
KeySystem = {}
local function readSavedKey(filename)
local ok, content = pcall(readfile, filename)
if not ok or not content or content == "" then return nil end
local ok2, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
if not ok2 or type(data) ~= "table" then return nil end
return data.key
end
local function saveKey(filename, key)
local ok, encoded = pcall(function()
return game:GetService("HttpService"):JSONEncode({ key = key })
end)
if ok then pcall(writefile, filename, encoded) end
end
function KeySystem.show(opts, screenGui, onSuccess)
opts = opts or {}
local validKeys = {}
for _, k in ipairs(opts.Keys or {}) do validKeys[k:upper()] = true end
local saveFile = opts.SaveFile or "muvaui_key.json"
local saved = readSavedKey(saveFile)
if saved and validKeys[saved:upper()] then
if opts.OnValidated then pcall(opts.OnValidated, saved:upper()) end
onSuccess()
return
end
local card = Instance.new("CanvasGroup")
card.BackgroundColor3  = Color.fromHex("#141416")
card.BorderSizePixel   = 0
card.Size              = UDim2.fromOffset(400, 0)
card.AutomaticSize     = Enum.AutomaticSize.Y
card.Position          = UDim2.new(0.5, -200, 0.5, 0)
card.AnchorPoint       = Vector2.new(0, 0.5)
card.GroupTransparency = 1
card.Parent            = screenGui
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 14)
cardCorner.Parent       = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = Theme:Border(1)
cardStroke.Thickness = 1
cardStroke.Parent    = card
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Vertical
cardLayout.SortOrder     = Enum.SortOrder.LayoutOrder
cardLayout.Parent        = card
local header = Instance.new("Frame")
header.BackgroundColor3 = Color.fromHex("#0e0e10")
header.BorderSizePixel  = 0
header.Size             = UDim2.new(1, 0, 0, 80)
header.LayoutOrder      = 1
header.Parent           = card
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent       = header
local headerFill = Instance.new("Frame")
headerFill.BackgroundColor3 = Color.fromHex("#0e0e10")
headerFill.BorderSizePixel  = 0
headerFill.Size             = UDim2.new(1, 0, 0, 14)
headerFill.Position         = UDim2.new(0, 0, 1, -14)
headerFill.Parent           = header
local headerDiv = Instance.new("Frame")
headerDiv.BackgroundColor3 = Theme:Border(1)
headerDiv.BorderSizePixel  = 0
headerDiv.Size             = UDim2.new(1, 0, 0, 1)
headerDiv.Position         = UDim2.new(0, 0, 1, -1)
headerDiv.Parent           = header
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, 32)
titleLbl.Position               = UDim2.new(0, 0, 0, 12)
titleLbl.Text                   = opts.Title or "MuvaUI"
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 24
titleLbl.TextColor3             = Theme:Text(0)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
titleLbl.Parent                 = header
local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Size                   = UDim2.new(1, 0, 0, 20)
subLbl.Position               = UDim2.new(0, 0, 0, 50)
subLbl.Text                   = "Enter your key to continue"
subLbl.Font                   = Enum.Font.Gotham
subLbl.TextSize               = 13
subLbl.TextColor3             = Theme:Text(4)
subLbl.TextXAlignment         = Enum.TextXAlignment.Center
subLbl.Parent                 = header
local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Size                   = UDim2.new(1, 0, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.Y
body.LayoutOrder            = 2
body.Parent                 = card
local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft   = UDim.new(0, 20)
bodyPad.PaddingRight  = UDim.new(0, 20)
bodyPad.PaddingTop    = UDim.new(0, 18)
bodyPad.PaddingBottom = UDim.new(0, 18)
bodyPad.Parent        = body
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.Padding       = UDim.new(0, 10)
bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
bodyLayout.Parent        = body
local keyLabel = Instance.new("TextLabel")
keyLabel.BackgroundTransparency = 1
keyLabel.Size                   = UDim2.new(1, 0, 0, 14)
keyLabel.Text                   = "LICENSE KEY"
keyLabel.Font                   = Enum.Font.GothamBold
keyLabel.TextSize               = 11
keyLabel.TextColor3             = Theme:Text(4)
keyLabel.TextXAlignment         = Enum.TextXAlignment.Left
keyLabel.LayoutOrder            = 1
keyLabel.Parent                 = body
local inputRow = Instance.new("Frame")
inputRow.BackgroundTransparency = 1
inputRow.Size                   = UDim2.new(1, 0, 0, 34)
inputRow.LayoutOrder            = 2
inputRow.Parent                 = body
local inputRowLayout = Instance.new("UIListLayout")
inputRowLayout.FillDirection     = Enum.FillDirection.Horizontal
inputRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
inputRowLayout.Padding           = UDim.new(0, 6)
inputRowLayout.Parent            = inputRow
local inputWrap = Instance.new("Frame")
inputWrap.BackgroundColor3 = Theme:BG(1)
inputWrap.BorderSizePixel  = 0
inputWrap.Size             = UDim2.new(1, -50, 1, 0)
inputWrap.ClipsDescendants = true
inputWrap.Parent           = inputRow
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 7)
inputCorner.Parent       = inputWrap
local inputStroke = Instance.new("UIStroke")
inputStroke.Color     = Theme:Border(1)
inputStroke.Thickness = 1
inputStroke.Parent    = inputWrap
local inputPad = Instance.new("UIPadding")
inputPad.PaddingLeft  = UDim.new(0, 10)
inputPad.PaddingRight = UDim.new(0, 10)
inputPad.Parent       = inputWrap
local keyInput = Instance.new("TextBox")
keyInput.BackgroundTransparency = 1
keyInput.BorderSizePixel        = 0
keyInput.Size                   = UDim2.new(1, 0, 1, 0)
keyInput.PlaceholderText        = "MUVA-XXXX-XXXX-XXXX"
keyInput.PlaceholderColor3      = Theme:Text(4)
keyInput.Text                   = ""
keyInput.Font                   = Enum.Font.Code
keyInput.TextSize               = 14
keyInput.TextColor3             = Theme:Text(0)
keyInput.ClearTextOnFocus       = false
keyInput.TextXAlignment         = Enum.TextXAlignment.Left
keyInput.Parent                 = inputWrap
local function updateOverflow()
local fits = keyInput.TextBounds.X <= (keyInput.AbsoluteSize.X - 2)
keyInput.TextXAlignment = fits and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
end
keyInput:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
keyInput:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
task.defer(updateOverflow)
keyInput.Focused:Connect(function()
Tween.fast(inputStroke, { Color = Theme:Accent() })
end)
keyInput.FocusLost:Connect(function()
Tween.fast(inputStroke, { Color = Theme:Border(1) })
end)
local submitBtn = Instance.new("TextButton")
submitBtn.BackgroundColor3 = Theme:Accent()
submitBtn.BorderSizePixel  = 0
submitBtn.Size             = UDim2.fromOffset(44, 34)
submitBtn.Text             = ""
submitBtn.AutoButtonColor  = false
submitBtn.LayoutOrder      = 99
submitBtn.Parent           = inputRow
local submitIco = Icons.new("arrow-right", 16, Color3.new(1, 1, 1))
submitIco.AnchorPoint = Vector2.new(0.5, 0.5)
submitIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
submitIco.Parent      = submitBtn
local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 7)
submitCorner.Parent       = submitBtn
local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Size                   = UDim2.new(1, 0, 0, 16)
statusLbl.Text                   = ""
statusLbl.Font                   = Enum.Font.Gotham
statusLbl.TextSize               = 13
statusLbl.TextColor3             = Color.fromHex("#ef4444")
statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
statusLbl.LayoutOrder            = 3
statusLbl.Parent                 = body
local linksRow = Instance.new("Frame")
linksRow.BackgroundTransparency = 1
linksRow.Size                   = UDim2.new(1, 0, 0, 20)
linksRow.LayoutOrder            = 4
linksRow.Parent                 = body
local linksLayout = Instance.new("UIListLayout")
linksLayout.FillDirection       = Enum.FillDirection.Horizontal
linksLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
linksLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
linksLayout.Padding             = UDim.new(0, 16)
linksLayout.Parent              = linksRow
local function makeLink(text, url)
local btn = Instance.new("TextButton")
btn.BackgroundTransparency = 1
btn.BorderSizePixel        = 0
btn.Size                   = UDim2.fromOffset(0, 16)
btn.AutomaticSize          = Enum.AutomaticSize.X
btn.Text                   = text
btn.Font                   = Enum.Font.Gotham
btn.TextSize               = 13
btn.TextColor3             = Theme:Text(4)
btn.AutoButtonColor        = false
btn.Parent                 = linksRow
btn.MouseEnter:Connect(function() btn.TextColor3 = Theme:Accent() end)
btn.MouseLeave:Connect(function() btn.TextColor3 = Theme:Text(4) end)
btn.MouseButton1Click:Connect(function()
if url and url ~= "" then
pcall(setclipboard, url)
statusLbl.TextColor3 = Color.fromHex("#22c55e")
statusLbl.Text = "Link copied to clipboard!"
task.delay(2, function()
if statusLbl.Parent then statusLbl.Text = "" end
end)
end
end)
return btn
end
makeLink("Get Key", opts.GetKeyUrl or "")
makeLink("Discord", opts.Discord   or "")
makeLink("Support", opts.Support   or "")
local function validate()
local key = keyInput.Text:match("^%s*(.-)%s*$"):upper()
if key == "" then
statusLbl.TextColor3 = Color.fromHex("#ef4444")
statusLbl.Text = "Please enter a key."
return
end
if validKeys[key] then
statusLbl.TextColor3 = Color.fromHex("#22c55e")
statusLbl.Text = "Key valid!"
saveKey(saveFile, key)
task.delay(0.6, function()
Tween.play(card, {
GroupTransparency = 1,
Position = UDim2.new(0.5, -200, 0.5, -24),
}, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.32, function()
pcall(function() card:Destroy() end)
if opts.OnValidated then pcall(opts.OnValidated, key) end
onSuccess()
end)
end)
else
statusLbl.TextColor3 = Color.fromHex("#ef4444")
statusLbl.Text = "Invalid key. Try again."
Tween.play(card, { Position = UDim2.new(0.5, -208, 0.5, 0) },
TweenInfo.new(0.05, Enum.EasingStyle.Linear))
task.delay(0.05, function()
Tween.play(card, { Position = UDim2.new(0.5, -192, 0.5, 0) },
TweenInfo.new(0.05, Enum.EasingStyle.Linear))
task.delay(0.05, function()
Tween.play(card, { Position = UDim2.new(0.5, -200, 0.5, 0) },
TweenInfo.new(0.05, Enum.EasingStyle.Linear))
end)
end)
end
end
submitBtn.MouseButton1Click:Connect(validate)
keyInput.FocusLost:Connect(function(enter) if enter then validate() end end)
submitBtn.MouseEnter:Connect(function() Tween.fast(submitBtn, { BackgroundColor3 = Theme:AccentDark() }) end)
submitBtn.MouseLeave:Connect(function() Tween.fast(submitBtn, { BackgroundColor3 = Theme:Accent() }) end)
Theme:OnAccentChanged(function(accent) submitBtn.BackgroundColor3 = accent end)
card.GroupTransparency = 1
card.Position = UDim2.new(0.5, -200, 0.5, 28)
task.defer(function()
Tween.play(card, {
GroupTransparency = 0,
Position = UDim2.new(0.5, -200, 0.5, 0),
}, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end)
end
LoadingScreen = {}
local COSMETIC_DELAY = 0.35
function LoadingScreen.show(config, screenGui, onDone)
config = config or {}
local title    = config.Title    or "MuvaUI"
local steps    = config.Steps    or { { Message = "Loading..." } }
local onResult = config.OnResult
local card = Instance.new("CanvasGroup")
card.BackgroundColor3 = Color.fromHex("#0e0e10")
card.BorderSizePixel  = 0
card.Size             = UDim2.fromOffset(310, 0)
card.AutomaticSize    = Enum.AutomaticSize.Y
card.Position         = UDim2.new(0.5, -155, 0.5, 0)
card.AnchorPoint      = Vector2.new(0, 0.5)
card.GroupTransparency = 1
card.Parent           = screenGui
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 14)
cardCorner.Parent       = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = Theme:Border(1)
cardStroke.Thickness = 1
cardStroke.Parent    = card
local cardPad = Instance.new("UIPadding")
cardPad.PaddingLeft   = UDim.new(0, 24)
cardPad.PaddingRight  = UDim.new(0, 24)
cardPad.PaddingTop    = UDim.new(0, 28)
cardPad.PaddingBottom = UDim.new(0, 28)
cardPad.Parent        = card
local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection       = Enum.FillDirection.Vertical
cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardLayout.Padding             = UDim.new(0, 12)
cardLayout.SortOrder           = Enum.SortOrder.LayoutOrder
cardLayout.Parent              = card
local spinnerFrame = Instance.new("Frame")
spinnerFrame.BackgroundTransparency = 1
spinnerFrame.Size                   = UDim2.fromOffset(38, 38)
spinnerFrame.LayoutOrder            = 1
spinnerFrame.Parent                 = card
local spinnerImg = Icons.new("loader", 28, Theme:Accent())
spinnerImg.AnchorPoint = Vector2.new(0.5, 0.5)
spinnerImg.Position    = UDim2.new(0.5, 0, 0.5, 0)
spinnerImg.Parent      = spinnerFrame
local spinTween = Tween.play(spinnerImg, { Rotation = 360 },
TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1))
Theme:OnAccentChanged(function(accent)
spinnerImg.ImageColor3 = accent
end)
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, 20)
titleLbl.Text                   = title
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 16
titleLbl.TextColor3             = Theme:Text(0)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
titleLbl.LayoutOrder            = 2
titleLbl.Parent                 = card
local progressFrame = Instance.new("Frame")
progressFrame.BackgroundTransparency = 1
progressFrame.Size                   = UDim2.new(1, 0, 0, 5)
progressFrame.LayoutOrder            = 3
progressFrame.Parent                 = card
local track = Instance.new("Frame")
track.BackgroundColor3 = Theme:BG(4)
track.BorderSizePixel  = 0
track.Size             = UDim2.new(1, 0, 1, 0)
track.Parent           = progressFrame
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent       = track
local fill = Instance.new("Frame")
fill.BackgroundColor3 = Theme:Accent()
fill.BorderSizePixel  = 0
fill.Size             = UDim2.new(0, 0, 1, 0)
fill.Parent           = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent       = fill
local fillGrad = Instance.new("UIGradient")
fillGrad.Color    = ColorSequence.new(Theme:AccentDark(), Theme:Accent())
fillGrad.Rotation = 90
fillGrad.Parent   = fill
Theme:OnAccentChanged(function(accent)
fill.BackgroundColor3 = accent
fillGrad.Color        = ColorSequence.new(Theme:AccentDark(), accent)
end)
local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Size                   = UDim2.new(1, 0, 0, 18)
statusLbl.Text                   = steps[1] and steps[1].Message or "Loading..."
statusLbl.Font                   = Enum.Font.Gotham
statusLbl.TextSize               = 13
statusLbl.TextColor3             = Theme:Text(2)
statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
statusLbl.TextTruncate           = Enum.TextTruncate.AtEnd
statusLbl.LayoutOrder            = 4
statusLbl.Parent                 = card
card.GroupTransparency = 1
card.Position = UDim2.new(0.5, -155, 0.5, 28)
task.defer(function()
Tween.play(card, {
GroupTransparency = 0,
Position = UDim2.new(0.5, -155, 0.5, 0),
}, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end)
task.spawn(function()
local totalSteps = #steps
local results    = {}
for i, step in ipairs(steps) do
statusLbl.Text       = step.Message or ("Step " .. i)
statusLbl.TextColor3 = Theme:Text(1)
local ok, value = true, nil
local errMsg    = nil
if step.Run then
ok, value = pcall(step.Run)
if not ok then
errMsg = tostring(value)
value  = nil
end
else
task.wait(COSMETIC_DELAY)
end
results[i] = { ok = ok, value = value, err = errMsg }
local pct = i / totalSteps
Tween.slow(fill, { Size = UDim2.new(pct, 0, 1, 0) })
if i < totalSteps then
task.wait(0.04)
end
end
task.wait(0.2)
if onResult then
pcall(onResult, results)
end
Tween.play(card, {
GroupTransparency = 1,
Position = UDim2.new(0.5, -155, 0.5, -24),
}, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
task.delay(0.32, function()
pcall(function() card:Destroy() end)
onDone()
end)
end)
end
ConfigSystem = {}
local HttpService = game:GetService("HttpService")
local SAVE_FILE_DEFAULT = "muvaui_configs.json"
local function loadAllConfigs(filename)
local ok, content = pcall(readfile, filename)
if not ok or not content or content == "" then return {} end
local ok2, data = pcall(function()
return HttpService:JSONDecode(content)
end)
if not ok2 or type(data) ~= "table" then return {} end
return data
end
local function saveAllConfigs(filename, configs)
local ok, encoded = pcall(function()
return HttpService:JSONEncode(configs)
end)
if ok then
pcall(writefile, filename, encoded)
end
end
local function getTimestamp()
return os.date and os.date("%Y-%m-%d %H:%M") or "just now"
end
function ConfigSystem.attach(win, config, flags)
config = config or {}
local saveFile = config.File or SAVE_FILE_DEFAULT
local maxSlots = config.Slots or 5
local tab = win:AddTab({ Title = "Config" })
local sec = tab:AddSection({ Title = "Saved Configurations" })
local configsData = loadAllConfigs(saveFile)
local slotCards   = {}
local function getCurrentFlagValues()
local snapshot = {}
for id, flag in pairs(flags) do
local val = flag.Value
local t = type(val)
if t == "boolean" or t == "number" or t == "string" then
snapshot[id] = val
end
end
return snapshot
end
local function applyFlagValues(snapshot)
if type(snapshot) ~= "table" then return end
for id, val in pairs(snapshot) do
local flag = flags[id]
if flag then
flag:SetAndFire(val)
end
end
end
local function refreshSlots()
for _, card in ipairs(slotCards) do
pcall(function() card:Destroy() end)
end
slotCards = {}
for i, slot in ipairs(configsData) do
local card, stroke = sec:_makeCard()
table.insert(slotCards, card)
local row = Instance.new("UIListLayout")
row.FillDirection     = Enum.FillDirection.Horizontal
row.VerticalAlignment = Enum.VerticalAlignment.Center
row.Padding           = UDim.new(0, 8)
row.Parent            = card
local iconImg = Icons.new("file-text", 18, Theme:Text(2))
iconImg.Parent = card
local info = Instance.new("Frame")
info.BackgroundTransparency = 1
info.Size                   = UDim2.new(1, -130, 1, 0)
info.Parent                 = card
local infoLayout = Instance.new("UIListLayout")
infoLayout.FillDirection     = Enum.FillDirection.Vertical
infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
infoLayout.Padding          = UDim.new(0, Layout.GAP_INFO)
infoLayout.Parent            = info
local nameLbl = Instance.new("TextLabel")
nameLbl.BackgroundTransparency = 1
nameLbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
nameLbl.Text                   = slot.Name or ("Config " .. i)
nameLbl.Font                   = Layout.FONT_TITLE
nameLbl.TextSize               = Layout.VALUE_SIZE
nameLbl.TextColor3             = Theme:Text(1)
nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
nameLbl.Parent                 = info
local metaLbl = Instance.new("TextLabel")
metaLbl.BackgroundTransparency = 1
metaLbl.Size                   = UDim2.new(1, 0, 0, Layout.DESC_SIZE)
metaLbl.Text                   = "Last saved: " .. (slot.SavedAt or "never")
metaLbl.Font                   = Layout.FONT_BODY
metaLbl.TextSize               = Layout.DESC_SIZE
metaLbl.TextColor3             = Theme:Text(4)
metaLbl.TextXAlignment         = Enum.TextXAlignment.Left
metaLbl.Parent                 = info
local btnFrame = Instance.new("Frame")
btnFrame.BackgroundTransparency = 1
btnFrame.Size                   = UDim2.fromOffset(100, 26)
btnFrame.LayoutOrder            = 99
btnFrame.Parent                 = card
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection     = Enum.FillDirection.Horizontal
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding           = UDim.new(0, 4)
btnLayout.Parent            = btnFrame
local function makeBtn(text, bgColor, textColor, callback)
local btn = Instance.new("TextButton")
btn.BackgroundColor3 = bgColor
btn.BorderSizePixel  = 0
btn.Size             = UDim2.fromOffset(46, 24)
btn.Text             = text
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 10
btn.TextColor3       = textColor
btn.AutoButtonColor  = false
btn.Parent           = btnFrame
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 5)
bc.Parent       = btn
btn.MouseEnter:Connect(function()
Tween.fast(btn, { BackgroundColor3 = Color.lighten(bgColor, 0.08) })
end)
btn.MouseLeave:Connect(function()
Tween.fast(btn, { BackgroundColor3 = bgColor })
end)
btn.MouseButton1Click:Connect(function()
pcall(callback)
end)
return btn
end
makeBtn("Load", Theme:Accent(), Color3.new(1,1,1), function()
applyFlagValues(slot.Data)
Toast.show({ Title = "Loaded", Body = slot.Name .. " applied", Type = "success", Duration = 2 })
end)
makeBtn("Save", Theme:BG(4), Theme:Text(2), function()
configsData[i].Data    = getCurrentFlagValues()
configsData[i].SavedAt = getTimestamp()
saveAllConfigs(saveFile, configsData)
metaLbl.Text = "Last saved: " .. configsData[i].SavedAt
Toast.show({ Title = "Saved", Body = slot.Name .. " updated", Type = "success", Duration = 2 })
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
end
end
local newBtn = Instance.new("TextButton")
newBtn.BackgroundColor3 = Theme:BG(2)
newBtn.BorderSizePixel  = 0
newBtn.Size             = UDim2.new(1, 0, 0, 36)
newBtn.Text             = "+ New Config"
newBtn.Font             = Enum.Font.GothamMedium
newBtn.TextSize         = 13
newBtn.TextColor3       = Theme:Text(3)
newBtn.AutoButtonColor  = false
newBtn.LayoutOrder      = 999
newBtn.Parent           = sec._frame
local newBtnCorner = Instance.new("UICorner")
newBtnCorner.CornerRadius = UDim.new(0, 7)
newBtnCorner.Parent       = newBtn
local newBtnStroke = Instance.new("UIStroke")
newBtnStroke.Color            = Theme:Border(0)
newBtnStroke.Thickness        = 1
newBtnStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
newBtnStroke.Parent           = newBtn
newBtn.MouseEnter:Connect(function()
Tween.fast(newBtn, { BackgroundColor3 = Theme:BG(3) })
newBtnStroke.Color = Theme:Border(1)
newBtn.TextColor3  = Theme:Accent()
end)
newBtn.MouseLeave:Connect(function()
Tween.fast(newBtn, { BackgroundColor3 = Theme:BG(2) })
newBtnStroke.Color = Theme:Border(0)
newBtn.TextColor3  = Theme:Text(3)
end)
newBtn.MouseButton1Click:Connect(function()
if #configsData >= maxSlots then
Toast.show({ Title = "Limit Reached", Body = "Max " .. maxSlots .. " config slots", Type = "warn", Duration = 2 })
return
end
local newSlot = {
Name    = "Config " .. (#configsData + 1),
SavedAt = "never",
Data    = {},
}
table.insert(configsData, newSlot)
saveAllConfigs(saveFile, configsData)
refreshSlots()
Toast.show({ Title = "Created", Body = newSlot.Name .. " added", Type = "info", Duration = 2 })
end)
refreshSlots()
end
local HttpService = game:GetService("HttpService")
Section.AddWebhook = function(self, opts)
assert(type(opts) == "table", "AddWebhook: opts must be a table")
local flag = self:_registerFlag(opts.ID, opts.Default or "")
local card, stroke = self:_makeCard()
card.Size          = UDim2.new(1, 0, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
local col = Instance.new("UIListLayout")
col.FillDirection = Enum.FillDirection.Vertical
col.SortOrder     = Enum.SortOrder.LayoutOrder
col.Padding       = UDim.new(0, 6)
col.Parent        = card
local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
titleLbl.Text                   = opts.Title or "Webhook"
titleLbl.Font                   = Layout.FONT_TITLE
titleLbl.TextSize               = Layout.TITLE_SIZE
titleLbl.TextColor3             = Theme:Text(1)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.LayoutOrder            = 1
titleLbl.Parent                 = card
local inputRow = Instance.new("Frame")
inputRow.BackgroundTransparency = 1
inputRow.Size                   = UDim2.new(1, 0, 0, 28)
inputRow.LayoutOrder            = 2
inputRow.Parent                 = card
local inputLayout = Instance.new("UIListLayout")
inputLayout.FillDirection     = Enum.FillDirection.Horizontal
inputLayout.VerticalAlignment = Enum.VerticalAlignment.Center
inputLayout.Padding           = UDim.new(0, 6)
inputLayout.Parent            = inputRow
local inputWrap = Instance.new("Frame")
inputWrap.BackgroundColor3       = Theme:BG(4)
inputWrap.BackgroundTransparency = 0.85
inputWrap.BorderSizePixel  = 0
inputWrap.Size             = UDim2.new(1, -70, 1, 0)
inputWrap.ClipsDescendants = true
inputWrap.Parent           = inputRow
local iwCorner = Instance.new("UICorner")
iwCorner.CornerRadius = UDim.new(0, 6)
iwCorner.Parent       = inputWrap
local iwStroke = Instance.new("UIStroke")
iwStroke.Color        = Theme:Accent()
iwStroke.Transparency = 0.22
iwStroke.Thickness    = 1
iwStroke.Parent       = inputWrap
task.defer(function()
if iwStroke and iwStroke.Parent then iwStroke.Thickness = 1.0001; iwStroke.Thickness = 1 end
end)
local iwPad = Instance.new("UIPadding")
iwPad.PaddingLeft  = UDim.new(0, 8)
iwPad.PaddingRight = UDim.new(0, 8)
iwPad.Parent       = inputWrap
local urlBox = Instance.new("TextBox")
urlBox.BackgroundTransparency = 1
urlBox.BorderSizePixel        = 0
urlBox.Size                   = UDim2.new(1, 0, 1, 0)
urlBox.Text                   = opts.Default or ""
urlBox.PlaceholderText        = opts.Placeholder or "https://discord.com/api/webhooks/..."
urlBox.PlaceholderColor3      = Theme:Text(4)
urlBox.Font                   = Enum.Font.Code
urlBox.TextSize               = 13
urlBox.TextColor3             = Theme:Text(0)
urlBox.ClearTextOnFocus       = false
urlBox.TextXAlignment         = Enum.TextXAlignment.Left
urlBox.Parent                 = inputWrap
local function updateOverflow()
local fits = urlBox.TextBounds.X <= (urlBox.AbsoluteSize.X - 2)
urlBox.TextXAlignment = fits and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
end
urlBox:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
urlBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
task.defer(updateOverflow)
urlBox.Focused:Connect(function()
iwStroke.Color = Theme:Accent()
Tween.fast(iwStroke, { Transparency = 0 })
end)
urlBox.FocusLost:Connect(function()
iwStroke.Color = Theme:Accent()
Tween.fast(iwStroke, { Transparency = 0.22 })
if flag then flag:_fire(urlBox.Text) end
if opts.Callback then
local valid = urlBox.Text:find("discord.com/api/webhooks/") ~= nil
pcall(opts.Callback, urlBox.Text, valid)
end
end)
local testBtn = Instance.new("TextButton")
testBtn.BackgroundColor3       = Theme:BG(4)
testBtn.BackgroundTransparency = 0.88
testBtn.BorderSizePixel  = 0
testBtn.Size             = UDim2.fromOffset(62, 28)
testBtn.Text             = "Test"
testBtn.Font             = Enum.Font.GothamBold
testBtn.TextSize         = 10
testBtn.TextColor3       = Theme:Text(2)
testBtn.AutoButtonColor  = false
testBtn.Parent           = inputRow
local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 6)
tbCorner.Parent       = testBtn
local tbStroke = Instance.new("UIStroke")
tbStroke.Color     = Theme:Border(2)
tbStroke.Thickness = 1
tbStroke.Parent    = testBtn
task.defer(function()
if tbStroke and tbStroke.Parent then tbStroke.Thickness = 1.0001; tbStroke.Thickness = 1 end
end)
local statusRow = Instance.new("Frame")
statusRow.BackgroundTransparency = 1
statusRow.Size                   = UDim2.new(1, 0, 0, 14)
statusRow.LayoutOrder            = 3
statusRow.Parent                 = card
local statusLayout = Instance.new("UIListLayout")
statusLayout.FillDirection     = Enum.FillDirection.Horizontal
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statusLayout.Padding           = UDim.new(0, 5)
statusLayout.Parent            = statusRow
local dot = Instance.new("Frame")
dot.BackgroundColor3 = Theme:Text(4)
dot.BorderSizePixel  = 0
dot.Size             = UDim2.fromOffset(6, 6)
dot.Parent           = statusRow
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent       = dot
local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Size                   = UDim2.new(1, -11, 1, 0)
statusLbl.Text                   = "Not configured"
statusLbl.Font                   = Layout.FONT_BODY
statusLbl.TextSize               = Layout.VALUE_SIZE
statusLbl.TextColor3             = Theme:Text(4)
statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
statusLbl.Parent                 = statusRow
local function setStatus(state, msg)
local colors = {
ok      = Color.fromHex("#22c55e"),
err     = Color.fromHex("#ef4444"),
testing = Color.fromHex("#eab308"),
idle    = Theme:Text(4),
}
dot.BackgroundColor3   = colors[state] or colors.idle
statusLbl.TextColor3   = colors[state] or colors.idle
statusLbl.Text         = msg or ""
end
testBtn.MouseButton1Click:Connect(function()
local url = urlBox.Text:match("^%s*(.-)%s*$")
if url == "" then
setStatus("err", "Enter a URL first")
return
end
setStatus("testing", "Testing...")
testBtn.Text       = "..."
testBtn.TextColor3 = Theme:Text(3)
task.spawn(function()
local ok, result = pcall(function()
return HttpService:RequestAsync({
Url    = url,
Method = "POST",
Headers = { ["Content-Type"] = "application/json" },
Body   = HttpService:JSONEncode({
content  = "MuvaUI webhook test - OK",
username = "MuvaUI",
}),
})
end)
task.wait(0.5)
testBtn.Text       = "Test"
testBtn.TextColor3 = Theme:Text(2)
if ok and result and result.StatusCode and result.StatusCode < 300 then
setStatus("ok", "Connected")
Toast.show({ Title = "Webhook OK", Type = "Success", Duration = 2 })
else
setStatus("err", "Failed - check URL")
Toast.show({ Title = "Webhook Error", Body = "Invalid URL or no access", Type = "Error", Duration = 3 })
end
end)
end)
testBtn.MouseEnter:Connect(function()
Tween.fast(testBtn, { BackgroundColor3 = Theme:BG(3) })
tbStroke.Color = Theme:Accent()
end)
testBtn.MouseLeave:Connect(function()
Tween.fast(testBtn, { BackgroundColor3 = Theme:BG(4) })
tbStroke.Color = Theme:Border(2)
end)
card.MouseEnter:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
stroke.Color = Theme:Border(1)
end)
card.MouseLeave:Connect(function()
Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
stroke.Color = Theme:Border(0)
end)
if flag then
flag.Send = function(_, msgOpts)
local url = flag.Value
if not url or url == "" then return end
task.spawn(function()
pcall(function()
HttpService:RequestAsync({
Url    = url,
Method = "POST",
Headers = { ["Content-Type"] = "application/json" },
Body   = HttpService:JSONEncode({
content  = msgOpts.Content  or "",
username = msgOpts.Username or "MuvaUI",
}),
})
end)
end)
end
end
table.insert(self._components, card)
return card
end
local StateRenderer = {}
function StateRenderer.buildSkeleton(parent, rows)
rows = rows or 3
local frame = Instance.new("Frame")
frame.BackgroundTransparency = 1
frame.Size                   = UDim2.new(1, 0, 0, 0)
frame.AutomaticSize          = Enum.AutomaticSize.Y
frame.Parent                 = parent
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding       = UDim.new(0, 6)
layout.Parent        = frame
for i = 1, rows do
local row = Instance.new("Frame")
row.BackgroundColor3 = Theme:BG(3)
row.BorderSizePixel  = 0
row.Size             = UDim2.new(1, 0, 0, 28)
row.Parent           = frame
local rowCorner = Instance.new("UICorner")
rowCorner.CornerRadius = UDim.new(0, 6)
rowCorner.Parent       = row
local shimmer = Instance.new("Frame")
shimmer.BackgroundColor3       = Theme:BG(4)
shimmer.BackgroundTransparency = 0.6
shimmer.BorderSizePixel        = 0
shimmer.Size                   = UDim2.new(0.3, 0, 1, 0)
shimmer.Position               = UDim2.new(-0.3, 0, 0, 0)
shimmer.ZIndex                 = 2
shimmer.Parent                 = row
local shCorner = Instance.new("UICorner")
shCorner.CornerRadius = UDim.new(0, 6)
shCorner.Parent       = shimmer
local delay = (i - 1) * 0.15
task.spawn(function()
task.wait(delay)
while shimmer.Parent do
Tween.play(shimmer,
{ Position = UDim2.new(1.3, 0, 0, 0) },
TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
)
task.wait(0.9)
shimmer.Position = UDim2.new(-0.3, 0, 0, 0)
task.wait(0.3)
end
end)
end
return frame
end
function StateRenderer.buildInline(parent, stateType, opts)
opts = opts or {}
local STATE_ICONS = {
Empty     = "inbox",
Error     = "triangle-alert",
NoResults = "search",
Locked    = "lock",
Warning   = "zap",
}
local STATE_COLORS = {
Empty     = Theme:Text(3),
Error     = Color.fromHex("#f87171"),
NoResults = Theme:Text(3),
Locked    = Theme:Accent(),
Warning   = Color.fromHex("#fbbf24"),
}
local color = STATE_COLORS[stateType] or Theme:Text(3)
local container = Instance.new("Frame")
container.BackgroundTransparency = 1
container.Size                   = UDim2.new(1, 0, 1, 0)
container.Parent                 = parent
local layout = Instance.new("UIListLayout")
layout.FillDirection       = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment   = Enum.VerticalAlignment.Center
layout.Padding             = UDim.new(0, 6)
layout.Parent              = container
if stateType == "Loading" then
local spinner = Instance.new("Frame")
spinner.BackgroundTransparency = 1
spinner.Size                   = UDim2.fromOffset(28, 28)
spinner.Parent                 = container
local ring = Instance.new("UIStroke")
ring.Color     = Theme:BG(4)
ring.Thickness = 3
ring.Parent    = spinner
local fill = Instance.new("Frame")
fill.BackgroundTransparency = 1
fill.Size                   = UDim2.new(1, 0, 1, 0)
fill.Parent                 = spinner
local img = Icons.new("loader", 22, Theme:Accent())
img.AnchorPoint = Vector2.new(0.5, 0.5)
img.Position    = UDim2.new(0.5, 0, 0.5, 0)
img.Parent      = spinner
local spinInfo = TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
Tween.play(img, { Rotation = 360 }, spinInfo)
Theme:OnAccentChanged(function(a) img.ImageColor3 = a end)
else
local iconName = STATE_ICONS[stateType]
if iconName then
local ico = Icons.new(iconName, 24, color)
ico.Parent = container
end
end
if opts.Title then
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size                   = UDim2.new(1, -24, 0, 0)
title.AutomaticSize          = Enum.AutomaticSize.Y
title.Text                   = opts.Title
title.TextSize               = 12
title.Font                   = Enum.Font.GothamBold
title.TextColor3             = color
title.TextXAlignment         = Enum.TextXAlignment.Center
title.TextWrapped            = true
title.Parent                 = container
end
local bodyText = opts.Body
if stateType == "NoResults" and opts.Query then
bodyText = 'Tidak ada hasil untuk "' .. opts.Query .. '"'
end
if bodyText then
local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Size                   = UDim2.new(1, -32, 0, 0)
body.AutomaticSize          = Enum.AutomaticSize.Y
body.Text                   = bodyText
body.TextSize               = 13
body.Font                   = Enum.Font.Gotham
body.TextColor3             = Theme:Text(3)
body.TextXAlignment         = Enum.TextXAlignment.Center
body.TextWrapped            = true
body.Parent                 = container
end
if opts.Action then
local btn = Instance.new("TextButton")
btn.BackgroundColor3 = color
btn.BorderSizePixel  = 0
btn.Size             = UDim2.fromOffset(90, 26)
btn.Text             = opts.Action.Text or "Action"
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 10
btn.TextColor3       = Color3.new(1, 1, 1)
btn.AutoButtonColor  = false
btn.Parent           = container
local btnC = Instance.new("UICorner")
btnC.CornerRadius = UDim.new(0, 5)
btnC.Parent       = btn
btn.MouseButton1Click:Connect(function()
if opts.Action.Callback then pcall(opts.Action.Callback) end
end)
end
return container
end
local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)
Library = {}
Library.__index = Library
Library.Flags   = {}
Library._windows = {}
function Library:CreateWindow(opts)
pcall(function()
if CoreGui then
for _, v in ipairs(CoreGui:GetChildren()) do
if v.Name:find("MuvaUI") then v:Destroy() end
end
end
end)
pcall(function()
local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
if pg then
for _, v in ipairs(pg:GetChildren()) do
if v.Name:find("MuvaUI") then v:Destroy() end
end
end
end)
local screenGui = Instance.new("ScreenGui")
screenGui.Name             = "MuvaUI_" .. (opts.Title or "Window")
screenGui.ResetOnSpawn     = false
screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder     = 5
screenGui.IgnoreGuiInset   = false
local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.Parent = playerGui
if opts.Key and KeySystem then
KeySystem.show(opts.Key, screenGui, function()
local win = self:_spawnWindow(opts, screenGui)
if win and opts.OnReady and not opts.BuildTabs and not self._loadingConfig then
pcall(opts.OnReady, win)
end
end)
return nil
else
local win = self:_spawnWindow(opts, screenGui)
if win and opts.OnReady and not opts.BuildTabs and not self._loadingConfig then
pcall(opts.OnReady, win)
end
return win
end
end
function Library:_spawnWindow(opts, screenGui)
local function buildWindow()
local ok, result = pcall(function() return Window.new(opts, screenGui, self.Flags) end)
if not ok then
warn("[MuvaUI] Window.new failed: " .. tostring(result))
return nil
end
table.insert(self._windows, result)
if self._configSystem and ConfigSystem then
ConfigSystem.attach(result, self._configSystem, self.Flags)
end
return result
end
if opts.BuildTabs and LoadingScreen then
local win = buildWindow()
if not win then return nil end
win:Hide()
local okB, steps = pcall(opts.BuildTabs, win)
if not okB then
warn("[MuvaUI] BuildTabs error: " .. tostring(steps))
steps = nil
end
local loadingConfig = {
Title    = (self._loadingConfig and self._loadingConfig.Title) or opts.Title or "Loading",
Steps    = steps or (self._loadingConfig and self._loadingConfig.Steps) or { { Message = "Loading..." } },
OnResult = self._loadingConfig and self._loadingConfig.OnResult,
}
LoadingScreen.show(loadingConfig, screenGui, function()
win:Show()
if opts.OnReady then pcall(opts.OnReady, win) end
end)
return nil
end
if self._loadingConfig and LoadingScreen then
LoadingScreen.show(self._loadingConfig, screenGui, function()
local win = buildWindow()
if opts.OnReady and win then
pcall(opts.OnReady, win)
end
end)
return nil
else
return buildWindow()
end
end
function Library:SetAccent(color)
Theme:SetAccent(color)
end
function Library:GetAccent()
return Theme:GetAccent()
end
function Library:SetLoadingScreen(config)
self._loadingConfig = config
end
function Library:SetConfigSystem(config)
self._configSystem = config
end
function Library:SaveConfig(name)
end
function Library:LoadConfig(name)
end
Library.Notify = function(self, opts)
local sg = nil
for _, w in ipairs(self._windows) do
if w and w._win and w._win.Parent then
sg = w._win.Parent
break
end
end
Toast.show(opts, sg)
end
Window.Dialog = function(self, opts)
Dialog.show(opts, self._win.Parent)
end
Window.Popup = function(self, opts)
Popup.show(opts, self._win)
end
return Library
end
local _ok, _result = pcall(MuvaUIFactory)
if not _ok then
warn('[MuvaUI] Fatal error during init: ' .. tostring(_result))
return nil
end
return _result