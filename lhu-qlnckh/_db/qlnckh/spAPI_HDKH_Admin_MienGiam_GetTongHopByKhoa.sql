CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_MienGiam_GetTongHopByKhoa]
    @NamHoc INT,
    @KhoaID VARCHAR(50),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- ======================================================================
        -- THÊM CỘT STT SỬ DỤNG ROW_NUMBER()
        -- Sắp xếp theo Tên, sau đó là Họ để đảm bảo thứ tự đúng
        -- ======================================================================
        ROW_NUMBER() OVER (ORDER BY NV.Ten, NV.HoTen) AS STT,

        NV.MaNV AS NhanVienID,
        NV.HoTen,
		HV.TenChucDanh AS HocVi ,
        NV.HocViID,
		NV.ChucVu,
		HV.DinhMucGioChuan,
        ISNULL(MienGiamData.TongSoGioMienGiam, 0) AS TongSoGioMienGiam,
        MienGiamData.DanhSachLyDo,
        Is_ThamGiaNCKH

    FROM dbo.NhanVien AS NV
	LEFT JOIN [dbo].[tblHDKH_DM_ChucDanhHocVi] HV ON NV.HocViID = HV.ID
    LEFT JOIN (
        SELECT
            NhanVienID,
            SUM(SoGioMienGiam) AS TongSoGioMienGiam,
            STUFF((
                SELECT '; ' + ISNULL(LyDo, N'Không có lý do')
                FROM dbo.tblHDKH_MienGiam
                WHERE NhanVienID = MG.NhanVienID AND NamHoc = @NamHoc AND IsDeleted = 0
                FOR XML PATH('')
            ), 1, 2, '') AS DanhSachLyDo
        FROM dbo.tblHDKH_MienGiam AS MG
        WHERE NamHoc = @NamHoc AND IsDeleted = 0
        GROUP BY NhanVienID
    ) AS MienGiamData ON NV.MaNV = MienGiamData.NhanVienID
    WHERE NV.MaDonVi = @KhoaID AND NV.IsActive = 1
    -- Bỏ ORDER BY ở đây vì đã có trong OVER()
    -- Tuy nhiên, để chắc chắn, vẫn có thể giữ lại
    ORDER BY NV.Ten, NV.HoTen;

END
