CREATE PROCEDURE [dbo].[spAPI_HDKH_KeKhai_GetDetailByID]
    @SubmissionID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sự tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission WHERE SubmissionID = @SubmissionID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin kê khai với ID %I64d.', 16, 1, @SubmissionID);
        RETURN;
    END

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
        TV.isTacGiaLienHe
    FROM dbo.tblHDKH_KeKhai_ThanhVien AS TV
    WHERE TV.SubmissionID = @SubmissionID AND TV.IsDeleted = 0
    ORDER BY TV.ViTri, TV.ThanhVienID;
    -- ======================================================================
    -- CÂU SELECT THỨ NHẤT: Trả về thông tin chính và các Fields
    -- Kết quả sẽ là một bảng có nhiều dòng (mỗi dòng một field)
    -- ======================================================================
    SELECT
        S.SubmissionID,
        S.FormID,
        S.NamHoc,
        FD.FieldName,
        FV.FieldValue,
		FD.FieldType,
		FD.FieldGroup,
		FD.FieldLabel
    FROM dbo.tblHDKH_KeKhai_Submission AS S
    JOIN dbo.tblHDKH_KeKhai_FieldValue AS FV ON S.SubmissionID = FV.SubmissionID
    JOIN dbo.tblHDKH_Field_Definition AS FD ON FV.FieldID = FD.FieldID
    WHERE S.SubmissionID = @SubmissionID AND S.IsDeleted = 0 AND FV.IsDeleted = 0;
    

    
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
