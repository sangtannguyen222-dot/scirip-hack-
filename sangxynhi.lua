-- =========================================================================
-- SCRIPT HITBOX EXTENDER - Tối ưu cho Executor Solara V3 (dùng API chuẩn V3rmillion)
-- TÁC DỤNG: Can thiệp để tấn công kẻ địch gần nhất trong một phạm vi nhất định.
-- LƯU Ý: Nếu GUI không hiện, bạn cần thay thế các hàm GUI_Library bằng API của Solara V3.
-- =========================================================================

-- KHỞI TẠO CẤU HÌNH VÀ BIẾN
local Config = {
    HitboxEnabled = false, -- Trạng thái tắt/mở chức năng Hitbox
    Range = 15,            -- Phạm vi đánh mặc định (Studs)
    GUIVisible = true      -- Trạng thái hiển thị của cửa sổ chính
}

-- [ Giả định các đối tượng Game ]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Logo URL (Đã sửa lại để không bị lỗi ký tự đặc biệt)
local LOGO_URL = "https://media.discordapp.net/attachments/1433418253547339867/1436265397157494784/image.png?width=222&height=223"

-- == [ 1. TẠO GIAO DIỆN NGƯỜI DÙNG (GUI) ] ==

-- Hầu hết các Executor hiện đại dùng một thư viện chung (V3rmillion/K.O.L)
-- Lệnh này sẽ cố gắng tải thư viện đó. Nếu Solara V3 có API khác, lỗi sẽ ở đây.
local GUI_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/v3rmillion-gui-library/main/Library.lua"))()

local Window = GUI_Library:CreateWindow({
    Title = "⚡ Hitbox Extender (Solara V3)",
    Center = true,
    MinSize = { 300, 200 },
    MaxSize = { 300, 400 },
    -- ToggleKey được dùng để ẩn/hiện GUI
    ToggleKey = Enum.KeyCode.RightControl -- Ví dụ: Ctrl Phải để ẩn/hiện
})

local MainTab = Window:AddTab({ Title = "Chức năng Chính" })

-- [ A. Toggle Hitbox ON/OFF ]
MainTab:AddToggle({
    Title = "Hitbox Extender ON/OFF",
    Default = Config.HitboxEnabled,
    Callback = function(state)
        Config.HitboxEnabled = state
        print("[Hitbox] Trạng thái: " .. tostring(state))
    end
})

-- [ B. Range Slider (Phạm vi đánh) ]
MainTab:AddSlider({
    Title = "Phạm vi đánh (Studs)",
    Min = 5,
    Max = 50, -- Phạm vi tối đa
    Default = Config.Range,
    Decimals = 0, -- Không có số thập phân
    Callback = function(value)
        Config.Range = value
        print("[Hitbox] Phạm vi đặt thành: " .. value .. " studs")
    end
})

-- [ C. Logo Button (Nút ẩn/hiện GUI) ]
-- Do các API GUI không dễ dàng hỗ trợ nút bấm hình ảnh, chúng ta sẽ mô phỏng
-- hành vi này bằng một nút bấm có URL logo trong tiêu đề (tùy thuộc vào Executor).
-- Hoặc đơn giản là dùng phím tắt Ctrl Phải (ToggleKey) đã định nghĩa ở trên.

-- Thêm một nút thông báo (chỉ để đẹp)
MainTab:AddButton({
    Title = "Sử dụng phím Ctrl Phải để Ẩn/Hiện",
    Callback = function()
        print("Nhấn Ctrl Phải để ẩn/hiện cửa sổ.")
    end
})

-- == [ 2. LOGIC XỬ LÝ HITBOX VÀ HOOK ] ==

-- Hàm tìm mục tiêu gần nhất trong phạm vi
local function FindTargetInProximity()
    if not Config.HitboxEnabled or not Character:FindFirstChild("HumanoidRootPart") then return nil end

    local ClosestDistance = Config.Range + 1
    local MyPosition = Character.HumanoidRootPart.Position

    for _, Player in ipairs(Players:GetPlayers()) do
        -- Loại bỏ người chơi cục bộ (bản thân) và kiểm tra Humanoid
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character.Humanoid.Health > 0 then
            local TargetHRP = Player.Character:FindFirstChild("HumanoidRootPart")
            if TargetHRP then
                local Distance = (MyPosition - TargetHRP.Position).Magnitude
                
                -- Nếu khoảng cách nằm trong phạm vi cho phép
                if Distance <= Config.Range and Distance < ClosestDistance then
                    ClosestDistance = Distance
                    return TargetHRP -- Trả về HumanoidRootPart của mục tiêu
                end
            end
        end
    end
    return nil
end

-- == [ 3. Xử lý Hành động Đánh (Hooking) ] ==

-- Chờ cho nhân vật xuất hiện và tìm RemoteEvent
local function SetupAttackHook()
    -- Cần phải chờ vũ khí được trang bị để tìm RemoteEvent
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        Character:WaitForChild("HumanoidRootPart")

        local Weapon = Character:FindFirstChildWhichIsA("Tool")
        if not Weapon then
            -- Nếu không phải Tool, có thể là LocalScript xử lý việc đánh.
            -- Cần thêm logic phức tạp hơn cho từng game.
            print("[Hook] KHÔNG tìm thấy Tool được trang bị.")
        end

        -- Nếu tìm thấy RemoteEvent trong Tool (Phương pháp phổ biến)
        if Weapon and Weapon:FindFirstChild("RemoteEvent") then
            local AttackEvent = Weapon:FindFirstChild("RemoteEvent")
            
            local OldFireServer = nil

            -- Thử Hook (Móc nối hàm FireServer)
            OldFireServer = hookfunction(AttackEvent.FireServer, function(self, ...)
                if not Config.HitboxEnabled then
                    return OldFireServer(self, ...)
                end

                local TargetHRP = FindTargetInProximity()

                if TargetHRP then
                    print("[Hook] Chuyển mục tiêu thành công: " .. TargetHRP.Parent.Name)
                    
                    -- Hầu hết các game gửi vị trí hit/mục tiêu làm tham số đầu tiên
                    -- Thay thế tham số tấn công bằng vị trí của mục tiêu gần nhất
                    return OldFireServer(self, TargetHRP.Position) 
                else
                    -- Không tìm thấy mục tiêu, vẫn tấn công bình thường
                    return OldFireServer(self, ...)
                end
            end)
            print("[Hook] Hitbox Extender Hooked thành công! ")
        end
    end)
end

-- Bắt đầu thiết lập Hook ngay lập tức
SetupAttackHook()

-- == [ 4. Xử lý Ẩn/Hiện GUI ] ==

-- Nếu muốn nút Logo ẩn/hiện, bạn cần Executor hỗ trợ chức năng Logo:
-- Vì Solara V3 không có API chuẩn cho nút logo/toggle, chúng ta chỉ dựa vào ToggleKey (Ctrl Phải)
-- và các nút trong GUI chính.
print("[HƯỚNG DẪN] Nhấn phím Ctrl Phải (RightControl) để ẩn/hiện cửa sổ GUI.")
