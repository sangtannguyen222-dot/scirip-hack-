-- Khởi tạo biến cấu hình
local Config = {
    HitboxEnabled = false,
    Range = 15, -- Phạm vi mặc định là 15 Studs/Đơn vị
    GUIVisible = false -- Trạng thái ẩn/hiện của bảng chính
}

-- [ Giả định các đối tượng Game ]
local LocalPlayer = Game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- URL của hình ảnh logo bạn cung cấp
local LOGO_URL = "https://media.discordapp.net/attachments/1433418253547339867/1436265397157494784/image.png?ex=6912ee63&is=69119ce3&hm=f031912a540a44b331755964544ec445ec94a11b6d0865ae6bd7c236bdb7f123bc236f1a&=&format=webp&quality=lossless&width=222&height=223"

-- == [ 1. Tạo Giao Diện Người Dùng (GUI) ] ==

-- Giả định sử dụng một thư viện GUI có khả năng tạo cả nút bấm hình ảnh và cửa sổ
local GUI_Library = DrawingLibrary:New() 

-- [ A. Tạo Cửa Sổ Chính ]
local Main_Window = GUI_Library:CreateWindow("⚡ Hitbox Extender Script")
Main_Window:SetVisibility(Config.GUIVisible) -- Bắt đầu với trạng thái ẩn

-- Thêm các điều khiển vào cửa sổ chính
local HitboxToggle = Main_Window:AddToggle("Hitbox ON/OFF", Config.HitboxEnabled, function(state)
    Config.HitboxEnabled = state
    print("[Config] Hitbox Extender Toggled: " .. tostring(state))
end)

local RangeSlider = Main_Window:AddSlider("Phạm vi đánh (Studs)", Config.Range, {
    Min = 5,
    Max = 50,
    Step = 1
}, function(value)
    Config.Range = value
    print("[Config] Phạm vi đánh được đặt thành: " .. value)
end)


-- [ B. Tạo Nút Bấm Logo (Toggle Button) ]
local Logo_Button = GUI_Library:AddImageButton({
    Image = LOGO_URL,
    Position = {X = 50, Y = 50}, -- Vị trí mặc định trên màn hình
    Size = {Width = 50, Height = 50}
})

-- Hàm xử lý khi bấm vào Logo
Logo_Button:SetCallback(function()
    Config.GUIVisible = not Config.GUIVisible -- Đảo ngược trạng thái
    Main_Window:SetVisibility(Config.GUIVisible) -- Cập nhật trạng thái hiển thị của cửa sổ chính
    print("[GUI] Bảng chính hiện/ẩn: " .. tostring(Config.GUIVisible))
end)


-- == [ 2. Logic Xử Lý Hitbox và Phạm Vi (Giống phiên bản trước) ] ==

local function FindTargetInProximity()
    if not Config.HitboxEnabled then return nil end

    local ClosestDistance = Config.Range + 1
    local MyPosition = Character.HumanoidRootPart.Position

    for _, Player in ipairs(Game.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            local TargetHRP = Player.Character:FindFirstChild("HumanoidRootPart")
            if TargetHRP then
                local Distance = (MyPosition - TargetHRP.Position).Magnitude
                if Distance <= Config.Range and Distance < ClosestDistance then
                    ClosestDistance = Distance
                    return Player -- Trả về mục tiêu ngay khi tìm thấy
                end
            end
        end
    end
    return nil
end

-- == [ 3. Xử lý Hành động Đánh (Hooking) ] ==

local Weapon = Character:FindFirstChildWhichIsA("Tool")

if Weapon then
    -- Giả định có một RemoteEvent để tấn công
    local AttackEvent = Weapon:FindFirstChild("RemoteEvent")
    
    if AttackEvent then
        local OldAttackFunction = nil

        -- Móc nối vào hàm gửi dữ liệu lên Server
        OldAttackFunction = hookfunction(AttackEvent.FireServer, function(self, ...)
            if not Config.HitboxEnabled then
                return OldAttackFunction(self, ...) -- Chạy hàm gốc nếu tắt
            end

            local TargetPlayer = FindTargetInProximity()

            if TargetPlayer then
                local TargetHRP = TargetPlayer.Character.HumanoidRootPart
                print("[Attack] Đánh thành công! Chuyển mục tiêu sang: " .. TargetPlayer.Name)

                -- Trong môi trường thực, bạn sẽ cố gắng thay đổi tham số
                -- sao cho server nghĩ rằng người chơi đang tấn công TargetHRP.Position
                -- Đây là một ví dụ thay đổi tham số:
                return OldAttackFunction(self, TargetHRP.Position) 
            else
                return OldAttackFunction(self, ...) -- Chạy hàm gốc nếu không có mục tiêu
            end
        end)
        print("[Script] Hitbox Extender Hooked thành công!")
    end
end
