CREATE pROCEDURE [dbo].[spAPI_HDKH_KeKhai_GetSubmissionDetail] -- 102,''
    @SubmissionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sự tồn tại của Submission
    IF NOT EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission WHERE SubmissionID = @SubmissionID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin kê khai với ID %I64d.', 16, 1, @SubmissionID);
        RETURN;
    END

    -- ====================================================================================
    -- Result Set 1: Thông tin chung của Submission
    -- Sẽ nằm trong response.data[0]
    -- ====================================================================================
    SELECT
        S.SubmissionID,
        S.FormID,
        F.FormTitle,
        S.NamHoc,
        S.TrangThaiDuyet,
        S.GhiChuTuChoi,
        S.CreateTime,
        S.CreateUser,
        S.UpdateTime,
        S.UpdateUser,
        -- Lấy thông tin người kê khai
        NV.HoTen AS HoTenNguoiKeKhai
    FROM dbo.tblHDKH_KeKhai_Submission AS S
    JOIN dbo.tblHDKH_Form_Definition AS F ON S.FormID = F.FormID
    LEFT JOIN dbo.NhanVien AS NV ON S.NhanVienID_KeKhai = NV.MaNV
    WHERE S.SubmissionID = @SubmissionID;

    -- ====================================================================================
    -- Result Set 2: Dữ liệu chi tiết các Field đã nhập
    -- Sẽ nằm trong response.data[1]
    -- ====================================================================================
    SELECT
        FD.FieldLabel,
		FD.FieldName,
        FV.FieldValue,
        FD.FieldType,
        FD.FieldGroup,
        FD.SortOrder
    FROM dbo.tblHDKH_KeKhai_FieldValue AS FV
    JOIN dbo.tblHDKH_Field_Definition AS FD ON FV.FieldID = FD.FieldID
    WHERE FV.SubmissionID = @SubmissionID AND FV.IsDeleted = 0 AND FD.IsDeleted = 0
    ORDER BY FD.SortOrder;

    -- ====================================================================================
    -- Result Set 3: Danh sách thành viên tham gia và kết quả tính giờ
    -- Sẽ nằm trong response.data[2]
    -- ====================================================================================
     SELECT
        TV.ThanhVienID,
        TV.isNhanVienLHU,
        TV.NhanVienID,
        TV.HoTen, -- Lấy trực tiếp từ cột HoTen đã lưu
        TV.VaiTroID,
        TV.ViTri,
        TV.isTacGiaLienHe,
		KQC.SoGioQuyDoi_CaNhan AS SoGio_HeThongTinh,
        KQC.SoGio_DaDuyet,
        KQC.DienGiaiCachTinh
    FROM dbo.tblHDKH_KeKhai_ThanhVien AS TV
	LEFT JOIN dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC 
		ON TV.SubmissionID = KQC.SubmissionID 
		AND TV.NhanVienID = KQC.NhanVienID
		AND KQC.IsDeleted = 0
    WHERE TV.SubmissionID = @SubmissionID AND TV.IsDeleted = 0
    ORDER BY TV.ViTri, TV.ThanhVienID;

	-- ====================================================================================
    -- Result Set 4: Danh sách file
    -- Sẽ nằm trong response.data[3]
    -- ====================================================================================
	 SELECT
        MC.MinhChungID,
        MC.URLMinhChung,
        MC.FileID,
		F.FileName
    FROM dbo.tblHDKH_KeKhai_Submission_MinhChung AS MC
	LEFT JOIN FileData f ON mc.fileid = F.FileID
    WHERE MC.SubmissionID = @SubmissionID AND MC.IsDeleted = 0

END;

