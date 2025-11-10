-- =========================================================
-- KHỞI TẠO CẤU HÌNH VÀ BIẾN
-- =========================================================
local Config = {
    HitboxEnabled = false,
    Range = 15, -- Phạm vi mặc định
    GUIVisible = true -- Bắt đầu với trạng thái hiển thị (dễ gỡ lỗi)
}

-- [ Giả định các đối tượng Game ]
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local LOGO_URL = "https://media.discordapp.net/attachments/1433418253547339867/1436265397157494784/image.png?ex=6912ee63&is=69119ce3&hm=f031912a540a44b331755964544ec445ec94a11b6d0865ae6bd7c236bdb7f123bc236f1a&=&format=webp&quality=lossless&width=222&height=223"

-- == [ 1. TẠO GIAO DIỆN NGƯỜI DÙNG (GUI) ] ==

-- Sử dụng API GUI tiêu chuẩn của Executor (thường là V3rm/Custom)
-- **LƯU Ý:** Nếu script vẫn không chạy, bạn cần kiểm tra chính xác hàm tạo GUI
-- của Solara V3. Tôi đang dùng hàm 'LoadLibrary' phổ biến nhất.

local GUI_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/v3rmillion-gui-library/main/Library.lua"))()

local Window = GUI_Library:CreateWindow({
    Title = "⚡ Hitbox Extender Script",
    Center = true,
    MinSize = { 300, 200 },
    MaxSize = { 300, 400 },
    ToggleKey = Enum.KeyCode.RightControl -- Ví dụ: Dùng Ctrl Phải để ẩn/hiện
})

-- Tạo một Tab chính
local MainTab = Window:AddTab({ Title = "Hitbox Settings" })

-- [ A. Toggle Hitbox ]
MainTab:AddToggle({
    Title = "Hitbox ON/OFF",
    Default = Config.HitboxEnabled,
    Callback = function(state)
        Config.HitboxEnabled = state
        print("[Config] Hitbox Extender Toggled: " .. tostring(state))
    end
})

-- [ B. Range Slider ]
MainTab:AddSlider({
    Title = "Phạm vi đánh (Studs)",
    Min = 5,
    Max = 50,
    Default = Config.Range,
    Callback = function(value)
        Config.Range = value
        print("[Config] Phạm vi đánh được đặt thành: " .. value)
    end
})

-- ** THIẾU LOGO TOGGLE **
-- Solara V3 không hỗ trợ dễ dàng nút bấm hình ảnh như GUI tôi giả định.
-- Tôi đã thay thế nó bằng một phím tắt mặc định (Ctrl Phải) cho Window.


-- == [ 2. LOGIC XỬ LÝ HITBOX VÀ HOOK ] ==

local function FindTargetInProximity()
    if not Config.HitboxEnabled or not Character:FindFirstChild("HumanoidRootPart") then return nil end

    local ClosestDistance = Config.Range + 1
    local MyPosition = Character.HumanoidRootPart.Position

    -- Lặp qua người chơi (Giữ nguyên logic cũ)
    for _, Player in ipairs(game.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            local TargetHRP = Player.Character:FindFirstChild("HumanoidRootPart")
            if TargetHRP then
                local Distance = (MyPosition - TargetHRP.Position).Magnitude
                if Distance <= Config.Range and Distance < ClosestDistance then
                    ClosestDistance = Distance
                    return Player
                end
            end
        end
    end
    return nil
end

-- == [ 3. Xử lý Hành động Đánh (Hooking) ] ==

-- Kiểm tra xem hàm tấn công có thể được hook hay không
local Weapon = Character:FindFirstChildWhichIsA("Tool")

if Weapon and Weapon:FindFirstChild("RemoteEvent") then
    local AttackEvent = Weapon:FindFirstChild("RemoteEvent")
    
    if AttackEvent then
        local OldAttackFunction = nil

        -- Solara/V3 thường hỗ trợ 'hookfunction'
        OldAttackFunction = hookfunction(AttackEvent.FireServer, function(self, ...)
            if not Config.HitboxEnabled then
                return OldAttackFunction(self, ...)
            end

            local TargetPlayer = FindTargetInProximity()

            if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local TargetHRP = TargetPlayer.Character.HumanoidRootPart
                print("[Attack] Chuyển mục tiêu thành công: " .. TargetPlayer.Name)
                
                -- Cố gắng thay đổi tham số RemoteEvent thành vị trí mục tiêu mới
                return OldAttackFunction(self, TargetHRP.Position) 
            else
                return OldAttackFunction(self, ...)
            end
        end)
        print("[Script] Hitbox Extender Hooked thành công! (Dùng Ctrl Phải để ẩn/hiện GUI)")
    end
end
