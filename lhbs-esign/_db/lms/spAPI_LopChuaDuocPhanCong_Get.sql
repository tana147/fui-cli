
CREATE PROCEDURE [dbo].[spAPI_LopChuaDuocPhanCong_Get]
    @CapID INT -- Tham số lọc theo CapID, có thể NULL
AS
BEGIN
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    SET NOCOUNT ON;

    -- Lấy danh sách lớp học chưa được phân công môn học
    SELECT 
        L.LopID, 
        L.TenLop, 
        MH.MonHocID, 
        MH.MonHocName
    FROM 
        dbo.tblLop L
    CROSS JOIN 
        dbo.tblMonHoc MH -- Kết hợp tất cả các lớp với tất cả các môn học
    LEFT JOIN 
        dbo.tblGiaoVienLop GVL 
        ON L.LopID = GVL.LopID AND L.NienKhoa = GVL.NienKhoa AND MH.MonHocID = GVL.MonHocID
    WHERE
        L.NienKhoa = @NienKhoa
        AND GVL.GVLopID IS NULL -- Chỉ lấy các lớp và môn học chưa có trong tblGiaoVienLop
        AND MH.CapID = L.CapID -- Lọc theo CapID trong MonHoc và Lop
        AND (@CapID IS NULL OR L.CapID = @CapID) -- Lọc theo CapID nếu được nhập
    ORDER BY 
        L.TenLop, MH.MonHocName; -- Sắp xếp theo tên lớp và tên môn học
END;

