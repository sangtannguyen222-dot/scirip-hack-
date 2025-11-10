-- =========================================================================
-- SCRIPT HITBOX EXTENDER - PHIÊN BẢN KHÔNG GUI (Dành cho Solara V3)
-- MỤC ĐÍCH: Kiểm tra khả năng chạy của logic chính và hàm hookfunction.
-- CHỨC NĂNG: Tự động nhắm mục tiêu gần nhất trong phạm vi khi bạn tấn công.
-- =========================================================================

print("--- SCRIPT HITBOX EXTENDER (NO GUI) LOADED ---")

-- KHỞI TẠO CẤU HÌNH CỐ ĐỊNH
local Config = {
    HitboxEnabled = true, -- BẬT MẶC ĐỊNH để chạy ngay lập tức
    Range = 25,            -- Phạm vi đánh mặc định 25 studs (Bạn có thể sửa số này thủ công)
}

-- [ Giả định các đối tượng Game ]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Khởi tạo nhân vật (đảm bảo script chờ nhân vật tải xong)
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RunService = game:GetService("RunService")

-- == [ 1. LOGIC XỬ LÝ HITBOX ] ==

-- Hàm tìm HumanoidRootPart của mục tiêu gần nhất trong phạm vi
local function FindTargetInProximity()
    -- Kiểm tra nếu chức năng không được bật hoặc người chơi chưa có nhân vật
    if not Config.HitboxEnabled or not Character:FindFirstChild("HumanoidRootPart") then return nil end

    local ClosestDistance = Config.Range + 1
    local MyPosition = Character.HumanoidRootPart.Position

    for _, Player in ipairs(Players:GetPlayers()) do
        -- Loại bỏ bản thân và kiểm tra Humanoid còn sống
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character.Humanoid.Health > 0 then
            local TargetHRP = Player.Character:FindFirstChild("HumanoidRootPart")
            if TargetHRP then
                local Distance = (MyPosition - TargetHRP.Position).Magnitude
                
                if Distance <= Config.Range and Distance < ClosestDistance then
                    ClosestDistance = Distance
                    return TargetHRP -- Trả về HumanoidRootPart của mục tiêu
                end
            end
        end
    end
    return nil
end

-- == [ 2. Xử lý Hành động Đánh (Hooking) ] ==

local function SetupAttackHook()
    local Weapon = Character:FindFirstChildWhichIsA("Tool")

    -- Phương pháp Hook phổ biến: tìm RemoteEvent trong Tool
    if Weapon and Weapon:FindFirstChild("RemoteEvent") then
        local AttackEvent = Weapon:FindFirstChild("RemoteEvent")
        
        if AttackEvent then
            local OldFireServer = nil

            -- Thử Hook (Móc nối hàm FireServer)
            OldFireServer = hookfunction(AttackEvent.FireServer, function(self, ...)
                if not Config.HitboxEnabled then
                    return OldFireServer(self, ...)
                end

                local TargetHRP = FindTargetInProximity()

                if TargetHRP then
                    print("[Hook] Chuyển mục tiêu thành công: " .. TargetHRP.Parent.Name)
                    
                    local args = {...} -- Lấy tất cả tham số tấn công ban đầu
                    
                    -- Thay thế tham số đầu tiên bằng vị trí của mục tiêu gần nhất.
                    args[1] = TargetHRP.Position
                    
                    -- Trả về hàm cũ với tham số mới
                    return OldFireServer(self, unpack(args)) 
                else
                    -- Không tìm thấy mục tiêu, tấn công như bình thường
                    return OldFireServer(self, ...)
                end
            end)
            print("[Hook] Hitbox Extender Hooked thành công! Phạm vi: " .. Config.Range)
            print("[Hook] CẦM VŨ KHÍ và TẤN CÔNG để kiểm tra!")
        else
            print("[LỖI HOOK] Không tìm thấy RemoteEvent trong Tool.")
        end
    else
        print("[LỖI HOOK] Vui lòng trang bị vũ khí (Tool) để Hook script.")
    end
end

-- Chờ nhân vật tải xong rồi thiết lập Hook
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    SetupAttackHook()
end)

-- Lần chạy đầu tiên (nếu nhân vật đã tải)
SetupAttackHook()

print("--- SCRIPT HOÀN TẤT. KIỂM TRA CONSOLE/OUTPUT LOG CỦA SOLARA V3 ---")
