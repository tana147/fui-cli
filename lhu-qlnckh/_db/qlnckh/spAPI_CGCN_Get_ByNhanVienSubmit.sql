CREATE PROC [dbo].[spAPI_CGCN_Get_ByNhanVienSubmit]
    @NhanVienSubmit CHAR(9),
    @TrangThai INT,
    @NamHoc VARCHAR(10),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserCheck VARCHAR(9) = ISNULL(@NhanVienSubmit, @sys_UserID);

    -- 1. Resultset chính: Các hồ sơ của user này
    SELECT 
        cn.[CGCNID],
        cn.[SoThuTu],
        cn.[TenDuAn],
        cn.[ChuNhiemDeTai],
        cn.[ThanhVienDeTai],
        cn.[DonViChuNhiem],
        cn.[DonViTiepNhan],
        cn.[GiaTriHopDong],
        cn.[NamThucHien],
        cn.[SoHopDong],
        cn.[FileID_List],
        (
            SELECT 
                fd.FileID AS [FILE_ID], 
                fd.[FileName] AS [FILE_NAME], 
                fd.Size AS [FILE_SIZE]
            FROM dbo.FileData fd
            WHERE fd.FileID IN (SELECT Data FROM [dbo].[FN_STRING_SPLIT](cn.[FileID_List], ','))
            FOR JSON PATH
        ) AS [FileData],
        cn.NamHoc,
        cn.NhanVienSubmit,
        COALESCE(nv.HoTen, LTRIM(RTRIM(CONCAT(tk.HoNV, ' ', tk.TenNV))), cn.NhanVienSubmit) AS TenNhanVienSubmit,
        cn.TrangThai,
        cn.ThoiGianSubmit,
        cn.LyDoReject,
        cn.NguoiDuyet,
        cn.ThoiGianDuyet,
        cn.ThoiGianCapNhat
    FROM dbo.ChuyenGiaoCongNghe cn
    LEFT JOIN dbo.NhanVien nv ON cn.NhanVienSubmit = nv.MaNV
    LEFT JOIN dbo.TaiKhoan tk ON cn.NhanVienSubmit = tk.MaNV
    WHERE cn.Is_Xoa = 0
      AND (cn.NhanVienSubmit = @UserCheck OR cn.NhanVienCapNhat = @UserCheck)
      AND (@TrangThai IS NULL OR @TrangThai = 0 OR cn.TrangThai = @TrangThai)
      AND (@NamHoc IS NULL OR @NamHoc = '' OR cn.NamHoc = @NamHoc)
    ORDER BY cn.[CGCNID] DESC;

    -- 2. Resultset 2: Đếm số lượng theo trạng thái để hiển thị badge trên tab
    SELECT 
        COUNT(*) AS TotalAll,
        SUM(CASE WHEN cn.TrangThai = 1 THEN 1 ELSE 0 END) AS CountDraft,
        SUM(CASE WHEN cn.TrangThai = 2 THEN 1 ELSE 0 END) AS CountPending,
        SUM(CASE WHEN cn.TrangThai = 3 THEN 1 ELSE 0 END) AS CountApproved,
        SUM(CASE WHEN cn.TrangThai = 4 THEN 1 ELSE 0 END) AS CountRejected
    FROM dbo.ChuyenGiaoCongNghe cn
    WHERE cn.Is_Xoa = 0
      AND (cn.NhanVienSubmit = @UserCheck OR cn.NhanVienCapNhat = @UserCheck);
END;
