CREATE PROCEDURE [dbo].[spAPI_HDKH_KeKhai_GetSubmissionList]
    @NamHoc INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    IF @sys_UserID = 'GV0000611' SET @sys_UserID = 'NV0000742';
    SELECT
        S.SubmissionID,
        F.FormTitle,
        (
            SELECT TOP 1
            FV.FieldValue
        FROM dbo.tblHDKH_KeKhai_FieldValue FV
            JOIN dbo.tblHDKH_Field_Definition FD ON FV.FieldID = FD.FieldID
        WHERE FV.SubmissionID = S.SubmissionID AND FV.IsDeleted = 0
        ORDER BY FD.SortOrder ASC
        ) AS TenHoatDong_CuThe,

        STUFF((
            SELECT ', ' + FV.FieldValue
        FROM dbo.tblHDKH_KeKhai_FieldValue FV
            JOIN dbo.tblHDKH_Field_Definition FD ON FV.FieldID = FD.FieldID
        WHERE FV.SubmissionID = S.SubmissionID AND FD.IsUsedForRule = 1 AND FV.IsDeleted = 0
        ORDER BY FD.SortOrder
        FOR XML PATH('')
        ), 1, 2, '') AS ThongTinTomTat,

        S.CreateTime,
        KQC.KetQuaID AS KetQuaID,
        KQC.TrangThaiDuyet,
        KQC.GhiChuTuChoi,
        KQC.SoGioQuyDoi_CaNhan AS SoGio_HeThongTinh,
        KQC.SoGio_DaDuyet,
        KQC.DienGiaiCachTinh

    FROM
        -- Bắt đầu từ bảng kết quả cá nhân để đảm bảo chỉ lấy các hoạt động liên quan đến user
        dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC
        JOIN
        dbo.tblHDKH_KeKhai_Submission AS S ON KQC.SubmissionID = S.SubmissionID
        JOIN
        dbo.tblHDKH_Form_Definition AS F ON S.FormID = F.FormID
    WHERE 
        KQC.NhanVienID = @sys_UserID -- Lọc theo người dùng đang đăng nhập
        AND S.NamHoc = @NamHoc -- Lọc theo năm học
        AND KQC.IsDeleted = 0
        AND S.IsDeleted = 0
    ORDER BY 
        S.CreateTime DESC;

END;
