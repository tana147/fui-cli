CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetLessontStats]
    @sys_UserID      VARCHAR(9)
  , @AssignToClassID BIGINT
  , @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------
    -- 1. Lấy thông tin user và quyền
    -------------------------------
    SELECT @sys_UserID      = SYS_USERID
         , @sys_SystemRight = SYS_SystemRight
    FROM
           dbo.Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    -------------------------------
    -- 2. Lấy LopHoacNhomID, MonHocID và NienKhoa
    -------------------------------
    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @MonHocID INT = 0;
    DECLARE @LessonID INT;
    DECLARE @NienKhoa INT;

    SELECT @LopHoacNhomID = mhl.LopNhomID
         , @MonHocID      = mhl.MonHocID
         , @LessonID      = atc.ResourceID
         , @NienKhoa      = COALESCE(atc.NienKhoa, dbo.fn_GetNienKhoa_HienTai())
    FROM
           dbo.tblEL_AssignToClass atc
           JOIN dbo.tblMonHocLop   mhl ON atc.MonHocLopID = mhl.MonHocLopID
                                      AND mhl.Enable      = 1
    WHERE
           atc.AssignToClassID = @AssignToClassID
      AND
           (
               atc.CreateUser       = @sys_UserID
          OR   @sys_SystemRight IN (3,5,9)
           )
      AND  atc.IsDeleted        = 0;

    IF @LopHoacNhomID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài hoặc bạn không có quyền truy cập.', 16, 1);
        RETURN;
    END;

    -------------------------------
    -- 3. Xác định là lớp hay nhóm
    -------------------------------
    DECLARE @IsNhom BIT = CASE WHEN TRY_CONVERT(INT, @LopHoacNhomID) IS NULL THEN 1 ELSE 0 END;
    -------------------------------
    -- 4. Chuẩn hóa danh sách học sinh theo Niên Khóa
    -------------------------------
    DECLARE @Table_HocSinh TABLE
    (
        HocSinhID INT
    );
    IF @IsNhom = 1
    BEGIN
        INSERT @Table_HocSinh
        SELECT hs.HocSinhID
        FROM
               dbo.tblHocSinhNhom        hsn
               INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                                           AND hs.TinhTrang = 0
               INNER JOIN dbo.tblNhom    n  ON n.NhomID      = hsn.NhomID
                                           AND n.MonHocID    = @MonHocID
                                           AND n.NienKhoa    = @NienKhoa
                                           AND n.Enable      = 1
        WHERE
               hsn.NhomID = @LopHoacNhomID
          AND  hsn.Enable  = 1;
    END;
    ELSE
    BEGIN
        INSERT @Table_HocSinh
        SELECT hs.HocSinhID
        FROM
               dbo.tblHocSinhLop         hsl
               INNER JOIN dbo.tblLop     l  ON hsl.LopID     = l.LopID
                                           AND l.NienKhoa    = @NienKhoa
               AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                           AND hs.TinhTrang = 0
        WHERE
               hsl.LopID = @LopHoacNhomID
          AND  (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
          AND  hsl.Enable = 1;
    END;

    -------------------------------
    -- 5. Trả về số liệu
    -------------------------------
    SELECT
        -- Tổng số học sinh
        (
            SELECT COUNT(*)
            FROM
                   @Table_HocSinh
        ) AS TotalStudents
      -- Số học sinh đã học (IsCompleted = 1)
      , (
            SELECT COUNT(DISTINCT lp.HocSinhID)
            FROM
                   @Table_HocSinh                         us
                   INNER JOIN dbo.tblEL_Learning_Progress lp ON lp.HocSinhID   = us.HocSinhID
                                                            AND lp.LessonID    = @LessonID
                                                            AND lp.IsCompleted = 1
                                                            AND lp.IsDeleted   = 0
        ) AS LearnedCount;
END;
