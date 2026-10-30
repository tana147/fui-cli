CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetLearning_ProgressByStudent]
    @AssignToClassID BIGINT,
    @sys_UserID      VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize user
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @LessonID_Check INT;
    DECLARE @MonHocID INT = 0;
    DECLARE @NienKhoa INT;

    -- Get assign info and check permission
    SELECT @LessonID_Check = atc.ResourceID,
           @LopHoacNhomID  = mhl.LopNhomID,
           @MonHocID       = mhl.MonHocID,
           @NienKhoa       = COALESCE(atc.NienKhoa, dbo.fn_GetNienKhoa_HienTai())
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl
      ON atc.MonHocLopID = mhl.MonHocLopID
     AND mhl.Enable = 1
    WHERE atc.AssignToClassID = @AssignToClassID
      AND (atc.CreateUser = @sys_UserID OR @sys_SystemRight IN (5,9))
      AND atc.IsDeleted = 0;

    IF @LessonID_Check IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END

    /*
      Build a table variable that contains the "latest" progress row per HocSinh
      for the requested LessonID, excluding deleted progress rows.
      Use CompletedDate, falling back to LastAccessed for ordering.
    */
    DECLARE @LatestProgress TABLE
    (
        ProgressID INT,
        HocSinhID INT,
        IsCompleted BIT,
        CompletedDate DATETIME,
        CompletedByUserID VARCHAR(50),
        CompletionSource VARCHAR(30),
        LastAccessed DATETIME
    );

    INSERT INTO @LatestProgress (ProgressID, HocSinhID, IsCompleted, CompletedDate, CompletedByUserID, CompletionSource, LastAccessed)
    SELECT ProgressID, HocSinhID, IsCompleted, CompletedDate, CompletedByUserID, CompletionSource, LastAccessed
    FROM
    (
        SELECT lp.ProgressID,
               lp.HocSinhID,
               lp.IsCompleted,
               lp.CompletedDate,
               lp.CompletedByUserID,
               lp.CompletionSource,
               lp.LastAccessed,
               ROW_NUMBER() OVER (
                   PARTITION BY lp.HocSinhID
                   ORDER BY ISNULL(lp.CompletedDate, lp.LastAccessed) DESC, lp.ProgressID DESC
               ) AS rn
        FROM dbo.tblEL_Learning_Progress lp
        WHERE lp.LessonID = @LessonID_Check
          AND ISNULL(lp.IsDeleted, 0) = 0
    ) t
    WHERE t.rn = 1;

    -- Determine if Lop or Nhom (group id contains non-numeric -> Nhom)
    DECLARE @IsNhom BIT = CASE WHEN TRY_CONVERT(INT, @LopHoacNhomID) IS NULL THEN 1 ELSE 0 END;

    IF @IsNhom = 1
    BEGIN
        -- Group (nhóm) branch
        SELECT
            hsn.HocSinhID,
            ISNULL(hsn.SoTT, 0) AS SoDanhBo,
            hs.Ho + ' ' + hs.Ten AS HoTen,
            lp.ProgressID,
            lp.IsCompleted,
            lp.CompletedDate,
            lp.CompletedByUserID,
            lp.CompletionSource,
            n.NhomID,
            n.TenNhom,
            CASE
                WHEN lp.ProgressID IS NOT NULL AND ISNULL(lp.IsCompleted, 0) = 1 THEN 'COMPLETED'
                WHEN lp.ProgressID IS NOT NULL AND ISNULL(lp.IsCompleted, 0) = 0 THEN 'IN_PROCESS'
                ELSE 'NOT_COMPLETED'
            END AS Status
        FROM dbo.tblHocSinh hs
        INNER JOIN dbo.tblHocSinhNhom hsn
            ON hsn.HocSinhID = hs.HocSinhID
           AND hsn.Enable = 1
        INNER JOIN dbo.tblNhom n
            ON n.NhomID = hsn.NhomID
           AND n.Enable = 1
           AND n.MonHocID = @MonHocID
           AND n.NienKhoa = @NienKhoa
        LEFT JOIN @LatestProgress lp
            ON lp.HocSinhID = hs.HocSinhID
        WHERE hsn.NhomID = @LopHoacNhomID
          AND hs.TinhTrang = 0
        ORDER BY hsn.SoTT;
    END
    ELSE
    BEGIN
        -- Class (lớp) branch: normalize students (class + possible group entries), then join latest progress
        ;WITH UnitStudents AS
        (
            SELECT hsl.HocSinhID,
                   ISNULL(hsl.SoDanhBo, '') AS SoDanhBo
            FROM dbo.tblHocSinhLop hsl
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
            INNER JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
            AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.LopID = @LopHoacNhomID
              AND (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
              AND hsl.Enable = 1

            UNION

            SELECT hsn.HocSinhID,
                   ISNULL(CAST(hsn.SoTT AS VARCHAR(20)), '') AS SoDanhBo
            FROM dbo.tblHocSinhNhom hsn
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
            INNER JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
            WHERE hsn.NhomID = @LopHoacNhomID
              AND hsn.Enable = 1
        )
        SELECT
            us.HocSinhID,
            us.SoDanhBo,
            hs.Ho + ' ' + hs.Ten AS HoTen,
            lp.ProgressID,
            lp.IsCompleted,
            lp.CompletedDate,
            lp.CompletedByUserID,
            lp.CompletionSource,
            CASE
                WHEN lp.ProgressID IS NOT NULL AND ISNULL(lp.IsCompleted, 0) = 1 THEN 'COMPLETED'
                WHEN lp.ProgressID IS NOT NULL AND ISNULL(lp.IsCompleted, 0) = 0 THEN 'IN_PROCESS'
                ELSE 'NOT_COMPLETED'
            END AS Status
        FROM UnitStudents us
        LEFT JOIN @LatestProgress lp ON lp.HocSinhID = us.HocSinhID
        INNER JOIN dbo.tblHocSinh hs ON us.HocSinhID = hs.HocSinhID AND hs.TinhTrang = 0
        ORDER BY us.SoDanhBo, hs.Ten;
    END;
END;
