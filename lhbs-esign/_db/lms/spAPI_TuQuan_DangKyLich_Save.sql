CREATE PROC [dbo].[spAPI_TuQuan_DangKyLich_Save]
    @LopID INT,
    @TuanHocID INT,
    @StartDate VARCHAR(20),
    @EndDate VARCHAR(20),
    @ScheduleJson NVARCHAR(MAX),
    @UserCode VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dtStartDate DATE = TRY_CAST(@StartDate AS DATE);
    DECLARE @dtEndDate DATE = TRY_CAST(@EndDate AS DATE);

    IF @dtStartDate IS NULL
        SET @dtStartDate = DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 5) % 7, CAST(GETDATE() AS DATE));
    IF @dtEndDate IS NULL
        SET @dtEndDate = DATEADD(DAY, 6, @dtStartDate);

    IF @ScheduleJson IS NOT NULL AND ISJSON(@ScheduleJson) = 1
    BEGIN
        MERGE INTO dbo.tblTuQuan_DangKyLich AS target
        USING (
            SELECT 
                @LopID AS LopID,
                @TuanHocID AS TuanHocID,
                @dtStartDate AS StartDate,
                @dtEndDate AS EndDate,
                [key] AS Thu,
                DATEADD(DAY, [key] - 2, @dtStartDate) AS Ngay,
                CAST(ISNULL(IsTuQuan, 0) AS BIT) AS IsTuQuan,
                CAST(ISNULL(CoMat, 1) AS BIT) AS CoMat,
                ISNULL(GhiChu, N'') AS GhiChu,
                @UserCode AS UserCode
            FROM OPENJSON(@ScheduleJson)
            WITH (
                [key] INT,
                IsTuQuan BIT,
                CoMat BIT,
                GhiChu NVARCHAR(500)
            )
        ) AS source
        ON (target.LopID = source.LopID AND target.StartDate = source.StartDate AND target.Thu = source.Thu AND target.Enable = 1)
        WHEN MATCHED THEN
            UPDATE SET 
                target.IsTuQuan = source.IsTuQuan,
                target.CoMat = source.CoMat,
                target.GhiChu = source.GhiChu,
                target.Ngay = source.Ngay,
                target.TuanHocID = source.TuanHocID,
                target.UpdateUser = source.UserCode,
                target.UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (LopID, TuanHocID, StartDate, EndDate, Thu, Ngay, IsTuQuan, CoMat, GhiChu, CreateUser, CreateTime, Enable)
            VALUES (source.LopID, source.TuanHocID, source.StartDate, source.EndDate, source.Thu, source.Ngay, source.IsTuQuan, source.CoMat, source.GhiChu, source.UserCode, GETDATE(), 1);

        -- Đồng bộ ngay lập tức sang tblTuQuan_DanhGiaNgay nếu ngày đó đã có đánh giá
        UPDATE dg
        SET dg.IsTuQuan = src.IsTuQuan,
            dg.GVCNCoMat = CASE WHEN src.IsTuQuan = 1 THEN 0 ELSE dg.GVCNCoMat END,
            dg.UpdateTime = GETDATE(),
            dg.UpdateUser = @UserCode
        FROM dbo.tblTuQuan_DanhGiaNgay dg
        INNER JOIN (
            SELECT 
                @LopID AS LopID,
                DATEADD(DAY, [key] - 2, @dtStartDate) AS Ngay,
                CAST(ISNULL(IsTuQuan, 0) AS BIT) AS IsTuQuan
            FROM OPENJSON(@ScheduleJson)
            WITH (
                [key] INT,
                IsTuQuan BIT
            )
        ) src ON (dg.LopID = src.LopID AND dg.Ngay = src.Ngay AND dg.Enable = 1);
    END;

    SELECT 
        DangKyID,
        LopID,
        TuanHocID,
        CONVERT(VARCHAR(10), StartDate, 120) AS StartDate,
        CONVERT(VARCHAR(10), EndDate, 120) AS EndDate,
        Thu AS [key],
        CONVERT(VARCHAR(10), Ngay, 120) AS NgayYMD,
        FORMAT(Ngay, 'dd/MM') AS [date],
        IsTuQuan,
        CoMat,
        GhiChu
    FROM dbo.tblTuQuan_DangKyLich
    WHERE LopID = @LopID 
      AND StartDate = @dtStartDate
      AND Enable = 1
    ORDER BY Thu;
END;