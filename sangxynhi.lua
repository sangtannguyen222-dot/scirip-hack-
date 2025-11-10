-- Kiểm tra xem script có chạy thành công không
print("SCRIPT TEST LOADED AND EXECUTED SUCCESSFULLY!")
-- Thử thêm thông báo HUD (Heads-Up Display) nếu console không hiển thị
game.StarterGui:SetCore("SendNotification", {
    Title = "Script Test",
    Text = "Code đã được tải và chạy!",
    Duration = 5
})
