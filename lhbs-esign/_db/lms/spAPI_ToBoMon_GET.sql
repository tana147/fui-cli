CREATE PROCEDURE spAPI_ToBoMon_GET
    @ToGiangDayID INT = NULL,        -- Tham số lọc theo ToID (nếu cần)
    @CapID INT = NULL,               -- Tham số lọc theo CapID (nếu cần)
    @ToDayName NVARCHAR(255) = NULL  -- Tham số lọc theo tên tổ giảng dạy (nếu cần)
AS
BEGIN
    -- Tắt thông báo số hàng bị ảnh hưởng
    SET NOCOUNT ON;

    -- Lấy dữ liệu từ bảng tblToGiangDay
    SELECT 
        ToGiangDayID, 
        ToDayName, 
        NienKhoa,
        HocKy,
        CapID,
        GhiChu
    FROM 
        [LMS-LHBS].dbo.tblToGiangDay
    WHERE
        (@ToGiangDayID IS NULL OR ToGiangDayID = @ToGiangDayID)  -- Lọc theo ToGiangDayID
        AND (@ToDayName IS NULL OR ToDayName LIKE '%' + @ToDayName + '%') -- Lọc gần đúng theo tên
        AND (@CapID IS NULL OR CapID = @CapID) -- Lọc chính xác theo CapID
        AND [LMS-LHBS].dbo.tblToGiangDay.Enable = 1   -- Chỉ lấy các tổ đang hoạt động
    ORDER BY 
        ToDayName; -- Sắp xếp theo tên tổ giảng dạy
END;