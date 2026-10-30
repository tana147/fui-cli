CREATE   PROC [dbo].[spAPI_TuQuan_DangKyLich_Get]
    @LopID INT = NULL,
    @StartDate VARCHAR(20) = NULL,
    @EndDate VARCHAR(20) = NULL,
    @TuanHocID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dtStartDate DATE = TRY_CAST(@StartDate AS DATE);
    DECLARE @dtEndDate DATE = TRY_CAST(@EndDate AS DATE);

    SELECT 
        DangKyID,
        LopID,
        TuanHocID,
        CONVERT(VARCHAR(10), StartDate, 120) AS StartDate,
        CONVERT(VARCHAR(10), EndDate, 120) AS EndDate,
        Thu AS [key],
        CASE Thu 
            WHEN 2 THEN N'Thứ 2'
            WHEN 3 THEN N'Thứ 3'
            WHEN 4 THEN N'Thứ 4'
            WHEN 5 THEN N'Thứ 5'
            WHEN 6 THEN N'Thứ 6'
            ELSE N'Thứ ' + CAST(Thu AS NVARCHAR)
        END AS label,
        CONVERT(VARCHAR(10), Ngay, 120) AS NgayYMD,
        FORMAT(Ngay, 'dd/MM') AS [date],
        IsTuQuan,
        CoMat,
        GhiChu
    FROM dbo.tblTuQuan_DangKyLich
    WHERE (@LopID IS NULL OR LopID = @LopID)
      AND (@dtStartDate IS NULL OR StartDate = @dtStartDate)
      AND (@TuanHocID IS NULL OR TuanHocID = @TuanHocID)
      AND Enable = 1
    ORDER BY LopID, Thu;
END;