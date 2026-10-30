CREATE PROCEDURE [dbo].[spAPI_AUTH_TKB_Tuan_Get]
    @NamHoc VARCHAR(20),
    @DonViID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Đọc danh sách Tuần học chuẩn trực tiếp từ bảng tblTuanHocTap của DB LMS
    SELECT 
        TuanHocID AS TuanID,
        Tuan,
        TuanTrongNam,
        ThangHoc,
        NgayBatDau,
        NgayKetThuc,
        N'Tuần ' + CAST(TuanTrongNam AS NVARCHAR(10)) + N' (' + 
        CONVERT(VARCHAR(10), NgayBatDau, 103) + N' - ' +
        CONVERT(VARCHAR(10), NgayKetThuc, 103) + N')' AS TenTuan
    FROM dbo.tblTuanHocTap
    WHERE (@NamHoc IS NULL OR NienKhoa = CAST(@NamHoc AS INT))
    ORDER BY NgayBatDau, TuanTrongNam;
END