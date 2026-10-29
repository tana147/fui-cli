# Lessons Learned — LHBS eSign

[tAPI/StoredProcedure] Guard chặn param có default value (= ...) -> Khai báo param thuần túy, gán default bên trong body bằng IF @param IS NULL SET @param = ...
[FUI/Component] Component nằm trong modules/<module>/components/ -> Luôn truyền cờ -m <module> khi chạy fui component update
[SQLServer/tAPI] SQL Server không hỗ trợ hàm LEAST/GREATEST -> Dùng biểu thức CASE WHEN a < b THEN a ELSE b END hoặc IIF để đảm bảo tương thích ngược
[tAPI/Frontend] callTapi() đã unwrap json.data -> Không truy cập res.data lần 2, dùng (res && res.data) ? res.data : res để tránh nuốt kết quả Array
[Vue3/Computed] Fallback trong computed cơ sở gọi chéo computed cấp cao gây circular dependency -> Dùng raw constant fallback
[Vue3/Template] Thẻ đóng lệch hoặc render crash làm trắng nội dung toàn component -> Kiểm tra bằng vue/compiler-sfc và test reactivity trước khi sync
