CREATE PROC [dbo].[spAPI_DEV_CGCN_Get_ByID]
    @CGCNID INT
AS
BEGIN
    SET NOCOUNT ON;

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
    FROM dbo.ChuyenGiaoCongNghe_DEV cn
    LEFT JOIN dbo.NhanVien nv ON cn.NhanVienSubmit = nv.MaNV
    LEFT JOIN dbo.TaiKhoan tk ON cn.NhanVienSubmit = tk.MaNV
    WHERE cn.CGCNID = @CGCNID;
END;
