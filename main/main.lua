--!nonstrict
--[[
    GXL Chat — improved version
    Based on original by ballssman3761

    To remove: game:GetService("CoreGui").GXL_Chat:Destroy()
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP = Players.LocalPlayer

local CONFIG = {
    GUI_NAME              = "GXL_Chat",
    MAX_MESSAGES          = 100,
    TIME_UPDATE_INTERVAL  = 1,
    MESSAGE_COLOR         = "#d4d4d4",
    SCROLL_BOTTOM_THRESH  = 60,   -- px
    CHANNEL_PREFERRED     = "RBXGeneral",
}

-- ==================== CLEANUP OLD ====================
do
    local old = CoreGui:FindFirstChild(CONFIG.GUI_NAME)
    if old then old:Destroy() end
end

-- ==================== UI HELPER ====================
local function inst(class, parent, props)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

-- ==================== UI ====================
local gui = inst("ScreenGui", CoreGui, {
    Name = CONFIG.GUI_NAME,
    DisplayOrder = -1,
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
})

local appLayout = inst("Frame", gui, {
    Name = "appLayout",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 4),
    Size = UDim2.new(0.4, 0, 0.169, 0),
})
inst("UIListLayout", appLayout, { Name = "layout", SortOrder = Enum.SortOrder.LayoutOrder })
inst("UISizeConstraint", appLayout, { Name = "uiSizeConstraint", MaxSize = Vector2.new(475, math.huge) })

-- ---------- chatWindow ----------
local chatWindow = inst("Frame", appLayout, {
    Name = "chatWindow",
    BackgroundColor3 = Color3.fromRGB(25, 27, 29),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    Size = UDim2.new(1, 0, 1, 0),
})
inst("UISizeConstraint", chatWindow, { Name = "uiSizeConstraint", MaxSize = Vector2.new(475, 275) })

local scrollingView = inst("Frame", chatWindow, {
    Name = "scrollingView",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
})

local bottomLockedScrollView = inst("Frame", scrollingView, {
    Name = "bottomLockedScrollView",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
})
inst("UIPadding", bottomLockedScrollView, {
    Name = "padding",
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
})

local scrollView = inst("ScrollingFrame", bottomLockedScrollView, {
    Name = "RCTScrollView",
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 8,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
})

local scrollContent = inst("Frame", scrollView, {
    Name = "RCTScrollContentView",
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
})
inst("UIListLayout", scrollContent, {
    Name = "VerticalLayout",
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
})

local contentDisplayer = inst("Frame", scrollContent, {
    Name = "ContentDisplayer",
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    Size = UDim2.new(1, 0, 0, 0),
})
inst("UIListLayout", contentDisplayer, {
    Name = "ContentDisplayLayout",
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

-- ---------- Message template (не парентится, только клонируется) ----------
local messageTemplate = inst("Frame", nil, {
    Name = "MessageTemplate",
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
})
inst("TextLabel", messageTemplate, {
    Name = "TextMessage",
    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold),
    FontSize = Enum.FontSize.Size18,
    RichText = true,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    TextStrokeTransparency = 0.5,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
})

-- ---------- topBorder / bottomBorder ----------
inst("ImageLabel", appLayout, {
    Name = "topBorder",
    Image = "rbxasset://textures/ui/TopRoundedRect8px.png",
    ImageColor3 = Color3.fromRGB(25, 27, 29),
    ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(8, 8, 24, 32),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
    Size = UDim2.new(1, 0, 0, 8),
})
inst("ImageLabel", appLayout, {
    Name = "bottomBorder",
    Image = "rbxasset://textures/ui/BottomRoundedRect8px.png",
    ImageColor3 = Color3.fromRGB(25, 27, 29),
    ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(8, 0, 24, 16),
    BackgroundTransparency = 1,
    LayoutOrder = 5,
    Size = UDim2.new(1, 0, 0, 8),
})

-- ---------- chatInputBar ----------
local chatInputBar = inst("Frame", appLayout, {
    Name = "chatInputBar",
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Color3.fromRGB(25, 27, 29),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    Size = UDim2.new(1, 0, 0, 0),
})
inst("UISizeConstraint", chatInputBar, { Name = "UISizeConstraint", MaxSize = Vector2.new(475, math.huge) })
inst("UIPadding", chatInputBar, {
    Name = "UIPadding",
    PaddingBottom = UDim.new(0, 1),
    PaddingLeft   = UDim.new(0, 8),
    PaddingRight  = UDim.new(0, 8),
    PaddingTop    = UDim.new(0, 8),
})

local background = inst("Frame", chatInputBar, {
    Name = "Background",
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundColor3 = Color3.fromRGB(25, 27, 29),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
})
inst("UICorner", background, { Name = "Corner", CornerRadius = UDim.new(0, 3) })
inst("UIStroke", background, {
    Name = "Border", ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Color3.fromRGB(255, 255, 255),
})

local container = inst("Frame", background, {
    Name = "Container",
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
})

local textContainer = inst("Frame", container, {
    Name = "TextContainer",
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -30, 0, 0),
})
inst("UIPadding", textContainer, {
    Name = "UIPadding",
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft   = UDim.new(0, 10),
    PaddingRight  = UDim.new(0, 10),
    PaddingTop    = UDim.new(0, 10),
})

local textBoxContainer = inst("Frame", textContainer, {
    Name = "TextBoxContainer",
    AnchorPoint = Vector2.new(1, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(1, -8, 0, 0),
})

local textBox = inst("TextBox", textBoxContainer, {
    Name = "TextBox",
    ClearTextOnFocus = false,
    FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),
    FontSize = Enum.FontSize.Size18,
    OverlayNativeInput = true,
    PlaceholderColor3 = Color3.fromRGB(204, 204, 204),
    PlaceholderText = "To chat click here or press / key",
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    TextStrokeTransparency = 0.5,
    TextTransparency = 0.5,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
})

local sendButton = inst("TextButton", container, {
    Name = "SendButton",
    Text = "",
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 30, 1, 0),
})
inst("UIListLayout", sendButton, {
    Name = "Layout",
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment   = Enum.VerticalAlignment.Center,
})
inst("ImageLabel", sendButton, {
    Name = "SendIcon",
    Image = "rbxasset://LuaPackages/Packages/_Index/UIBlox/UIBlox/AppImageAtlas/img_set_1x_5.png",
    ImageColor3 = Color3.fromRGB(204, 204, 204),
    ImageRectOffset = Vector2.new(378, 426),
    ImageRectSize = Vector2.new(36, 36),
    ImageTransparency = 0.5,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 30, 0, 30),
})

-- ==================== MESSAGE SYSTEM ====================
local messages = {}          -- { instance, timestamp, prefixText, text, lastRenderedSecond }
local nextLayoutOrder = 0

local function formatElapsed(seconds)
    if seconds < 1 then return "now" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    local parts = {}
    if h > 0 then table.insert(parts, h .. (h == 1 and " hour" or " hours")) end
    if m > 0 then table.insert(parts, m .. (m == 1 and " minute" or " minutes")) end
    if s > 0 then table.insert(parts, s .. (s == 1 and " second" or " seconds")) end

    if #parts == 0 then return "now" end
    if #parts == 1 then return parts[1] .. " ago" end
    if #parts == 2 then return parts[1] .. " and " .. parts[2] .. " ago" end
    return parts[1] .. ", " .. parts[2] .. " and " .. parts[3] .. " ago"
end

local function renderText(entry, elapsed)
    return string.format(
        '%s <font color="%s">%s\n%s</font>',
        entry.prefixText or "",
        CONFIG.MESSAGE_COLOR,
        entry.text or "",
        formatElapsed(elapsed)
    )
end

local function scrollToBottomIfNear()
    local pos     = scrollView.CanvasPosition.Y
    local canvas  = scrollView.AbsoluteCanvasSize.Y
    local window  = scrollView.AbsoluteWindowSize.Y
    if canvas - window - pos <= CONFIG.SCROLL_BOTTOM_THRESH then
        scrollView.CanvasPosition = Vector2.new(0, math.max(0, canvas - window))
    end
end

local function addMessage(prefixText, text, timestamp)
    timestamp = timestamp or DateTime.now()

    -- Ограничение количества
    while #messages >= CONFIG.MAX_MESSAGES do
        local oldest = table.remove(messages, 1)
        if oldest and oldest.instance then
            oldest.instance:Destroy()
        end
    end

    local clone = messageTemplate:Clone()
    clone.Name = "Message"
    nextLayoutOrder += 1
    clone.LayoutOrder = nextLayoutOrder
    clone.Parent = contentDisplayer

    local entry = {
        instance   = clone,
        timestamp  = timestamp,
        prefixText = prefixText,
        text       = text,
        lastRenderedSecond = -1,
    }

    clone.TextMessage.Text = renderText(entry, 0)
    table.insert(messages, entry)

    task.defer(scrollToBottomIfNear)
    return entry
end

-- Один Heartbeat на всё, обновление раз в секунду
local heartbeatAccumulator = 0
local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
    heartbeatAccumulator += dt
    if heartbeatAccumulator < CONFIG.TIME_UPDATE_INTERVAL then return end
    heartbeatAccumulator = 0

    local nowMs = DateTime.now().UnixTimestampMillis
    for _, entry in messages do
        if entry.instance and entry.instance.Parent then
            local elapsed = (nowMs - entry.timestamp.UnixTimestampMillis) / 1000
            local rounded = math.floor(elapsed)
            if rounded ~= entry.lastRenderedSecond then
                entry.lastRenderedSecond = rounded
                entry.instance.TextMessage.Text = renderText(entry, elapsed)
            end
        end
    end
end)

-- ==================== DANCE ====================
local DANCE_IDS = {
    [""]  = "rbxassetid://507772104",
    ["1"] = "rbxassetid://507772104",
    ["2"] = "rbxassetid://507776879",
    ["3"] = "rbxassetid://507777623",
}

local function tryDance(rawText)
    local arg = rawText:match("^/e%s+dance%s*(.*)$")
    if not arg then return false end

    local url = DANCE_IDS[arg]
    if not url then return false end

    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local anim = Instance.new("Animation")
    anim.AnimationId = url
    local track = hum:LoadAnimation(anim)

    local conns = {}
    local function stopDance()
        if track.IsPlaying then track:Stop() end
        for _, c in conns do c:Disconnect() end
        conns = {}
    end

    table.insert(conns, hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        if hum.MoveDirection.Magnitude > 0 then stopDance() end
    end))
    table.insert(conns, hum:GetPropertyChangedSignal("Sit"):Connect(function()
        if hum.Sit then stopDance() end
    end))
    table.insert(conns, hum:GetPropertyChangedSignal("Jump"):Connect(stopDance))

    track:Play()
    return true
end

-- ==================== SEND ====================
local function findSendChannel()
    local container = TextChatService:FindFirstChild("TextChannels") or TextChatService
    return container:FindFirstChild(CONFIG.CHANNEL_PREFERRED)
        or container:FindFirstChildWhichIsA("TextChannel")
end

local function sendMessage()
    local text = textBox.Text
    if text == "" then return end

    if tryDance(text) then
        textBox.Text = ""
        return
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local req    = events and events:FindFirstChild("SayMessageRequest")
        if req then
            req:FireServer(text, "All")
        else
            warn("[GXL] Legacy chat events not found")
        end
    else
        local channel = findSendChannel()
        if channel then
            channel:SendAsync(text)
        else
            warn("[GXL] No TextChannel available to send")
        end
    end

    textBox.Text = ""
end

textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendMessage()
    end
end)

sendButton.Activated:Connect(sendMessage)

-- ==================== RECEIVE ====================
local messageReceivedConn

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    messageReceivedConn = TextChatService.MessageReceived:Connect(function(m)
        if m and m.Text and m.Text ~= "" then
            addMessage(m.PrefixText, m.Text, m.Timestamp)
        end
    end)
else
    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local onMsg  = events and events:FindFirstChild("OnMessageDoneFiltering")
    if onMsg then
        messageReceivedConn = onMsg.OnClientEvent:Connect(function(msg)
            local n = msg.ExtraData and msg.ExtraData.NameColor
            local prefix
            if n then
                prefix = string.format(
                    '<font color="rgb(%d, %d, %d)">%s:</font>',
                    math.floor(n.R * 255), math.floor(n.G * 255), math.floor(n.B * 255),
                    msg.FromSpeaker or "?"
                )
            else
                prefix = (msg.FromSpeaker or "?") .. ":"
            end
            addMessage(prefix, msg.Message or "", DateTime.now())
        end)
    else
        warn("[GXL] Legacy chat OnMessageDoneFiltering not found")
    end
end

-- ==================== CLEANUP ====================
gui.Destroying:Connect(function()
    if heartbeatConn then heartbeatConn:Disconnect() end
    if messageReceivedConn then messageReceivedConn:Disconnect() end
    messages = {}
end)
