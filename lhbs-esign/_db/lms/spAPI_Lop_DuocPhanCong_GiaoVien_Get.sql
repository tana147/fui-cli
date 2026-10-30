

CREATE PROCEDURE [dbo].[spAPI_Lop_DuocPhanCong_GiaoVien_Get]
    @GiaoVienID NVARCHAR(50), -- Lọc theo ID giáo viên (có thể NULL)
    @NienKhoa INT,            -- Niên khóa (có thể NULL)
    @ToGiangDayID INT         -- Lọc theo tổ giảng dạy (có thể NULL)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy danh sách tất cả các lớp đã được phân công
    SELECT DISTINCT
        GVL.GVLopID,
        GVL.GiaoVienID,
        GV.HoGV + N' ' + GV.TenGV AS HoTenGV,
        GVL.LopID,
        L.TenLop,
        GVL.MonHocID,
        MH.MonHocName,
        GVL.VaiTro,
        GVL.ToGiangDayID,
        GVL.NienKhoa
    FROM 
        tblGiaoVienLop GVL
    INNER JOIN 
        tblGiaoVien GV ON GVL.GiaoVienID = GV.GiaoVienID
    INNER JOIN 
        tblLop L ON GVL.LopID = L.LopID AND L.NienKhoa = GVL.NienKhoa
    LEFT JOIN 
        tblMonHoc MH ON GVL.MonHocID = MH.MonHocID
    WHERE 
        GVL.Enable = 1
        AND (@NienKhoa IS NULL OR GVL.NienKhoa = @NienKhoa) -- Lọc theo NienKhoa nếu có
        AND (@GiaoVienID IS NULL OR GVL.GiaoVienID = @GiaoVienID) -- Lọc theo GiaoVienID nếu có
        AND (@ToGiangDayID IS NULL OR GVL.ToGiangDayID = @ToGiangDayID) -- Lọc theo ToGiangDayID nếu có
    ORDER BY 
        L.TenLop, MH.MonHocName;
END;