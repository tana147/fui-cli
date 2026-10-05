CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetKeKhaiByGiangVien] --'NV0000202', 2025, 'gv0000611',''
    @NhanVienID VARCHAR(9),
    @NamHoc INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) -- Giữ lại cho đúng chuẩn
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy danh sách các hoạt động mà giảng viên được chỉ định có tham gia
    SELECT
        S.SubmissionID,
        F.FormTitle,
        -- Lấy tên hoạt động từ FieldValue
        ISNULL((
            SELECT TOP 1 FV.FieldValue
            FROM dbo.tblHDKH_KeKhai_FieldValue AS FV
            JOIN dbo.tblHDKH_Field_Definition AS FD ON FV.FieldID = FD.FieldID
            WHERE FV.SubmissionID = S.SubmissionID AND FV.IsDeleted = 0
            ORDER BY FD.SortOrder ASC
        ), N'Không có tiêu đề') AS TenHoatDong_CuThe,
        S.CreateTime,
        
        -- ======================================================================
        -- SỬA LẠI LOGIC LẤY THÔNG TIN TRONG JSON_DATA
        -- ======================================================================
        json_data = (
            SELECT
                TV.ThanhVienID,
                TV.isNhanVienLHU,
                TV.NhanVienID AS MaThanhVien,
                TV.HoTen AS HoTenThanhVien,
                DMV.TenVaiTro, 
                TV.ViTri,
                TV.isTacGiaLienHe,
                
                -- Chỉ trả về kết quả cho nhân viên LHU
                KQC.KetQuaID AS KetQuaID,
                KQC.SoGioQuyDoi_CaNhan AS SoGio_HeThongTinh,
                isnull(KQC.SoGio_DaDuyet,0) SoGio_DaDuyet,
                KQC.TrangThaiDuyet, 
                KQC.GhiChuTuChoi,
                KQC.NguoiDuyet,
                KQC.NgayDuyet,
				KQC.DienGiaiCachTinh
                
            FROM dbo.tblHDKH_KeKhai_ThanhVien AS TV
            -- LEFT JOIN để lấy kết quả (chỉ có cho nhân viên LHU)
            LEFT JOIN dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC 
                ON TV.SubmissionID = KQC.SubmissionID 
                AND TV.NhanVienID = KQC.NhanVienID
                AND KQC.IsDeleted = 0
            LEFT JOIN dbo.tblHDKH_DM_VaiTro AS DMV ON TV.VaiTroID = DMV.ID
            WHERE TV.SubmissionID = S.SubmissionID AND TV.IsDeleted = 0
            ORDER BY TV.ViTri, TV.ThanhVienID
            FOR JSON PATH
        )
    FROM dbo.tblHDKH_KeKhai_Submission AS S
    JOIN dbo.tblHDKH_Form_Definition AS F ON S.FormID = F.FormID
    WHERE 
        S.IsDeleted = 0
        AND S.NamHoc = @NamHoc
        AND EXISTS (
            SELECT 1 
            FROM dbo.tblHDKH_KeKhai_ThanhVien AS TV
            WHERE TV.SubmissionID = S.SubmissionID AND TV.NhanVienID = @NhanVienID AND TV.isNhanVienLHU = 1 AND TV.IsDeleted = 0
        )
    ORDER BY S.CreateTime DESC;

END;
