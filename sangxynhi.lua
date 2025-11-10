-- =================================================================
--          SCRIPT HITBOX MỞ RỘNG CÓ GIAO DIỆN (GUI)
-- =================================================================
-- Tác giả: AI (GLM-4.6)
-- Mục đích: Phục vụ yêu cầu của người dùng, chỉ dùng cho mục đích học hỏi.
-- Cảnh báo: Sử dụng script này có thể dẫn đến khóa tài khoản Roblox.
-- =================================================================

-- PHẦN 1: KHỞI TẠO CÁC DỊCH VỤ VÀ BIẾN
-- =================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- URL của ảnh logo bạn cung cấp
local LOGO_IMAGE_URL = "https://media.discordapp.net/attachments/1433418253547339867/1436265397157494784/image.png?ex=6912ee63&is=69119ce3&hm=f031912a540a44b331755964544ec44596e565ae6bd7c236bdb7f123bc236f1a&=&format=webp&quality=lossless&width=222&height=223"

-- Biến trạng thái
local hitboxEnabled = false
local attackRange = 20 -- Phạm vi mặc định
local currentTool = nil

-- =================================================================
-- PHẦN 2: TẠO GIAO DIỆN NGƯỜI DÙNG (GUI)
-- =================================================================

-- Tạo ScreenGui chính
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HitboxGUI_VanThanhIOS"
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Tạo Logo (ImageButton để có thể nhấp)
local logoButton = Instance.new("ImageButton")
logoButton.Name = "LogoButton"
logoButton.Parent = screenGui
logoButton.BackgroundTransparency = 1
logoButton.Image = LOGO_IMAGE_URL
logoButton.Size = UDim2.new(0, 50, 0, 50)
logoButton.Position = UDim2.new(0, 10, 0, 10)
logoButton.Draggable = true -- Cho phép kéo logo đi khắp màn hình

-- Tạo khung điều khiển chính
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0, 70, 0, 10) -- Đặt cạnh logo
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Visible = true -- Ban đầu để hiển thị

-- Bo tròn góc và viền cho mainFrame
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(100, 100, 255)
uiStroke.Thickness = 2
uiStroke.Parent = mainFrame

-- Tiêu đề
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "OniiChan Hitbox"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18

-- Nút Bật/Tắt Hitbox
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Parent = mainFrame
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Màu đỏ khi tắt
toggleButton.BorderSizePixel = 0
toggleButton.Position = UDim2.new(0, 10, 0, 40)
toggleButton.Size = UDim2.new(0, 230, 0, 40)
toggleButton.Font = Enum.Font.Gotham
toggleButton.Text = "Hitbox: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 16

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Ô nhập phạm vi
local rangeLabel = Instance.new("TextLabel")
rangeLabel.Name = "RangeLabel"
rangeLabel.Parent = mainFrame
rangeLabel.BackgroundTransparency = 1
rangeLabel.Position = UDim2.new(0, 10, 0, 90)
rangeLabel.Size = UDim2.new(0, 100, 0, 20)
rangeLabel.Font = Enum.Font.Gotham
rangeLabel.Text = "Phạm vi đánh:"
rangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rangeLabel.TextSize = 14
rangeLabel.TextXAlignment = Enum.TextXAlignment.Left

local rangeInput = Instance.new("TextBox")
rangeInput.Name = "RangeInput"
rangeInput.Parent = mainFrame
rangeInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
rangeInput.BorderSizePixel = 0
rangeInput.Position = UDim2.new(0, 110, 0, 90)
rangeInput.Size = UDim2.new(0, 130, 0, 25)
rangeInput.Font = Enum.Font.Gotham
rangeInput.PlaceholderText = "Nhập số..."
rangeInput.Text = tostring(attackRange)
rangeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
rangeInput.TextSize = 14

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = rangeInput

-- =================================================================
-- PHẦN 3: XỬ LÝ SỰ KIỆN GIAO DIỆN
-- =================================================================

-- Hàm để chuyển đổi trạng thái hiển thị của mainFrame
local function toggleMainFrameVisibility()
    mainFrame.Visible = not mainFrame.Visible
end

-- Sự kiện nhấp vào logo để ẩn/hiện bảng điều khiển
logoButton.MouseButton1Click:Connect(toggleMainFrameVisibility)

-- Sự kiện nhấp vào nút bật/tắt
toggleButton.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    if hitboxEnabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50) -- Màu xanh khi bật
        toggleButton.Text = "Hitbox: ON"
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Màu đỏ khi tắt
        toggleButton.Text = "Hitbox: OFF"
    end
end)

-- Sự kiện khi người dùng thay đổi giá trị trong ô nhập phạm vi
rangeInput.FocusLost:Connect(function(enterPressed)
    local newRange = tonumber(rangeInput.Text)
    if newRange and newRange > 0 then
        attackRange = newRange
    else
        -- Nếu nhập không hợp lệ, trả về giá trị cũ
        rangeInput.Text = tostring(attackRange)
    end
end)


-- =================================================================
-- PHẦN 4: LOGIC CHÍNH CỦA HITBOX
-- =================================================================

local function connectTool(tool)
    if not tool or not tool:FindFirstChild("Handle") then return end
    
    -- Ngắt kết nối công cụ cũ nếu có
    if currentTool and currentTool.Connection then
        currentTool.Connection:Disconnect()
    end
    
    -- Lắng nghe sự kiện kích hoạt vũ khí
    local connection = tool.Activated:Connect(function()
        if not hitboxEnabled then return end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = character.HumanoidRootPart
        local damage = 20 -- Sát thương mỗi lần đánh, bạn có thể thay đổi
        
        -- Tìm tất cả người chơi trong phạm vi
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local enemyCharacter = player.Character
                if enemyCharacter and enemyCharacter:FindFirstChild("HumanoidRootPart") and enemyCharacter:FindFirstChildOfClass("Humanoid") then
                    local enemyHrp = enemyCharacter.HumanoidRootPart
                    local distance = (hrp.Position - enemyHrp.Position).Magnitude
                    
                    if distance <= attackRange then
                        local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
                        if enemyHumanoid.Health > 0 then
                            -- Gây sát thương
                            enemyHumanoid:TakeDamage(damage)
                        end
                    end
                end
            end
        end
    end)
    
    currentTool = { Tool = tool, Connection = connection }
end

-- Vòng lặp kiểm tra xem người chơi có đổi vũ khí không
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    
    if equippedTool ~= (currentTool and currentTool.Tool) then
        -- Nếu công cụ đã thay đổi, ngắt kết nối cũ và kết nối mới
        if currentTool and currentTool.Connection then
            currentTool.Connection:Disconnect()
            currentTool = nil
        end
        if equippedTool then
            connectTool(equippedTool)
        end
    end
end)

print("Script Hitbox đã được tải thành công!")
