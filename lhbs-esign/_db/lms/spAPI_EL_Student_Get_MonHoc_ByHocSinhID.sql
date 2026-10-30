CREATE PROC [dbo].[spAPI_EL_Student_Get_MonHoc_ByHocSinhID]
    @HocSinhID INT
  , @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Bước 1: Lấy tất cả Lớp + Nhóm của học sinh (giống SP NhiemVu)
    DECLARE @MyUnits TABLE (UnitID VARCHAR(100));

    INSERT INTO @MyUnits (UnitID)
    SELECT hsl.LopID
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID
      AND hsl.Enable = 1
      AND hsl.NienKhoa = @NienKhoa
    UNION
    SELECT hsn.NhomID
    FROM dbo.tblHocSinhNhom hsn
    JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID
      AND hsn.Enable = 1;


    -- Bước 2: Lấy môn học theo lớp/nhóm từ các bài tập/bài học đã giao (dựa trên MonHocID thực tế của Bài tập/Bài học)
    SELECT DISTINCT
           mh.MonHocID
         , mh.TenMonHoc_HienThi
         , mh.Icon
         , mh.Color
    FROM (
        -- Môn học của bài tập giao cho lớp
        SELECT ISNULL(asm.MonHocID, mhl.MonHocID) AS MonHocID
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        JOIN dbo.tblEL_Assignments asm ON atc.ResourceID = asm.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' AND asm.IsDeleted = 0
        WHERE atc.IsDeleted = 0 AND atc.Status IN (1, 2)
          AND mhl.NienKhoa = @NienKhoa AND mhl.Enable = 1
          AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)

        UNION

        -- Môn học của bài học giao cho lớp
        SELECT ls.MonHocID
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        JOIN dbo.tblEL_Lessons ls ON atc.ResourceID = ls.LessonID AND atc.ResourceType = 'LESSON' AND ls.IsDeleted = 0
        WHERE atc.IsDeleted = 0 AND atc.Status IN (1, 2)
          AND mhl.NienKhoa = @NienKhoa AND mhl.Enable = 1
          AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)

        UNION

        -- Môn học của bài tập giao riêng học sinh
        SELECT ISNULL(asm.MonHocID, mhl.MonHocID) AS MonHocID
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblMonHocLop mhl ON ats.MonHocLopID = mhl.MonHocLopID
        JOIN dbo.tblEL_Assignments asm ON ats.ResourceID = asm.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' AND asm.IsDeleted = 0
        WHERE ats.IsDeleted = 0 AND ats.Status IN (1, 2)
          AND ats.HocSinhID = @HocSinhID
          AND mhl.NienKhoa = @NienKhoa AND mhl.Enable = 1
          AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
    ) src
    JOIN dbo.tblMonHoc mh ON mh.MonHocID = src.MonHocID
    WHERE mh.Enable = 1;
END;