CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetLop_GiaoBai]
    @AssignmentID    INT
  , @ResourceType VARCHAR(20)
  , @MonHocID        INT
  , @KhoiID          INT
  , @sys_UserID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    SELECT @sys_SystemRight = SYS_SystemRight
         , @sys_UserID      = SYS_USERID
    FROM dbo.Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    IF (@KhoiID IS NULL OR @KhoiID = 0)
    BEGIN
        IF(@ResourceType = 'LESSON')
        BEGIN
            SELECT TOP 1 @KhoiID = KhoiID FROM dbo.tblEL_Lessons WHERE LessonID = @AssignmentID;
        END
        ELSE
        BEGIN
            SELECT TOP 1 @KhoiID = KhoiID FROM dbo.tblEL_Assignments WHERE AssignmentID = @AssignmentID;
        END
    END

    ;WITH AllClasses AS (
        -- 1. Từ phân công giảng dạy chính (tblMonHocLop)
        SELECT t.GiaoVienID
             , t.MonHocID
             , ISNULL(NULLIF(t.KhoiID, 0), ISNULL(l.KhoiID, n.KhoiID)) AS KhoiID
             , t.LopID
             , ISNULL(l.TenLop, n.TenNhom) AS TenLop
        FROM dbo.fn_GetGiaoVienTheoMonLop(@MonHocID, '', @NienKhoa_HienTai, @sys_UserID, @sys_SystemRight) AS t
        LEFT JOIN dbo.tblLop l ON l.LopID = t.LopID AND l.NienKhoa = @NienKhoa_HienTai
        LEFT JOIN dbo.tblNhom n ON n.NhomID = t.LopID AND n.NienKhoa = @NienKhoa_HienTai
        WHERE t.GiaoVienID = @sys_UserID
          AND EXISTS (
                   SELECT 1 FROM dbo.tblMonHocLop mhl
                   WHERE mhl.LopNhomID = t.LopID
                     AND mhl.MonHocID = @MonHocID
                     AND mhl.NienKhoa = @NienKhoa_HienTai
                     AND (mhl.Enable IS NULL OR mhl.Enable = 1)
               )

        UNION

        -- 2. Từ bảng tblGiaoVienLop
        SELECT gvl.GiaoVienID
             , ISNULL(NULLIF(gvl.MonHocID, 0), @MonHocID) AS MonHocID
             , ISNULL(NULLIF(gvl.KhoiID, 0), ISNULL(l.KhoiID, n.KhoiID)) AS KhoiID
             , gvl.LopID
             , ISNULL(l.TenLop, n.TenNhom) AS TenLop
        FROM dbo.tblGiaoVienLop gvl
        LEFT JOIN dbo.tblLop l ON l.LopID = gvl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa_HienTai
        LEFT JOIN dbo.tblNhom n ON n.NhomID = gvl.LopID AND n.Enable = 1 AND n.NienKhoa = @NienKhoa_HienTai
        WHERE gvl.GiaoVienID = @sys_UserID
          AND gvl.NienKhoa = @NienKhoa_HienTai
          AND (gvl.Enable IS NULL OR gvl.Enable = 1)
          AND (gvl.MonHocID = @MonHocID OR gvl.MonHocID IS NULL OR gvl.MonHocID = 0)

        UNION

        -- 3. Từ bảng tblEL_GiaoVienLop
        SELECT elgvl.GiaoVienID
             , ISNULL(NULLIF(elgvl.MonHocID, 0), @MonHocID) AS MonHocID
             , ISNULL(NULLIF(elgvl.KhoiID, 0), ISNULL(l.KhoiID, n.KhoiID)) AS KhoiID
             , elgvl.LopID
             , ISNULL(l.TenLop, n.TenNhom) AS TenLop
        FROM dbo.tblEL_GiaoVienLop elgvl
        LEFT JOIN dbo.tblLop l ON l.LopID = elgvl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa_HienTai
        LEFT JOIN dbo.tblNhom n ON n.NhomID = elgvl.LopID AND n.Enable = 1 AND n.NienKhoa = @NienKhoa_HienTai
        WHERE elgvl.GiaoVienID = @sys_UserID
          AND elgvl.NienKhoa = @NienKhoa_HienTai
          AND (elgvl.Enable IS NULL OR elgvl.Enable = 1)
          AND (elgvl.MonHocID = @MonHocID OR elgvl.MonHocID IS NULL OR elgvl.MonHocID = 0)
    )
    SELECT ac.GiaoVienID
         , ac.MonHocID
         , ac.KhoiID
         , ac.LopID
         , ac.TenLop
    FROM AllClasses ac
    WHERE ac.LopID NOT IN
    (
        SELECT DISTINCT mhl.LopNhomID
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = atc.MonHocLopID AND mhl.NienKhoa = @NienKhoa_HienTai
        WHERE atc.AssignmentID = @AssignmentID AND atc.ResourceType = @ResourceType AND atc.IsDeleted = 0
    )
      AND (
          (ac.KhoiID = @KhoiID)
          OR (@KhoiID IS NULL OR @KhoiID = 0)
          OR EXISTS (
              SELECT 1 FROM dbo.tblNhom n
              WHERE n.NhomID = ac.LopID
                AND n.IsNhomLMS_GiaoBai = 1
                AND n.NienKhoa = @NienKhoa_HienTai
          )
      )
    GROUP BY ac.GiaoVienID, ac.MonHocID, ac.KhoiID, ac.LopID, ac.TenLop
    ORDER BY ac.TenLop;
END;