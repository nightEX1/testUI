--[[
    allfunsion.lua
    Modern Premium Script UI — ไฟล์เดียวรวมทุกอย่าง (ไม่ต้อง require ไฟล์อื่น)
    โครงสร้างภายในยังแยกเป็นโมดูลย่อยด้วย local table เพื่อให้แก้ไข/ต่อยอดง่าย
    ส่วนที่ต้องแก้เอง (โลโก้ / logic ฟีเจอร์) มาร์คด้วย "-- TODO:"
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--====================================================================
-- THEME
--====================================================================
local Theme = {}
Theme.Colors = {
    Background      = Color3.fromRGB(18, 18, 20),
    Surface         = Color3.fromRGB(26, 26, 29),
    SurfaceAlt      = Color3.fromRGB(32, 32, 36),
    SurfaceHover    = Color3.fromRGB(40, 40, 45),
    Border          = Color3.fromRGB(46, 46, 51),

    TextPrimary     = Color3.fromRGB(235, 235, 240),
    TextSecondary   = Color3.fromRGB(150, 150, 158),
    TextMuted       = Color3.fromRGB(100, 100, 108),

    Accent          = Color3.fromRGB(64, 196, 160), -- TODO: เปลี่ยนให้ตรงโทนโลโก้จริง
    AccentDim       = Color3.fromRGB(40, 120, 100),
    AccentHover     = Color3.fromRGB(80, 215, 178),

    Success         = Color3.fromRGB(76, 201, 140),
    Warning         = Color3.fromRGB(230, 180, 70),
    Danger          = Color3.fromRGB(230, 90, 90),

    Divider         = Color3.fromRGB(44, 44, 48),
}
Theme.Fonts = {
    Regular = Enum.Font.Gotham,
    Medium  = Enum.Font.GothamMedium,
    Bold    = Enum.Font.GothamBold,
}
Theme.Radius = {
    Small  = UDim.new(0, 6),
    Medium = UDim.new(0, 10),
    Large  = UDim.new(0, 14),
    Pill   = UDim.new(1, 0),
}
Theme.Sizing = {
    SidebarWidth   = 180,
    HeaderHeight   = 52,
    CardPadding    = 14,
    ElementSpacing = 10,
}
Theme.Animation = {
    Fast   = 0.15,
    Normal = 0.22,
    Slow   = 0.3,
    Easing = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,
}

--====================================================================
-- ANIMATION
--====================================================================
local Animation = {}

local function makeInfo(duration, style, direction)
    return TweenInfo.new(
        duration or Theme.Animation.Normal,
        style or Theme.Animation.Easing,
        direction or Theme.Animation.EasingDirection
    )
end

function Animation.Tween(instance, props, duration, style, direction)
    local tw = TweenService:Create(instance, makeInfo(duration, style, direction), props)
    tw:Play()
    return tw
end

function Animation.Open(frame, opts)
    opts = opts or {}
    local duration = opts.Duration or 0.25
    local targetSize = opts.Size or frame.Size
    local targetPos = opts.Position or frame.Position

    frame.Visible = true
    frame.Size = UDim2.new(targetSize.X.Scale * 0.92, targetSize.X.Offset, targetSize.Y.Scale * 0.92, targetSize.Y.Offset)
    frame.Position = targetPos + UDim2.fromOffset(0, 16)

    local stroke = frame:FindFirstChild("UIStroke")
    if stroke then stroke.Transparency = 1 end

    local startTransparency = frame.BackgroundTransparency
    frame.BackgroundTransparency = 1

    Animation.Tween(frame, {
        Size = targetSize,
        Position = targetPos,
        BackgroundTransparency = startTransparency,
    }, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Animation.Close(frame, opts, onComplete)
    opts = opts or {}
    local duration = opts.Duration or 0.2
    local shrunkSize = UDim2.new(frame.Size.X.Scale * 0.92, frame.Size.X.Offset, frame.Size.Y.Scale * 0.92, frame.Size.Y.Offset)
    local droppedPos = frame.Position + UDim2.fromOffset(0, 16)

    local tw = Animation.Tween(frame, {
        Size = shrunkSize,
        Position = droppedPos,
        BackgroundTransparency = 1,
    }, duration, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

    tw.Completed:Connect(function()
        frame.Visible = false
        if onComplete then onComplete() end
    end)
end

--====================================================================
-- DRAGGABLE
--====================================================================
local Draggable = {}

function Draggable.Make(frame, opts)
    opts = opts or {}
    local dragTarget = opts.DragTarget or frame
    local onDragEnd = opts.OnDragEnd

    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local targetPos

    local function update(input)
        local delta = input.Position - dragStart
        targetPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            targetPos = startPos

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                    if onDragEnd then onDragEnd(frame.Position) end
                end
            end)
        end
    end)

    dragTarget.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)

    local connection = RunService.RenderStepped:Connect(function(dt)
        if targetPos then
            local alpha = math.clamp(dt * 18, 0, 1)
            frame.Position = frame.Position:Lerp(targetPos, alpha)
        end
    end)

    return {
        Disconnect = function()
            if connection then connection:Disconnect() end
        end,
    }
end

--====================================================================
-- COMPONENTS: Card / Toggle / Button / Dropdown / Slider
--====================================================================
local Components = {}

-- Card ---------------------------------------------------------------
function Components.Card(parent, title, layoutOrder)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.BackgroundColor3 = Theme.Colors.SurfaceAlt
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.LayoutOrder = layoutOrder or 1
    card.Parent = parent

    Instance.new("UICorner", card).CornerRadius = Theme.Radius.Large

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1
    stroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, Theme.Sizing.CardPadding)
    padding.PaddingBottom = UDim.new(0, Theme.Sizing.CardPadding)
    padding.PaddingLeft = UDim.new(0, Theme.Sizing.CardPadding)
    padding.PaddingRight = UDim.new(0, Theme.Sizing.CardPadding)
    padding.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, Theme.Sizing.ElementSpacing)
    layout.Parent = card

    if title then
        local label = Instance.new("TextLabel")
        label.Name = "Title"
        label.Text = title
        label.Font = Theme.Fonts.Bold
        label.TextSize = 14
        label.TextColor3 = Theme.Colors.TextPrimary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, 18)
        label.LayoutOrder = 0
        label.Parent = card
    end

    return card
end

-- Toggle ---------------------------------------------------------------
function Components.Toggle(parent, config)
    config = config or {}
    local text = config.Text or "Toggle"
    local default = config.Default or false
    local callback = config.Callback
    local state = default

    local row = Instance.new("Frame")
    row.Name = "Toggle"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 24)
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Theme.Fonts.Medium
    label.TextSize = 13
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Parent = row

    local switch = Instance.new("Frame")
    switch.Size = UDim2.fromOffset(40, 22)
    switch.Position = UDim2.new(1, -40, 0.5, -11)
    switch.BackgroundColor3 = state and Theme.Colors.Accent or Theme.Colors.Border
    switch.Parent = row
    Instance.new("UICorner", switch).CornerRadius = Theme.Radius.Pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = switch
    Instance.new("UICorner", knob).CornerRadius = Theme.Radius.Pill

    local click = Instance.new("TextButton")
    click.Text = ""
    click.BackgroundTransparency = 1
    click.Size = UDim2.fromScale(1, 1)
    click.Parent = row

    local function setState(value, fire)
        state = value
        Animation.Tween(switch, { BackgroundColor3 = state and Theme.Colors.Accent or Theme.Colors.Border }, Theme.Animation.Fast)
        Animation.Tween(knob, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, Theme.Animation.Fast)
        if fire and callback then
            callback(state) -- TODO: ใส่ logic จริง
        end
    end

    click.MouseButton1Click:Connect(function()
        setState(not state, true)
    end)

    return {
        Instance = row,
        Set = function(_, value) setState(value, false) end,
        Get = function() return state end,
    }
end

-- Button ---------------------------------------------------------------
function Components.Button(parent, config)
    config = config or {}
    local text = config.Text or "Button"
    local callback = config.Callback
    local variant = config.Variant or "default"

    local bg = Theme.Colors.SurfaceHover
    if variant == "accent" then bg = Theme.Colors.Accent
    elseif variant == "danger" then bg = Theme.Colors.Danger end

    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Font = Theme.Fonts.Medium
    btn.TextSize = 13
    btn.TextColor3 = variant == "default" and Theme.Colors.TextPrimary or Color3.new(1, 1, 1)
    btn.BackgroundColor3 = bg
    btn.AutoButtonColor = false
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = Theme.Radius.Medium

    btn.MouseEnter:Connect(function()
        Animation.Tween(btn, { BackgroundColor3 = variant == "default" and Theme.Colors.Border or Theme.Colors.AccentHover }, Theme.Animation.Fast)
    end)
    btn.MouseLeave:Connect(function()
        Animation.Tween(btn, { BackgroundColor3 = bg }, Theme.Animation.Fast)
    end)

    btn.MouseButton1Click:Connect(function()
        Animation.Tween(btn, { Size = UDim2.new(1, -6, 0, 32) }, 0.08)
        task.delay(0.08, function()
            Animation.Tween(btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.1)
        end)
        if callback then
            callback() -- TODO: ใส่ logic จริง
        end
    end)

    return { Instance = btn }
end

-- Dropdown ---------------------------------------------------------------
function Components.Dropdown(parent, config)
    config = config or {}
    local text = config.Text or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or options[1] or "None"
    local callback = config.Callback

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = container

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Theme.Fonts.Medium
    label.TextSize = 13
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 16)
    label.LayoutOrder = 1
    label.Parent = container

    local head = Instance.new("TextButton")
    head.Text = ""
    head.BackgroundColor3 = Theme.Colors.SurfaceHover
    head.Size = UDim2.new(1, 0, 0, 36)
    head.LayoutOrder = 2
    head.Parent = container
    Instance.new("UICorner", head).CornerRadius = Theme.Radius.Medium

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Text = default
    selectedLabel.Font = Theme.Fonts.Regular
    selectedLabel.TextSize = 13
    selectedLabel.TextColor3 = Theme.Colors.TextSecondary
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Position = UDim2.fromOffset(12, 0)
    selectedLabel.Size = UDim2.new(1, -36, 1, 0)
    selectedLabel.Parent = head

    local arrow = Instance.new("TextLabel")
    arrow.Text = "▾"
    arrow.Font = Theme.Fonts.Bold
    arrow.TextSize = 14
    arrow.TextColor3 = Theme.Colors.TextSecondary
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.fromOffset(24, 36)
    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.Parent = head

    local list = Instance.new("Frame")
    list.BackgroundColor3 = Theme.Colors.SurfaceHover
    list.Size = UDim2.new(1, 0, 0, 0)
    list.ClipsDescendants = true
    list.LayoutOrder = 3
    list.Parent = container
    Instance.new("UICorner", list).CornerRadius = Theme.Radius.Medium

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local open = false
    local optionHeight = 32

    local function close()
        open = false
        Animation.Tween(list, { Size = UDim2.new(1, 0, 0, 0) }, Theme.Animation.Fast)
        Animation.Tween(arrow, { Rotation = 0 }, Theme.Animation.Fast)
    end

    local function toggleOpen()
        open = not open
        if open then
            Animation.Tween(list, { Size = UDim2.new(1, 0, 0, optionHeight * #options) }, Theme.Animation.Fast)
            Animation.Tween(arrow, { Rotation = 180 }, Theme.Animation.Fast)
        else
            close()
        end
    end

    for i, optionText in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Text = optionText
        optBtn.Font = Theme.Fonts.Regular
        optBtn.TextSize = 13
        optBtn.TextColor3 = Theme.Colors.TextSecondary
        optBtn.BackgroundTransparency = 1
        optBtn.Size = UDim2.new(1, 0, 0, optionHeight)
        optBtn.LayoutOrder = i
        optBtn.Parent = list

        optBtn.MouseButton1Click:Connect(function()
            selectedLabel.Text = optionText
            close()
            if callback then
                callback(optionText) -- TODO: ใส่ logic จริง
            end
        end)
    end

    head.MouseButton1Click:Connect(toggleOpen)

    return {
        Instance = container,
        Get = function() return selectedLabel.Text end,
    }
end

-- Slider ---------------------------------------------------------------
function Components.Slider(parent, config)
    config = config or {}
    local text = config.Text or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local callback = config.Callback
    local suffix = config.Suffix or ""

    local value = math.clamp(default, min, max)

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 44)
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Theme.Fonts.Medium
    label.TextSize = 13
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -50, 0, 16)
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(value) .. suffix
    valueLabel.Font = Theme.Fonts.Medium
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Theme.Colors.Accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.Size = UDim2.new(0, 50, 0, 16)
    valueLabel.Parent = container

    local track = Instance.new("Frame")
    track.BackgroundColor3 = Theme.Colors.Border
    track.Position = UDim2.new(0, 0, 0, 26)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = Theme.Radius.Pill

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Colors.Accent
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = Theme.Radius.Pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = Theme.Radius.Pill

    local dragging = false

    local function setFromAlpha(alpha, fire)
        alpha = math.clamp(alpha, 0, 1)
        value = math.floor(min + (max - min) * alpha + 0.5)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(value) .. suffix
        if fire and callback then
            callback(value) -- TODO: ใส่ logic จริง
        end
    end

    local function inputToAlpha(input)
        local relativeX = input.Position.X - track.AbsolutePosition.X
        return relativeX / track.AbsoluteSize.X
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromAlpha(inputToAlpha(input), true)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromAlpha(inputToAlpha(input), true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Instance = container,
        Set = function(_, v) setFromAlpha((v - min) / (max - min), false) end,
        Get = function() return value end,
    }
end

--====================================================================
-- FLOATING ICON
--====================================================================
local FloatingIcon = {}

function FloatingIcon.New(screenGui, config)
    config = config or {}

    local icon = Instance.new("ImageButton")
    icon.Name = "FloatingIcon"
    icon.Size = UDim2.fromOffset(56, 56)
    icon.Position = config.GetSavedPosition and config.GetSavedPosition() or UDim2.new(0, 20, 0.5, -28)
    icon.BackgroundColor3 = Theme.Colors.Surface
    icon.Image = config.LogoId or "" -- TODO: ใส่ rbxassetid โลโก้
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 1000
    icon.Parent = screenGui
    Instance.new("UICorner", icon).CornerRadius = Theme.Radius.Pill

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = icon

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = icon

    icon.MouseEnter:Connect(function()
        Animation.Tween(icon, { Size = UDim2.fromOffset(60, 60) }, Theme.Animation.Fast)
    end)
    icon.MouseLeave:Connect(function()
        Animation.Tween(icon, { Size = UDim2.fromOffset(56, 56) }, Theme.Animation.Fast)
    end)

    local dragHandle = Draggable.Make(icon, {
        OnDragEnd = function(position)
            if config.SavePosition then
                config.SavePosition(position) -- TODO: บันทึกตำแหน่งจริง
            end
        end,
    })

    local isOpen = false
    icon.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if config.OnToggle then
            config.OnToggle(isOpen)
        end
    end)

    return {
        Instance = icon,
        SetOpenState = function(_, value) isOpen = value end,
        Destroy = function()
            dragHandle.Disconnect()
            icon:Destroy()
        end,
    }
end

--====================================================================
-- SIDEBAR
--====================================================================
local Sidebar = {}
local MENU_ITEMS = { "Main", "AutoFarm", "Webhook", "ESP", "Shop", "Setting" }

function Sidebar.New(parent, config)
    config = config or {}

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = Theme.Colors.Surface
    sidebar.Size = UDim2.new(0, Theme.Sizing.SidebarWidth, 1, 0)
    sidebar.Parent = parent

    local navHolder = Instance.new("Frame")
    navHolder.BackgroundTransparency = 1
    navHolder.Position = UDim2.fromOffset(0, 12)
    navHolder.Size = UDim2.new(1, 0, 1, -112)
    navHolder.Parent = sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Padding = UDim.new(0, 4)
    navLayout.Parent = navHolder

    local navPadding = Instance.new("UIPadding")
    navPadding.PaddingLeft = UDim.new(0, 10)
    navPadding.PaddingRight = UDim.new(0, 10)
    navPadding.Parent = navHolder

    local buttons = {}
    local activeName = MENU_ITEMS[1]

    local function setActive(name)
        activeName = name
        for itemName, btn in pairs(buttons) do
            local active = itemName == name
            Animation.Tween(btn, {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = Theme.Colors.SurfaceHover,
            }, Theme.Animation.Fast)
            Animation.Tween(btn.Indicator, {
                BackgroundTransparency = active and 0 or 1,
            }, Theme.Animation.Fast)
            btn.TextLabel.TextColor3 = active and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
        end
        if config.OnSelect then
            config.OnSelect(name)
        end
    end

    for i, name in ipairs(MENU_ITEMS) do
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = ""
        btn.BackgroundColor3 = Theme.Colors.SurfaceHover
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.LayoutOrder = i
        btn.Parent = navHolder
        Instance.new("UICorner", btn).CornerRadius = Theme.Radius.Medium

        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.BackgroundColor3 = Theme.Colors.Accent
        indicator.BackgroundTransparency = 1
        indicator.Size = UDim2.new(0, 3, 0, 18)
        indicator.Position = UDim2.new(0, 0, 0.5, -9)
        indicator.Parent = btn
        Instance.new("UICorner", indicator).CornerRadius = Theme.Radius.Pill

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Text = name
        textLabel.Font = Theme.Fonts.Medium
        textLabel.TextSize = 13
        textLabel.TextColor3 = Theme.Colors.TextSecondary
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.BackgroundTransparency = 1
        textLabel.Position = UDim2.fromOffset(14, 0)
        textLabel.Size = UDim2.new(1, -14, 1, 0)
        textLabel.Parent = btn

        btn.TextLabel = textLabel
        btn.Indicator = indicator
        buttons[name] = btn

        btn.MouseButton1Click:Connect(function()
            setActive(name)
        end)
    end

    local divider = Instance.new("Frame")
    divider.BackgroundColor3 = Theme.Colors.Divider
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.new(0, 10, 1, -92)
    divider.Parent = sidebar

    local profile = Instance.new("Frame")
    profile.BackgroundTransparency = 1
    profile.Size = UDim2.new(1, -20, 0, 70)
    profile.Position = UDim2.new(0, 10, 1, -80)
    profile.Parent = sidebar

    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundColor3 = Theme.Colors.SurfaceHover
    avatar.Size = UDim2.fromOffset(38, 38)
    avatar.Position = UDim2.new(0, 0, 0.5, -19)
    avatar.Image = (config.UserInfo and config.UserInfo.AvatarId) or ""
    avatar.Parent = profile
    Instance.new("UICorner", avatar).CornerRadius = Theme.Radius.Pill

    local username = Instance.new("TextLabel")
    username.Text = (config.UserInfo and config.UserInfo.Username) or "Username"
    username.Font = Theme.Fonts.Bold
    username.TextSize = 13
    username.TextColor3 = Theme.Colors.TextPrimary
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.BackgroundTransparency = 1
    username.Position = UDim2.fromOffset(48, 0)
    username.Size = UDim2.new(1, -48, 0, 16)
    username.Parent = profile

    local tag = Instance.new("TextLabel")
    tag.Text = (config.UserInfo and config.UserInfo.PlayerTag) or "@PlayerName"
    tag.Font = Theme.Fonts.Regular
    tag.TextSize = 11
    tag.TextColor3 = Theme.Colors.TextSecondary
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.BackgroundTransparency = 1
    tag.Position = UDim2.fromOffset(48, 17)
    tag.Size = UDim2.new(1, -48, 0, 14)
    tag.Parent = profile

    local role = Instance.new("TextLabel")
    role.Text = (config.UserInfo and config.UserInfo.Role) or "Script User"
    role.Font = Theme.Fonts.Regular
    role.TextSize = 10
    role.TextColor3 = Theme.Colors.Accent
    role.TextXAlignment = Enum.TextXAlignment.Left
    role.BackgroundTransparency = 1
    role.Position = UDim2.fromOffset(48, 32)
    role.Size = UDim2.new(1, -48, 0, 14)
    role.Parent = profile

    setActive(MENU_ITEMS[1])

    return {
        Instance = sidebar,
        SetActive = setActive,
        GetActive = function() return activeName end,
        Items = MENU_ITEMS,
    }
end

--====================================================================
-- WINDOW (ประกอบ Header + Search + Sidebar + Content + Floating Icon)
--====================================================================
local Window = {}
Window.__index = Window

function Window.New(config)
    config = config or {}
    local self = setmetatable({}, Window)

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ModernScriptUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.IgnoreGuiInset = true
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = PlayerGui

    local viewport = workspace.CurrentCamera.ViewportSize
    local isMobile = viewport.X < 700
    local winWidth = isMobile and UDim2.new(0.92, 0, 0, 420) or UDim2.new(0, 640, 0, 420)

    self.Main = Instance.new("Frame")
    self.Main.Name = "Main"
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Position = UDim2.fromScale(0.5, 0.5)
    self.Main.Size = winWidth
    self.Main.BackgroundColor3 = Theme.Colors.Background
    self.Main.Visible = false
    self.Main.Parent = self.ScreenGui
    Instance.new("UICorner", self.Main).CornerRadius = Theme.Radius.Large

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Name = "UIStroke"
    mainStroke.Color = Theme.Colors.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = self.Main

    local maxHeight = math.min(420, viewport.Y - 80)
    self.Main.Size = UDim2.new(winWidth.X.Scale, winWidth.X.Offset, 0, maxHeight)

    -- Header ------------------------------------------------------
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundColor3 = Theme.Colors.Surface
    header.Size = UDim2.new(1, 0, 0, Theme.Sizing.HeaderHeight)
    header.Parent = self.Main
    Instance.new("UICorner", header).CornerRadius = Theme.Radius.Large

    local headerMask = Instance.new("Frame")
    headerMask.BackgroundColor3 = Theme.Colors.Surface
    headerMask.BorderSizePixel = 0
    headerMask.Size = UDim2.new(1, 0, 0, Theme.Sizing.HeaderHeight / 2)
    headerMask.Position = UDim2.new(0, 0, 1, -Theme.Sizing.HeaderHeight / 2)
    headerMask.ZIndex = 0
    headerMask.Parent = header

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Image = config.LogoId or "" -- TODO: ใส่ rbxassetid โลโก้
    logo.Size = UDim2.fromOffset(28, 28)
    logo.Position = UDim2.fromOffset(14, 12)
    logo.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = config.Title or "Script Name"
    titleLabel.Font = Theme.Fonts.Bold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = Theme.Colors.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(50, 8)
    titleLabel.Size = UDim2.new(0, 200, 0, 18)
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Text = config.Subtitle or "Premium Script"
    subtitleLabel.Font = Theme.Fonts.Regular
    subtitleLabel.TextSize = 11
    subtitleLabel.TextColor3 = Theme.Colors.TextSecondary
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(50, 26)
    subtitleLabel.Size = UDim2.new(0, 200, 0, 14)
    subtitleLabel.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Font = Theme.Fonts.Bold
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Theme.Colors.TextSecondary
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.Position = UDim2.new(1, -38, 0, 10)
    closeBtn.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Text = "–"
    minBtn.Font = Theme.Fonts.Bold
    minBtn.TextSize = 15
    minBtn.TextColor3 = Theme.Colors.TextSecondary
    minBtn.BackgroundTransparency = 1
    minBtn.Size = UDim2.fromOffset(32, 32)
    minBtn.Position = UDim2.new(1, -72, 0, 10)
    minBtn.Parent = header

    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "Search..."
    searchBox.Text = ""
    searchBox.Font = Theme.Fonts.Regular
    searchBox.TextSize = 12
    searchBox.TextColor3 = Theme.Colors.TextPrimary
    searchBox.PlaceholderColor3 = Theme.Colors.TextMuted
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.BackgroundColor3 = Theme.Colors.SurfaceHover
    searchBox.ClearTextOnFocus = false
    searchBox.Size = UDim2.new(0, 160, 0, 28)
    searchBox.Position = UDim2.new(1, -240, 0, 12)
    searchBox.Parent = header
    Instance.new("UICorner", searchBox).CornerRadius = Theme.Radius.Medium

    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 10)
    searchPadding.Parent = searchBox

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self.OnSearch then
            self.OnSearch(searchBox.Text) -- TODO: เชื่อม filter element จริง
        end
    end)

    -- Body: Sidebar + Content --------------------------------------
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(0, Theme.Sizing.HeaderHeight)
    body.Size = UDim2.new(1, 0, 1, -Theme.Sizing.HeaderHeight)
    body.Parent = self.Main

    self.SidebarComp = Sidebar.New(body, {
        UserInfo = config.UserInfo,
        OnSelect = function(name)
            self:SelectPage(name)
        end,
    })

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "Content"
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Position = UDim2.new(0, Theme.Sizing.SidebarWidth, 0, 0)
    self.ContentArea.Size = UDim2.new(1, -Theme.Sizing.SidebarWidth, 1, 0)
    self.ContentArea.Parent = body

    self.Pages = {}
    for i, name in ipairs(self.SidebarComp.Items) do
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Colors.Accent
        page.Visible = (i == 1)
        page.Parent = self.ContentArea

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 14)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.PaddingBottom = UDim.new(0, 14)
        padding.Parent = page

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 12)
        layout.Parent = page

        self.Pages[name] = page
    end

    Draggable.Make(self.Main, { DragTarget = header })

    closeBtn.MouseButton1Click:Connect(function() self:Close() end)
    minBtn.MouseButton1Click:Connect(function() self:Close() end)

    self.Floating = FloatingIcon.New(self.ScreenGui, {
        LogoId = config.LogoId,
        GetSavedPosition = config.GetSavedIconPosition,
        SavePosition = config.SaveIconPosition,
        OnToggle = function(isOpen)
            if isOpen then self:Open() else self:Close() end
        end,
    })

    self.IsOpen = false
    return self
end

function Window:SelectPage(name)
    for pageName, page in pairs(self.Pages) do
        page.Visible = (pageName == name)
    end
end

function Window:GetPage(name)
    return self.Pages[name]
end

function Window:Open()
    self.IsOpen = true
    self.Floating:SetOpenState(true)
    Animation.Open(self.Main, { Size = self.Main.Size, Position = self.Main.Position, Duration = 0.25 })
end

function Window:Close()
    self.IsOpen = false
    self.Floating:SetOpenState(false)
    Animation.Close(self.Main, { Duration = 0.2 })
end

function Window:Toggle()
    if self.IsOpen then self:Close() else self:Open() end
end

--====================================================================
-- สร้างหน้าต่างจริง + ใส่ element ตัวอย่างในแต่ละเมนู
-- (จุดนี้คือที่ต้องแก้ logic ของแต่ละฟีเจอร์ — ค้นหาคำว่า "TODO:")
--====================================================================
local window = Window.New({
    Title = "Voidware", -- TODO: เปลี่ยนชื่อ script
    Subtitle = "Premium Script UI",
    LogoId = "rbxassetid://0", -- TODO: ใส่ไอดีโลโก้จริง
    UserInfo = {
        Username = LocalPlayer.DisplayName,
        PlayerTag = "@" .. LocalPlayer.Name,
        Role = "Script User",
        AvatarId = "",
    },
    GetSavedIconPosition = function()
        return nil -- TODO: โหลดตำแหน่งล่าสุดถ้ามี
    end,
    SaveIconPosition = function(position)
        -- TODO: เซฟตำแหน่งไอคอนจริง
    end,
})

-- Main --------------------------------------------------------------
do
    local page = window:GetPage("Main")
    local card = Components.Card(page, "Status")
    Components.Toggle(card, {
        Text = "Enable Script",
        Default = false,
        Callback = function(state)
            -- TODO: logic เปิด/ปิดการทำงานหลัก
        end,
    })
    Components.Button(card, {
        Text = "Rejoin Server",
        Callback = function()
            -- TODO: logic rejoin
        end,
    })
end

-- AutoFarm ------------------------------------------------------------
do
    local page = window:GetPage("AutoFarm")
    local card = Components.Card(page, "Auto Farm")
    Components.Toggle(card, {
        Text = "Auto Farm",
        Default = false,
        Callback = function(state)
            -- TODO: logic auto farm
        end,
    })
    Components.Dropdown(card, {
        Text = "Farm Mode",
        Options = { "Nearest", "Strongest", "Weakest" },
        Default = "Nearest",
        Callback = function(selected)
            -- TODO: logic เปลี่ยนโหมดฟาร์ม
        end,
    })
    Components.Slider(card, {
        Text = "Farm Range",
        Min = 10,
        Max = 200,
        Default = 50,
        Suffix = " studs",
        Callback = function(value)
            -- TODO: logic ปรับระยะฟาร์ม
        end,
    })
end

-- Webhook ------------------------------------------------------------
do
    local page = window:GetPage("Webhook")
    local card = Components.Card(page, "Discord Webhook")
    Components.Toggle(card, {
        Text = "Enable Webhook",
        Default = false,
        Callback = function(state)
            -- TODO: logic เปิด/ปิดการส่ง webhook
        end,
    })
    Components.Button(card, {
        Text = "Test Webhook",
        Variant = "accent",
        Callback = function()
            -- TODO: logic ยิง webhook ทดสอบ
        end,
    })
end

-- ESP ------------------------------------------------------------
do
    local page = window:GetPage("ESP")
    local card = Components.Card(page, "ESP")
    Components.Toggle(card, {
        Text = "Player ESP",
        Default = false,
        Callback = function(state)
            -- TODO: logic เปิด/ปิด ESP ผู้เล่น
        end,
    })
    Components.Toggle(card, {
        Text = "Item ESP",
        Default = false,
        Callback = function(state)
            -- TODO: logic เปิด/ปิด ESP ไอเทม
        end,
    })
end

-- Shop ------------------------------------------------------------
do
    local page = window:GetPage("Shop")
    local card = Components.Card(page, "Premium Key")
    Components.Button(card, {
        Text = "Buy Key",
        Variant = "accent",
        Callback = function()
            -- TODO: logic เปิดลิงก์ซื้อ key
        end,
    })
end

-- Setting ------------------------------------------------------------
do
    local page = window:GetPage("Setting")
    local card = Components.Card(page, "General")
    Components.Dropdown(card, {
        Text = "UI Theme",
        Options = { "Dark", "Darker" },
        Default = "Dark",
        Callback = function(selected)
            -- TODO: logic เปลี่ยนธีม
        end,
    })
    Components.Button(card, {
        Text = "Reset Position",
        Variant = "danger",
        Callback = function()
            -- TODO: logic รีเซ็ตตำแหน่ง UI/ไอคอน
        end,
    })
end

-- หน้าต่างเริ่มต้นแบบซ่อนไว้ (มีแค่ Floating Icon ลอยอยู่) คลิก Logo เพื่อเปิด
