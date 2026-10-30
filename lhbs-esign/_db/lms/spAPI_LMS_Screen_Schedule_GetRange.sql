CREATE PROC [dbo].[spAPI_LMS_Screen_Schedule_GetRange]
    @NienKhoa INT,
    @PageNumber INT,
    @PageSize INT,
    @TypeScreen INT,
    @Search NVARCHAR(100),
    @FromDate DATE,
    @ToDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber IS NULL OR @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 200 SET @PageSize = 200;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    DECLARE @SearchTerm NVARCHAR(120) = NULL;

    IF @Search IS NOT NULL
    BEGIN
        SET @Search = LTRIM(RTRIM(@Search));
        IF @Search <> ''
        BEGIN
            SET @SearchTerm = '%' + @Search + '%';
        END
    END

    ;WITH DataSource AS (
        SELECT sch.*
             , lop.TenLop
             , lop.HocSinhID
        FROM dbo.tblLMS_View_Schedule sch
        OUTER APPLY (
            SELECT TRY_CAST(sch.CreateUser AS INT) AS CreateUserHocSinhID
        ) cu
        OUTER APPLY (
            SELECT TOP 1 l.TenLop, hsl.HocSinhID
            FROM dbo.tblHocSinhLop hsl
            JOIN dbo.tblLop l ON l.LopID     = hsl.LopID
                              AND l.NienKhoa = @NienKhoa
                              AND l.Enable   = 1
            AND hsl.NienKhoa = l.NienKhoa
        WHERE cu.CreateUserHocSinhID IS NOT NULL
              AND hsl.HocSinhID = cu.CreateUserHocSinhID
        ) lop
        WHERE sch.IsDeleted = 0
          AND (@TypeScreen IS NULL OR sch.TypeScreen = @TypeScreen)
          -- End date is inclusive for users; use the next midnight to include datetime values on that day.
          AND (@FromDate IS NULL OR sch.[Date] >= @FromDate)
          AND (@ToDate IS NULL OR sch.[Date] < DATEADD(DAY, 1, @ToDate))
          AND (
                @SearchTerm IS NULL
                OR CAST(sch.ViewID AS NVARCHAR(30)) LIKE @SearchTerm
                OR ISNULL(sch.CreateUser, '') LIKE @SearchTerm
                OR ISNULL(sch.UpdateUser, '') LIKE @SearchTerm
                OR ISNULL(lop.TenLop, '') LIKE @SearchTerm
              )
    )
    SELECT ds.*
         , COUNT(1) OVER() AS TotalRows
         , SUM(ISNULL(ds.ViewCount, 0)) OVER() AS TotalViewCount
         , SUM(CASE WHEN ds.TypeScreen = 0 THEN ISNULL(ds.ViewCount, 0) ELSE 0 END) OVER() AS MobileViewCount
         , SUM(CASE WHEN ds.TypeScreen = 1 THEN ISNULL(ds.ViewCount, 0) ELSE 0 END) OVER() AS DesktopViewCount
    FROM DataSource ds
    ORDER BY ds.[Date] DESC, ds.ViewID DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
