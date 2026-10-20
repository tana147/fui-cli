CREATE PROC [dbo].[spAPI_DEV_CGCN_Get]
    @TrangThai INT,
    @NamHoc VARCHAR(10),
    @TuKhoa NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Resultset chính: Danh sách hợp đồng CGCN
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
        cn.TrangThai,
        cn.ThoiGianSubmit,
        cn.LyDoReject,
        cn.NguoiDuyet,
        cn.ThoiGianDuyet,
        cn.ThoiGianCapNhat
    FROM dbo.ChuyenGiaoCongNghe_DEV cn
    WHERE cn.Is_Xoa = 0
      AND (@TrangThai IS NULL OR @TrangThai = 0 OR cn.TrangThai = @TrangThai)
      AND (@NamHoc IS NULL OR @NamHoc = '' OR cn.NamHoc = @NamHoc)
      AND (@TuKhoa IS NULL OR @TuKhoa = '' OR (
          cn.TenDuAn LIKE N'%' + @TuKhoa + N'%' OR
          cn.ChuNhiemDeTai LIKE N'%' + @TuKhoa + N'%' OR
          cn.DonViTiepNhan LIKE N'%' + @TuKhoa + N'%' OR
          cn.SoHopDong LIKE N'%' + @TuKhoa + N'%'
      ))
    ORDER BY cn.[CGCNID] DESC;

    -- 2. Resultset 2: Đếm số lượng theo trạng thái cho Admin
    SELECT 
        COUNT(*) AS TotalAll,
        SUM(CASE WHEN cn.TrangThai = 1 THEN 1 ELSE 0 END) AS CountDraft,
        SUM(CASE WHEN cn.TrangThai = 2 THEN 1 ELSE 0 END) AS CountPending,
        SUM(CASE WHEN cn.TrangThai = 3 THEN 1 ELSE 0 END) AS CountApproved,
        SUM(CASE WHEN cn.TrangThai = 4 THEN 1 ELSE 0 END) AS CountRejected
    FROM dbo.ChuyenGiaoCongNghe_DEV cn
    WHERE cn.Is_Xoa = 0
      AND (@NamHoc IS NULL OR @NamHoc = '' OR cn.NamHoc = @NamHoc);
END;