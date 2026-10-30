CREATE   PROCEDURE dbo.spAPI_SoGVCNList
    @NienKhoa int,
    @CapID varchar(20),
    @KhoiID int,
    @LopID varchar(10),
    @Keyword nvarchar(200),
    @sys_UserID varchar(20),
    @sys_SystemRight int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SoGVCNID = ISNULL(s.SoGVCNID, 0),
        l.NienKhoa,
        l.LopID,
        l.TenLop,
        l.KhoiID,
        CapID = CASE WHEN l.KhoiID BETWEEN 1 AND 5 THEN 1 WHEN l.KhoiID BETWEEN 6 AND 9 THEN 2 ELSE 3 END,
        GiaoVienID = ISNULL(s.GiaoVienID, ''),
        TrangThai = ISNULL(s.TrangThai, 'NEW'),
        UpdateTime = s.UpdateTime,
        SubmitTime = s.SubmitTime
    FROM dbo.tblLop l
    LEFT JOIN dbo.tblSoGVCN s
        ON s.LopID = l.LopID
       AND s.NienKhoa = l.NienKhoa
       AND s.Enable = 1
    WHERE l.Enable = 1
      AND (@NienKhoa = 0 OR l.NienKhoa = @NienKhoa)
      AND (@KhoiID = 0 OR l.KhoiID = @KhoiID)
      AND (@LopID = '' OR l.LopID = @LopID)
      AND (
          @CapID = ''
          OR (@CapID = '1' AND l.KhoiID BETWEEN 1 AND 5)
          OR (@CapID = '23' AND l.KhoiID BETWEEN 6 AND 12)
          OR CHARINDEX(',' + CAST(CASE WHEN l.KhoiID BETWEEN 1 AND 5 THEN 1 WHEN l.KhoiID BETWEEN 6 AND 9 THEN 2 ELSE 3 END AS varchar(10)) + ',', ',' + @CapID + ',') > 0
      )
      AND (@Keyword = N'' OR l.TenLop LIKE N'%' + @Keyword + N'%')
    ORDER BY l.NienKhoa DESC, l.KhoiID, l.TenLop;
END